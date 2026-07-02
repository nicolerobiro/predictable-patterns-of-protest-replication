********************************************************************************
*Table 11: Start of Season across Rainfed Shares (static specification)
********************************************************************************
*
* NOTE: the original source had no `use` statement and relied on whatever
* dataset was already in memory. It is made self-sufficient here by loading the
* cached 80%-agri analysis sample (which contains priots_20km and rainfed_mean).
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

est clear 
reghdfe priots_20km season_start if rainfed_mean>=0.4, absorb(id year#dekate_variable) cluster(name1)
est store model1
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km season_start if rainfed_mean>=0.5, absorb(id year#dekate_variable) cluster(name1)
est store model2
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km season_start if rainfed_mean>=0.6, absorb(id year#dekate_variable) cluster(name1)
est store model3
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km season_start if rainfed_mean>=0.7, absorb(id year#dekate_variable) cluster(name1)
est store model4
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km season_start if rainfed_mean>=0.8, absorb(id year#dekate_variable) cluster(name1)
est store model5
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km season_start if rainfed_mean>=0.9, absorb(id year#dekate_variable) cluster(name1)
est store model6
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


#delimit ;
esttab model1 model2 model3 model4 model5 model6 using "app_table11.tex", replace
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start)
    coeflabel(season_start "Start of Season")
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress
    mgroups("Sum of Protest (Buffer size: 20 km)", pattern(1 0 0 0 0 0) span)
    mtitles("40%" "50%" "60%" "70%" "80%" "90%")
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0)
        labels("Observations" "Mean DV"
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast collabels(none) ;
#delimit cr

* On-screen version
esttab model1 model2 model3 model4 model5 model6,  ///
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start) ///
    coeflabel(season_start "Start of Season") ///
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    mgroups("Sum of Protest (Buffer size: 20 km)", pattern(1 0 0 0 0 0) span) ///
    mtitles("40%" "50%" "60%" "70%" "80%" "90%") ///
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0) ///
        labels("Observations" "Mean DV" ///
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast  collabels(none)
