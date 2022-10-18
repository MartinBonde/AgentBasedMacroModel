using Revise
using Test
using GLMakie
using Profile
using BenchmarkTools
using Statistics

include("src/DREAM_themes.jl")

using AgentMAKRO
M = AgentMAKRO

# baselines = StatisticsAgency[]
# for _ in 1:1
#     world = new_world()
#     zero_shock!(world, 50)
#     push!(baselines, statistics(world))
# end

# s = median(baselines)
# upper = quantile(baselines, 0.75)
# lower = quantile(baselines, 0.25)
# function plt(getter, label="", color=MAKRO)
#     f = lines(getter(s); label, color)
#     band!(1:length(s), getter(lower), getter(upper), color=(color, 0.2))
#     return f
# end
# plt(household_cash)

world::World = new_world()
zero_shock!(world, 50)
# firm_destruction_shock!(world, 25)
s = deepcopy(statistics(world))
s = subset(s, (Settings.periods_pr_year*25+1):length(s))

growth_detrend!(s)
# inflation_detrend!(s)

f = Figure()

function format_axis()
    axislegend()
    ax = f.current_axis
    ax[].xticks = (0:(Settings.periods_pr_year*10):length(s), string.(0:10:(length(s)÷Settings.periods_pr_year)))
end

lines(f[1, 1], annual_growth_rate(price(s)), label="Yearly inflation")
lines!(annual_growth_rate(wage(s)), label="Yearly wage growth")
lines!(annual_growth_rate(wage(s)./price(s)), label="Yearly real wage growth")
# lines(f[1, 1], price(s), label="Price")
# lines!(wage(s), label="Wage")
format_axis()

lines(f[2, 1], capacity(s), label="Capacity")
lines!(profits(s) ./ price(s), label="Profits / price")
lines!(revenues(s) ./ price(s), label="Revenues / price")
lines!(payroll(s) ./ price(s), label="Payroll / price")
# lines!(demand(s), label="demand")
# lines!(household_cash(s), label="Household cash")
format_axis()

# lines(f[1, 2], population(s), label="Population (100 persons)")
lines(f[1, 2], firms(s), label="Number of firms")
format_axis()

lines(f[2, 2], employment_rate(s), label="employment rate")
# lines!(unemployment_rate(s), label="unemployment rate")
lines!(provider_coverage(s), label="provider coverage rate")
format_axis()

growth_retrend!(s)
# inflation_retrend!(s)

# @profview for i in 1:3 step!(world) end

# @benchmark step!($world)
