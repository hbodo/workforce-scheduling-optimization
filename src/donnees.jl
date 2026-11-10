function charger_donnees()
# Les ensembles
	I = ["E$(lpad(i, 2, '0'))" for i in 1:20]
	J = ["S$(lpad(j, 2, '0'))" for j in 1:21]
	K = ["A","B","C","D"]
	T = ["M","AP","N"]
	S = ["Lun","Mar","Mer","Jeu","Ven","Sam","Dim"]
	# Les constantes
	# disponibilité par shift
	D = [ 	
		  1   1	  0	  1	  1	  0	  1	  1	  0	  1	  1	  0	  1	  1	  0	  1	  1	  0   1   1	0;
		1	0	0	1	1	0	1	0	0	1	1	0	1	0	0	1	1	0	1	0	0;
		0	1	1	1	0	1	0	1	1	1	0	1	0	1	1	0	1	1	0	1	1;
		1	1	0	0	1	0	1	1	0	0	1	0	1	1	0	1	1	0	1	1	0;
		1	1	1	1	1	0	1	1	1	1	1	0	1	1	1	1	1	0	1	1	1;
		1	0	0	1	1	0	1	0	0	1	1	0	1	0	0	1	1	0	1	0	0;
		0	1	0	1	1	1	0	1	1	0	1	1	0	1	1	0	1	1	0	1	1;
		0	0	1	0	0	1	0	0	1	0	0	1	0	0	1	0	0	1	0	0	1;
		1	1	0	1	0	0	1	1	0	1	0	0	1	1	0	1	0	0	1	1	0;
		1	1	1	1	0	1	1	0	1	1	1	0	1	0	1	1	0	1	1	0	1;
		1	0	0	0	1	0	1	0	0	1	1	0	1	0	0	1	1	0	1	0	0;
		1	1	0	1	0	0	1	1	0	1	0	0	1	1	0	1	1	0	1	1	0;
		1	1	1	1	1	0	1	1	1	1	1	0	1	1	1	1	1	0	1	1	1;
		0	0	1	0	0	1	0	0	1	0	0	1	0	0	1	0	0	1	0	0	1;
		1	1	0	0	1	0	1	1	0	0	1	0	1	1	0	1	1	0	1	1	0;
		1	0	0	1	1	0	1	0	0	1	1	0	1	0	0	1	1	0	1	0	0;
		0	1	0	1	1	1	0	1	1	0	1	1	0	1	1	0	1	1	0	1	1;
		1	1	1	1	1	1	1	1	1	1	1	0	1	1	1	1	1	1	1	1	1;
		0	0	1	0	0	1	0	0	1	0	0	1	0	0	1	0	0	1	0	0	1;
		1	1	0	1	1	0	1	1	0	1	1	0	1	1	0	1	1	0	1	1	0;	
	]

	# nombre d'employés par compétence sur les shifts
	N = [
	    2 1 1 1;
	    2 1 1 1;
	    1 1 1 0;
	    2 1 1 1;
	    2 1 1 1;
	    1 1 1 0;
	    2 1 1 1;
	    2 2 1 1;
	    1 1 1 0;
	    2 1 1 1;
	    2 1 1 1;
	    1 1 1 0;
	    2 1 1 1;
	    2 1 2 1;
	    1 1 1 1;
	    2 1 1 0;
	    2 1 1 1;
	    1 1 1 0;
	    2 1 1 0;
	    2 1 1 0;
	    1 1 1 0
	]

	# nombre de personnes sur les shifts
	nb_personnes = [
	    5, 5, 3, 6, 5, 3, 5,
	    6, 3, 5, 5, 3, 6, 6,
	    4, 4, 5, 3, 4, 4, 3
	]
	
	# compétences des employés
	C = [
	    1 1 0 0;
	    1 0 1 0;
	    1 0 0 1;
	    0 1 1 0;
	    1 1 1 0;
	    1 0 0 1;
	    0 1 0 1;
	    0 0 1 0;
	    1 1 0 0;
	    1 0 1 1;
	    0 1 1 0;
	    1 0 0 1;
	    1 1 1 0;
	    0 0 1 1;
	    1 1 0 0;
	    1 0 1 0;
	    0 1 0 1;
	    1 1 1 1;
	    0 0 1 0;
	    1 1 0 1
	]

	# shifts maximum et minimum par employé
	S_max = [
	    8, 9, 8, 8, 10, 9, 8, 7, 10, 9,
	    8, 8, 10, 8, 9, 8, 8, 10, 7, 9
	]

	S_min = [
	    5, 5, 4, 4, 6, 5, 4, 4, 6, 5,
	    4, 4, 6, 4, 5, 4, 4, 6, 4, 5
	]

	# Le type de chaque shift
	TypeShift = Dict(
	    "S01" => "M",
	    "S02" => "AP",
	    "S03" => "N",
	    "S04" => "M",
	    "S05" => "AP",
	    "S06" => "N",
	    "S07" => "M",
	    "S08" => "AP",
	    "S09" => "N",
	    "S10" => "M",
	    "S11" => "AP",
	    "S12" => "N",
	    "S13" => "M",
	    "S14" => "AP",
	    "S15" => "N",
	    "S16" => "M",
	    "S17" => "AP",
	    "S18" => "N",
	    "S19" => "M",
	    "S20" => "AP",
	    "S21" => "N"
	)

	# Le jour de chaque shift

	Jour = Dict(
	    "S01" => "Lun",
	    "S02" => "Lun",
	    "S03" => "Lun",
	    "S04" => "Mar",
	    "S05" => "Mar",
	    "S06" => "Mar",
	    "S07" => "Mer",
	    "S08" => "Mer",
	    "S09" => "Mer",
	    "S10" => "Jeu",
	    "S11" => "Jeu",
	    "S12" => "Jeu",
	    "S13" => "Ven",
	    "S14" => "Ven",
	    "S15" => "Ven",
	    "S16" => "Sam",
	    "S17" => "Sam",
	    "S18" => "Sam",
	    "S19" => "Dim",
	    "S20" => "Dim",
	    "S21" => "Dim"
	)

	# Les successions autorisées ou pas
	Succ = Dict(
	    ("M", "M") => 1,
	    ("M", "AP") => 1,
	    ("M", "N") => 0,
	    ("AP", "M") => 0,
	    ("AP", "AP") => 1,
	    ("AP", "N") => 1,
	    ("N", "M") => 0,
	    ("N", "AP") => 0,
	    ("N", "N") => 1
	)

	# Les préférences de type de shift
	PrefType = [
	#       M  A  N
	    1 0 0;  # E01
	    1 0 0;  # E02
	    0 1 0;  # E03
	    0 1 0;  # E04
	    0 0 0;  # E05
	    1 0 0;  # E06
	    0 1 0;  # E07
	    0 0 1;  # E08
	    0 1 0;  # E09
	    0 0 0;  # E10
	    0 1 0;  # E11
	    1 0 0;  # E12
	    1 0 0;  # E13
	    0 0 1;  # E14
	    0 1 0;  # E15
	    1 0 0;  # E16
	    0 0 0;  # E17
	    0 0 0;  # E18
	    0 0 1;  # E19
	    0 1 0   # E20
	]

	# Les préférences de journée
	PrefJour = [
	#       Lun Mar Mer Jeu Ven Sam Dim
	    0 0 0 0 0 0 0;  # E01
	    0 0 0 0 0 0 0;  # E02
	    0 0 0 0 0 0 0;  # E03
	    0 0 0 0 0 0 0;  # E04
	    0 0 0 0 0 1 0;  # E05
	    0 0 0 0 0 0 0;  # E06
	    0 0 0 0 0 0 0;  # E07
	    0 0 0 0 0 0 0;  # E08
	    0 0 0 0 0 0 0;  # E09
	    0 0 0 0 1 0 0;  # E10
	    0 0 0 0 0 0 0;  # E11
	    0 0 0 0 0 0 0;  # E12
	    0 0 0 0 0 0 0;  # E13
	    0 0 0 0 0 0 0;  # E14
	    0 0 0 0 0 0 0;  # E15
	    0 0 0 0 0 0 0;  # E16
	    0 0 0 0 0 0 1;  # E17
	    0 0 0 0 0 0 0;  # E18
	    0 0 0 0 0 0 0;  # E19
	    0 0 0 0 0 0 0   # E20
	]

	# Le poids des préférences
	PoidsPref = Dict(
	    "E01" => 3,
	    "E02" => 2,
	    "E03" => 3,
	    "E04" => 2,
	    "E05" => 1,
	    "E06" => 2,
	    "E07" => 3,
	    "E08" => 3,
	    "E09" => 2,
	    "E10" => 1,
	    "E11" => 2,
	    "E12" => 3,
	    "E13" => 1,
	    "E14" => 3,
	    "E15" => 2,
	    "E16" => 2,
	    "E17" => 1,
	    "E18" => 0,
	    "E19" => 3,
	    "E20" => 2
	)
	
	# Les types par shift/jour en booléen
	TypeShiftBool = zeros(length(J), length(T))
	JourShiftBool = zeros(length(J), length(S))
	
	for (p, j) in enumerate(J)
	    TypeShiftBool[p, findfirst(==(TypeShift[j]), T)] = 1
	    JourShiftBool[p, findfirst(==(Jour[j]), S)] = 1
	end

    return (;
        I, J, K, T, S,
        D, N, nb_personnes, C, S_max, S_min,
        TypeShift, Jour, Succ,
        PrefType, PrefJour, PoidsPref, TypeShiftBool, JourShiftBool,
		semaines = 1, shifts_par_semaine = 21,
    ) 
end