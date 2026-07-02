********************************************************************************
********************************************************************************
**                                                                            **
**   MASTER DO-FILE                                                           **
**   Predictable Patterns of Protest: The Impact of Agricultural Cycles on    **
**   Social Unrest in Kenya — Replication Package                   		  **
**                                                                            **
**   Runs the full replication pipeline: data prep, main tables, figures,     **
**   and appendix material. Set the project root ONCE below and run.          **
**                                                                            **
********************************************************************************
********************************************************************************

clear all
set more off
set varabbrev off
macro drop _all

*==============================================================================*
* 1. PROJECT ROOT  ---  EDIT THIS ONE LINE ONLY
*------------------------------------------------------------------------------
* If you launch this file by double-clicking / "do"-ing it, the line below
* auto-detects the location of master.do and uses its parent as the root, so
* in most cases you do not need to change anything.
*==============================================================================*

* --- auto-detect root from the master.do location (falls back to cwd) -------
quietly {
    if ("${root}" == "") {
        local mloc "`c(filename)'"
        if ("`mloc'" != "") {
            * master.do lives in <root>/code/  -> go up one level
            local mdir = substr("`mloc'", 1, length("`mloc'") - strlen("master.do"))
            global root "`mdir'../"
        }
        else {
            global root "."
        }
    }
}

* >>> If auto-detection does not suit your setup, hard-code the root here: <<<
 global root "PROJECT_ROOT_NEEDS_TO_BE_SET"

*==============================================================================*
* 2. DERIVED PATHS  (do not edit)
*==============================================================================*
global code     "${root}/code"
global data     "${root}/data"
global results  "${root}/Results"
global cache    "${data}/_cache"

cap mkdir "${results}"
cap mkdir "${cache}"

* Make graph/table exports land in Results by default
cd "${results}"

display as text _n "{hline 78}"
display as text "  Project root : ${root}"
display as text "  Data folder  : ${data}"
display as text "  Results to   : ${results}"
display as text "{hline 78}" _n

*==============================================================================*
* 3. DEPENDENCIES  (installed once; comment out if your machine is offline /
*    already has them)
*==============================================================================*
local pkgs reghdfe ftools did_multiplegt_dyn gtools estout xtevent acreg
foreach p of local pkgs {
    capture which `p'
    if (_rc) {
        display as text "Installing `p' ..."
        capture ssc install `p', replace
    }
}
* did_multiplegt_dyn ships the companion command "sotable"; it installs with the
* main package above. xtevent / acreg are only needed for the (optional /
* commented-out) event-study and Conley-HAC blocks.

*==============================================================================*
* 4. RUN ORDER
*------------------------------------------------------------------------------
* 00_prepare_data builds ${cache}/_cache_analysis_80percent.dta once. Every
* script that uses the 80%-agri sample then loads that cached file, so the raw
* derivations are not repeated on each run.
*
* Set RUN_PREP to 0 to skip the (re)build of the cache if it already exists and
* the raw data has not changed.
*==============================================================================*
global RUN_PREP 1

if ($RUN_PREP) {
    do "${code}/00_prepare_data.do"
}

* ---- Main text -------------------------------------------------------------
do "${code}/Figure2.do"
do "${code}/Figure3.do"
do "${code}/Figure4.do"
do "${code}/Figure5.do"
do "${code}/Table1.do"
do "${code}/Table2.do"
do "${code}/Table3.do"
do "${code}/Table4.do"
do "${code}/Table5.do"
do "${code}/Table6.do"
do "${code}/Table7.do"
do "${code}/Table8.do"

* ---- Appendix --------------------------------------------------------------
do "${code}/App_Figure9.do"
do "${code}/App_Figure10.do"
do "${code}/App_Table9.do"
do "${code}/App_Table10.do"
do "${code}/App_Table11.do"
do "${code}/App_Table12.do"
do "${code}/App_Table13.do"

display as result _n "{hline 78}"
display as result "  PIPELINE COMPLETE.  All output written to ${results}"
display as result "{hline 78}"
