using Revise
using Test
using GLMakie
using Profile
using BenchmarkTools
using Statistics

include("src/DREAM_themes.jl")

using AgentMAKRO

# List with one function for each scenario we want to simulate, including the baseline (zero_shock!)
scenario_functions = [zero_shock!, firm_destruction_shock!, firm_productivity_shock!]
burnin_years = 60
simulation_years = 20

scenario_statistics = n_simulations(300, scenario_functions; burnin_years, simulation_years)

"""Return a figure containing a line on top of a shaded area between a lower and upper bound"""
function bandedline!(y, ylower, yupper; alpha=0.2, color=:Red, kwargs...)
    lines!(y; color, kwargs...)
    band!(1:length(y), ylower, yupper; color=(color, alpha))
end

"""Return a figure containing a scatter on top of a shaded area between a lower and upper bound"""
function bandedscatter!(y, ylower, yupper; alpha=0.2, color=:Red, kwargs...)
    scatter!(y; color, markersize=3, kwargs...)
    band!(1:length(y), ylower, yupper; color=(color, alpha))
end

function plt!(simulations, getter; color=DREAM, title="", plot_first=true, kwargs...)
    y = zip(getter.(simulations)...) |> collect;

    ppy = Settings.periods_pr_year
    y = y[1+ppy:end];

    # f = Figure()
    # Axis(f[1,1])
    f = bandedline!(mean.(y), quantile.(y, 0.025), quantile.(y, 0.975); color, kwargs...)
    if plot_first
        lines!(first.(y); color=RGBAf(0.0, 0.0, 0.0, 0.3))
    end

    # Change x-axis ticks to years instead of months with 6 ticks shown
    years = length(y) ÷ ppy
    rng = 0:years÷5:years
    current_axis().xticks = (rng * ppy, string.(rng))
    current_axis().xlabel = "Years"
    current_axis().title = title

    return f
end

function rel_multiplier_plt!(baselines, shocks, getter; kwargs...) 
    f = plt!(zip(baselines, shocks), x -> (getter(x[2]) ./ getter(x[1]) .- 1) .* 100; plot_first=false, kwargs...)
    current_axis().ylabel = "Percentage change from baseline"
    return f
end

function abs_multiplier_plt!(baselines, shocks, getter; kwargs...) 
    f = plt!(zip(baselines, shocks), x -> getter(x[2]) .- getter(x[1]); plot_first=false, kwargs...)
    current_axis().ylabel = "Absolute difference from baseline"
    return f
end

function pct_plt!(baselines, getter; kwargs...) 
    f = plt!(baselines, x -> getter(x) * 100.0; kwargs...)
    current_axis().ylabel = "(%)"
    return f
end

function shock_plt(baselines, shocks; fontsize=10, kwargs...)
    f = Figure(; fontsize, kwargs...)
    Axis(f[1,1])
    rel_multiplier_plt!(baselines, shocks, firms; title="Number of firms", color=DREAM)
    Axis(f[1,2])
    abs_multiplier_plt!(baselines, shocks, expected_profitability; title="Expected Sharpe Ratio", color=DREAM)
    Axis(f[1,3])
    rel_multiplier_plt!(baselines, shocks, employed; title="Employement", color=DREAM)

    Axis(f[2,1])
    rel_multiplier_plt!(baselines, shocks, sales; title="Sales", color=DREAM)
    Axis(f[2,2])
    rel_multiplier_plt!(baselines, shocks, sales; color=DREAM)
    rel_multiplier_plt!(baselines, shocks, capacity; title="Supply (red) and sales (petrol)", color=MAKRO)
    Axis(f[2,3])
    rel_multiplier_plt!(baselines, shocks, vacancies; title="Vacancies", color=DREAM)

    Axis(f[3,1])
    rel_multiplier_plt!(baselines, shocks, x -> wage(x) ./ price(x); title="Real wage", color=DREAM)
    Axis(f[3,2])
    rel_multiplier_plt!(baselines, shocks, wage; title="Wage", color=DREAM)
    Axis(f[3,3])
    rel_multiplier_plt!(baselines, shocks, price; title="Price", color=DREAM)

    return f
end

function baseline_plt(baselines; fontsize = 10, kwargs...)
    f = Figure(; fontsize, kwargs...)
    Axis(f[1,1])
    plt!(baselines, firms; title="Number of firms", color=DREAM)
    Axis(f[1,2])
    plt!(baselines, expected_profitability; title="Expected Sharpe Ratio", color=DREAM)
    Axis(f[1,3])
    plt!(baselines, sales; title="Sales", color=DREAM)

    Axis(f[2,1])
    plt!(baselines, employed; title="Employement", color=DREAM)
    Axis(f[2,2])
    pct_plt!(baselines, unemployment_rate; title="Unemployment rate", color=DREAM)
    Axis(f[2,3])
    plt!(baselines, x -> sales(x) ./ productivity(x); title="Sales, detrended", color=DREAM)

    Axis(f[3,1])
    pct_plt!(baselines, x -> annual_growth_rate(wage(x) ./ price(x)); title="Real wage growth", color=DREAM)
    Axis(f[3,2])
    pct_plt!(baselines, x -> annual_growth_rate(wage(x)); title="Wage growth", color=DREAM)
    Axis(f[3,3])
    pct_plt!(baselines, x -> annual_growth_rate(price(x)); title="Inflation", color=DREAM)

    return f
end

baselines = scenario_statistics[zero_shock!];

using CairoMakie
CairoMakie.activate!()

baseline_fig = baseline_plt(baselines)
firm_destruction_fig = shock_plt(baselines, scenario_statistics[firm_destruction_shock!])
firm_productivity_fig = shock_plt(baselines, scenario_statistics[firm_productivity_shock!])

save("images/baseline.svg", baseline_fig, pt_per_unit=1.0)
save("images/firm_destruction_shock.svg", firm_destruction_fig, pt_per_unit=1.0)
save("images/firm_productivity_shock.svg", firm_productivity_fig, pt_per_unit=1.0)

# @profview for i in 1:10 step!(world) end
# @benchmark step!($world, 1)
# @code_warntype step!(world)
