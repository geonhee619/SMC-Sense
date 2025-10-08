struct LogDensity
    model::StanModel
    data::typeof(data_0)
end

LogDensityProblems.capabilities(::Type{<:LogDensity}) = LogDensityProblems.LogDensityOrder{1}()
LogDensityProblems.logdensity_and_gradient(p::LogDensity, θ) = log_density_gradient(p.model, θ)
LogDensityProblems.dimension(p::LogDensity) = p.model |> param_unc_num

function run_MCMC(ℓπ::LogDensity)
    
    D = LogDensityProblems.dimension(ℓπ)
    metric = DiagEuclideanMetric(D)
    hamiltonian = Hamiltonian(metric, ℓπ)
    
    n_samples, n_adapts, thin = 1_200 * 3, 200, 3
    
    initial_θ = rand(Uniform(-1,1), D)
    initial_ϵ = find_good_stepsize(hamiltonian, initial_θ)
    integrator = Leapfrog(initial_ϵ)
    
    kernel = HMCKernel(Trajectory{MultinomialTS}(integrator, GeneralisedNoUTurn()))
    adaptor = StanHMCAdaptor(MassMatrixAdaptor(metric), StepSizeAdaptor(0.8, integrator))
    
    samples, stats = sample(hamiltonian, kernel, initial_θ, n_samples, adaptor, n_adapts; progress=true)

    global stats = stats
    global samples = samples[n_adapts+1 : thin : end] |> vecvec2mat
    return
end

function save_SMC(results, perturb_i::String)
    
    (; ℓπ_vec, names_vec, D_vec, 
        particles, weights,
        ESS, k̂, mcmc_flag,
        R, N, L,
        times
    ) = results
    
    DIR = joinpath("output", perturb_i, "smc-4")
    isdir(DIR) || mkpath(DIR) # Ensure path is present
    
    save(joinpath(DIR, "particles.jld"), "data", particles .|> Matrix |> Vector) # [L][N,D]
    save(joinpath(DIR, "weights.jld"),   "data", weights |> Matrix)              # [L,N]
    save(joinpath(DIR, "ESS.jld"),       "data", ESS |> Vector)                  # [L]
    save(joinpath(DIR, "khat.jld"),      "data", k̂ |> Vector)                    # [L]
    save(joinpath(DIR, "mcmc-flag.jld"), "data", mcmc_flag |> Vector)            # [L]
    save(joinpath(DIR, "times.jld"),     "data", times |> Vector)                # [L]
    
    return
end

function load_SMC(perturb_i::String)

    ℓπ_vec, names_vec, D_vec = nothing, nothing, nothing
    if perturb_i == "1"
        ℓπ_vec = perturb_1(s="CA") |> return_LogDensities
    elseif perturb_i == "1-neg"
        ℓπ_vec = perturb_1(s="CA", negative=true) |> return_LogDensities
    elseif perturb_i == "2"
        ℓπ_vec = perturb_2() |> return_LogDensities
    elseif perturb_i == "2-neg"
        ℓπ_vec = perturb_2(negative=true) |> return_LogDensities
    elseif perturb_i == "3"
        ℓπ_vec = perturb_3() |> return_LogDensities
    elseif perturb_i == "3-inv"
        ℓπ_vec = perturb_3(inverse=true) |> return_LogDensities
    elseif perturb_i == "4"
        ℓπ_vec = perturb_4(30;
            state="PA", n_dem=300, n=600, date=RUN + Day(10),
            poll_mode=1, poll_pop_state=3, pollster="NBC"
        ) |> return_LogDensities
    end
    L = length(ℓπ_vec) - 1
    ℓπ_vec      = NamedArray(ℓπ_vec,                                       0:L, :l)
    names_vec   = NamedArray([param_unc_names(ℓπ.model) for ℓπ in ℓπ_vec], 0:L, :l)
    D_vec       = NamedArray(LogDensityProblems.dimension.(ℓπ_vec),        0:L, :l)
    
    DIR = joinpath("output", perturb_i, "smc")
    
    particles = NamedArray(
        [((N,D) = size(particle);
            NamedArray(particle, (1:N, 1:D), (:n, :d))
            ) for particle in load(joinpath(DIR, "particles.jld"))["data"]],
        0:L, :l)
    weights   = load(joinpath(DIR, "weights.jld"))["data"]
    R = N     = size(weights,2)
    weights   = NamedArray(weights, (0:L, 1:N), (:l,:n))
    
    ESS       = NamedArray(load(joinpath(DIR, "ESS.jld"))["data"],       0:L, :l)
    k̂         = NamedArray(load(joinpath(DIR, "khat.jld"))["data"],      0:L, :l)
    mcmc_flag = NamedArray(load(joinpath(DIR, "mcmc-flag.jld"))["data"], 0:L, :l)
    times     = NamedArray(load(joinpath(DIR, "times.jld"))["data"],     0:L, :l)
    
    (; ℓπ_vec, names_vec, D_vec, 
        particles, weights,
        ESS, k̂, mcmc_flag,
        R, N, L,
        times)
end

function plot_trend(θ::Array{Float64, 2})
    plot!(START:END, _mean(θ .|> logistic; dims=1),
        color=:blue)
    plot!(START:END, _quantile(θ .|> logistic; dims=1, α=0.1),
        fillrange=_quantile(θ .|> logistic; dims=1, α=1-0.1),
        color=:blue, alpha=0.2, linewidth=0)
end

;