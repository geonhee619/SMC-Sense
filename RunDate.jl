df = CSV.read(joinpath("input", "df_$(RUN).csv"), DataFrame);

data_0 = JSON.parsefile(joinpath("input", "data_$(RUN).json"))
model_0 = StanModel(
    joinpath("input", "poll_model_2020.stan"),
    joinpath("input", "data_$(RUN).json"),
    SEED
)

int2ev = CSV.read(joinpath("input", "2012.csv"), DataFrame)
int2ev = [filter(row -> row.state == int2abbrev[s_i], int2ev).ev[1] for s_i in 1:data_0["S"]]

include("Functions.jl")
include("Perturbations.jl")

draws_0 = load(joinpath("input", "draws_$(RUN).jld"))["data"]
draws_0 = NamedArray(
    draws_0,
    (axes(draws_0,1), param_unc_names(model_0)),
    (:r, :d),
)
stats_0 = CSV.read(joinpath("input", "stats-df_$(RUN).csv"), DataFrame);

;