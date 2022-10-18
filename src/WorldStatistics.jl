using Statistics
using Base.Iterators: partition


"""Statistics object keeping track of aggregate statistics"""
@with_kw struct StatisticsAgency <: AbstractStatisticsAgency
    price::Vector{Float64} = []
    wage::Vector{Float64} = []
    population::Vector{Int64} = []
    household_cash::Vector{Float64} = []
    labor_force::Vector{Int64} = []
    employed::Vector{Int64} = []
    labor::Vector{Float64} = []
    capacity::Vector{Float64} = []
    sales::Vector{Float64} = []
    revenues::Vector{Float64} = []
    payroll::Vector{Float64} = []
    firms::Vector{Int64} = []
    provider_coverage::Vector{Float64} = []
    productivity::Vector{Float64} = []

    _growth_trend::Vector{Float64} = []
    _inflation_trend::Vector{Float64} = []
end

# --------------------------------------------------------------------------------
# Functions to measure or survey households and firms to generate aggregate statistics
# --------------------------------------------------------------------------------
# Household statistics
population(world::AbstractWorld) = length(households(world))
labor_force(world::AbstractWorld) = length([h for h in households(world) if age(h) < Settings.pension_age])

household_cash(world::AbstractWorld) = world |> households .|> cash |> sum

# Firm statistics
n_firms(world::AbstractWorld) = length(firms(world))
capacity(world::AbstractWorld) = world |> firms .|> capacity |> sum
revenues(world::AbstractWorld) = world |> firms .|> revenues |> sum
payroll(world::AbstractWorld) = world |> firms .|> payroll |> sum
sales(world::AbstractWorld) = world |> firms .|> sales |> sum
labor(world::AbstractWorld) = world |> firms .|> labor |> sum
price(world::AbstractWorld) = revenues(world) / sales(world)

inflation(world::AbstractWorld) = inflation(statistics(world))[end]

# Labor market Statistics
employed(world::AbstractWorld) = firms(world) .|> employees .|> length |> sum
unemployed(world::AbstractWorld) = labor_force(world) - employed(world)
employment_rate(world::AbstractWorld) = employed(world) / labor_force(world)
unemployment_rate(world::AbstractWorld) = unemployed(world) / labor_force(world)
wage(world::AbstractWorld) = payroll(world) / labor(world)

# Consumer market statistics
provider_coverage(world::AbstractWorld) = sum(has_provider.(households(world))) / population(world)

Base.length(s::StatisticsAgency) = length(price(s))

# --------------------------------------------------------------------------------

"""Update statistics by measuring or surveying firms and households"""
function update_statistics!(s::StatisticsAgency, world::AbstractWorld)
    push!(s.population, population(world))
    push!(s.household_cash, household_cash(world))
    push!(s.labor_force, labor_force(world))
    push!(s.employed, employed(world))
    push!(s.labor, labor(world))
    push!(s.price, price(world))
    push!(s.wage, wage(world))
    push!(s.capacity, capacity(world))
    push!(s.sales, sales(world))
    push!(s.revenues, revenues(world))
    push!(s.payroll, payroll(world))
    push!(s.firms, n_firms(world))
    push!(s.provider_coverage, provider_coverage(world))
    push!(s.productivity, productivity(world))
    push!(s._growth_trend, 1.0)
    push!(s._inflation_trend, 1.0)
    return s
end

"""Delete all statistics (for example to delete statistics after a shock or burn-in period)"""
function Base.empty!(s::StatisticsAgency)
    for sym in fieldnames(StatisticsAgency)
        empty!(getfield(s, sym))
    end
end

_GROWTH_ADJUSTED = [:capacity, :sales, :revenues, :payroll, :_growth_trend]
function growth_detrend!(s::StatisticsAgency)
    @assert all(s._growth_trend .== 1.0) "Statistics are aldready detrended."
    for sym in _GROWTH_ADJUSTED
        getfield(s, sym) ./= productivity(s)
    end
end
function growth_retrend!(s::StatisticsAgency)
    @assert any(s._growth_trend .< 1.0) "Statistics are not detrended."
    for sym in _GROWTH_ADJUSTED
        getfield(s, sym) .*= productivity(s)
    end
end

_INFLATION_ADJUSTED = [:revenues, :payroll, :_inflation_trend]
function inflation_detrend!(s::StatisticsAgency)
    @assert all(s._inflation_trend .== 1.0) "Statistics are aldready detrended."
    for sym in _INFLATION_ADJUSTED
        getfield(s, sym) ./= price(s)
    end
end
function inflation_retrend!(s::StatisticsAgency)
    @assert any(s._inflation_trend .≠ 1.0) "Statistics are not detrended."
    for sym in _INFLATION_ADJUSTED
        getfield(s, sym) .*= price(s)
    end
end

"""Return copy of statistics agency with data only in <rng> period"""
function subset(s::StatisticsAgency, rng)
    s_copy = deepcopy(s)
    for sym in fieldnames(StatisticsAgency)
        A = getfield(s_copy, sym)
        deleteat!(A, [x for x in eachindex(A) if x ∉ rng])
    end
    return s_copy
end

annualize(collection, f) = f.(partition(collection, Settings.periods_pr_year))
annualize(collection::AbstractArray{Int}, f) = round.(Int, f.(partition(collection, Settings.periods_pr_year)))
get_end(collection) = collection[end]
mid_year(collection) = collection[ceil(Int, length(collection))]

function annualize(s::StatisticsAgency)
    StatisticsAgency(
        population=annualize(s.population, mean),
        household_cash=annualize(s.household_cash, mean),
        labor_force=annualize(s.labor_force, mean),
        employed=annualize(s.employed, mean),
        labor=annualize(s.labor, mean),
        price=annualize(s.price, mean),
        wage=annualize(s.wage, mean),
        capacity=annualize(s.capacity, mean),
        sales=annualize(s.sales, mean),
        revenues=annualize(s.revenues, mean),
        payroll=annualize(s.payroll, mean),
        firms=annualize(s.firms, mean),
        provider_coverage=annualize(s.provider_coverage, mean),
        productivity=annualize(s.productivity, mean),
        _growth_trend=s._growth_trend,
        _inflation_trend=s._inflation_trend,
    )
end

# --------------------------------------------------------------------------------
# Getters to retrieve statistics from StatisticsAgency
# --------------------------------------------------------------------------------
price(s::StatisticsAgency) = s.price
wage(s::StatisticsAgency) = s.wage
population(s::StatisticsAgency) = s.population
household_cash(s::StatisticsAgency) = s.household_cash
labor_force(s::StatisticsAgency) = s.labor_force
employed(s::StatisticsAgency) = s.employed
capacity(s::StatisticsAgency) = s.capacity
sales(s::StatisticsAgency) = s.sales
revenues(s::StatisticsAgency) = s.revenues
payroll(s::StatisticsAgency) = s.payroll
firms(s::StatisticsAgency) = s.firms
provider_coverage(s::StatisticsAgency) = s.provider_coverage
productivity(s::StatisticsAgency) = s.productivity

profits(s::StatisticsAgency) = revenues(s) - payroll(s)

unemployed(s::StatisticsAgency) = labor_force(s) .- employed(s)
unemployment_rate(s::StatisticsAgency) = unemployed(s) ./ labor_force(s)
employment_rate(s::StatisticsAgency) = employed(s) ./ labor_force(s)

inflation(s::StatisticsAgency) = diff(log.(price(s)))

function annual_growth_rate(A)
    ppy = Settings.periods_pr_year
    return [
        i > ppy ? A[i] / A[i - ppy] - 1 : (A[i] / A[1])^(ppy/i) - 1
        for i in 2:length(A)
    ]
end
