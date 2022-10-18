module AgentMAKRO

export step!, Settings

using Distributions
using Parameters
using OrderedCollections

abstract type AbstractAgent end
abstract type AbstractFirm <: AbstractAgent end
abstract type AbstractHousehold <: AbstractAgent end
abstract type AbstractStatisticsAgency <: AbstractAgent end
abstract type AbstractInvestor <: AbstractAgent end
abstract type AbstractWorld <: AbstractAgent end

include("Utils.jl")
include("Firms.jl")
include("Households.jl")
include("Investors.jl")
include("Interactions.jl")
include("WorldStatistics.jl")
include("Worlds.jl")
include("Simulations.jl")
include("Settings.jl")

# export all
for n in names(@__MODULE__; all=true)
    if Base.isidentifier(n) && n ∉ (Symbol(@__MODULE__), :eval, :include)
        @eval export $n
    end
end

end # module