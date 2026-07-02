*** Main regression dynamic approach (dCDH)
*
* Uses the cached 80%-agri analysis sample (priots_20km already built).
* Produces:
*   - the headline event-study graph  -> ${results}/did_multiplegt_dyn_harvest_final.png
*   - a one-column results table       -> ${results}/figure5_table.tex
* Requires ${cache}, ${results}.
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

* Make sure exports land in Results
cd "${results}"

* Load the dCDH table helpers (dcdh_run / dcdh_post)
do "${code}/_dcdh_table.do"

est clear

* priots_20km is already present in the cached file.

dcdh_run priots_20km id end_t harvest , effects(10) placebo(5) cluster(name1) ///
    normalized same_switchers same_switchers_pl
dcdh_post c1 "ward year dekyear"

graph export "${results}/did_multiplegt_dyn_harvest_final.png", replace

