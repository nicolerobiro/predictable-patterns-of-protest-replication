*Table 5: Robustness Test: Buffer Variation
*
* Uses the cached 80%-agri analysis sample. priots_0/5/10/15/20km already built.
* Produces:
*   - the formatted dCDH results table  -> ${results}/table5.tex
*   - the per-buffer event-study graphs -> ${results}/dCDH_*.png
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

*** Buffers --------------------------------------------------------------------
* priots_0km, priots_5km, priots_10km, priots_15km, priots_20km already in cache.

dcdh_run priots_0km id end_t harvest , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c1 "ward year dekyear"
graph export "dCDH_0km.png", replace

dcdh_run priots_5km id end_t harvest , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c2 "ward year dekyear"
graph export "dCDH_5km.png", replace

dcdh_run priots_10km id end_t harvest , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c3 "ward year dekyear"
graph export "dCDH_10km.png", replace

dcdh_run priots_15km id end_t harvest , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c4 "ward year dekyear"
graph export "dCDH_15km.png", replace

dcdh_run priots_20km id end_t harvest , ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c5 "ward year dekyear"
graph export "dCDH_20km.png", replace

*** Assemble the table ---------------------------------------------------------
#delimit ;
esttab c1 c2 c3 c4 c5 using "table5.tex", replace
    cells(b(fmt(%9.3f) star) se(fmt(%9.3f) par([ ]))) star(* 0.1 ** 0.05 *** 0.01)
    coeflabel(delta "Avg. Total Effect (\$\delta\$)")
    mgroups("Sum of Protests", pattern(1 0 0 0 0) span
            prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
    mtitles("0km" "5km" "10km" "15km" "20km")
    nonotes label compress collabels(none) obslast
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs,
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc)
        labels("Placebo Joint \$p\$-val" "Placebo Sup t-test" "Effects Joint \$p\$-val"
               "Ward FE" "Year FE" "Year \$\times\$ Dekad FE"
               "Switchers" "Observations")) ;
#delimit cr

* On-screen version
esttab c1 c2 c3 c4 c5, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    coeflabel(delta "Avg. Total Effect (delta)") ///
    mtitles("0km" "5km" "10km" "15km" "20km") ///
    nonotes label compress collabels(none) obslast ///
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs, ///
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc) ///
        labels("Placebo Joint p-val" "Placebo Sup t-test" "Effects Joint p-val" ///
               "Ward FE" "Year FE" "Year x Dekad FE" ///
               "Switchers" "Observations"))
