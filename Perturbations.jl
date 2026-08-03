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

function perturb_5(; negative::Bool=false)
    δ_vec = data_0["polling_bias_scale"] * (LinRange(0, .75, 30+1).^1)
    negative && (δ_vec = -δ_vec)
    data_vec = typeof(data_0)[]
    for (ℓ, δ_ℓ) in enumerate(δ_vec)
        # Create perturbed data
        data_1 = data_0 |> deepcopy
        data_1["polling_bias_loc"] .= δ_ℓ
        push!(data_vec, data_1)
    end
    data_vec
end

function perturb_6(; p::Int, negative::Bool=false)
    @assert 1 ≤ p ≤ data_0["P"]
    δ_vec = 0.1 * (LinRange(0, 1, 30+1).^2)
    negative && (δ_vec = -δ_vec)
    data_vec = typeof(data_0)[]
    for (ℓ, δ_ℓ) in enumerate(δ_vec)
        # Create perturbed data
        data_1 = data_0 |> deepcopy
        data_1["mu_c_loc"][p] += δ_ℓ
        push!(data_vec, data_1)
    end
    data_vec
end

function perturb_7(; negative::Bool=false)
    
    data_vec = typeof(data_0)[]
    
    λ_vec = Float64[]
    for str in readdir(joinpath("input"))
        if (occursin("cov", str) && occursin("$(RUN)", str))
            λ_str = split(str, "_")[end]  # "lambda=$(λ).csv"
            λ_str = split(λ_str, ".csv")[1]  # "lambda=$(λ)"
            λ_str = split(λ_str, "=")[end]  # "$(λ)"
            λ = parse(Float64, λ_str)
            push!(λ_vec, λ)

            data_1 = data_0 |> deepcopy
            cov_λ =  CSV.read(joinpath("input", str), DataFrame) |> Array |> mat2vecvec
            data_1["state_covariance_0"] = cov_λ
            push!(data_vec, data_1)
        end
    end

    sort_idx = λ_vec |> sortperm
    λ_vec = λ_vec[sort_idx]
    data_vec = data_vec[sort_idx]
    
    λ_0_idx = findall(λ_vec .== .75)
    @assert length(λ_0_idx) == 1
    λ_0_idx = λ_0_idx[1]

    if negative
        @info "λ↓:", λ_vec[λ_0_idx:-1:1]
        data_vec_neg = data_vec[λ_0_idx:-1:1]
    else
        @info "λ↑:", λ_vec[λ_0_idx:end]
        data_vec_pos = data_vec[λ_0_idx:end]
    end
end

function perturb_8(;
        L::Int=30,
        n::Int=800, state::String, pollster::String,
        date::Date=Date("2016-10-15"),
        poll_mode::Int=1, poll_pop_state::Int=2,
    )
    
    adjusters = ["ABC", "Washington Post", "Ipsos", "Pew", "YouGov", "NBC"]
    
    @assert RUN < date
    
    particles_0 = NamedArray(
        [param_constrain(model_0, draws_0[:r => r];
                include_tp=true,
                include_gq=true,
                rng=StanRNG(model_0, SEED)) for r in axes(draws_0, 1)] |> vecvec2mat,
        (axes(draws_0, 1), param_names(model_0; include_tp=true, include_gq=true)),
        (:n, :d))
    
    s_i = [i[1] for i in int2abbrev if i[end] == state]
    @assert length(s_i) == 1
    s_i = s_i[1]
    score = particles_0[:d => "predicted_score.$(data_0["T"]).$(s_i)"] |> mean

    if score > .5
        score -= .05
    else
        score += .05
    end
        
    n_dem = Int(round(score * n))
    δ_vec = LinRange(0, n_dem, L+1)
    @info "[$(date)] @$(state) by $(pollster), Dem/Two"; sleep(0.1)

    data_vec = []
    
    for (ℓ, δ_ℓ) in enumerate(δ_vec)

        n_dem_ℓ = δ_vec[ℓ] |> round |> Int
        n_ℓ = (δ_vec[ℓ] / score) |> round |> Int
        
        print((ℓ == 1 ? "" : " -> ") * "$(n_dem_ℓ)/$(n_ℓ)")
        data_1 = data_0 |> deepcopy

        if ℓ > 1
            data_1["N_state_polls"] += 1 # Update data size
            push!(data_1["state"], abbrev2int[state]) # Insert state
            push!(data_1["n_democrat_state"], n_dem_ℓ) # Hypothetical poll
            push!(data_1["n_two_share_state"], n_ℓ)
            push!(data_1["poll_mode_state"], poll_mode) # Insert poll mode
            push!(data_1["poll_pop_state"], poll_pop_state) # Insert poll_pop_state
            push!(data_1["unadjusted_state"], pollster ∈ adjusters ? 0 : 1)
            
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

function perturb_9(data_0; negative::Bool=false)
    data_1 = data_0 |> deepcopy

    RW_δ_vec = -LinRange(0, 0.05/5, 30+1)[2:end]
    c_δ_vec = LinRange(1, 1.25, 30+1)[2:end]
    
    negative && ((RW_δ_vec, c_δ_vec) = (-RW_δ_vec, 1 ./ c_δ_vec))
    data_vec = typeof(data_1)[]
    for (ℓ, (RW_δ_ℓ, c_δ_ℓ)) in enumerate(zip(RW_δ_vec, c_δ_vec))
        # Create perturbed data
        data_2 = data_1 |> deepcopy
        data_2["random_walk_scale"] = round((0.05 + RW_δ_ℓ) / sqrt(300) * 4; digits=4)
        data_2["polling_bias_scale"] = data_1["polling_bias_scale"] * c_δ_ℓ
        push!(data_vec, data_2)
    end
    
    data_vec
end

;