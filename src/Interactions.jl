function change_job!(hh::AbstractHousehold, f::AbstractFirm)
    is_employed(hh) && quit_job!(hh)
    push!(f.employees, hh)
    hh.employer = f
    set_labor!(f)
    set_vacancies!(f)
end

function quit_job!(hh::AbstractHousehold)
    f = employer(hh)
    f.job_quits += 1.0
    destroy_job!(hh, f)
end

function destroy_job!(hh::AbstractHousehold, f::AbstractFirm)
    delete!(f.employees, hh)
    hh.employer = nothing
    set_labor!(f)
    set_vacancies!(f)
end

purchase_consumption!(hh::AbstractHousehold) = purchase_consumption!(hh, provider(hh), consumer_spending(hh))
function purchase_consumption!(hh::AbstractHousehold, f::AbstractFirm, spending)
    f.demand += spending / price(f)
    hh.cash -= spending
    f.cash += spending
end

"""Delete household and give any remaining assets to another randomly selected household."""
function die!(hh::AbstractHousehold, world::AbstractWorld)
    is_employed(hh) && quit_job!(hh)
    delete!(world.households, hh)
    rand(households(world)).cash += hh.cash
end

function close_firm!(f::AbstractFirm, world::AbstractWorld)
    for hh in copy(employees(f))
        destroy_job!(hh, f)
    end
    delete!(world.firms, f)
    return
end

function change_provider!(hh::AbstractHousehold, f::AbstractFirm)
    hh.provider = f
end

function drop_provider!(hh::AbstractHousehold)
    hh.provider = nothing
end

function apply_for_job!(hh::AbstractHousehold, f::Firm)
    f.job_applications += 1.0
    vacancies(f) > 0 && change_job!(hh, f)
end

function pay_wages!(f::AbstractFirm)
    payroll = 0
    for employee in employees(f)
        pay = wage(f) * productivity(employee)
        employee.cash += pay
        payroll += pay
    end
    f.payroll = payroll
    f.cash -= payroll
end

function pay_dividends!(world::AbstractWorld)
    dividends = 0
    for f in firms(world)
        dividends += f.cash
        f.cash = 0
    end
    pr_household = dividends / length(households(world))
    for hh in households(world)
        hh.cash += pr_household
    end
end
