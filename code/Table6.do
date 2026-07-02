*Table 6: Robustness Test: Variation in Share of Rainfed Area
*
* Uses the cached 80%-agri analysis sample. priots_20km already built.
* Produces:
*   - the formatted dCDH results table  -> ${results}/table6.tex
*   - the per-threshold event-study graphs -> ${results}/rainfed*.png
* Requires ${cache}, ${results}. Packages installed by master.do.
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

*** Rainfed Variation ----------------------------------------------------------
* priots_20km already present in cache.

dcdh_run priots_20km id end_t harvest if rainfed_mean >= 0.4 , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c1 "ward year dekyear"
graph export "rainfed40.png", replace

dcdh_run priots_20km id end_t harvest if rainfed_mean >= 0.5 , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c2 "ward year dekyear"
graph export "rainfed50.png", replace

dcdh_run priots_20km id end_t harvest if rainfed_mean >= 0.6 , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c3 "ward year dekyear"
graph export "rainfed60.png", replace

dcdh_run priots_20km id end_t harvest if rainfed_mean >= 0.7 , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c4 "ward year dekyear"
graph export "rainfed70.png", replace

dcdh_run priots_20km id end_t harvest if rainfed_mean >= 0.8 , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c5 "ward year dekyear"
graph export "rainfed80.png", replace

dcdh_run priots_20km id end_t harvest if rainfed_mean >= 0.9 , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c6 "ward year dekyear"
graph export "rainfed90.png", replace

*** Assemble the table ---------------------------------------------------------
#delimit ;
esttab c1 c2 c3 c4 c5 c6 using "table6.tex", replace
    cells(b(fmt(%9.3f) star) se(fmt(%9.3f) par([ ]))) star(* 0.1 ** 0.05 *** 0.01)
    coeflabel(delta "Avg. Total Effect (\$\delta\$)")
    mgroups("Sum of Protests (Buffer size: 20 km)", pattern(1 0 0 0 0 0) span
            prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
    mtitles("40\%" "50\%" "60\%" "70\%" "80\%" "90\%")
    nonotes label compress collabels(none) obslast
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs,
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc)
        labels("Placebo Joint \$p\$-val" "Placebo Sup t-test" "Effects Joint \$p\$-val"
               "Ward FE" "Year FE" "Year \$\times\$ Dekad FE"
               "Switchers" "Observations")) ;
#delimit cr

* On-screen version
esttab c1 c2 c3 c4 c5 c6, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    coeflabel(delta "Avg. Total Effect (delta)") ///
    mtitles("40%" "50%" "60%" "70%" "80%" "90%") ///
    nonotes label compress collabels(none) obslast ///
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs, ///
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc) ///
        labels("Placebo Joint p-val" "Placebo Sup t-test" "Effects Joint p-val" ///
               "Ward FE" "Year FE" "Year x Dekad FE" ///
               "Switchers" "Observations"))
