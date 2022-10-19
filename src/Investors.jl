using Statistics

export invest!

@with_kw mutable struct Investor <: AbstractInvestor
    expected_profitability::Float64 = 0.0
end
expected_profitability(i::Investor) = i.expected_profitability

"""Investment decision"""
function invest!(i::Investor, world::AbstractWorld)
    s = statistics(world)
    n_new_firms = round(Settings.investor_profit_sensitivity * clamp(expected_profitability(i), 0.0, 1.0) * n_firms(world))
    for _ in 1:n_new_firms
        f = add_firm!(world::World, price(s)[end], wage(s)[end])
    end
    return
end

discounted_profits(f::AbstractFirm) = profits(f) / (1 + Settings.discount_rate)^age(f)

function sharpe_ratio(firms)
    π = discounted_profits.(firms)
    return mean(π) / std(π)
end

function update_expectations!(i::Investor, world::AbstractWorld)
    γ = Settings.investor_expectations_smooth
    i.expected_profitability = γ * i.expected_profitability + (1 - γ) * sharpe_ratio(firms(world))
end

