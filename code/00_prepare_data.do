********************************************************************************
* 00_prepare_data.do
*------------------------------------------------------------------------------
* Builds the cached analysis dataset used by the bulk of the regression and
* dynamic-DiD scripts. All derived variables that were previously regenerated
* inside every single do-file (priots_*, buffer sums, dummies, robustness
* flags) are constructed ONCE here and saved to:
*
*     ${data}/_cache_analysis_80percent.dta
*
* Downstream do-files load this cached file instead of rebuilding the same
* variables on every run. This is the single largest efficiency gain in the
* pipeline.
*
* Requires (in ${data}/):
*     database_final_80percent.dta
*     adm3_area.dta
*------------------------------------------------------------------------------
* NOTE: assumes the global ${data}, ${results} and ${cache} are already set by
* the master file (master.do). If you run this file on its own, run the
* "Standalone configuration" block below first.
********************************************************************************

*--- Standalone configuration (only needed if NOT called from master.do) ------
if ("${data}" == "") {
    * <<< EDIT THIS ONE LINE if running standalone >>>
    global root "."
    global data    "${root}/data"
    global results "${root}/Results"
    global cache   "${data}/_cache"
    cap mkdir "${cache}"
}

*--- Build -------------------------------------------------------------------
use "${data}/database_final_80percent.dta", clear

* Headline outcome and buffer-specific protest+riot sums --------------------
gen priots_0km  = protests_0km  + riots_0km
gen priots_5km  = protests_5km  + riots_5km
gen priots_10km = protests_10km + riots_10km
gen priots_15km = protests_15km + riots_15km
gen priots_20km = protests_20km + riots_20km

* Binary version of the headline outcome (LPM / logit) ----------------------
gen priots_20km_dum = (priots_20km > 0) if !missing(priots_20km)

* Interacted FE groups for acreg (cannot parse # inside pfe()) --------------
egen id_dek   = group(id   dekate_variable)
egen year_dek = group(year dekate_variable)

* Robustness flags (previously generated inside App_Table12) ----------------
gen election_dekate_new = ///
       (year == 2002 & inrange(dekate_variable,35,36)) ///
     | (year == 2003 & inrange(dekate_variable, 1, 1)) ///
     | (year == 2007 & inrange(dekate_variable,35,36)) ///
     | (year == 2008 & inrange(dekate_variable, 1, 1)) ///
     | (year == 2013 & inrange(dekate_variable, 6, 8)) ///
     | (year == 2017 & inrange(dekate_variable,21,23)) ///
     | (year == 2017 & inrange(dekate_variable,29,31))
replace election_dekate_new = 0 if missing(election_dekate_new)

gen warning_all = (warning1 > 0 | warning2 > 0 | warning3 > 0 | warning4 > 0)
replace warning_all = 0 if missing(warning_all)

gen warning_2_4 = (warning2 > 0 | warning3 > 0 | warning4 > 0)
replace warning_2_4 = 0 if missing(warning_2_4)

* Area-normalised outcome (needs adm3_area.dta) -----------------------------
* Original code used merge m:m on grid_cell_id; kept identical join logic.
merge m:m grid_cell_id using "${data}/adm3_area.dta"
drop if _merge == 2
drop _merge
gen priots_20km_sqkm = priots_20km / area * 1000000

sort id year

label data "Cached analysis sample (80% agri) with all derived variables"
compress
save "${cache}/_cache_analysis_80percent.dta", replace

display as result ///
    "{hline 70}" _n ///
    "  Cached analysis dataset written to:" _n ///
    "  ${cache}/_cache_analysis_80percent.dta" _n ///
    "{hline 70}"
