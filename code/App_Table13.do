*Table 13: Different Outcome Variable (protest dummy / protests per sqkm)
*
* Uses the cached 80%-agri analysis sample. priots_20km_dum and
* priots_20km_sqkm (incl. the adm3_area merge) are both built in
* 00_prepare_data.do, so they are NOT regenerated / re-merged here.
* Produces:
*   - the formatted dCDH results table  -> ${results}/app_table13.tex
*   - the per-outcome event-study graphs -> ${results}/{protest_dummy,protest_sqkm}.png
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

*** Different Outcome Variable -------------------------------------------------
* priots_20km_dum, priots_20km_sqkm already present in cache.

dcdh_run priots_20km_dum id end_t harvest, ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c1 "ward year dekyear"
graph export "protest_dummy.png", replace

dcdh_run priots_20km_sqkm id end_t harvest, ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c2 "ward year dekyear"
graph export "protest_sqkm.png", replace

*** Assemble the table ---------------------------------------------------------
#delimit ;
esttab c1 c2 using "app_table13.tex", replace
    cells(b(fmt(%9.3f) star) se(fmt(%9.3f) par([ ]))) star(* 0.1 ** 0.05 *** 0.01)
    coeflabel(delta "Avg. Total Effect (\$\delta\$)")
    mgroups("Outcome (Buffer size: 20 km)", pattern(1 0) span
            prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
    mtitles("Protest (0/1)" "Protests per km\$^2\$")
    nonotes label compress collabels(none) obslast
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs,
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc)
        labels("Placebo Joint \$p\$-val" "Placebo Sup t-test" "Effects Joint \$p\$-val"
               "Ward FE" "Year FE" "Year \$\times\$ Dekad FE"
               "Switchers" "Observations")) ;
#delimit cr

* On-screen version
esttab c1 c2, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    coeflabel(delta "Avg. Total Effect (delta)") ///
    mtitles("Protest (0/1)" "Protests per sqkm") ///
    nonotes label compress collabels(none) obslast ///
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs, ///
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc) ///
        labels("Placebo Joint p-val" "Placebo Sup t-test" "Effects Joint p-val" ///
               "Ward FE" "Year FE" "Year x Dekad FE" ///
               "Switchers" "Observations"))
