
********************************************************************************
*Figure 2
********************************************************************************
*Descriptive statistics harvest
*
* Uses database_final.dta (NOT the cached 80% analysis sample).
* Requires ${data} and ${results} to be set (master.do does this). If running
* standalone, define them in the block below.
********************************************************************************

if ("${data}" == "") {
    global root    "."
    global data    "${root}/data"
    global results "${root}/Results"
    global cache   "${data}/_cache"
}

use "${data}/database_final.dta", clear
global LOADED "${data}/database_final.dta"

drop if year == 2020

gen year_count_sd = 1
foreach value of numlist 2000/2019{
replace year_count_sd = year_count_sd+1 if year >= `value'
}

replace year_count_sd = year_count_sd-1
gen decate = end_t 
foreach value of numlist 1/21{
	replace decate = end_t-36*`value' if year_count_sd== `value'
}



gen harvest_1 = 1 if harvest ==1 & month >=11 | harvest ==1 & month<=5
gen harvest_2 = 1 if harvest ==1 & month >=5  & month<=11


gen decate_2 = decate
replace decate = 0 if decate == 36
replace decate = -1 if decate == 35
replace decate = -2 if decate == 34
replace decate = -3 if decate == 33
replace decate = -4 if decate == 32
replace decate = -5 if decate == 31

egen harvest_sd_1 = sd(decate) if harvest_1 == 1, by(id)
egen harvest_sd_2 = sd(decate_2)if harvest_2 == 1, by(id)

tab harvest_sd_1 if agri_adm3>=0.8
tab harvest_sd_1 if agri_adm3<=0.5
tab harvest_sd_1 

tab harvest_sd_2 if agri_adm3>=0.8
tab harvest_sd_2 if agri_adm3<=0.5
tab harvest_sd_2 


*all wards season 1
qui hist harvest_sd_1 if harvest_sd_1 <=5, yscale(range(0 1.2)) ylabel(0 0.3 0.6  0.9 1.2)  xtitle("") title("All wards") ytitle("Season 1" "Density", size(medlarge)) name("std1_all", replace) xlabel(0 1 2 3 4 5) graphregion(color(white))
*all wards season 2 
qui hist harvest_sd_2 if harvest_sd_2 <=5, yscale(range(0 1.2)) ylabel(0 0.3 0.6  0.9 1.2) xtitle("")  ytitle("Season 2" "Density", size(medlarge)) name("std2_all", replace) xscale(range(0 5)) xlabel(0 1 2 3 4 5)  graphregion(color(white))
*50% agricul. area season 1
qui hist harvest_sd_1 if agri_adm3>=0.5 & harvest_sd_1 <=5, yscale(range(0 1.2)) ylabel(0 0.3 0.6  0.9 1.2) xtitle("") ytitle("") title(">= 50% Agricultural Area") name("std1_50", replace) xlabel(0 1 2 3 4 5) graphregion(color(white))
*50% agricul. area season 2
qui hist harvest_sd_2 if agri_adm3>=0.5 & harvest_sd_2 <=5, yscale(range(0 1.2)) ylabel(0 0.3 0.6  0.9 1.2)  xtitle("") ytitle("")  name("std2_50", replace) xlabel(0 1 2 3 4 5) graphregion(color(white))
*80% agricul. area season 1
qui hist harvest_sd_1 if agri_adm3>=0.8 & harvest_sd_1 <=5, yscale(range(0 1.2)) ylabel(0 0.3 0.6  0.9 1.2)  xtitle("") ytitle("") title(">= 80% Agricultural Area") name("std1_80", replace) xlabel(0 1 2 3 4 5) graphregion(color(white))
*80% agricul. area season 2
qui hist harvest_sd_2 if agri_adm3>=0.8 & harvest_sd_2 <=5, yscale(range(0 1.2)) ylabel(0 0.3 0.6  0.9 1.2)  xtitle("") ytitle("")  name("std2_80", replace) xlabel(0 1 2 3 4 5) graphregion(color(white))


graph combine std1_all  std1_50  std1_80 std2_all std2_50  std2_80, rows(2) cols(3) name("Graph", replace)  b1title("Standard Deviation of Harvest Season", size(small)) graphregion(color(white)) // title("Deviation in Harvest Periods")
graph export "${results}/std_wards_v2.png", as(png) name("Graph") replace
