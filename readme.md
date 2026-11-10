# Planning de shifts : programmation linéaire en nombres entiers et recuit simulé

Projet de recherche opérationnelle en Julia : affecter des employés à des shifts en respectant des règles dures (effectifs, compétences, repos) et en tenant compte au mieux de leurs préférences. Deux méthodes sont construites puis comparées :

- un **programme linéaire en nombres entiers** (PLNE), écrit avec la bibliothèque de modélisation [JuMP](https://jump.dev) et résolu par le solveur libre [HiGHS](https://highs.dev) ;
- un **recuit simulé**, métaheuristique implémentée à la main.

Les notebooks conservent volontairement la démarche complète, y compris les fausses pistes et les erreurs corrigées en cours de route.


---

## Le problème

**Instance de référence** (`src/donnees.jl`) : 20 employés, 21 shifts sur une semaine (7 jours × 3 types de shift : matin `M`, après-midi `AP`, nuit `N`).

**Contraintes dures** (toujours respectées) :
- nombre de personnes requis sur chaque shift ;
- nombre de personnes requis par compétence sur chaque shift ;
- disponibilités des employés ;
- nombre maximal de shifts par employé ;
- successions interdites entre types de shift, vérifiées sur le shift suivant et celui d'après.

<!-- À VÉRIFIER : liste des contraintes dures contre le notebook 02. -->

**Contraintes souples** (pénalisées dans la fonction objectif) :
- préférence de type de shift ou de jour, pondérée par employé ;
- nombre minimal de shifts souhaité, par shift manquant (cette contrainte était dure au départ et elle a été assouplie pour permettre la résolution du problème) ;
- semaine chargée : chaque shift au-delà de 5 dans la semaine.

> **Règles simplifiées.** Les règles de départ ne sont pas conformes au droit du travail : elles autorisent par exemple des journées de 16 h. Le projet porte sur la méthode d'optimisation, pas sur un planning applicable tel quel. Pour la comparaison finale, elles ont en partie été implémentées.

---

## Démarche

| Notebook | Contenu |
|---|---|
| `01-donnees` | Présentation des données et des règles du problème |
| `02-modelisation` | Trois formulations successives du PLNE. La première est infaisable avec un minimum de shifts en contrainte dure ; il devient ensuite une contrainte souple |
| `03-analyse` | Analyse de la solution optimale : vérification de la validité du modèle |
| `04-poids` | Sensibilité de la solution aux poids des pénalités et aux préférences ; indicateurs calculés à partir des affectations réelles |
| `05-recuit_simule` | Recuit simulé : deux voisinages (échange, réaffectation), réglage des paramètres, validation contre l'optimum de HiGHS |
| `06-comparaison` | Comparaison des deux méthodes sur des instances générées, plus grandes et sur plusieurs semaines |

---

## Principaux résultats


- **Instance de référence :** HiGHS prouve un coût optimal de **18**.
- **Voisinage par échange :** depuis un planning construit par un algorithme glouton, le recuit stagne à un coût de 37. Échanger deux affectations ne modifie pas le nombre de shifts de chaque employé, donc certaines pénalités ne peuvent pas baisser.
- **Voisinage par réaffectation :** le recuit retrouve l'optimum de 18 dans 49 essais sur 50, répartis sur cinq plannings de départ.
- **Instances générées :** HiGHS prouve l'optimum en 1,73 s sur 100 employés et 4 semaines avec des contraintes conformes au droit français. Le recuit met 35 ms par itération donc on estime qu'il faudrait 30 min pour résoudre le problème. 

**Conclusion.** Sur ces instances, le PLNE est la méthode adaptée : HiGHS prouve l'optimum rapidement, et le recuit ne peut au mieux qu'égaler ce coût. Le recuit deviendrait pertinent si des contraintes supplémentaires, difficiles à écrire de façon linéaire ou rendant le problème trop dur pour le solveur, étaient ajoutées. Ce cas n'a pas été testé.

---

## Limites et pistes

- **Équité :** le modèle ne répartit pas les violations de préférences équitablement entre employés.
- **Évaluation incrémentale :** le recuit recalcule le coût de tout le planning à chaque itération, alors qu'un déplacement ne modifie que quelques termes. Ne calculer que la variation accélérerait fortement chaque itération.
- **Réalisme :** les règles devraient être alignées sur le Code du travail (durée quotidienne, repos quotidien et hebdomadaire).

---

## Structure du dépôt

```
.
├── README.md
├── Project.toml          # paquets utilisés
├── Manifest.toml         # versions exactes, pour réexécuter à l'identique
├── notebooks/            # les 6 notebooks Jupyter, à lire dans l'ordre
└── src/
    ├── donnees.jl          # instance de référence (charger_donnees)
    ├── modele_v3.jl        # PLNE sur une semaine
    ├── modele_v4.jl        # PLNE sur plusieurs semaines
    ├── recuit.jl           # coût, contrôle des contraintes, voisinages, recuit simulé
    └── generer_donnees.jl  # générateur d'instances de taille quelconque
```

---

## Exécuter le projet

Prérequis : Julia [version 1.13] et Jupyter avec le noyau Julia ([IJulia](https://github.com/JuliaLang/IJulia.jl)).

```julia
# dans Julia, à la racine du dépôt
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

Ouvrir ensuite les notebooks du dossier `notebooks/` dans l'ordre. Le notebook 02 s'arrête volontairement sur l'erreur de la première formulation (problème infaisable) : exécuter les cellules suivantes une à une.

---

## Utilisation d'outils d'IA générative

Ce projet a été réalisé avec l'aide de Claude et ChatGPT. La répartition est la suivante :

- **Produit par l'IA, puis relu et intégré :** les données de l'instance de référence (`donnees.jl`), le générateur d'instances (`generer_donnees.jl`), la fonction `indicateurs` du notebook 04.
- **Avec l'aide de l'IA :** relecture du code et des textes, aide au diagnostic de bugs, opérations mécaniques sur les notebooks (fusion des versions du modèle dans le notebook 02), rédaction de ce README.
- **Mon travail :** la formulation du modèle, l'implémentation du recuit simulé, le choix et la conduite des expériences, l'interprétation des résultats et les conclusions.

---

## Auteure

Hélène Douchet

## Licence

Ce projet est distribué sous licence MIT. Voir le fichier [LICENSE](LICENSE).