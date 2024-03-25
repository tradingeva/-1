// Williams VixFix is a realized volatility indicator developed by Larry Williams, and can help in finding market bottoms.
// Indeed, as Williams describes in his paper, markets tend to find the lowest prices during times of highest volatility, which usually accompany times of highest fear. The VixFix is calculated as how much the current low price statistically deviates from the maximum within a given look-back period.
// As Odink 2016 explains, the VixFix cannot signal bottoms on its own: it needs a point of comparison, since it is not an oscillator, values are unbounded. One strategy is to combine with another indicator that averages over the past, to compare current volatility with past, with the goal of detecting **emotional overreactions** as evidenced by extreme volatility compared to historical volatility. Two published examples are the Hestla, 2015 strategy which uses a 20-SMA, or Odink, 2016 MOPOI strategy, using the upper level of the 20-Bollinger Band, which is just the 20-SMA + standard deviation. Note that the MOPOI strategy is equivalent to ChrisMoody's indicator for TradingView published in 2014, both were likely published independently from one another.
// Although the VixFix originally only indicates market bottoms, its inverse may indicate market tops. As masa_crypto [writes](https://www.tradingview.com/script/xOY1jFKD-Williams-VIX-fix-inverse/): "The inverse can be formulated by considering "how much the current high value statistically deviates from the minimum within a given look-back period." This transformation equates Vix_Fix_inverse. This indicator can be used for finding market tops, and therefore, is a good signal for a timing for taking a short position." However, in practice, the Inverse VixFix is much less reliable than the classical VixFix, but is nevertheless a good addition to get some additional context. Indeed, VixFix exit signals are as usual much less reliable than long entries signals, because: 1) mature markets such as SP500 tend to increase over the long term, 2) when market fall, retail traders panic and hence volatility skyrockets and bottom is more reliably signalled, but at market tops, no one is panicking, price action only loses momentum because of liquidity drying up.
//
// For more information on the Vix Fix, which is a strategy published under public domain:
// * The VIX Fix, Larry Williams, Active Trader magazine, December 2007, https://web.archive.org/web/20210115154821/https://www.marketcalls.in/wp-content/uploads/2014/12/VIXFix.pdf
// * Fixing the VIX: An Indicator to Beat Fear, Amber Hestla-Barnhart, Journal of Technical Analysis, March 13, 2015, https://ssrn.com/abstract=2577930
// * Replicating the CBOE VIX using a synthetic volatility index trading algorithm, Dayne Cary and Gary van Vuuren, Cogent Economics & Finance, Volume 7, 2019, Issue 1, https://doi.org/10.1080/23322039.2019.1641063
// * Identifying and trading reversals following a downward overreaction: The MOPOI trading algorithm, Martin Odink, 13 May 2016, Master Thesis at the University of Twente, Faculty of Behavioural, Management and Social Sciences, under the supervision of : Ir. H. Kroon and Dr. P.C. Schuur. https://web.archive.org/web/20221110163702/https://essay.utwente.nl/69695/1/Odink_BA_FacultyofBehaviouralManagementandSocialSciences%20%20.pdf
// * ChrisMoody original source code for the Williams' VixFix + Upper Bollinger Band's level for to generate bottom signals, 2014, equivalent to the MOPOI indicator: https://www.tradingview.com/script/og7JPrRA-CM-Williams-Vix-Fix-Finds-Market-Bottoms/
//
// Note that in the Hestla, 2015 and Odink, 2016 papers, each author respectively disclose a practical set of rules to design a strategy to automatically derive benefits from the proposed strategy, but per our conception of trading, we won't implement them, only the indicators are implemented here, not the strategies.
//
// Created By ChrisMoody on 12-26-2014... https://www.tradingview.com/script/og7JPrRA-CM-Williams-Vix-Fix-Finds-Market-Bottoms/
// V3 MAJOR Update on 1-05-2014 https://www.tradingview.com/script/pJpXG5JH-CM-Williams-Vix-Fix-V3-Ultimate-Filtered-Alerts/
// 01-05-2014 Major Updates Include: 
// * FILTERED ENTRIES ---  AND AGGRESSIVE FILTERED ENTRIES - HIGHLIGHT BARS AND ALERTS
// * Ability to Change All Bars To Gray, and Plot Entries AND Highlight Bars That Match The Williams Vix Fix
// * Alerts Enabled for 4 Different Criteria
// * Ability To Plot Alerts True/False Conditions on top of the WVF Histogram
// * Or Get Rid Of the Histogram and just see True/False Alerts Conditions.
// tista merged LazyBear's Black Dots filter in 2020: https://www.tradingview.com/script/zwFb8K6B-CM-Williams-Vix-Fix-V3-Ultimate-Filtered-Alerts-With-Threshold/
// extended by tartigradia in 10-2022:
// * Can select a symbol different from current to calculate vixfix, allows to select SP:SPX to mimic the original VIX index.
// * Inverse VixFix (from masa_crypto https://www.tradingview.com/script/xOY1jFKD-Williams-VIX-fix-inverse/ and https://web.archive.org/web/20221015105629/https://www.prorealcode.com/topic/the-ultimate-historical-and-implied-volatility-rank-and-percentile-indicator/page/2/)
// * VixFix OHLC Bars plot
// * Price / VixFix Candles plot (Pro Tip: draw trend lines to find good entry/exit points)
// * Add ADX filtering, Minimaxis signals, Minimaxis filtering (from samgozman https://www.tradingview.com/script/9zutsrOa-vix-fix-double-pleasure/)
// * Convert to pinescript v5
// * Allow timeframe selection (MTF)
// * Skip off days (more accurate reproduction of original VIX)
// * Reorganized, cleaned up code, commented out parts, commented out or removed unused code (eg, some of the KC calculations)
// * Changed default Bollinger Band settings to reduce false positives in crypto markets.
// * Improve combination plots, with autoscaling to ensure all kinds of plots can be visualized simultaneously.
// * A lot more additions, such as Stochastic VixFix (SVIX), adaptive rescaling, etc. See the indicator's page on TradingView for more details on subsequent updates.
//
// Set Index symbol to SPX, and index_current = false, and timeframe Weekly, to reproduce the original VIX as close as possible by the VIXFIX (use the Add Symbol option, because you want to plot CBOE:VIX on the same timeframe as the current chart, which may include extended session / weekends). With the Weekly timeframe, off days / extended session days should not change much, but with lower timeframes this is important, because nights and weekends can change how the graph appears and seemingly make them different because of timing misalignment when in reality they are not when properly aligned.
//
// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/

//@version=5
indicator(title='Williams Vix Fix ultra complete indicator (Tartigradia)', shorttitle='VIXFIX_TG', overlay=false, timeframe="", timeframe_gaps=false)

// AUX FUNCTIONS
//
na_skip_highest_or_lowest(series float src, int len, int mode) =>
    // Finds the highest or lowest historic value over len bars but skip na valued bars (eg, off days).
    // In other words, this will ensure we find the highest or lowest value over len bars with a real value, and if there are any na bars in-between, we skip over but the loop will continue.
    // This allows to mimic calculations on markets with off days (eg, weekends).
    highest_or_lowest = src
    i = 1
    j = 1
    while i < len and j <= len*2  // for the first few historic bars, there is not many previous bars, so we need to limit the maximum number of bars we walk through, here it's len*2, then we give up
        val = src[j]
        if not na(val)
            i += 1
            if (mode == 0 and highest_or_lowest < val) or (mode == 1 and highest_or_lowest > val)
                highest_or_lowest := val
        j += 1
    highest_or_lowest

na_skip_highest(series float src, int len) =>
    // Finds the highest historic value over len bars but skip na valued bars (eg, off days).
    // In other words, this will ensure we find the highest value over len bars with a real value, and if there are any na bars in-between, we skip over but the loop will continue.
    // This allows to mimic calculations on markets with off days (eg, weekends).
    na_skip_highest_or_lowest(src, len, 0)

na_skip_lowest(series float src, int len) =>
    // Finds the lowest historic value over len bars but skip na valued bars (eg, off days).
    // In other words, this will ensure we find the lowest value over len bars with a real value, and if there are any na bars in-between, we skip over but the loop will continue.
    // This allows to mimic calculations on markets with off days (eg, weekends).
    na_skip_highest_or_lowest(src, len, 1)

// @function Directional Movement Indicator
// @param len Lookback period
// @results [DIplus, DIminus] Directional movement positive and negative
dirmov(len) =>
    // by samgozman in: https://www.tradingview.com/script/9zutsrOa-vix-fix-double-pleasure/
	up = ta.change(high)
	down = -ta.change(low)
	plusDM = na(up) ? na : (up > down and up > 0 ? up : 0)
	minusDM = na(down) ? na : (down > up and down > 0 ? down : 0)
	truerange = ta.rma(ta.tr(false), len)
	plus = fixnan(100 * ta.rma(plusDM, len) / truerange)
	minus = fixnan(100 * ta.rma(minusDM, len) / truerange)
	[plus, minus]

// @function ADX Filter
// @param dilen Lookback period for the Directional Movement Indicator
// @param adxlen Lookback period for the ADX moving average (RMA)
// @results adx Adirectional trend or ranging market indicator
adx(dilen, adxlen) =>
    // by samgozman in: https://www.tradingview.com/script/9zutsrOa-vix-fix-double-pleasure/
	[plus, minus] = dirmov(dilen)
	sum = plus + minus
	adx = 100 * ta.rma(math.abs(plus - minus) / (sum == 0 ? 1 : sum), adxlen)

// @function Rescale x to be between minimum a and maximum b values
// @param x Input series
// @param a Target minimum value
// @param b Target maximum value
// @param min_x Minimum value for x before rescaling. Can be set to ta.min(x) unless you want future bars to have the same scaling as past bars, then a constant must be used.
// @param max_x Maximum value for x before rescaling. Can be set to ta.max(x) unless you want future bars to have the same scaling as past bars, then a constant must be used.
f_featurescale(x, a, b, min_x, max_x) =>
    a + ((x - min_x) * (b - a) / (max_x - min_x))

// @function Apply a featurescaling over a log rescaling
// @param x Input series
// @param b Target maximum value
// @param min_x Minimum value for log(x) before rescaling but after log transform (cannot be below 0)
// @param max_x Maximum value for log(x) before rescaling but after log transform
f_logfscale(x, b, min_x=0.0, max_x=10.0) =>
    //x_log = math.log(math.max(x, 1.0)) // threshold to 1.0 so that after log the min value is 0.0, we don't want negative values
    x_log = math.log(x+1) // for some reason, not thresholding looks better. But if it ever fails on a symbol, we will revert back to the thresholded version.
    // if we use max_x = ta.max(x) and similarly for min_x, there are two consistency issues with min and max values: temporal and between variables: 1) if we want multiple variables to be scaled linearly, ie, if variable A was greater than B then after scaling it should still be the same, such as for OHLC values, then we need to define the same max_x for all variables, 2) temporal consistency is more tricky, because ta.max can only find the highest value in past bars, it cannot look forward in the future, hence the value of past bars may not reflect their absolute value, ie, rescaled(bar1) can be == rescaled(bar100) but bar1 == 0.01 * bar100, for this issue there is no easy solution, we would need a lookahead and draw past bars from the future, otherwise the easiest but imperfect solution is to simply set a constant value, which is easier done on logarithmic values since we know they likely will be bounded.
    f_featurescale(x_log, 0.0, b, min_x, max_x)

// @function Zero-lag EMA (ZLMA)
// @param src Input series
// @param len Lookback period
// @returns Series smoothed with ZLMA
zema(series float src, int len) =>
    // by DreamsDefined in: https://www.tradingview.com/script/pFyPlM8z-Reverse-Engineered-RSI-Key-Levels-MTF/
    ema1 = ta.ema(src, len)
    ema2 = ta.ema(ema1, len)
    d = ema1 - ema2
    zlema = ema1 + d
    zlema

// @function Approximate Standard Moving Average, which substracts the average instead of popping the oldest element, hence losing the base frequency and is why it is approximative. For some reason, this appears to give the same results as a standard RMA
// @param x Input series.
// @param ma_length Lookback period.
// @results Approximate SMA series.
approximate_sma(series float x, int ma_length) =>
    sma = 0.0
    sma := nz(sma[1]) - (nz(sma[1] / ma_length)) + x
    sma

// @function Generalized moving average selector
// @param serie Input series
// @param ma_type String describing which moving average to use
// @param ma_length Lookback period
// @returns Serie smoothed with the selected moving average.
f_maSelect(series float serie, simple string ma_type="sma", ma_length=14) =>
    switch ma_type
        "sma" => ta.sma(serie, ma_length)
        "ema" => ta.ema(serie, ma_length)
        "rma" => ta.rma(serie, ma_length)
        "wma" => ta.wma(serie, ma_length)
        "vwma" => ta.vwma(serie, ma_length)
        "swma" => ta.swma(serie)
        "hma" => ta.hma(serie, ma_length)
        "alma" => ta.alma(serie, ma_length, 0.85, 6)
        "zlma" => zema(serie, ma_length)
        "approximate_sma" => approximate_sma(serie, ma_length)
        "median" => ta.percentile_nearest_rank(serie, ma_length, 50)
        =>
            runtime.error("No matching MA type found.")
            float(na)

// INPUT PARAMETERS
//
grp1='Core VixFix parameters'
index_current = input.bool(true, title='Use current chart symbol instead of the selected one below?', group=grp1, tooltip='If enabled, will use the currently selected symbol in TradingView chart to calculate VixFix. If disabled, you can select a symbol below.')
index_symbol = input.symbol('SP:SPX', 'Index symbol', group=grp1, tooltip='Symbol to calculate vixfix from. Select SPX to reproduce the VIX index.')
sym = index_current ? syminfo.tickerid : index_symbol  // select symbol: current or another symbol selected by user?
pd = input(11, title='LookBack Period for Classical Vix Fix', group=grp1)
pd_inv = input(50, title='LookBack Period for Inverse Vix Fix', group=grp1)
swvf = input(true, title='Show Williams Vix Fix Histogram', group=grp1)
swvf_inv = input(true, title='Show Inverse Williams Vix Fix Histogram', group=grp1)
skip_off_days = input.bool(false, title='Skip off days?', tooltip='The real VIX is calculated on SPX, which is closed on week-ends, but VixFix never closes off. With this option enabled, we try to mimic the real VIX calculation by skipping off days in the calculation (ie, more bars will be accounted for in timeframes lower than weekly).', group=grp1)
vixfix_log = input.bool(true, title='Logscale?', group=grp1, tooltip='Display on a logarithmic scale? This will not affect calculations, but only display.')

grp2='Outliers detection (highlight VIXFIX high points - market bottom/long entry/short exit signal)'
bbl = input(20, title='Bollinger Band Length', group=grp2)
mult = input.float(3.0, minval=1, maxval=5, title='Bollinger Band Standard Deviation Up', group=grp2, tooltip='Increase to reduce false positives rate, but some potential good signals will be missed.')
lb = input(100, title='Look Back Period Percentile High', group=grp2, tooltip='Increase to reduce false positives rate, but some potential good signals will be missed.')
ph = input(.85, title='Highest Percentile - 0.90=90%, 0.95=95%, 0.99=99%', group=grp2)
threshold = input(-5.0, title='Bar threshold', group=grp2)

grp25='Inverse outliers detection (highlight Inverse VIXFIX high points - market top/long exit/short entry signal)'
inv_bbl = input(20, title='Bollinger Band Length', group=grp25)
inv_mult = input.float(3.0, minval=1, maxval=5, title='Bollinger Band Standard Deviation Up', group=grp25)
inv_lb = input(100, title='Look Back Period Percentile High', group=grp25)
inv_ph = input(.85, title='Highest Percentile - 0.90=90%, 0.95=95%, 0.99=99%', group=grp25)
inv_scale = input.float(1.0, title='Visual Scaling Factor', group=grp25, tooltip='Scaling factor to reduce size of bars, so that positive VixFix can be seen on a similar scale. This is just for visual neatness, no difference in calculations.')
inv_scale_auto = input.bool(true, title='Automatic Visual Scaling', group=grp25, tooltip='Automatically scale Inverse VixFix on the same range as classical VixFix. Note however that this can misrepresent historical trends, since newer ATH will not update older bars, hence newer ATH will display as high as older ones.')
inv_scale_percentile = input.int(99, title='Visual scale to a percentile, so that we exclude extreme values from downscaling too much?', group=grp25, minval=1, maxval=100, step=1, tooltip='Allows to scale bigger when < 100 by scaling according to the percentile, instead of the max, ie, instead of scaling to the max value of classical vixfix, we calculate the 99th percentile value to scale 99% of the values but do not scale the extreme outliers. This is great to visually balance both Inverse VixFix and Classical VixFix, but this is done only on the last 100 bars, so this breaks comparability with historical values even more than the automatic visual scaling without percentile. Set to 100 to disable and use the max value over the whole past history.')
//inv_threshold = input(-5.0, title='Bar threshold', group=grp25) // not implemented

grp3='Price candles highlighting/coloring for entry/exit points'
new = input(false, title='-------Highlight Bars Below Use Original Criteria-------', group=grp3)
sbc = input(true, title='Show Highlight Bar if WVF WAS True and IS Now False', group=grp3)
sbcc = input(false, title='Show Highlight Bar if WVF IS True', group=grp3)
new2 = input(false, title='-------Highlight Bars Below Use FILTERED Criteria-------', group=grp3)
sbcFilt = input(true, title='Show Highlight Bar For Filtered Entry', group=grp3)
sbcAggr = input(false, title='Show Highlight Bar For AGGRESSIVE Filtered Entry', group=grp3)
new3 = input(false, title='Check Below to turn All Bars Gray, Then Check the Boxes Above, And your will have Same Colors As VixFix', group=grp3)
sgb = input(false, title='Check Box To Turn Bars Gray?', group=grp3)

grp4='Criteria for Down Trend Definition for Filtered Pivots and Aggressive Filtered Pivots'
ltLB = input.int(40, minval=25, maxval=99, title='Long-Term Look Back Current Bar Has To Close Below This Value OR Medium Term--Default=40', group=grp4)
mtLB = input.int(14, minval=10, maxval=20, title='Medium-Term Look Back Current Bar Has To Close Below This Value OR Long Term--Default=14', group=grp4)
str = input.int(3, minval=1, maxval=9, title='Entry Price Action Strength--Close > X Bars Back---Default=3', group=grp4)

grp5='Alerts Instructions and Options Below...Inputs Tab'
new4 = input(false, title='-------------------------Turn On/Off ALERTS Below---------------------', group=grp5)
new5 = input(false, title='----To Activate Alerts You HAVE To Check The Boxes Below For Any Alert Criteria You Want----', group=grp5)
new6 = input(false, title='----You Can Un Check The Box BELOW To Turn Off the WVF Histogram And Just See True/False Alert Criteria----', group=grp5)
sa1 = input(false, title='Show Alert WVF = True?', group=grp5)
sa2 = input(false, title='Show Alert WVF Was True Now False?', group=grp5)
sa3 = input(false, title='Show Alert WVF Filtered?', group=grp5)
sa4 = input(false, title='Show Alert WVF AGGRESSIVE Filter?', group=grp5)

grp6 = 'KC'
lengthKCBB = input(20, title='BB Length', group=grp6)
// mult1 = input(2.0,title="BB MultFactor", group=grp6)
lengthKC = input(20, title='KC Length', group=grp6)
multKC = input(1.5, title='KC MultFactor', group=grp6)
useTrueRange = input(true, title='Use TrueRange (KC)', group=grp6)
useBlackDot = input(false, title='Use Squeeze Black Dot as confirmation?')

grp7="Filter signals by ADX"
useAdxFilter = input(false, title="Use ADX filter?", group=grp7, tooltip='If enabled, will filter histogram colors depending on ADX value, ie, bars will only be highlighted if vixfix is both higher than bollinger bands and if ADX shows there is a trend.')
adxMinVal = input.int(20, title="🛠 Do not show signals if ADX is below", group=grp7, minval=0, maxval=100)
adxlen = input(14, title="ADX Smoothing (optional)", group=grp7)
dilen = input(14, title="DI Length (optional)", group=grp7)

grp75='Filter signals by Minimaxis'
useMinimaxisFilter = input.bool(false, title="Use Minimaxis filter?", group=grp75, tooltip='Highlight bars if current bar of classic or inversed VixFix value is lowest or highest under the lookback period. Works for both classical and inverse vixfix simultaneously.')
showMinimaxiSignals = input.bool(false, title='Show Minimaxis Signals as marks on top of the histogram?', group=grp75, tooltip='Show signals regardless of histogram colors. This another kind of signal that gives different results. It works for both classical and inverse vixfix simultaneously.')
showMinimaxiGoldenDeathCrosses = input.bool(false, title='Show Minimaxi GoldenCross and DeathCross histogram highlight?', group=grp75, tooltip='Use a golden cross and death cross like calculation to try to determine when there is a trend change, ie, when we are exiting a market bottom or top. This will color the relevant bars of the VixFix and Inverse VixFix histograms with a different color.')

grp76='Filter signals by Stochastic VixFix (SVIX)'
stoch_filter = input.bool(false, title='Use SVIX to filter both classical and inverse VixFix highlights?', group=grp76)
stoch_pd = input(20, title='LookBack Period', group=grp76, tooltip='Default: 20 period in the original SVIX.')
stoch_thr1 = input.int(80, title='Entry threshold', group=grp76, tooltip='Default: 80 for the original SVIX threshold.')
stoch_thr2 = input.int(20, title='Exit threshold', group=grp76, tooltip='Default: 20 for the original SVIX threshold.')
stoch_highlight = input.bool(false, title='Highlight SVIX entries and exits (above or below the thresholds)?', group=grp76)
stoch_highlight_ma = input.string('SVIX', title='Highlight based on SVIX or the smoothed SVIX?', group=grp76, options=['SVIX', 'SVIX_MA', 'SVIX_MA_2ND'], tooltip='SVIX is the raw SVIX (k in the Stochastic Oscillator), SVIX_MA is the first-level moving averaged SVIX, SVIX_MA_2ND is the second-level moving averaged SVIX, ie, MA(MA(SVIX)). In the original indicator, the raw SVIX is used. By default, the SVIX is used, as in the original paper, as it provides all entries signals, but alternatively the 14-period ZLMA smoothed SVIX is recommended, to reduce false positives and improve entry timing (enter after more falling instead of too early), but at the expense of missing some potential entries.')
stoch_ma_length = input.int(14, "Moving Average Length", minval=1, maxval=300, step=1, group=grp76, tooltip='Default: 14, empirically tweaked value tested on SPX and BTCUSD. Original is 20 in the original Stochastic Oscillator, and no moving average used for the original SVIX.')
stoch_ma_type = input.string('zlma', 'Moving Average Type', group=grp76, options=['sma', 'ema', 'rma', 'wma', 'vwma', 'swma', 'hma', 'alma', 'zlma', 'approximate_sma'], tooltip='What algorithm to use to smooth out SVIX? Default: sma as is applied on K to calculate D in the original Stochastic Oscillator, but note that MA is not used for the SVIX originally. These MAs smoothings are provided so that the SVIX can also be used as the standard stochastic oscillator simultaneously. Default: zlma, produces fast but smoothed entry signals. Original value would be sma for the Stochastic Oscillator, or no smoothing for the original SVIX.')
stoch_ma_length2 = input.int(20, "Moving Average Length second-level", minval=1, maxval=300, step=1, group=grp76)
stoch_ma_type2 = input.string('zlma', 'Moving Average Type second-level', group=grp76, options=['sma', 'ema', 'rma', 'wma', 'vwma', 'swma', 'hma', 'alma', 'zlma', 'approximate_sma'], tooltip='What algorithm to use to smooth out the already smoothed SVIX_MA to generate a second-level smoothed SVIX? In the Full Stochastic Oscillator, this would be D2. Default: zlma. Original type is sma.')
stoch_display = input.bool(false, title='Display SVIX and its smoothed variants as plots?', group=grp76, tooltip='Note that the plot will be rescaled to fit with the classical vixfix scale, so that both can be plotted simultaneously.')

grp8='VixFix OHLC bars plot'
showvixfixbars = input.bool(true, title='Show classical VixFix as an OHLC bars plot', group=grp8, tooltip='If enabled, display VixFix as a OHLC bars plot, which allows to more easily draw trend lines or better assess market pressure.')

grp9='Price/VixFix OHLC candles plot'
showpricediv = input.bool(false, title='Show Price Divided By VixFix', group=grp9, tooltip='If enabled, will display current chart symbol price divided by vixfix as an OHLC candles bars chart, essentially a SYM/VIXFIX relationship chart. These candles are automatically scaled on a log-scale. Pro tip: draw trend lines.')
pricedivscale = input.float(0.0, title="Price Divided by VixFix Rescaling", group=grp9, tooltip='Price divided by vixfix is in log scale to allow to draw it alongside normal vixfix, but a rescaling is still necessary, this value increases the rescaling, more = reduced values. Set to 0.0 for autorescaling, but scale is then not invariant (ie, higher price in the long past can in reality represent lower absolute prices than more recent past - this is especially true for assets which are increasing in a logarithmic scale, hence if autoscaling is used, do not compare very old bars with newer bars, try to do comparisons only within a relatively delimited window of eg 50-100 bars at once).')
pricedivscale_log = input.bool(true, title='Logscale?', group=grp9, tooltip='Rescale on a logarithmic scale? Enabling this is highly recommended.')
pricedivafterscale = input.float(1.0, title='Visual scaling factor (will be applied after the previous rescaling)', minval=0.000001, step=0.5, group=grp9, tooltip='If Price Divided By VixFix Rescaling is set to 0.0 for automatic rescaling, use this to manually rescale after, to visually magnify.')

// VIX FIX CALCULATIONS
//

// Load data
source_close = request.security(sym, timeframe.period, close, gaps=barmerge.gaps_on, lookahead=barmerge.lookahead_off)
source_open = request.security(sym, timeframe.period, open, gaps=barmerge.gaps_on, lookahead=barmerge.lookahead_off)
source_high = request.security(sym, timeframe.period, high, gaps=barmerge.gaps_on, lookahead=barmerge.lookahead_off)
source_low = request.security(sym, timeframe.period, low, gaps=barmerge.gaps_on, lookahead=barmerge.lookahead_off)
highest_close = not skip_off_days ? ta.highest(source_close, pd) : na_skip_highest(source_close, pd) // there is one difference with the real VIX: when the target market has closed days, such as SPX being closed on weekends, the calculation will be off because length window pd will include less open days bars because off days will be included, which are just duplicate values. Not sure there is an easy fix unless pinescript gets modified to include a way to fetch only open days bars regardless on the current symbol opened in the chart. The next equation, skipping na bars, is trying to workaround this limitation.
lowest_close = not skip_off_days ? ta.lowest(source_close, pd_inv) : na_skip_lowest(source_close, pd_inv)
stoch_highest_high = not skip_off_days ? ta.highest(source_high, stoch_pd) : na_skip_highest(source_high, stoch_pd)
stoch_lowest_low = not skip_off_days ? ta.lowest(source_low, stoch_pd) : na_skip_lowest(source_low, stoch_pd)

// Williams Vix Fix Formula
wvf = (highest_close - source_low) / highest_close * 100
// Inverse Williams Vix Fix, from https://web.archive.org/web/20221015105629/https://www.prorealcode.com/topic/the-ultimate-historical-and-implied-volatility-rank-and-percentile-indicator/page/2/ and https://www.tradingview.com/script/9zutsrOa-vix-fix-double-pleasure/
wvf_inverse = -1 * (lowest_close - source_high) / lowest_close * 100 // most accurate one, present in both sources, it's essentially just the opposite of the standard wvf
// Stochastic Vix Fix = mathematical complement of original Stochastic Oscillator
svix = (1 - (source_close - stoch_lowest_low) / (stoch_highest_high - stoch_lowest_low)) * 100 // svix = 100/k in the standard stochastic oscillator

// CLASSICAL VIX FIX OUTLIER DETECTION (TOPS/BOTTOMS HIGHLIGHTING)
//

// Outlier detection by Bollinger Bands (ie, local bottoms) for classical VixFix
sDev = mult * ta.stdev(wvf, bbl)
midLine = ta.sma(wvf, bbl)
lowerBand = midLine - sDev
upperBand = midLine + sDev
rangeHigh = not skip_off_days ? ta.highest(wvf, lb) * ph : na_skip_highest(wvf, lb) * ph

// KC / Black Dots filtering
// @author LazyBear 
// List of all my indicators: https://www.tradingview.com/v/4IneGo8h/
//

// Calculate BB
basis = ta.sma(source_close, lengthKCBB)
dev = multKC * ta.stdev(source_close, lengthKCBB)
upperBB = basis + dev
lowerBB = basis - dev

// Calculate KC
ma = ta.sma(source_close, lengthKC)
range_1 = useTrueRange ? ta.tr : source_high - source_low
rangema = ta.sma(range_1, lengthKC)
upperKC = ma + rangema * multKC
lowerKC = ma - rangema * multKC

sqzOn = lowerBB > lowerKC and upperBB < upperKC
sqzOff = lowerBB < lowerKC and upperBB > upperKC
noSqz = sqzOn == false and sqzOff == false

//val_kc = ta.linreg(source_close - math.avg(math.avg(ta.highest(source_high, lengthKC), ta.lowest(source_low, lengthKC)), ta.sma(source_close, lengthKC)), lengthKC, 0)
// bcolor = iff( val_kc > 0, 
//             iff( val_kc > nz(val_kc[1]), lime, green),
//             iff( val_kc < nz(val_kc[1]), red, maroon))
// scolor = noSqz ? blue : sqzOn ? black : gray 
// plot(val_kc, color=bcolor, style=histogram, linewidth=4)
// plot(0, color=scolor, style=cross, linewidth=2)
isBlackDot = noSqz ? false : sqzOn ? true : false

// ADX Filtering
adx_val = adx(dilen, adxlen)

// Minimaxis filtering
// by samgozman in: https://www.tradingview.com/script/9zutsrOa-vix-fix-double-pleasure/
isMaxUp = ta.highest(wvf_inverse, pd) == wvf_inverse // Top peaks
isMaxDown = ta.lowest(wvf, pd) == wvf // Top bottoms
isMinUp = ta.lowest(wvf_inverse, pd) == wvf_inverse // Min peaks
isMinDown = ta.highest(wvf, pd) == wvf // Min bottoms

// Minimaxis Signals
minimaxi_buySignal = isMaxDown or isMinUp
minimaxi_sellSignal = isMinDown or isMaxUp

// ADX Filtered Minimaxis Signals
minimaxi_buySignalFiltered = minimaxi_buySignal and adx_val >= adxMinVal
minimaxi_sellSignalFiltered = minimaxi_sellSignal and adx_val >= adxMinVal

// INVERSE VIXFIX OUTLIER DETECTION (BOLLINGER BAND, death cross, etc)
//

// Outlier detection by Bollinger Bands (ie, local maximums) for inverse VixFix
inv_sDev = inv_mult * ta.stdev(wvf_inverse, inv_bbl)
inv_midLine = ta.sma(wvf_inverse, inv_bbl)
inv_lowerBand = inv_midLine - inv_sDev
inv_upperBand = inv_midLine + inv_sDev
inv_rangeHigh = not skip_off_days ? ta.highest(wvf_inverse, inv_lb) * inv_ph : na_skip_highest(wvf_inverse, inv_lb) * inv_ph
inv_rangeLow = not skip_off_days ? ta.lowest(wvf_inverse, inv_lb) * inv_ph : na_skip_lowest(wvf_inverse, inv_lb) * inv_ph

// Death cross / Golden cross detection of trend change, courtesy of masa_crypto: https://www.tradingview.com/script/xOY1jFKD-Williams-VIX-fix-inverse/
inv_upperBand_crossover  = wvf_inverse > inv_upperBand
inv_upperBand_crossunder = wvf_inverse < inv_upperBand
goldencross = inv_upperBand_crossover and inv_upperBand_crossunder[1]
deathcross = inv_upperBand_crossunder and inv_upperBand_crossover[1]

// Stochastic VixFix SVIX smoothing and threshold, by tartigradia: https://www.tradingview.com/script/NbFQ85ud-Stochastic-Vix-Fix-SVIX-Tartigradia/
// Moving averages
d = f_maSelect(svix, stoch_ma_type, stoch_ma_length)
d2 = f_maSelect(d, stoch_ma_type2, stoch_ma_length2)

// Select if we use raw SVIX or smoothing SVIX
stoch_thr_val = switch stoch_highlight_ma
    'SVIX' => svix
    'SVIX_MA' => d
    'SVIX_MA_2ND' => d2
    =>
        runtime.error("No matching highlight_ma type found.")
        float(na)

// Detect if SVIX is beyond thresholds
svix_signal_oversold = stoch_thr_val > stoch_thr1
svix_signal_overbought = stoch_thr_val < stoch_thr2

// Entry/exit signals background highlight
bgcolor(not stoch_highlight ? na : svix_signal_oversold ? color.new(color.green, 50) : svix_signal_overbought ? color.new(color.red, 50) : na, title='Entry/exit signals background highlighting')

// CLASSICAL VIXFIX AND INVERSE VIXFIX HIGHLIGHTING
//

// Put it all together : Coloring Criteria of classical Williams Vix Fix
confirmationColor = wvf * -1 <= threshold ? useBlackDot ? isBlackDot ? color.lime : color.gray : color.lime : color.gray
wvf_color = (showMinimaxiGoldenDeathCrosses and goldencross) ?
     color.aqua :
     (wvf >= upperBand or wvf >= rangeHigh)
     and (not useAdxFilter or adx_val >= adxMinVal)
     and (not useMinimaxisFilter or (useAdxFilter ? minimaxi_buySignalFiltered : minimaxi_buySignal))
     and (not stoch_filter or svix_signal_oversold) ?
         confirmationColor :
         color.gray

// Coloring Criteria of Inverse Williams Vix Fix
//wvf_inverse_color = wvf_inverse <= inv_rangeLow ? color.gray : Death ? color.red : wvf_inverse >= inv_upperBand ? color.orange : color.gray
wvf_inverse_color = (wvf_inverse > inv_rangeLow) and (showMinimaxiGoldenDeathCrosses and deathcross) ?
     color.red :
     (wvf_inverse > inv_rangeLow)
     and (wvf_inverse >= inv_upperBand or wvf_inverse >= inv_rangeHigh)
     and (not useAdxFilter or adx_val >= adxMinVal)
     and (not useMinimaxisFilter or (useAdxFilter ? minimaxi_sellSignalFiltered : minimaxi_sellSignal))
     and (not stoch_filter or svix_signal_overbought) ?
         color.orange :
         color.gray

// CLASSICAL VIXFIX AND INVERSE VIXFIX PLOTS
//

// Plots for classical Williams Vix Fix Histogram
hline(0, title='Zero line', color=color.new(color.white, 70), linestyle=hline.style_solid, display=swvf or swvf_inv ? display.all : display.none)
wvf_display = (vixfix_log ? math.log(wvf+1) : wvf) // add +1 to ensure we don't get any value between 0 and 1, which would result in a negative value, and so it would overlap with the inverse vixfix
plot(swvf and wvf ? wvf_display : na, title='Williams Vix Fix', style=plot.style_columns, linewidth=4, color=color.new(wvf_color, 50), histbase=0.0)
plot(swvf and wvf ? upperBand : na, title='Williams Vix Fix Upper Band (values beyond are highlighted)', style = plot.style_line, color=color.gray, display=display.none)

// Williams' VixFix Inverse plotting
wvf_inverse_display = (vixfix_log ? math.log(wvf_inverse+1) : wvf_inverse) // add +1 to ensure we don't get any value between 0 and 1, which would result in a negative value, and so it would become positive and overlap with the classical vixfix
wvf_inverse_plot = not inv_scale_auto ? -wvf_inverse_display * inv_scale : -f_featurescale(wvf_inverse_display, 0.0, inv_scale_percentile < 100 ? ta.percentile_nearest_rank(wvf_display, 100, inv_scale_percentile) : ta.max(wvf_display), 0.0, inv_scale_percentile < 100 ? ta.percentile_nearest_rank(wvf_inverse_display, 100, inv_scale_percentile) : ta.max(wvf_inverse_display)) * inv_scale
plot(swvf_inv and wvf_inverse ? wvf_inverse_plot : na, title='Inverse Williams Vix Fix', style=plot.style_columns, linewidth=4, color=color.new(wvf_inverse_color, 50), histbase=0.0)
plot(swvf_inv and wvf_inverse ? -inv_upperBand : na, title='Inverse Williams Vix Fix Upper Band (values beyond are highlighted)', style = plot.style_line, color=color.gray, display=display.none)

// Minimaxis buy/sell signals, by samgozman: https://www.tradingview.com/script/9zutsrOa-vix-fix-double-pleasure/
// Note: above we already filter the vixfix and inverse vixfix histograms colors by minimaxis if enabled, but we also allow user to display the signal independently from the bollinger bands, because it may show more opportunities although it is more noisy, but by default they are hidden
plotshape(showMinimaxiSignals ? (useAdxFilter ? minimaxi_sellSignalFiltered : minimaxi_sellSignal) : na, title="Minimaxi Sell signal", color = color.red, style=shape.circle, location=location.top, size=size.tiny)
plotshape(showMinimaxiSignals ? (useAdxFilter ? minimaxi_buySignalFiltered : minimaxi_buySignal) : na, title="Minimaxi Buy signal", color = color.green, style=shape.circle, location=location.bottom, size=size.tiny)

// ALERTS AND PRICE BARS COLORING
//

//Filtered Bar Criteria
upRange = source_low > source_low[1] and source_close > source_high[1]
upRange_Aggr = source_close > source_close[1] and source_close > source_open[1]
//Filtered Criteria
filtered = (wvf[1] >= upperBand[1] or wvf[1] >= rangeHigh[1]) and wvf < upperBand and wvf < rangeHigh
filtered_Aggr = (wvf[1] >= upperBand[1] or wvf[1] >= rangeHigh[1]) and not(wvf < upperBand and wvf < rangeHigh)

//Alerts Criteria
alert1 = wvf >= upperBand or wvf >= rangeHigh ? 1 : 0
alert2 = (wvf[1] >= upperBand[1] or wvf[1] >= rangeHigh[1]) and wvf < upperBand and wvf < rangeHigh ? 1 : 0
alert3 = upRange and source_close > source_close[str] and (source_close < source_close[ltLB] or source_close < source_close[mtLB]) and filtered ? 1 : 0
alert4 = upRange_Aggr and source_close > source_close[str] and (source_close < source_close[ltLB] or source_close < source_close[mtLB]) and filtered_Aggr ? 1 : 0

//Highlight Price Bars Criteria
barcolor(sbcAggr and alert4 ? color.orange : na)
barcolor(sbcFilt and alert3 ? color.fuchsia : na)
barcolor(sbc and (wvf[1] >= upperBand[1] or wvf[1] >= rangeHigh[1]) and wvf < upperBand and wvf < rangeHigh ? color.aqua : na)
barcolor(sbcc and (wvf >= upperBand or wvf >= rangeHigh) ? color.lime : na)  // main highlighting criterion
barcolor(sgb and source_close ? color.gray : na)

// Plot alerts
plot(sa1 and alert1 ? alert1 : na, title='Alert If WVF = True', style=plot.style_line, linewidth=2, color=color.new(color.lime, 0))
plot(sa2 and alert2 ? alert2 : na, title='Alert If WVF Was True Now False', style=plot.style_line, linewidth=2, color=color.new(color.aqua, 0))
plot(sa3 and alert3 ? alert3 : na, title='Alert Filtered Entry', style=plot.style_line, linewidth=2, color=color.new(color.fuchsia, 0))
plot(sa4 and alert4 ? alert4 : na, title='Alert Aggressive Filtered Entry', style=plot.style_line, linewidth=2, color=color.new(color.orange, 0))

///////////////////////////

// WILLIAM'S VIXFIX CANDLES/BARS OHLC PLOT
//
wvf_open_mode = true
highest_open = not skip_off_days ? ta.highest(source_open, pd) : na_skip_highest(source_open, pd)
highest_high = not skip_off_days ? ta.highest(source_high, pd) : na_skip_highest(source_high, pd)
highest_low = not skip_off_days ? ta.highest(source_low, pd) : na_skip_highest(source_low, pd)
wvf_close = wvf // to avoid calculation duplication, but it's equivalent to: (highest_close - source_low) / highest_close * 100
wvf_open = wvf_open_mode ? nz(wvf_close[1]) : (highest_open - source_low) / highest_open * 100 // the latter equation is useless in general because unless there are lots of gaps, open == close of the previous day, hence candles will most often have the same open and close values
wvf_high = (highest_high - source_low) / highest_high * 100
wvf_low = (highest_low - source_low) / highest_low * 100
// rescale on a logscale if necessary
wvf_close_rescaled = vixfix_log ? math.max(0.0, math.log(wvf_close+1)) : wvf_close  // add +1 to ensure we don't get any value between 0 and 1, which would result in a negative value
wvf_open_rescaled = vixfix_log ? math.max(0.0, math.log(wvf_open+1)) : wvf_open
wvf_high_rescaled = vixfix_log ? math.max(0.0, math.log(wvf_high+1)) : wvf_high
wvf_low_rescaled = vixfix_log ? math.max(0.0, math.log(wvf_low+1)) : wvf_low // cap to 0.0 because log of values < 1.0 will produce negative values, which we don't want as they will go towards the inverse vixfix part of the graph and are not meaningful
// plot bars (can be replaced by a candles plot but there is less clutter when plotting the vixfix histogram when using a bars plot)
plotbar(wvf_open_rescaled, wvf_high_rescaled, wvf_low_rescaled, wvf_close_rescaled, title="Williams VixFix OHLC Bars Plot", color=(wvf_close >= wvf_open) ? color.lime : color.red, display=showvixfixbars ? display.all : display.none)

// PRICE DIVISION
//
price_div_wvf_close = close / wvf_close
price_div_wvf_open = open / wvf_open
price_div_wvf_low = high / math.max(wvf_high, wvf_close, wvf_open, wvf_low)  // low and high are inverted since we divide
price_div_wvf_high = high / math.min(wvf_low, wvf_close, wvf_open, wvf_high)  // wvf_low can be 0.0, then division by zero and hence na value
if na(price_div_wvf_high) or price_div_wvf_high > 2*(math.max(price_div_wvf_close, price_div_wvf_open))
    // Since we divide by lowest prices, we can get a division by a very tiny number like 0.01, then we can get a huge wick that does not represent anything.
    // In this case, we just revert to divide to another more reasonable value.
    price_div_wvf_high := nz(high / math.min(wvf_close, wvf_open, wvf_high))
    //price_div_wvf_high := nz(math.max(price_div_wvf_close, price_div_wvf_open, price_div_wvf_high))
    //price_div_wvf_high := 1.0

// Plot divided price on a log scale, otherwise because of division we can only see some big candles and the rest is flat
// Also we featurescale so that we can plot price alongside the vixfix histogram
//max_wvf_high = math.max(wvf_high, nz(wvf_high[1]))
max_wvf_high = ta.max(wvf_high_rescaled) // get the max price over the historic bars, to rescale price divided by vixfix
if nz(pricedivscale) == 0.0 // autoscaling
    pricedivscale := max_wvf_high
max_price_div_wvf_high = pricedivscale_log ? math.log(ta.max(price_div_wvf_high)) : ta.max(price_div_wvf_high)
min_price_div_wvf_low = pricedivscale_log ? math.log(ta.min(price_div_wvf_low)) : ta.min(price_div_wvf_low)
price_div_wvf_color = (price_div_wvf_close >= price_div_wvf_open) ? color.lime : color.red
price_div_wvf_open_rescaled = pricedivscale_log ? f_logfscale(price_div_wvf_open, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high) * pricedivafterscale : f_featurescale(price_div_wvf_open, 0.0, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high)
price_div_wvf_high_rescaled = pricedivscale_log ? f_logfscale(price_div_wvf_high, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high) * pricedivafterscale : f_featurescale(price_div_wvf_high, 0.0, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high)
price_div_wvf_low_rescaled = pricedivscale_log ? f_logfscale(price_div_wvf_low, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high) * pricedivafterscale : f_featurescale(price_div_wvf_low, 0.0, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high)
price_div_wvf_close_rescaled = pricedivscale_log ? f_logfscale(price_div_wvf_close, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high) * pricedivafterscale : f_featurescale(price_div_wvf_close, 0.0, pricedivscale, min_price_div_wvf_low, max_price_div_wvf_high)
plotcandle(price_div_wvf_open_rescaled, price_div_wvf_high_rescaled, price_div_wvf_low_rescaled, price_div_wvf_close_rescaled, title="Price Divided By William's VixFix (OHLC Candles Plot)", color=price_div_wvf_color, wickcolor=price_div_wvf_color, bordercolor=price_div_wvf_color, display=showpricediv ? display.all : display.none) // uncomment this when ready
//plotcandle(price_div_wvf_open, price_div_wvf_high, price_div_wvf_low, price_div_wvf_close, title="Price Divided By William's VixFix", color=price_div_wvf_color, wickcolor=price_div_wvf_color, bordercolor=price_div_wvf_color) // debug

// SVIX plots
plot(f_featurescale(svix, 0.0, max_wvf_high, 0.0, 100.0), title='SVIX', color=color.yellow, linewidth=2, display=stoch_display ? display.all : display.none)
plot(f_featurescale(d, 0.0, max_wvf_high, 0.0, 100.0), title='SVIX_MA (smoothed SVIX aka D)', color=color.aqua, display=stoch_display ? display.all : display.none)
plot(f_featurescale(d2, 0.0, max_wvf_high, 0.0, 100.0), title='SVIX_MA_2ND (smoothed D aka D2)', color=color.purple, display=stoch_display ? display.all : display.none)

// BONUS
//

// Variant calculation, sensitive to both lows and highs
lowest_close_classical = not skip_off_days ? ta.lowest(source_close, pd) : na_skip_lowest(source_close, pd)
wvf_variant = (1 + ((source_high - lowest_close_classical - source_low) / lowest_close_classical)) * 200
plot(wvf_variant, title='WVF Variant (Both Highs and Lows detection)', color=color.red, display=display.none) // may be interesting to know big impulsive moves but regardless of direction
