*Table 8: Robustness Test: Sample Restrictions and Additional Controls
*
* Uses the cached 80%-agri analysis sample. priots_20km, election_dekate_new
* and warning_2_4 are all built in 00_prepare_data.do.
* Produces:
*   - the formatted dCDH results table  -> ${results}/table8.tex
*   - the per-spec event-study graphs   -> ${results}/{nairobi,election,anomalies,quality}.png
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

* priots_20km, election_dekate_new, warning_2_4 already present in cache.

*excluding nairobi
dcdh_run priots_20km id end_t harvest if nairobi_area == 0, ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c1 "ward dekyear"
graph export "nairobi.png", replace

*exclude election years
dcdh_run priots_20km id end_t harvest if !election_dekate_new, ///
    effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c2 "ward dekyear"
graph export "election.png", replace

*anomalies
dcdh_run priots_20km id end_t harvest, ///
   controls(warning_2_4) effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c3 "ward  dekyear controls"
graph export "anomalies.png", replace

*quality
dcdh_run priots_20km id end_t harvest, ///
   controls( maxNDVI end_linteg_filled ampl_filled length_filled) effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c4 "ward dekyear controls"
graph export "quality.png", replace

*** Assemble the table ---------------------------------------------------------
#delimit ;
esttab c1 c2 c3 c4 using "table8.tex", replace
    cells(b(fmt(%9.3f) star) se(fmt(%9.3f) par([ ]))) star(* 0.1 ** 0.05 *** 0.01)
    coeflabel(delta "Avg. Total Effect (\$\delta\$)")
    mgroups("Sum of Protests (Buffer size: 20 km)", pattern(1 0 0 0) span
            prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span}))
    mtitles("Excl. Nairobi" "Excl. Election" "Anomalies" "Quality")
    nonotes label compress collabels(none) obslast
    stats(p_placebo p_supt p_effects ward_fe dekyear_fe controls switchers nobs,
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc)
        labels("Placebo Joint \$p\$-val" "Placebo Sup t-test" "Effects Joint \$p\$-val"
               "Ward FE"  "Year \$\times\$ Dekad FE" "Controls"
               "Switchers" "Observations")) ;
#delimit cr

* On-screen version
esttab c1 c2 c3 c4, ///
    b(%9.3f) se(%9.3f) star(* 0.1 ** 0.05 *** 0.01) ///
    coeflabel(delta "Avg. Total Effect (delta)") ///
    mtitles("Excl. Nairobi" "Excl. Election" "Anomalies" "Quality") ///
    nonotes label compress collabels(none) obslast ///
    stats(p_placebo p_supt p_effects ward_fe dekyear_fe controls switchers nobs, ///
        fmt(%9.3f %9.3f %9.3f 0 0 0 %9.0fc %9.0fc) ///
        labels("Placebo Joint \$p\$-val" "Placebo Sup t-test" "Effects Joint \$p\$-val" ///
               "Ward FE"  "Year \$\times\$ Dekad FE" "Controls" ///
               "Switchers" "Observations")) 
