**********************************************
*** Table 12 : Robustness (static specification)
**********************************************
*
* NOTE: the original source had no `use` statement and generated
* election_dekate_new / warning_all / warning_2_4 inline. Those variables are
* now built once in 00_prepare_data.do and live in the cached sample, so they
* are NOT regenerated here. Requires ${cache}, ${results}.
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

* election_dekate_new, warning_all, warning_2_4 already present in cache.
* (data is already sorted by id year in 00_prepare_data.do)

est clear

**************************

*excluding nairobi
eststo model2: reghdfe priots_20km season_start if  nairobi_area == 0 , absorb(id year#dekate_variable) cluster(name1)
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

*exclude election years
eststo model3: reghdfe priots_20km season_start if  election_dekate_new == 0 , absorb(id year#dekate_variable) cluster(name1)
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

*anomalies
eststo model4: reghdfe priots_20km season_start warning_2_4, absorb(id year#dekate_variable) cluster(name1)
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


*quality 
eststo model5: reghdfe priots_20km season_start maxNDVI end_linteg_filled ampl_filled length_filled, absorb(id year#dekate_variable) cluster(name1)
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


#delimit ;
esttab model2 model3 model4 model5 using "app_table12.tex", replace
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start)
    coeflabel(season_start "Start of Season")
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress
    mgroups("Protests", pattern(1 0 0 0) span)
    mtitles("Nairobi" "Election" "Anomalies" "Quality")
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0)
        labels("Observations" "Mean DV"
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast collabels(none) ;
#delimit cr

* On-screen version
esttab  model2 model3 model4 model5,  ///
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start) ///
    coeflabel(season_start "Start of Season") ///
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    mgroups("Protests", pattern(1 0 0 0) span) ///
    mtitles("Nairobi" "Election" "Anomalies" "Quality") ///
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0) ///
        labels("Observations" "Mean DV" ///
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast  collabels(none)
