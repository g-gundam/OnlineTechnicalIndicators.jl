const WMA_PERIOD = 3

"""
    WMA{T}(; period = WMA_PERIOD, input_filter = always_true, input_modifier = identity, input_modifier_return_type = T)

The `WMA` type implements a Weighted Moving Average indicator.
"""
mutable struct WMA{Tval} <: MovingAverageIndicator{Tval}
    value::Union{Missing,Tval}
    n::Int

    period::Integer

    total::Tval
    numerator::Tval
    denominator::Tval

    input_values::CircBuff{Tval}

    function WMA{Tval}(;
        period = WMA_PERIOD,
        input_filter = always_true,
        input_modifier = identity,
        input_modifier_return_type = Tval,
    ) where {Tval}
        input_values = CircBuff(Tval, period + 1, rev = false)
        total = zero(Tval)
        numerator = zero(Tval)
        denominator = period * (period + one(Tval)) / (2 * one(Tval))
        new{Tval}(missing, 0, period, total, numerator, denominator, input_values)
    end
end

function _calculate_new_value(ind::WMA)
    if ind.n > ind.period
        losing = ind.input_values[1]
    else
        losing = 0
    end
    data = ind.input_values[end]
    # See https://en.wikipedia.org/wiki/Moving_average#Weighted_moving_average
    ind.numerator = ind.numerator + ind.period * data - ind.total
    ind.total = ind.total + data - losing
    return ind.numerator / ind.denominator
end
