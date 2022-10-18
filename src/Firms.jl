"""
Firm agent
"""
@with_kw mutable struct Firm{H<:AbstractHousehold} <: AbstractFirm
    age::Int64 = 0
    employees::Vector{H}
    price::Float64
    wage::Float64
    demand::Float64 = 0.0
    labor::Float64 = 0.0
    capacity::Float64 = 0.0
    cash::Float64 = 0
    revenues::Float64 = 0
    payroll::Float64 = 0
    vacancies::Float64 = 0
    job_applications::Int64 = 0
    job_quits::Int64 = 0

    optimal_labor::Float64 = 0.0
    expected_demand::Float64 = 0.0
    expected_capacity::Float64 = 0.0
    expected_quits::Float64 = 0.0
    expected_applicants::Float64 = 0.0
    expected_price::Float64
    expected_wage::Float64

    productivity::Float64
end

"""Firm constructor"""
function add_firm!(world, price, wage)
    f = Firm(;
        employees=Household[],
        price=price,
        expected_price=price,
        wage=wage,
        expected_wage=wage,
        productivity=rand(Settings.firm_productivity_distribution) * productivity(world)
    )
    push!(world.firms, f)
    return f
end

# Getters
age(f::Firm) = f.age
employees(f::Firm) = f.employees
price(f::Firm) = f.price
wage(f::Firm) = f.wage
demand(f::Firm) = f.demand
labor(f::Firm) = f.labor
capacity(f::Firm) = f.capacity
cash(f::Firm) = f.cash
revenues(f::Firm) = f.revenues
payroll(f::Firm) = f.payroll
vacancies(f::Firm) = f.vacancies
job_applications(f::Firm) = f.job_applications
job_quits(f::Firm) = f.job_quits

optimal_labor(f::Firm) = f.optimal_labor
expected_demand(f::Firm) = f.expected_demand
expected_capacity(f::Firm) = f.expected_capacity
expected_quits(f::Firm) = f.expected_quits
expected_applicants(f::Firm) = f.expected_applicants
expected_price(f::Firm) = f.expected_price
expected_wage(f::Firm) = f.expected_wage
expected_sales(f::Firm) = min(expected_demand(f), expected_capacity(f))

productivity(f::Firm) = f.productivity

# Setters
function set_labor!(f::Firm)
    f.labor = sum(productivity.(employees(f)))
end

function set_vacancies!(f::Firm)
    labor_difference = optimal_labor(f) - labor(f)
    if labor_difference < 0
        f.vacancies = 0
    elseif labor_difference ≤ Settings.min_remaining_vacancies
        f.vacancies = labor_difference
    else
        f.vacancies = Settings.vacancy_posting_share * labor_difference
    end
end

function set_capacity!(f::Firm)
    f.capacity = production_function(f)
end

function set_revenues!(f::Firm)
    f.revenues = cash(f)
end

function set_price!(f::Firm)
    rand() < Settings.choose_price_probability || return nothing
    dᴱ = expected_demand(f)
    yᵒ = optimal_capacity(f)
    sᴱ = expected_sales(f)
    Pᴱ = expected_price(f)
    if dᴱ > yᵒ # Expected demand above optimal capacity → increase price
        g = Settings.firm_max_price_markup * min(1.0, Settings.firm_price_markup_sensitivity * (dᴱ - yᵒ) / yᵒ)
        f.price = (1 + g) * Pᴱ
    elseif sᴱ < yᵒ # Expected sales below optimal capacity → lower price
        g = Settings.firm_max_price_markdown * min(1.0, Settings.firm_price_markdown_sensitivity * (yᵒ - sᴱ) / yᵒ)
        f.price = (1 - g) * Pᴱ
    end
end

function set_wage!(f::Firm)
    rand() < Settings.choose_wage_probability || return nothing
    aᴱ = expected_applicants(f)
    qᴱ = expected_quits(f)
    v = vacancies(f)
    Wᴱ = expected_wage(f)
    if (aᴱ - qᴱ) < v # Fewer expected net applications than vacancies
        g = Settings.firm_max_wage_markup * min(1.0, Settings.firm_wage_markup_sensitivity * (v - (aᴱ - qᴱ)) / optimal_labor(f))
        f.wage = (1 + g) * Wᴱ
    elseif v < (aᴱ - qᴱ) # More expected net applications than vacancies
        g = Settings.firm_max_wage_markdown * min(1.0, Settings.firm_wage_markdown_sensitivity * (aᴱ - qᴱ) / optimal_labor(f))
        f.wage = (1 - g) * Wᴱ
    end
end

profits(f::Firm) = revenues(f) - payroll(f)
sales(f::Firm) = revenues(f) / price(f)

can_supply(f::Nothing) = false
can_supply(f::Firm) = demand(f) ≤ capacity(f)

n_employees(f::Firm) = length(employees(f))

function update_expectations!(f::Firm, price, wage)
    f.expected_demand = expectation(f.expected_demand, demand(f))
    f.expected_capacity = expectation(f.expected_capacity, capacity(f))
    f.expected_applicants = expectation(f.expected_applicants, job_applications(f))
    f.expected_quits = expectation(f.expected_quits, job_quits(f))
    f.expected_price = expectation(f.expected_price, price)
    f.expected_wage = expectation(f.expected_wage, wage)
end

"""Expecation of a variable given a past state and a new observation"""
function expectation(state, observation)
    γ = Settings.firm_expectations_smooth
    return (1 - γ) * observation + γ * state
end

function set_optimal_labor!(f::Firm)
    Pᴱ, Wᴱ = expected_price(f), expected_wage(f)
    ϕ = productivity(f)
    α = Settings.decreasing_returns_to_scale

    f.optimal_labor = (α * ϕ / Wᴱ * Pᴱ)^(1 / (1 - α))
end

production_function(l, ϕ, Φ, α) = ϕ * max(l^α - Φ, 0.0)
production_function(f::Firm) = production_function(labor(f), productivity(f), Settings.increasing_returns_to_scale, Settings.decreasing_returns_to_scale)

optimal_capacity(f::Firm) = production_function(
    optimal_labor(f),
    productivity(f),
    Settings.increasing_returns_to_scale,
    Settings.decreasing_returns_to_scale
)

min_productivity(α, Φ) = 1 / α * (Φ / (1 - α))^(1 / α - 1)

optimal_profit(f::Firm) = expected_price(f) * optimal_capacity(f) - expected_wage(f) * optimal_labor(f)

fire_employee!(f::Firm, worker::AbstractHousehold) = destroy_job!(worker, f)
marginal_employee(f::Firm) = employees(f)[end]

function fire_excess_workers!(f::Firm)
    while labor(f) > 0 && labor(f) - productivity(marginal_employee(f)) > optimal_labor(f)
        fire_employee!(f, marginal_employee(f))
    end
end

function reset_flows!(f::Firm)
    f.demand = 0
    f.revenues = 0
    f.job_applications = 0
    f.job_quits = 0
end

function age!(f::Firm, world::AbstractWorld)
    f.age += 1
    if (age(f) > Settings.firm_startup_age)
        if (optimal_labor(f) > Settings.firm_max_size
            || (optimal_profit(f) < 0 && rand() < Settings.firm_optimal_closure_probability)
            || (profits(f) < 0.0 && rand() < Settings.firm_lossmaking_closure_probability)
        )
            return close_firm!(f, world)
        end
    end
end

