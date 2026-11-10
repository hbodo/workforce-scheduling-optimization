function construire_modele(data ;p_min = 1, p_semaine = 1)

model = Model(HiGHS.Optimizer)

	I = data.I
	J = data.J
	K = data.K
	T = data.T
	S = data.S
	D = data.D 
	N = data.N 
	nb_personnes = data.nb_personnes
	C = data.C 
	S_max = data.S_max 
	S_min = data.S_min
	TypeShift = data.TypeShift
	Jour = data.Jour
    Succ= data.Succ
	PrefType = data.PrefType
	PrefJour= data.PrefJour
	PoidsPref = data.PoidsPref
	TypeShiftBool = data.TypeShiftBool
	JourShiftBool = data.JourShiftBool
	
	# Les variables
	@variable(model,x[i in I,j in J], Bin)
	@variable(model,e[i in I] >= 0, Int)
	@variable(model,viol_jour[i in I, j in J], Bin)
	@variable(model,viol_type[i in I, j in J], Bin)
	@variable(model,viol_semaine[i in I] >= 0, Int)


    	# Les contraintes 
	for (p, j) in enumerate(J)
		# Nombre total de personnes sur le shift
		@constraint(
			model,
			sum(x[i,j] for i in I) == nb_personnes[p]
		)	

		# Nombre de personnes possédant chaque compétence
		for k in eachindex(K)
			@constraint(
				model,
				sum( x[I[m],j]*C[m,k] for m in eachindex(I)) >= N[p,k]
			)
		end
	end

	# Contraintes min / max
	for (m,i) in enumerate(I)
		@constraint(model, sum(x[i,j] for j in J) <= S_max[m])
		@constraint(model, sum(x[i,j] for j in J) + e[i] >= S_min[m])
	end

	# Contraintes de disponibilité
	for (p, j) in enumerate(J)
		for (m,i) in enumerate(I)
			@constraint(
				model,
				x[i,j] <= D[m,p])
		end
	end	

	# Contraintes de repos - les transitions non autorisées ont lieu le même jour ou le lendemain
	for i in I
		for (p,j) in enumerate(J)
			if p < length(J)
				@constraint(model, x[i,J[p]] + x[i,J[p+1]] <= 1 + Succ[TypeShift[J[p]], TypeShift[J[p+1]]]) 
			end
            if p < length(J)-1
				@constraint(model, x[i,J[p]] + x[i,J[p+2]] <= 1 + Succ[TypeShift[J[p]], TypeShift[J[p+2]]])
			end
		end
	end

	# Contraintes sur les préférences de shift 
	for (p,i) in enumerate(I)
		if  sum(PrefType[p, :]) == 1 #il y a une pref de type
			for (m,j) in enumerate(J) 
				for (l,t) in enumerate(T)
					@constraint(
						model, 
						x[i,j] * TypeShiftBool[m,l] * (1 - PrefType[p,l])
                    <= viol_type[i,j])
				end
			end
		end 
	end

	# Contraintes sur les préférences de jour 
	for (p,i) in enumerate(I)
		if  sum(PrefJour[p, :]) == 1 #il y a une pref de jour
			for (m,j) in enumerate(J) 
				for (l,k) in enumerate(S)
					@constraint(
						model, 
						x[i,j] * JourShiftBool[m,l] * (1 - PrefJour[p,l])
                    <= viol_jour[i,j])
				end
			end
		end 
	end

	# Contraintes sur les semaines trop chargées
	for i in I
		@constraint(model, sum(x[i,j] for j in J) - viol_semaine[i]  <= 5)
	end

    # Fonction objectif 
	@objective(model, Min, 
			   p_min * sum(e[i] for i in I)
			   + sum(PoidsPref[i] * sum(viol_type[i,j] for j in J) for i in I)
			  	+ sum(PoidsPref[i] * sum(viol_jour[i,j] for j in J) for i in I)
			   + p_semaine * sum(viol_semaine[i] for i in I)
			   
			  )
              
    return model, x, e, viol_type, viol_jour, viol_semaine

end