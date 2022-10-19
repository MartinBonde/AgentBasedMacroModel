"""
Household agent
"""
@with_kw mutable struct Household <: AbstractHousehold
    age::Int64 = Settings.min_household_age
    productivity::Float64 = rand(Settings.household_productivity_distribution)
    employer::Union{Nothing,AbstractFirm} = nothing
    provider::Union{Nothing,AbstractFirm} = nothing
    cash::Float64 = 0
end

function add_household!(world::AbstractWorld)
    push!(world.households, Household())
end

# Household getters
age(hh::Household) = hh.age
productivity(hh::Household) = hh.productivity
employer(hh::Household) = hh.employer
provider(hh::Household) = hh.provider
cash(hh::Household) = hh.cash

is_unemployed(hh::Household) = isnothing(employer(hh))
is_employed(hh::Household) = !is_unemployed(hh)
wages(hh::Household) = wage(employer(hh)) * productivity(hh::Household)
wage(::Nothing) = 0
has_provider(hh::Household) = !isnothing(hh.provider)

"""Households always consume their entire income"""
consumer_spending(hh::Household) = max(0.0, cash(hh))

__annual_death_probability(age; β=5.0) = exp(1.0 / β * age - Settings.max_household_age / Settings.periods_pr_year / β)
__death_probability(age) = 1.0 - (1.0 - __annual_death_probability(age / Settings.periods_pr_year))^(1.0 / Settings.periods_pr_year)
DEATH_PROBABILITY::Dict{Int64, Float64} = Dict(a => __death_probability(a) for a in 0:Settings.max_household_age)
death_probability(age) = DEATH_PROBABILITY[age]
death_probability(hh::Household) = death_probability(age(hh))

function job_search!(
    hh::Household,
    world::AbstractWorld,
    reservation_wage,
    n_firms,
)
    for f in rand(firms(world), n_firms)
        if wage(f) ≥ reservation_wage
            apply_for_job!(hh, f)
            return
        end
    end
    return
end

"""
The household checks up to <n_firms> for a better price/product and switches provider if it finds one.
"""
function provider_search!(
    hh::Household,
    world::AbstractWorld,
)
    for f in rand(firms(world), Settings.provider_search_n_firms)
        if prefers(hh, f, provider(hh))
            return change_provider!(hh, f)
        end
    end
    return
end

"""Does the household prefer provider a over provider b?"""
function prefers(hh::Household, a::AbstractFirm, b::AbstractFirm)
    if !can_supply(a)
        return false
    elseif !can_supply(b)
        return true
    else
        return price(a) < price(b)
    end
end
prefers(hh::Household, a::AbstractFirm, b::Nothing) = can_supply(a)

function age!(hh::Household, world::AbstractWorld)
    if rand() < death_probability(hh)
        die!(hh, world)
    else
        hh.age += 1
    end
    return
end

function job_destruction!(hh::Household)
    if (is_employed(hh) && (rand() < Settings.job_quit_probability || age(hh) ≥ Settings.pension_age))
        quit_job!(hh)
    end
    return
end

function job_search!(hh::Household, world::AbstractWorld)
    if is_employed(hh)
        if rand() < Settings.on_the_job_search_probability
            job_search!(hh, world, wage(employer(hh)), Settings.on_the_job_search_n_firms)
        end
    elseif age(hh) < Settings.pension_age
        job_search!(hh, world, 0.0, Settings.job_search_n_firms)
    end
    return
end

function consumer_market!(hh::Household, world::AbstractWorld)
    can_supply(provider(hh)) || drop_provider!(hh)
    if !has_provider(hh) || rand() < Settings.provider_search_probability
        provider_search!(hh, world)
    end
    has_provider(hh) && purchase_consumption!(hh)
    return
end
