*Table 9: Different Types of Protest and Conflict
*
* NOTE: the original source had no `use` statement and relied on whatever
* dataset was already in memory. It is made self-sufficient here by loading the
* cached 80%-agri analysis sample (which also contains protests_20km, riots_20km,
* viol_20km, battle_20km_).
* Produces:
*   - the formatted dCDH results table  -> ${results}/app_table9.tex
*   - the per-category event-study graphs -> ${results}/{protests,riots,viol_20km,battle_20km_}.png
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

dcdh_run protests_20km id end_t harvest, ///
   effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c1 "ward year dekyear"
graph export "protests.png", replace

dcdh_run riots_20km id end_t harvest, ///
   effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c2 "ward year dekyear"
graph export "riots.png", replace
 /*
did_multiplegt_dyn stra_dev_20km id end_t harvest, ///
   effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl

	sotable, pnames(`=e(placebo)') normal

	graph export "stra_dev_20km.png", replace
	*/
dcdh_run viol_20km id end_t harvest, ///
   effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c3 "ward year dekyear"
graph export "viol_20km.png", replace

dcdh_run battle_20km id end_t harvest, ///
   effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c4 "ward year dekyear"
graph export "battle_20km_.png", replace

*** Assemble the table ---------------------------------------------------------
#delimit ;
esttab c1 c2 c3 c4 using "app_table9.tex", replace
    cells(b(fmt(%9.3f) star) se(fmt(%9.3f) par([ ]))) star(* 0.1 ** 0.05 *** 0.01)
    coeflabel(delta "Avg. Total Effect (\$\delta\$)")
    mgroups("Conflict Category (Buffer size: 20 km)", pattern(1 0 0 0) span
            prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
    mtitles("Protests" "Riots" "Viol. vs Civ." "Battles")
    nonotes label compress collabels(none) obslast
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs,
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc)
        labels("Placebo Joint \$p\$-val" "Placebo Sup t-test" "Effects Joint \$p\$-val"
               "Ward FE" "Year FE" "Year \$\times\$ Dekad FE"
               "Switchers" "Observations")) ;
#delimit cr

* On-screen version
esttab c1 c2 c3 c4, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    coeflabel(delta "Avg. Total Effect (delta)") ///
    mtitles("Protests" "Riots" "Viol. vs Civ." "Battles") ///
    nonotes label compress collabels(none) obslast ///
    stats(p_placebo p_supt p_effects ward_fe year_fe dekyear_fe switchers nobs, ///
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc) ///
        labels("Placebo Joint p-val" "Placebo Sup t-test" "Effects Joint p-val" ///
               "Ward FE" "Year FE" "Year x Dekad FE" ///
               "Switchers" "Observations"))
