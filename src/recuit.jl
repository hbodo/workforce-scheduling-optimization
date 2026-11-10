using Random
using JuMP

function calcul_cout(x, data ; p_min = 1, p_semaine = 1)
	# x se présente sous la forme d'une matrice booléenne où les lignes sont
	# les employés et les colonnes les shifts.
	
	if x isa JuMP.Containers.DenseAxisArray
		x = Array(Int.(value(x)))
	end


	N = size(x,1)
	M = size(x,2)
	
	cout = 0
    nb_pref = 0
    nb_pref_jour = 0
    nb_surcharge = 0
    nb_min = 0

    # Index des shifts par semaine
    shifts_semaine(w, data) = ((w - 1) * data.shifts_par_semaine + 1):(w * data.shifts_par_semaine)
    
	# Valeur fonction objectif
	for i in 1:N
		for j in 1:M
			for l in eachindex(data.T)
				# preference type non respectee
				if data.PrefType[i,l] == 1 && x[i,j] > 0.5 && data.T[l] != data.TypeShift[data.J[j]]
                    nb_pref += data.PoidsPref[data.I[i]]
				end
			end

			for l in eachindex(data.S)
				# preference de jour non respectee
				if data.PrefJour[i,l] == 1 && x[i,j] > 0.5 && data.S[l] != data.Jour[data.J[j]]
                    nb_pref_jour += data.PoidsPref[data.I[i]]
				end
			end
		end

        
        for w in 1:data.semaines
            nb_shift = sum( x[i,j]  for j in shifts_semaine(w, data))
            if nb_shift < data.S_min[i] # moins de shifts que le minimum souhaité
                nb_min += p_min * (data.S_min[i] - nb_shift)
            end
            
            if nb_shift > 5
                nb_surcharge += p_semaine * (nb_shift - 5)
            end
        end

        cout = nb_pref + nb_pref_jour + nb_min + nb_surcharge
	end
	return cout, nb_pref, nb_pref_jour, nb_min, nb_surcharge
end


function controleContraintes(x, data)
    """
    Fonction de contrôle des contraintes dures. Retourne :
    Booléen 
    """
	# i est le numéro de l'employé
	# j est le numéro du shift
	if x isa JuMP.Containers.DenseAxisArray
		x = Array(Int.(value(x)))
	end
	N = size(x,1)
	M = size(x,2)

    
    # Index des shifts par semaine
    shifts_semaine(w, data) = ((w - 1) * data.shifts_par_semaine + 1):(w * data.shifts_par_semaine)

    
	for i in 1:N
		for j in 1:M
			# un employé n'est pas affecté sur un shift où il n'est pas disponible
			if x[i,j] == 1 && data.D[i,j] == 0
				return false
			end

            # les contraintes de repos
            if j <= M-1 && x[i,j] == 1 && x[i,j+1] == 1 && data.Succ[data.TypeShift[data.J[j]], data.TypeShift[data.J[j+1]]] == 0
                return false
            end
            
            if j <= M-2 && x[i,j] == 1 && x[i,j+2] == 1 && data.Succ[data.TypeShift[data.J[j]], data.TypeShift[data.J[j+2]]] == 0
                return false
            end

		end

		# un employé dépasse son nombre de shifts max
        for w in 1:data.semaines
    		if sum(x[i,j] for j in shifts_semaine(w, data)) > data.S_max[i]
    			return false
    		end
        end
	end

	
	for j in 1:M
		# un shift n'a pas le bon nombre de personnes requises
		if sum(x[i,j] for i in 1:N) != data.nb_personnes[j]
			return false
		end

		# Pas assez de personnes avec une compétence donnée sur le shift
		for l in eachindex(data.K) 
			nb_employes = sum(x[i,j] * data.C[i,l] for i in 1:N)
			if nb_employes < data.N[j,l]
				return false
			end
		end
	end
	
	return true
end



function voisinage(x, p1, p2)
    """
    Fonction qui génère un voisin de x. Retourne :
    x_voisin : matrice (n,m) de booléens où n est le nombre d'employés et m le nombre de shifts
    """
    x_voisin = copy(x)

    i1, j1 = p1
    i2, j2 = p2

    x_voisin[i1, j1] = 0
    x_voisin[i1, j2] = 1
    x_voisin[i2, j1] = 1
    x_voisin[i2, j2] = 0

    return x_voisin
end


function voisin_valide(x, data; limite=30)
    
    """
    Fonction qui retourne un voisin respecte les contraintes dures. Retourne :
    - x_candidat : matrice (n,m) de booléens où n est le nombre d'employés et m le nombre de shifts
    - nb_genere : le nombre de voisins générés
    - nb_invalides : le nombre de voisins invalides sur ceux générés
    """
    nb_genere = 0
    nb_invalide = 0
    # Convertir la solution en matrice numérique 
    if x isa JuMP.Containers.DenseAxisArray
        x = Array(Int.(value(x)))
    end

    for cpt in 1:limite

        # Coordonnées des affectations égales à 1
        coord = [(i, j) for i in axes(x, 1), j in axes(x, 2)
                 if x[i, j] == 1]

        # Il faut au moins deux affectations à échanger
        if length(coord) < 2
            return nothing
        end

        # Choisir deux affectations distinctes au hasard
        indices = randperm(length(coord))[1:2]
        p1 = coord[indices[1]]
        p2 = coord[indices[2]]

        # Éviter les échanges entre deux shifts identiques
        if p1[2] == p2[2]
            continue
        end

        if p1[1] == p2[1] || p1[2] == p2[2]
            continue
        end
        
        i1, j1 = p1
        i2, j2 = p2
        
        if x[i1, j2] != 0 || x[i2, j1] != 0
            continue
        end

        # Créer un candidat à partir du planning courant
        x_candidat = voisinage(x, p1, p2)
        nb_genere += 1 

        # Accepter uniquement les candidats valides
        if controleContraintes(x_candidat, data)
            return x_candidat, nb_genere, nb_invalide
        else
            nb_invalide += 1
        end
    end

    return nothing, nb_genere, nb_invalide
end

function recuit_simule(x0, data, t0, alpha, n_iter, steps)
    """
    Applique le recuit simulé à une matrice de booléens n x m où n est le nombre d'employés et m le nombre de shifts
    Retourne :
    - x_meilleur : le meilleur planning, matrice de booléens
    - c_meilleur : le meilleur coût
    - nb_valide : nombre de plannings valides
    - nb_genere_total : nombre total de plannings générés
    - nb_invalide_total : nombre total de plannings invalides générés
    - nb_accepte : nombre de plannings acceptés (delta negatif ou probabilité acceptable si dégradation)
    - nb_ameliore : nombre de plannings améliorés (delta negatif)
    - nb_degrade : nombre de plannings dégradés (avec probabilité acceptable)
    """
    # Initialisation des compteurs
    nb_valide = 0
    nb_genere_total = 0
    nb_invalide_total = 0
    nb_ameliore = 0
    nb_degrade = 0 
    nb_accepte = 0 

    # Convertir la solution initiale en matrice numérique
    if x0 isa JuMP.Containers.DenseAxisArray
        x = Array(Int.(value(x0)))
    else
        x = copy(x0)
    end

    # Planning courant
    c_courant = calcul_cout(x, data)[1]

    # Meilleur planning rencontré
    x_meilleur = copy(x)
    c_meilleur = c_courant

    t = t0

    for step in 1:steps
        for cpt in 1:n_iter

            x_voisin, nb_genere, nb_invalide = voisin_valide(x, data)

            # Cumuler les compteurs
            nb_genere_total += nb_genere
            nb_invalide_total += nb_invalide

            # Aucun voisin valide trouvé
            if x_voisin === nothing
                continue
            end

            nb_valide += 1

            c_voisin = calcul_cout(x_voisin, data)[1]
            delta = c_voisin - c_courant

            # Décider si on accepte le voisin
            if delta <= 0 || (t > 0 && rand() < exp(-delta / t))
                nb_accepte += 1
            
                if delta < 0
                    nb_ameliore += 1
                elseif delta > 0
                    nb_degrade += 1
                end
            
                x = copy(x_voisin)
                c_courant = c_voisin
            end

            # Mettre à jour le meilleur planning
            if c_courant < c_meilleur
                x_meilleur = copy(x)
                c_meilleur = c_courant
            end
        end

        # Refroidissement
        t = alpha * t
    end

    return x_meilleur, c_meilleur, nb_valide, nb_genere_total, nb_invalide_total, nb_accepte, nb_ameliore, nb_degrade
end

function voisin_valide_reaffectation(x, data; limite=30)
    """
    Sélectionne un voisin après réaffectation du shift à un employé disponible 
    Retourne :
    - x_candidat : un planning de booléen
    - nb_genere : nombre de candidats générés
    - nb_invalide : nombre de planning ne respectant par les contraintes
    """

    if x isa JuMP.Containers.DenseAxisArray
        x = Array(Int.(value(x)))
    end

    nb_genere = 0
    nb_invalide = 0

    # Coordonnées des affectations existantes
    coord = [(i, j) for i in axes(x, 1), j in axes(x, 2)
             if x[i, j] == 1]

    for cpt in 1:limite

        isempty(coord) && break

        # Choisir une affectation existante
        i1, j = rand(coord)

        # Chercher un employé qui n'est pas sur ce shift
        candidats = [i for i in axes(x, 1) if x[i, j] == 0]

        isempty(candidats) && continue

        i2 = rand(candidats)

        # Construire le nouveau planning
        x_candidat = copy(x)
        x_candidat[i1, j] = 0
        x_candidat[i2, j] = 1

        nb_genere += 1

        if controleContraintes(x_candidat, data)
            return x_candidat, nb_genere, nb_invalide
        else
            nb_invalide += 1
        end
    end

    return nothing, nb_genere, nb_invalide
end

function recuit_simule2(x0, data, t0, alpha, n_iter, steps)
    """
    Applique le recuit simulé à une matrice de booléens n x m où n est le nombre d'employés et m le nombre de shifts
    après avoir cherché un voisin par réaffectation
    Retourne :
    - x_meilleur : le meilleur planning, matrice de booléens
    - c_meilleur : le meilleur coût
    - nb_valide : nombre de plannings valides
    - nb_genere_total : nombre total de plannings générés
    - nb_invalide_total : nombre total de plannings invalides générés
    - nb_accepte : nombre de plannings acceptés (delta negatif ou probabilité acceptable si dégradation)
    - nb_ameliore : nombre de plannings améliorés (delta negatif)
    - nb_degrade : nombre de plannings dégradés (avec probabilité acceptable)
    """
    # Initialisation des compteurs
    nb_valide = 0
    nb_genere_total = 0
    nb_invalide_total = 0
    nb_ameliore = 0
    nb_degrade = 0 
    nb_accepte = 0 

    # Convertir la solution initiale en matrice numérique
    if x0 isa JuMP.Containers.DenseAxisArray
        x = Array(Int.(value(x0)))
    else
        x = copy(x0)
    end

    # Planning courant
    c_courant = calcul_cout(x, data)[1]

    # Meilleur planning rencontré
    x_meilleur = copy(x)
    c_meilleur = c_courant

    t = t0

    for step in 1:steps
        for cpt in 1:n_iter

            x_voisin, nb_genere, nb_invalide = voisin_valide_reaffectation(x, data)

            # Cumuler les compteurs
            nb_genere_total += nb_genere
            nb_invalide_total += nb_invalide

            # Aucun voisin valide trouvé
            if x_voisin === nothing
                continue
            end

            nb_valide += 1

            c_voisin = calcul_cout(x_voisin, data)[1]
            delta = c_voisin - c_courant

            # Décider si on accepte le voisin
            if delta <= 0 || (t > 0 && rand() < exp(-delta / t))
                nb_accepte += 1
            
                if delta < 0
                    nb_ameliore += 1
                elseif delta > 0
                    nb_degrade += 1
                end
            
                x = copy(x_voisin)
                c_courant = c_voisin
            end

            # Mettre à jour le meilleur planning
            if c_courant < c_meilleur
                x_meilleur = copy(x)
                c_meilleur = c_courant
            end
        end

        # Refroidissement
        t = alpha * t
    end

    return x_meilleur, c_meilleur, nb_valide, nb_genere_total, nb_invalide_total, nb_accepte, nb_ameliore, nb_degrade
end


"""
    Construction de la solution gloutonne
"""
function peut_travailler(x, data, i, j)
    data.D[i, j] == 1 || return false
    L = data.shifts_par_semaine
    w = (j - 1) ÷ L + 1            # numéro de la semaine du shift j
    sum(x[i, ((w - 1) * L + 1):(w * L)]) < data.S_max[i] || return false

    for ecart in 1:2
        p = j - ecart
        if p >= 1 && x[i, p] == 1 &&
           data.Succ[data.TypeShift[data.J[p]], data.TypeShift[data.J[j]]] == 0
            return false
        end
    end

    return true
end

function construire_planning(data; max_essais = 10_000)
    n = length(data.I)
    m = length(data.J)

    for essai in 1:max_essais
        x = zeros(Int, n, m)
        ok = true

        for j in 1:m
            candidats = shuffle!([i for i in 1:n if peut_travailler(x, data, i, j)])

            # Couvrir d'abord les compétences requises
            for l in eachindex(data.K)
                while sum(x[i, j] * data.C[i, l] for i in 1:n) < data.N[j, l]
                    idx = findfirst(i -> data.C[i, l] == 1, candidats)
                    if idx === nothing
                        ok = false
                        break
                    end
                    x[candidats[idx], j] = 1
                    deleteat!(candidats, idx)
                end
                ok || break
            end
            ok || break

            # Compléter l'effectif
            manque = data.nb_personnes[j] - sum(x[:, j])
            if manque < 0 || manque > length(candidats)
                ok = false
                break
            end
            x[candidats[1:manque], j] .= 1
        end

        if ok && controleContraintes(x, data)
            return x, essai
        end
    end

    return nothing, max_essais
end