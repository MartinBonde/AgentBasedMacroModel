"""
World object
Contains every agent in the simulated world, including a statistics agency keeping track of world statistics.
"""
@with_kw mutable struct World <: AbstractWorld
    households::Vector{Household}
    firms::Vector{Firm}
    investor::Investor
    statistics::StatisticsAgency
    productivity::Float64
end

Base.Broadcast.broadcastable(world::World) = Ref(world)

# Getters
households(world::World) = world.households
firms(world::World) = world.firms
investor(world::World) = world.investor
statistics(world::World) = world.statistics
productivity(world::World) = world.productivity

# --------------------------------------------------------------------------------
"""World initialization and burn-in"""
function new_world()
    world = World(;
        households=Vector{Household}(),
        firms=Vector{Firm}(),
        investor=Investor(),
        statistics=StatisticsAgency(),
        productivity=1.0
    )

    # Initialize households, adding one cohort at a time and aging everyone
    for _ in Settings.min_household_age:Settings.max_household_age
        for hh in copy(households(world))
            if rand() < death_probability(hh)
                die!(hh, world)
            else
                hh.age += 1
            end
        end
        for _ in 1:(Settings.cohort_init_size)
            add_household!(world)
        end
    end

    # Initialize firms
    labor_supply = Settings.burnin_employment_rate * sum(productivity.(households(world)))
    labor_demand = 0.0
    while labor_demand < labor_supply
        f = add_firm!(world, Settings.initial_price, Settings.initial_wage)
        set_optimal_labor!(f)
        if (optimal_labor(f) > Settings.firm_max_size || optimal_profit(f) < 0)
            close_firm!(f, world)
        else
            labor_demand += optimal_labor(f)
        end
    end

    # Initialize labor market
    set_vacancies!.(firms(world))

    max_iterations = 10 * Settings.periods_pr_year
    # Initialize labor market by searching for jobs until burnin_employment_rate reached or convergence is too slow
    for i in 1:max_iterations
        employement = employment_rate(world)
        for hh in households(world)
            if is_unemployed(hh) && age(hh) < Settings.pension_age
                job_search!(hh, world)
            end
        end
        employment_rate(world) < Settings.burnin_employment_rate || break
        if employment_rate(world) - employement < 0.001
            println("********************************************************************************")
            println("Convergence too slow in initialization of labor market:")
            println("employement at $(employment_rate(world)) after $i rounds of search")
            println("********************************************************************************")
            break
        end
    end

    # Initialize production and pay wages
    for f in firms(world)
        set_capacity!(f)
        f.revenues = price(f) * capacity(f)
        pay_wages!(f)
        f.cash = 0
    end

    # Initialize consumer market by running provider_search! until burnin_provider_coverage reached or convergence is too slow
    for i in 1:max_iterations
        coverage = provider_coverage(world)
        for hh in households(world)
            provider_search!(hh, world)
        end
        provider_coverage(world) < Settings.burnin_provider_coverage || break
        if provider_coverage(world) - coverage < 0.001
            println("********************************************************************************")
            println("Convergence too slow in initialization of consumer market:")
            println("provder coverage at $(provider_coverage(world)) after $i rounds of search")
            println("********************************************************************************")    
        end
    end

    return world
end

# --------------------------------------------------------------------------------

"""
Advance the simulated world 1 period.
We explicitly call various actions on each agent type to have fine-tuned control over the timing of events.
"""
function step!(world::World)
    WST = statistics(world) # World Statistics Institutute
    update_statistics!(WST, world)

    world.productivity *= (1 + Settings.firm_productivity_growth)

    update_expectations!.(firms(world), price(WST)[end], wage(WST)[end])

    # Firm aging and closure
    age!.(copy(firms(world)), world)

    # Firm marketing
    set_price!.(firms(world))

    # Firm HR
    set_optimal_labor!.(firms(world))
    fire_excess_workers!.(firms(world))
    set_vacancies!.(firms(world))
    set_wage!.(firms(world))

    # Reset demand, jobs, and quits before household purchases and job search
    reset_flows!.(firms(world))

    # Create new households
    for _ in 1:Settings.cohort_init_size
        add_household!(world)
    end

    job_destruction!.(households(world))
    job_search!.(households(world), world)

    # Production
    set_capacity!.(firms(world))

    # Consumption
    consumer_market!.(households(world), world)
    set_revenues!.(firms(world))

    # Household aging and death
    age!.(copy(households(world)), world)

    # Pay wages and dividends
    pay_wages!.(firms(world))
    pay_dividends!(world)

    # Invest in new firms
    update_expectations!(investor(world), world)
    invest!(investor(world), world)
end
