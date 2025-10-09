function return_LogDensities(data_vec::Vector{typeof(data_0)})::Vector{LogDensity}
    
    DIR = joinpath("input", "tmp")
    isdir(DIR) || mkpath(DIR) # Ensure path is present
    
    models = StanModel[]
    @showprogress for (ℓ, data_1) in enumerate(data_vec)
        # Save data-JSON and model-Stan for later use
        _name = joinpath("input", "tmp", "data_$(RUN)_$(ℓ).json")
        open(_name, "w") do f
            JSON.print(f, data_1) 
        end
        model_1 = StanModel(
            joinpath("input", "poll_model_2020.stan"),
            _name,
            SEED
        )
        push!(models, model_1)
        IJulia.clear_output(); sleep(0.01)
    end
    [LogDensity(model, data) for (model, data) in zip(models, data_vec)]
end
    
function perturb_1(; s::String, negative::Bool=false)
    δ_vec = LinRange(0, .1, 30+1)
    negative && (δ_vec = -δ_vec)
    data_vec = typeof(data_0)[]
    for (ℓ, δ_ℓ) in enumerate(δ_vec)
        # Create perturbed data
        data_1 = data_0 |> deepcopy
        data_1["mu_b_prior"][abbrev2int[s]] += δ_ℓ
        push!(data_vec, data_1)
    end
    data_vec
end

function perturb_2(; negative::Bool=false)
    δ_vec = LinRange(0, 0.05/5, 30+1)
    negative && (δ_vec = -δ_vec)
    data_vec = typeof(data_0)[]
    for (ℓ, δ_ℓ) in enumerate(δ_vec)
        # Create perturbed data
        data_1 = data_0 |> deepcopy
        data_1["random_walk_scale"] = round((0.05 + δ_ℓ) / sqrt(300) * 4; digits=4)
        push!(data_vec, data_1)
    end
    data_vec
end

function perturb_3(; inverse::Bool=false)
    δ_vec = LinRange(1, 1.25, 30+1)
    inverse && (δ_vec = 1 ./ δ_vec)
    data_vec = typeof(data_0)[]
    for (ℓ, δ_ℓ) in enumerate(δ_vec)
        # Create perturbed data
        data_1 = data_0 |> deepcopy
        data_1["mu_b_T_scale"] = δ_ℓ * data_1["mu_b_T_scale"]
        push!(data_vec, data_1)
    end
    data_vec
end

function perturb_4(L::Int64;
        state::String, n_dem::Int, n::Int, date::Date,
        poll_mode::Int, poll_pop_state::Int, pollster::String
    )::Vector{typeof(data_0)}

    δ_vec = LinRange(0, n_dem, L+1)
    
    @info "[$(date)] @$(state) by $(pollster), Dem/Two"; sleep(0.1)
    r = n_dem / n
    data_vec = []
    
    for (ℓ, δ_ℓ) in enumerate(δ_vec)

        n_dem_ℓ = δ_vec[ℓ] |> round |> Int
        n_ℓ = (δ_vec[ℓ] / r) |> round |> Int
        
        print((ℓ == 1 ? "" : " -> ") * "$(n_dem_ℓ)/$(n_ℓ)")
        data_1 = data_0 |> deepcopy

        if ℓ > 1
            data_1["N_state_polls"] += 1 # Update data size
            push!(data_1["state"], abbrev2int[state]) # Insert state
            push!(data_1["n_democrat_state"], n_dem_ℓ) # Hypothetical poll
            push!(data_1["n_two_share_state"], n_ℓ)
            push!(data_1["poll_mode_state"], poll_mode) # Insert poll mode
            push!(data_1["poll_pop_state"], poll_pop_state) # Insert poll_pop_state
            push!(data_1["unadjusted_state"], 1)
            
            """Specify the date"""
            t = findall(START:END .== date)[1]
            @assert 1 ≤ t < data_1["T"]
            push!(data_1["day_state"], t)
            
            """Pollster"""
            pollster_i = findall(unique(df.pollster) .== pollster)[1] # Matches R code
            push!(data_1["poll_state"], pollster_i)
        end
        
        push!(data_vec, data_1)
    end

    data_vec
end

;