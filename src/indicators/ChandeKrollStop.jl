const ChandeKrollStop_ATR_PERIOD = 5
const ChandeKrollStop_ATR_MULT = 2.0
const ChandeKrollStop_PERIOD = 3

struct ChandeKrollStopVal{Tval}
    short_stop::Tval
    long_stop::Tval
end

"""
    ChandeKrollStop{Tohlcv,S}(; atr_period = ChandeKrollStop_ATR_PERIOD, atr_mult = ChandeKrollStop_ATR_MULT, period = ChandeKrollStop_PERIOD)

The `ChandeKrollStop` type implements a ChandeKrollStop indicator.
"""
mutable struct ChandeKrollStop{Tohlcv,S} <: TechnicalIndicator{Tohlcv}
    value::Union{Missing,ChandeKrollStopVal{S}}
    n::Int

    atr_period::Integer
    atr_mult::S
    period::Integer

    # sub_indicators::Series
    atr::ATR

    high_stop_list::CircBuff
    low_stop_list::CircBuff

    input::CircBuff

    function ChandeKrollStop{Tohlcv,S}(;
        atr_period = ChandeKrollStop_ATR_PERIOD,
        atr_mult = ChandeKrollStop_ATR_MULT,
        period = ChandeKrollStop_PERIOD,
    ) where {Tohlcv,S}
        input = CircBuff(Tohlcv, atr_period, rev = false)
        atr = ATR{Tohlcv,S}(period = atr_period)
        high_stop_list = CircBuff(S, period, rev = false)
        low_stop_list = CircBuff(S, period, rev = false)
        new{Tohlcv,S}(
            missing,
            0,
            atr_period,
            atr_mult,
            period,
            atr,
            high_stop_list,
            low_stop_list,
            input,
        )
    end
end

function OnlineStatsBase._fit!(ind::ChandeKrollStop, candle)
    fit!(ind.input, candle)
    fit!(ind.atr, candle)
    ind.n += 1
    if (ind.n < ind.atr_period) || !has_output_value(ind.atr)
        ind.value = missing
        return
    end

    fit!(
        ind.high_stop_list,
        max([cdl.high for cdl in ind.input.value]...) - value(ind.atr) * ind.atr_mult,
    )
    fit!(
        ind.low_stop_list,
        min([cdl.low for cdl in ind.input.value]...) + value(ind.atr) * ind.atr_mult,
    )

    if ind.n < ind.period
        ind.value = missing
        return
    end

    ind.value = ChandeKrollStopVal(
        max(ind.high_stop_list.value...),
        min(ind.low_stop_list.value...),
    )
end
