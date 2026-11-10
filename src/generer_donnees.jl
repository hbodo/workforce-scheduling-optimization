# Génération d'instances de planning de taille quelconque.
# Nécessite charger_donnees(), définie dans donnees.jl.
using Random

# Répartit `total` (entier) proportionnellement à `valeurs`, en donnant à chacun
# la partie entière de sa part, puis une unité de plus aux plus grands restes.
# Contrairement à round() case par case, la somme tombe exactement sur `total`.
function arrondi_somme(valeurs, total, rng)
    parts = valeurs .* (total / sum(valeurs))
    resultat = floor.(Int, parts)
    restes = parts .- resultat
    ordre = sortperm(restes .+ 1e-9 .* rand(rng, length(restes)), rev = true)  # hasard = départage des égalités
    for p in ordre[1:(total - sum(resultat))]
        resultat[p] += 1
    end
    return resultat
end

# L'employé i peut-il prendre le shift j, vu ce qu'il a déjà sur les 2 shifts précédents ?
# Même règle de repos que le modèle : Succ est testée à j+1 et j+2.
function repos_respecte(x, i, j, types, Succ)
    for ecart in 1:2
        if j - ecart >= 1 && x[i, j - ecart] == 1 && Succ[(types[j - ecart], types[j])] == 0
            return false
        end
    end
    return true
end

# Construit un planning complet, shift par shift. C'est lui qui garantit la faisabilité :
# les disponibilités et les besoins sont ensuite ajustés pour qu'il reste valide.
# S_max_semaine est le maximum de shifts par semaine de chaque employé.
function construire_planning_cache(D, C, S_max_semaine, N, nb_personnes, shifts_par_semaine, types, Succ, rng)
    n, m = size(D)
    x = zeros(Int, n, m)
    charge = zeros(Int, n)

    for j in 1:m
        if (j - 1) % shifts_par_semaine == 0
            charge .= 0                   # nouvelle semaine
        end
        restant = copy(N[j, :])           # compétences encore à couvrir sur ce shift
        for _ in 1:nb_personnes[j]
            candidats = [i for i in 1:n
                         if x[i, j] == 0 && charge[i] < S_max_semaine[i] && repos_respecte(x, i, j, types, Succ)]
            isempty(candidats) && break

            # Priorités : couvrir une compétence manquante, puis utiliser un employé
            # disponible, puis charger les moins remplis, le reste au hasard.
            score(i) = 2 * any(C[i, :] .* restant .> 0) + 2 * D[i, j] +
                       (1 - charge[i] / S_max_semaine[i]) + 0.1 * rand(rng)
            choisi = candidats[argmax(score.(candidats))]

            x[choisi, j] = 1
            charge[choisi] += 1
            restant .= max.(restant .- C[choisi, :], 0)
        end
    end
    return x
end

"""
    generer_donnees(n; semaines = 4, tension = 1.0, graine = 1, bruit_dispo = 0.10)

Génère une instance à `n` employés sur `semaines` semaines, soit 21 × semaines
shifts, avec les champs de `charger_donnees()` et trois champs en plus :
`semaines`, `shifts_par_semaine` et `planning_cache`, un planning qui respecte
les contraintes dures.

- Le planning cumule les semaines : les règles de repos s'appliquent aussi
  entre le dimanche et le lundi suivant.
- `S_min` et `S_max` restent des valeurs PAR SEMAINE.
- Besoins : ceux de `donnees.jl` multipliés par `tension × n/20`, identiques
  chaque semaine. Si le planning caché ne couvre pas toute la demande visée,
  les besoins sont ramenés à ce qu'il couvre.
- Employés : chacun reprend un profil de `donnees.jl`. Tous les profils sont
  utilisés le même nombre de fois, à une unité près.
- `bruit_dispo` : probabilité d'inverser chaque disponibilité reprise du profil.
- `graine` : à graine et version de Julia égales, l'instance est identique.
- `conforme` : si le planning est conforme au droit français.
"""
function generer_donnees(n; semaines = 4, tension = 1.0, graine = 1, bruit_dispo = 0.10, conforme = false)
    n >= 10 || error("generer_donnees : il faut au moins 10 employés")
    semaines >= 1 || error("generer_donnees : il faut au moins 1 semaine")
    rng = Xoshiro(graine)
    ref = charger_donnees()
    n_ref = length(ref.I)
    m_ref = length(ref.J)
    m = m_ref * semaines

    # Noms : E01... puis E001... si besoin ; même chose pour les shifts
    I = ["E$(lpad(i, max(2, ndigits(n)), '0'))" for i in 1:n]
    J = ["S$(lpad(j, max(2, ndigits(m)), '0'))" for j in 1:m]

    # Le type et le jour de chaque shift se répètent de semaine en semaine
    motif(j) = ref.J[(j - 1) % m_ref + 1]
    TypeShift = Dict(J[j] => ref.TypeShift[motif(j)] for j in 1:m)
    Jour = Dict(J[j] => ref.Jour[motif(j)] for j in 1:m)
    
    # 1. Besoins par shift, proportionnels à n, identiques chaque semaine
    total = round(Int, sum(ref.nb_personnes) * n / n_ref * tension)
    nb_semaine = arrondi_somme(ref.nb_personnes, total, rng)
    N_semaine = zeros(Int, m_ref, length(ref.K))
    for j in 1:m_ref
        total_shift = round(Int, sum(ref.N[j, :]) * nb_semaine[j] / ref.nb_personnes[j])
        N_semaine[j, :] = arrondi_somme(ref.N[j, :], total_shift, rng)
    end
    nb_personnes = repeat(nb_semaine, semaines)
    N = repeat(N_semaine, semaines)

    # 2. Chaque employé reprend un profil de référence
    profils = shuffle(rng, vcat(repeat(1:n_ref, n ÷ n_ref), randperm(rng, n_ref)[1:(n % n_ref)]))
    C = ref.C[profils, :]
    S_max_semaine = ref.S_max[profils]
    Succ = ref.Succ
    if conforme
        Succ = merge(ref.Succ, Dict(("M", "AP") => 0, ("AP", "N") => 0))  # pas deux shifts d'affilée : 10 h max par jour
        S_max_semaine = min.(S_max_semaine, 6)                          # 6 × 8 h = 48 h max par semaine
    end
    S_min_semaine = ref.S_min[profils]
    PrefType = ref.PrefType[profils, :]
    PrefJour = ref.PrefJour[profils, :]
    PoidsPref = Dict(I[i] => ref.PoidsPref[ref.I[profils[i]]] for i in 1:n)

    # 3. Variations entre employés d'un même profil et entre semaines
    D = repeat(ref.D[profils, :], 1, semaines)
    inversion = rand(rng, n, m) .< bruit_dispo
    D[inversion] .= 1 .- D[inversion]
    for i in 1:n
        if sum(PrefJour[i, :]) > 0         # le type de préférence reste celui du profil
            PrefJour[i, :] .= 0            # mais le jour préféré est retiré au hasard
            PrefJour[i, rand(rng, 1:length(ref.S))] = 1
        end
    end

    # 4. Le planning caché rend l'instance faisable
    types = [TypeShift[j] for j in J]
    x = construire_planning_cache(D, C, S_max_semaine, N, nb_personnes, m_ref, types, Succ, rng)
    D = max.(D, x)                         # un employé placé devient disponible
    nb_personnes = vec(sum(x, dims = 1))   # les besoins ne dépassent jamais le planning
    N = min.(N, x' * C)

    # Matrices booléennes, construites comme dans charger_donnees
    TypeShiftBool = zeros(m, length(ref.T))
    JourShiftBool = zeros(m, length(ref.S))
    for (p, j) in enumerate(J)
        TypeShiftBool[p, findfirst(==(TypeShift[j]), ref.T)] = 1
        JourShiftBool[p, findfirst(==(Jour[j]), ref.S)] = 1
    end

    return (;
        I, J, K = ref.K, T = ref.T, S = ref.S,
        D, N, nb_personnes, C,
        S_max = S_max_semaine, S_min = S_min_semaine,
        semaines, shifts_par_semaine = m_ref,
        TypeShift, Jour, Succ,
        PrefType, PrefJour, PoidsPref, TypeShiftBool, JourShiftBool,
        planning_cache = x
    )
end
