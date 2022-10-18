function change_job!(hh::AbstractHousehold, f::AbstractFirm)
    is_employed(hh) && quit_job!(hh)
    push!(f.employees, hh)
    hh.employer = f
    set_labor!(f)
    set_vacancies!(f)
end

function quit_job!(hh::AbstractHousehold)
    f = employer(hh)
    f.job_quits += 1
    destroy_job!(hh, f)
end

function destroy_job!(hh::AbstractHousehold, f::AbstractFirm)
    delete!(f.employees, hh)
    hh.employer = nothing
    set_labor!(f)
    set_vacancies!(f)
end

function purchase_consumption!(hh::AbstractHousehold, spending)
    f = provider(hh)
    f.demand += spending / price(f)

    hh.cash -= spending
    f.cash += spending
end

function die!(hh::AbstractHousehold, world::AbstractWorld)
    is_employed(hh) && quit_job!(hh)
    delete!(world.households, hh)
    distribute_cash!(households(world), hh.cash)
end

function close_firm!(f::AbstractFirm, world::AbstractWorld)
    for hh in copy(employees(f))
        destroy_job!(hh, f)
    end
    delete!(world.firms, f)
end

function change_provider!(hh::AbstractHousehold, f::AbstractFirm)
    hh.provider = f
end

function drop_provider!(hh::AbstractHousehold)
    hh.provider = nothing
end

function apply_for_job!(hh::AbstractHousehold, f::Firm)
    f.job_applications += 1
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
    distribute_cash!(households(world), dividends)
end

function distribute_cash!(households, amount)
    pr_household = amount / length(households)
    for hh in households
        hh.cash += pr_household
    end
end
