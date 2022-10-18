
function Base.delete!(vec::Vector{T}, val::T) where {T<:AbstractAgent}
    i = findfirst(==(val), vec)
    deleteat!(vec, i)
end

"""Yeo-Johnson transformation"""
function yeo_johnson(x, λ)
    if x ≥ 0
        λ ≈ 0 ? log(x + 1) : ((x + 1.0)^λ - 1) / λ
    else
        -yeo_johnson(-x, 2 - λ)
    end
end

"""Inverse Yeo-Johnson transformation."""
function inverse_yeo_johnson(x, λ)
    if x ≥ 0
        λ ≈ 0 ? exp(x) - 1 : (1.0 + λ * x)^(1 / λ) - 1
    else
        -inverse_yeo_johnson(-x, 2 - λ)
    end
end

for x = (-5:0.1:5), y = (-5:0.1:5)
    x2 = inverse_yeo_johnson(yeo_johnson(x, y), y)
    @assert x2 ≈ x "x2=$x2, x=$x, y=$y"
end

