using Random
using Statistics

export simulation, n_simulations, simulate_shock
export zero_shock!, firm_destruction_shock!
export median, quantile

function simulation(seed)
    # Create a common starting point prior to any shocks
    Random.seed!(seed)
    world = new_world()
    zero_shock!(world, 50)

    # Simulate scenarios
    baseline = simulate_shock(world, seed, zero_shock!)
    firm_destuction = simulate_shock(world, seed, firm_destruction_shock!)

    return (baseline, firm_destuction)
end

function n_simulations(n)
    baselines = StatisticsAgency[]
    firm_destruction_shocks = StatisticsAgency[]
    for _ in 1:n
        baseline, firm_destuction = simulation(rand(1:2^31))
        push!(baselines, baseline)
        push!(firm_destruction_shocks, firm_destuction)
    end

    return baselines, firm_destruction_shocks
end

"""For each simulation in a vector, apply a getter function, then reduce the vector using a reduction function"""
apply_reduction(v::Vector{<:AbstractStatisticsAgency}, getter, reduction) = reduction.(zip(getter.(v)...))

"""Return a statistics object where each field is the result of reducing the corresponding field of each simulation in <v>."""
function apply_reduction(v::Vector{T}, reduction) where {T<:AbstractStatisticsAgency}
    reduced = T()
    for fieldname in fieldnames(T)
        getter(x) = getfield(x, fieldname)
        append!(getfield(reduced, fieldname), apply_reduction(v, getter, reduction))
    end
    return reduced
end

"""Return a statistics object where each field is the median of each simulation in <v>."""
Statistics.median(v::Vector{<:AbstractStatisticsAgency}) = apply_reduction(v, median)

"""Return a statistics object where each field is the quantile of each simulation in <v>."""
Statistics.quantile(v::Vector{<:AbstractStatisticsAgency}, p) = apply_reduction(v, x -> quantile(x, p))

# """Return a statistics object that is the result of applying a function to each pair of observations from two statistics objects (typically a baseline and a shock)"""
# function statistics(shock::T, baseline::T, func) where {T<:AbstractStatisticsAgency}
#     multipliers = T()
#     for fieldname in fieldnames(T)
#         multiplier = func.(getfield(baseline, fieldname), getfield(shock, fieldname))
#         setfield!(multipliers, fieldname, multiplier)
#     end
#     return multipliers
# end

# """Return a statistics object with all fields set to multipliers between observations"""
# multiplier(shock, baseline) = statistics(shock, baseline, (s, b) -> s / b - 1)

# """Return a statistics object with all fields set to the difference between observations"""
# Base.:-(shock, baseline) = statistics(shock, baseline, (s, b) -> s - b)

# median.(zip([1, 2, 3], [1, 1, 3]))

"""Run a shock simulation and return statistics"""
function simulate_shock(world, seed, shock_function)
    Random.seed!(seed)
    shock_world = deepcopy(world)
    shock_function(shock_world, 50)
    return statistics(shock_world)
end

"""Simulate world for <years> years without any exogenous shocks. Used to create a baseline."""
function zero_shock!(world, years)
    for _ in 1:12*years
        step!(world)
    end
    return world
end

"""Close 10% of firms and simulate world for <years> years."""
function firm_destruction_shock!(world, years)
    for _ in 1:ceil(0.25 * n_firms(world))
        close_firm!(rand(firms(world)), world)
    end

    for _ in 1:12*years
        step!(world)
    end

    return world
end