using Random
using Statistics
using Base.Threads
using ProgressMeter

"""Create a world and perform a simulation of each scenario in <scenario_functions>."""
function simulation(scenario_functions; burnin_years=20, simulation_years=20)
    # Create a common starting point prior to any shocks
    seed = rand(1:2^31)
    Random.seed!(seed)
    world = new_world()
    zero_shock!(world, burnin_years)

    # Simulate scenarios
    simulation_by_scenario = Dict(scenario => simulate_shock(world, seed, scenario, simulation_years) for scenario in scenario_functions)
    return simulation_by_scenario
end

"""
Perform <n_simulations> of each scenario in <scenario_functions>
using multiple threads if available (Julia needs to be started with multiple threads)
"""
function n_simulations(n, scenario_functions; burnin_years=20, simulation_years=20)
    simulations = [[] for _ in 1:nthreads()]
    p = Progress(n; showspeed=true) # A progress bar showing % of simulations completed
    @threads for _ in 1:n
        push!(simulations[threadid()], simulation(scenario_functions; burnin_years, simulation_years))
        next!(p)
    end

    # Merge arrays from each thread
    simulations = vcat(simulations...)

    scenario_statistics = Dict(
        scenario => StatisticsAgency[d[scenario] for d in simulations]
        for scenario in scenario_functions
    )

    return scenario_statistics
end

"""Run a shock simulation and return shock statistics"""
function simulate_shock(world, seed, scenario_function, years)
    Random.seed!(seed)
    shock_world = deepcopy(world)
    scenario_function(shock_world, years)
    s = statistics(shock_world)
    return subset(s, (length(s)-(years+2)*Settings.periods_pr_year):length(s))
end

"""Simulate world for <years> years without any exogenous shocks. Used to create a baseline."""
zero_shock!(world, years) = step!(world, years)

"""Close 10% of firms and simulate world for <years> years."""
function firm_destruction_shock!(world, years)
    for _ in 1:ceil(0.1 * n_firms(world))
        close_firm!(rand(firms(world)), world)
    end

    step!(world, years)

    return world
end

"""Permanently increase productivity of all firms by 10% and simulate world for <years> years."""
function firm_productivity_shock!(world, years)
    world.productivity *= 1.1
    for f in firms(world)
        f.productivity *= 1.1
    end

    step!(world, years)

    return world
end

"""Simulate <years> years"""
function step!(world, years)
    for _ in 1:Settings.periods_pr_year*years
        step!(world)
    end
    return world
end
