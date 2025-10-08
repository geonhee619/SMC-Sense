using DataFrames, CSV, JLD
using Dates, LaTeXStrings
using LinearAlgebra, SparseArrays, NamedArrays
using Random, Distributions, StatsBase, StatsFuns, GLM
using Plots, StatsPlots, ProgressMeter
using AdvancedHMC, LogDensityProblems
using JSON, RData, BridgeStan, PSIS
# using CUDA

vecvec2mat(_v) = reduce(hcat, _v)' |> Matrix
mat2vecvec(_m) = [_m[i,:] for i in 1:size(_m,1)]
symmetric(_m) = Symmetric((_m + _m') ./ 2)
_round(_x::Float64)::Float64 = round(_x; digits=3)
_sum(_M; dims::Int64) = dropdims(sum(_M; dims=dims); dims=dims)
_mean(_M; dims::Int64) = dropdims(mean(_M; dims=dims); dims=dims)
_var(_M; dims::Int64) = dropdims(var(_M; dims=dims); dims=dims)
_quantile(_mat; dims::Int64, α::Float64) = dropdims(mapslices(_vec -> quantile(_vec, α), _mat; dims=dims); dims=dims)

default(size=(500,200), legend=false, tick_direction=:out, dpi=300)
ProgressMeter.ijulia_behavior(:clear)

SEED = 1843 # from original code
START, END = Date("2016-03-01"), Date("2016-11-09")
RUN = END - Day(90)
RUN_MCMC = false

abbrev2full = Dict(
    "AK" => "Alaska", "AL" => "Alabama", "AR" => "Arkansas", "AZ" => "Arizona", "CA" => "California",
    "CO" => "Colorado", "CT" => "Connecticut", "DC" => "District of Columbia", "DE" => "Delaware",
    "FL" => "Florida", "GA" => "Georgia", "HI" => "Hawaii", "IA" => "Iowa", "ID" => "Idaho",
    "IL" => "Illinois", "IN" => "Indiana", "KS" => "Kansas", "KY" => "Kentucky", "LA" => "Louisiana",
    "MA" => "Massachusetts", "MD" => "Maryland", "ME" => "Maine", "MI" => "Michigan", "MN" => "Minnesota",
    "MO" => "Missouri", "MS" => "Mississippi", "MT" => "Montana", "NC" => "North Carolina",
    "ND" => "North Dakota", "NE" => "Nebraska", "NH" => "New Hampshire", "NJ" => "New Jersey",
    "NM" => "New Mexico", "NV" => "Nevada", "NY" => "New York", "OH" => "Ohio", "OK" => "Oklahoma",
    "OR" => "Oregon", "PA" => "Pennsylvania", "RI" => "Rhode Island", "SC" => "South Carolina",
    "SD" => "South Dakota", "TN" => "Tennessee", "TX" => "Texas", "UT" => "Utah", "VA" => "Virginia",
    "VT" => "Vermont", "WA" => "Washington", "WI" => "Wisconsin", "WV" => "West Virginia", "WY" => "Wyoming"
)
int2full = Dict(
    1 => "Alaska", 2 => "Alabama", 3 => "Arkansas", 4 => "Arizona", 5 => "California",
    6 => "Colorado", 7 => "Connecticut", 8 => "District of Columbia", 9 => "Delaware",
    10 => "Florida", 11 => "Georgia", 12 => "Hawaii", 13 => "Iowa", 14 => "Idaho",
    15 => "Illinois", 16 => "Indiana", 17 => "Kansas", 18 => "Kentucky", 19 => "Louisiana",
    20 => "Massachusetts", 21 => "Maryland", 22 => "Maine", 23 => "Michigan", 24 => "Minnesota",
    25 => "Missouri", 26 => "Mississippi", 27 => "Montana", 28 => "North Carolina",
    29 => "North Dakota", 30 => "Nebraska", 31 => "New Hampshire", 32 => "New Jersey",
    33 => "New Mexico", 34 => "Nevada", 35 => "New York", 36 => "Ohio", 37 => "Oklahoma",
    38 => "Oregon", 39 => "Pennsylvania", 40 => "Rhode Island", 41 => "South Carolina",
    42 => "South Dakota", 43 => "Tennessee", 44 => "Texas", 45 => "Utah", 46 => "Virginia",
    47 => "Vermont", 48 => "Washington", 49 => "Wisconsin", 50 => "West Virginia", 51 => "Wyoming"
)
int2abbrev = Dict(
    1 => "AK",  2 => "AL",  3 => "AR",  4 => "AZ",  5 => "CA",
    6 => "CO",  7 => "CT",  8 => "DC",  9 => "DE", 10 => "FL",
   11 => "GA", 12 => "HI", 13 => "IA", 14 => "ID", 15 => "IL",
   16 => "IN", 17 => "KS", 18 => "KY", 19 => "LA", 20 => "MA",
   21 => "MD", 22 => "ME", 23 => "MI", 24 => "MN", 25 => "MO",
   26 => "MS", 27 => "MT", 28 => "NC", 29 => "ND", 30 => "NE",
   31 => "NH", 32 => "NJ", 33 => "NM", 34 => "NV", 35 => "NY",
   36 => "OH", 37 => "OK", 38 => "OR", 39 => "PA", 40 => "RI",
   41 => "SC", 42 => "SD", 43 => "TN", 44 => "TX", 45 => "UT",
   46 => "VA", 47 => "VT", 48 => "WA", 49 => "WI", 50 => "WV",
   51 => "WY"
)
abbrev2int = Dict(v => k for (k, v) in int2abbrev)

df = CSV.read(joinpath("us-potus-model-copied", "Julia", "df_$(RUN).csv"), DataFrame);

data_0 = JSON.parsefile(joinpath("us-potus-model-copied", "Julia", "data_$(RUN).json"))
model_0 = StanModel(
    joinpath("us-potus-model-copied", "Julia", "poll_model_2020.stan"),
    joinpath("us-potus-model-copied", "Julia", "data_$(RUN).json"),
    SEED
);

draws_0 = load(joinpath("Julia", "draws_$(RUN).jld"))["data"]
draws_0 = NamedArray(
    draws_0,
    (axes(draws_0,1), param_unc_names(model_0)),
    (:r, :d),
)
stats_0 = CSV.read(joinpath("Julia", "stats-df_$(RUN).csv"), DataFrame)

include("Functions.jl")
include("Perturbations.jl")

;