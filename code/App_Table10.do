********************************************************************************
*Table 10: Start of Season across Buffer Sizes (static specification)
********************************************************************************
*
* Uses the cached 80%-agri analysis sample. priots_0/5/10/15/20km already built.
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

* priots_0km, priots_5km, priots_10km, priots_15km, priots_20km already in cache.

reghdfe priots_0km season_start, absorb(id year#dekate_variable) cluster(name1)
eststo model1
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_0km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


reghdfe priots_5km season_start, absorb(id year#dekate_variable) cluster(name1)
eststo model2
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_5km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


reghdfe priots_10km season_start, absorb(id year#dekate_variable) cluster(name1)
eststo model3
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_10km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


reghdfe priots_15km season_start, absorb(id year#dekate_variable) cluster(name1)
eststo model4
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_15km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km season_start, absorb(id year#dekate_variable) cluster(name1)
eststo model5
estadd local ward_fe =   "\checkmark"
estadd local dekate_fexyear_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


#delimit ;
esttab model1 model2 model3 model4 model5 using "app_table10.tex", replace
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start)
    coeflabel(season_start "Start of Season")
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress
    mgroups("Sum of Protest", pattern(1 0 0 0 0) span)
    mtitles("0km" "5km" "10km" "15km" "20km")
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0)
        labels("Observations" "Mean DV"
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast collabels(none) ;
#delimit cr

* On-screen version
esttab model1 model2 model3 model4 model5,  ///
   cells(b(fmt(3) star) se(fmt(3) par)) onecell keep(season_start) ///
    coeflabel(season_start "Start of Season") ///
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    mgroups("Sum of Protest", pattern(1 0 0 0 0 ) span) ///
    mtitles("0km" "5km" "10km" "15km" "20km") ///
    stats(N mean_dv ward_fe dekate_fexyear_fe, fmt(%9.0fc 3 0 0) ///
        labels("Observations" "Mean DV" ///
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast  collabels(none)
