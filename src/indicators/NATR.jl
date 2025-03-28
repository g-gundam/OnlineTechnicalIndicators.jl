#const ATR_PERIOD = 3

"""
    NATR{Tohlcv}(; period = ATR_PERIOD, ma = SMMA, input_filter = always_true, input_modifier = identity, input_modifier_return_type = Tohlcv)

The `NATR` type implements a Normalized Average True Range indicator.
"""
mutable struct NATR{Tohlcv,IN,S} <: TechnicalIndicatorSingleOutput{Tohlcv}
    value::Union{Missing,S}
    n::Int
    output_listeners::Series
    input_indicator::Union{Missing,TechnicalIndicator}

    period::Number

    atr::ATR

    input_modifier::Function
    input_filter::Function
    input_values::CircBuff

    function NATR{Tohlcv}(;
        period = ATR_PERIOD,
        ma = SMMA,
        input_filter = always_true,
        input_modifier = identity,
        input_modifier_return_type = Tohlcv,
    ) where {Tohlcv}
        T2 = input_modifier_return_type
        if hasfield(T2, :close)
            S = fieldtype(T2, :close)
        else
            S = Float64
        end
        atr = ATR{input_modifier_return_type}(period = period, ma = ma)
        input_values = CircBuff(T2, 2, rev = false)
        new{Tohlcv,true,S}(
            initialize_indicator_common_fields()...,
            period,
            atr,
            input_modifier,
            input_filter,
            input_values,
        )
    end
end

function _calculate_new_value(ind::NATR)
    candle = ind.input_values[end]
    fit!(ind.atr, candle)
    if ind.input_values[end].close == 0
        return missing
    end
    return 100.0 * value(ind.atr) / ind.input_values[end].close
end
