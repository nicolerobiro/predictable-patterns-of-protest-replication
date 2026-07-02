*Table 7: Robustness Test: Variation in Evaluation Windows
*
* Uses the cached 80%-agri analysis sample. priots_20km already built.
* Produces:
*   - the formatted dCDH results table  -> ${results}/table7.tex
*   - the per-window event-study graphs -> ${results}/timewindow*.png
* Requires ${cache}, ${results}. Packages installed by master.do.
*
* NOTE: in the original source the effects(4) and effects(5) runs both exported
* to "timewindow5_5.png", so the first was overwritten. The 4-effects export is
* renamed to "timewindow4_4.png" so no result is lost. Estimation unchanged.
*
* Each column has a different number of post-treatment horizons (effects), so
* the placebo / effects test rows differ across columns accordingly.
********************************************************************************

if ("${data}" == "") {
    global root    "."
    global code    "${root}/code"
    global data    "${root}/data"
    global results "${root}/Results"
    global cache   "${data}/_cache"
}

* Load cached analysis sample only if not already in memory
do "${code}/_load.do" "${cache}/_cache_analysis_80percent.dta"

* Make graph exports land in Results
cd "${results}"

* Load the dCDH table helpers (dcdh_run / dcdh_post)
do "${code}/_dcdh_table.do"

est clear

*** Different Time Horizons ----------------------------------------------------
* priots_20km already present in cache.


dcdh_run priots_20km id end_t harvest, ///
    effects(5) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c2 "ward year dekyear"
graph export "timewindow5_5.png", replace

dcdh_run priots_20km id end_t harvest, ///
    effects(6) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c3 "ward year dekyear"
graph export "timewindow5_6.png", replace

dcdh_run priots_20km id end_t harvest, ///
    effects(8) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c4 "ward year dekyear"
graph export "timewindow5_8.png", replace

dcdh_run priots_20km id end_t harvest, ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c5 "ward year dekyear"
graph export "timewindow5_10.png", replace

dcdh_run priots_20km id end_t harvest, ///
    effects(12) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c6 "ward year dekyear"
graph export "timewindow6_12.png", replace

dcdh_run priots_20km id end_t harvest, ///
    effects(14) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c7 "ward year dekyear"
graph export "timewindow7_14.png", replace

*** Assemble the table ---------------------------------------------------------
#delimit ;
esttab  c2 c3 c4 c5 c6 c7 using "table7.tex", replace
    cells(b(fmt(%9.3f) star) se(fmt(%9.3f) par([ ]))) star(* 0.1 ** 0.05 *** 0.01)
    coeflabel(delta "Avg. Total Effect (\$\delta\$)")
    mgroups("Sum of Protests (Buffer size: 20 km)", pattern(1 0 0 0 0 0 0) span
            prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
    mtitles("5" "6" "8" "10" "12" "14")
    nonotes label compress collabels(none) obslast
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs,
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc)
        labels("Placebo Joint \$p\$-val" "Placebo Sup t-test" "Effects Joint \$p\$-val"
               "Ward FE" "Year FE" "Year \$\times\$ Dekad FE"
               "Switchers" "Observations")) ;
#delimit cr

* On-screen version
esttab  c2 c3 c4 c5 c6 c7, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    coeflabel(delta "Avg. Total Effect (delta)") ///
    mtitles("4" "5" "6" "8" "10" "12" "14") ///
    nonotes label compress collabels(none) obslast ///
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs, ///
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc) ///
        labels("Placebo Joint p-val" "Placebo Sup t-test" "Effects Joint p-val" ///
               "Ward FE" "Year FE" "Year x Dekad FE" ///
               "Switchers" "Observations"))
