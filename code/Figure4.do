* Additional approach Event study
*
* Uses the cached 80%-agri analysis sample (priots_20km already built in
* 00_prepare_data.do). Requires ${cache}, ${results}. Packages are installed by
* master.do; the standalone ssc line is kept commented for reference.
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

* priots_20km is already present in the cached file; no need to regenerate.

*ssc install xtevent
xtevent priots_20km, pol(harvest) panelvar(id) timevar(end_t) window(4) norm(-4)
xteventplot , title("Quasi Event Study Plot") subtitle("Reference Period: Max NDVI / Pre-Harvest") graphregion(color(white))
graph export "${results}/CropCycle_Eventstudy_t_minus4.png", as(png) name("Graph") replace
