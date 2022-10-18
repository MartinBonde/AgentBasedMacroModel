module Settings

using Distributions

periods_pr_year::Int64 = 12

# --------------------------------------------------------------------------------
# Households
# --------------------------------------------------------------------------------
# Demographics
cohort_init_size::Int64 = round(1000 / periods_pr_year)
min_household_age::Int64 = 18 * periods_pr_year
max_household_age::Int64 = 100 * periods_pr_year

pension_age::Int64 = 67 * periods_pr_year

# Production
household_productivity_distribution::Sampleable = LogNormal()

# Job search
job_search_n_firms::Int64 = round(12 / periods_pr_year)
on_the_job_search_n_firms::Int64 = 3
on_the_job_search_probability::Float64 = 0.3 / periods_pr_year

job_quit_probability::Float64 = 0.2 / periods_pr_year

# Provider search
provider_search_probability::Float64 = 0.1 / periods_pr_year
provider_search_n_firms::Int64 = round(120 / periods_pr_year)

# --------------------------------------------------------------------------------
# Firms
# --------------------------------------------------------------------------------
firm_productivity_growth::Float64 = (1.02)^(1/periods_pr_year) - 1

firm_optimal_closure_probability::Float64 = 0.5 #/ periods_pr_year # Probability of closing IF not expected to become profitable
firm_lossmaking_closure_probability::Float64 = 0.0 #/ periods_pr_year # Probability of closing IF not profitable
firm_startup_age::Float64 = 2 * periods_pr_year # Age before which 
firm_max_size::Int64 = 1000

## Production function
firm_productivity_distribution::Sampleable = LogNormal(log(8.0), 0.1)
increasing_returns_to_scale::Float64 = 2.0
decreasing_returns_to_scale::Float64 = 0.5

## Expectations
firm_expectations_smooth::Float64 = 0.4

## Wage setting
mark = 0.05
sens = 1 / 0.15

choose_wage_probability::Float64 = 0.5 #/ periods_pr_year
firm_max_wage_markup::Float64 = mark #/ periods_pr_year
firm_wage_markup_sensitivity::Float64 = sens
firm_max_wage_markdown::Float64 = mark #/ periods_pr_year
firm_wage_markdown_sensitivity::Float64 = sens

## Price setting
choose_price_probability::Float64 = 0.5 #/ periods_pr_year
firm_max_price_markup::Float64 = mark #/ periods_pr_year
firm_price_markup_sensitivity::Float64 = sens
firm_max_price_markdown::Float64 = mark #/ periods_pr_year
firm_price_markdown_sensitivity::Float64 = sens

vacancy_posting_share::Float64 = 0.1
min_remaining_vacancies::Float64 = 1.0

# --------------------------------------------------------------------------------
# Investors
# --------------------------------------------------------------------------------
investor_expectations_smooth::Float64 = 0.7
investor_profit_sensitivity::Float64 = 0.15 / periods_pr_year
discount_rate::Float64 = 1.05^(1 / periods_pr_year) - 1

# --------------------------------------------------------------------------------
# Initialization and burn-in
# --------------------------------------------------------------------------------
burnin_employment_rate::Float64 = 0.975
burnin_provider_coverage::Float64 = 0.99

initial_price::Float64 = 1.0
initial_wage::Float64 = 0.8

end
