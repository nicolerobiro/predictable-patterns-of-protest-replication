
********************************************************************************
***** Descriptive Statistics: Distribution of COnflict and Harvest over a Year
********************************************************************************

*this figure is now adjusted for protests and riots
*
* Uses dataset_20240202_copernicus_clean.dta. Requires ${data} and ${results}.
********************************************************************************

if ("${data}" == "") {
    global root    "."
    global data    "${root}/data"
    global results "${root}/Results"
    global cache   "${data}/_cache"
}

use "${data}/dataset_20240202_copernicus_clean.dta", clear
global LOADED "${data}/dataset_20240202_copernicus_clean.dta"

drop year_count
gen year_count = 1 
foreach value of numlist 2000/2019{
replace year_count = year_count+1 if year >= `value'
}
replace year_count = year_count-1

gen decate = end_t
foreach value of numlist 1/21{
	replace decate = end_t-36*`value' if year_count== `value'
}

drop if year == 2020

gen sum_prot_riot_20km = agg_protests_20km + agg_riots_20km
gen conflict_pro_rio = protests_0km + riots_0km


bysort decate : egen conflict_decate= sum(sum_prot_riot_20km)
gen all_conflict = sum(sum_prot_riot_20km)
sum all_conflict
replace all_conflict = 89354 //replace it with the max value of conflicts
gen conflict_prob = conflict_decate /all_conflict

keep if agri_adm3>=0.8
bysort decate : egen harvest_decate = sum(harvest)
gen all_harvest= sum(harvest)
sum all_harvest
replace all_harvest = 24154
gen harvest_prob = harvest_decate /all_harvest

bysort decate : egen conflict_decate_agri = sum(conflict_pro_rio)
gen all_conflict_agri = sum(conflict)
tab all_conflict_agri
replace all_conflict_agri = 1092
gen conflict_prob_agri = conflict_decate_agri /all_conflict_agri

duplicates drop decate , force

		
twoway  (bar harvest_prob decate,fcolor(sand%99) legend(label(1 "prob(harvest)"))) ///
		(bar conflict_prob_agri decate, fcolor(maroon%70) legend(label(2 "prob(protest)"))),  ///
	title("Distribution over Dekades" "(Agricultural Wards)") ///
    xtitle("Month") ytitle("Probability") ///
    yline(0, lcolor(gray) lpattern(dash)) ///
	xlabels(2 "January" 5 "February" 8 "March" 11 "April" ///
            14 "May" 17 "June" 20 "July" 23 "August" ///
            26 "September" 29 "October" 32 "November" 35 "December") ///
			xlab(, angle(45)) graphregion(color(white))
			
graph export "${results}/Distribution dekates Agricultural.png", as(png) name("Graph") replace	

			
twoway  (bar harvest_prob decate,fcolor(sand%99) legend(label(2 "prob(harvest)")) )  ///
		(bar conflict_prob decate, fcolor(maroon%70)  legend(label(1 "prob(protest)")))		, ///
	title("Distribution over Dekades" "(Agricultural Wards - 20km Buffer)") ///
    xtitle("Month") ytitle("Probability") ///
    yline(0, lcolor(gray) lpattern(dash)) ///
	xlabels(2 "January" 5 "February" 8 "March" 11 "April" ///
            14 "May" 17 "June" 20 "July" 23 "August" ///
            26 "September" 29 "October" 32 "November" 35 "December") ///
			xlab(, angle(45)) graphregion(color(white))


graph export "${results}/Distribution dekates 20km.png", as(png) name("Graph") replace	
