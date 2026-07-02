********************************************************************************
*****************************  Table 3  ****************************************
***  Crop Cycle: harvest / season start / pre-harvest                       ***
********************************************************************************
*
* Uses the cached 80%-agri analysis sample. priots_20km already built.
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

* priots_20km is already present in the cached file.

****************************************
*** Table 3 : Crop Cycle
****************************************

est clear 

*** New Model

reghdfe priots_20km harvest , absorb(id year#dekate_variable) cluster(name1)
eststo model1
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if harvest==0 & e(sample)
estadd scalar mean_dv = r(mean)


reghdfe priots_20km season_start , absorb(id year#dekate_variable) cluster(name1)
eststo model2
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km preharvest , absorb(id year#dekate_variable) cluster(name1)
eststo model3
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if preharvest==0 & e(sample)
estadd scalar mean_dv = r(mean)


reghdfe priots_20km harvest season_start preharvest , absorb(id year#dekate_variable) cluster(name1)
eststo model4
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & harvest == 0 & preharvest == 0  & e(sample)
estadd scalar mean_dv = r(mean)


#delimit ;
esttab model1 model2 model3 model4 using "table3.tex", replace
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start harvest preharvest)
    coeflabel(season_start "Start of Season" harvest "Harvest" preharvest "Pre Harvest")
    nomtitle label nonotes star(* 0.1 ** 0.05 *** 0.01) compress
    mgroups("Sum of Protests (Buffer size: 20 km)", pattern(1 0 0 0) span)
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0)
        labels("Observations" "Mean DV"
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast collabels(none) ;
#delimit cr

* On-screen version
esttab model1 model2 model3 model4,  ///
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start harvest preharvest) ///
    coeflabel(season_start "Start of Season" harvest "Harvest" preharvest "Pre Harvest") ///
    nomtitle label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    mgroups("Sum of Protests (Buffer size: 20 km)", pattern(1 0 0 0) span) ///
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0) ///
        labels("Observations" "Mean DV" ///
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast  collabels(none)
