********************************************************************************
*Figure 9 Appendix
********************************************************************************
*
* Uses data_figure2.dta. Requires ${data} and ${results}.
********************************************************************************

if ("${data}" == "") {
    global root    "."
    global code    "${root}/code"
    global data    "${root}/data"
    global results "${root}/Results"
    global cache   "${data}/_cache"
}

use "${data}/data_figure2.dta", clear
global LOADED "${data}/data_figure2.dta"


**Generate plots for comparison

twoway (scatter dekate_variable year if county == 16 & harvest >0, graphregion(color(white)) title("Kisii County")   ylabel(1(5)36) ytitle("dekates") xtitle("") name("graph1_county", replace)) 

twoway (scatter dekate_variable year if county == 8 & harvest >0, graphregion(color(white)) title("Homa Bay County") ylabel(1(5)36) ytitle("") xtitle("") name("graph2_county", replace) )  
*graph export "${results}/HomaBay_county.png", as(png) name("Graph") replace
twoway (scatter dekate_variable year if county == 17 & harvest >0, graphregion(color(white)) title("Kisumu County")     ylabel(1(5)36) ytitle("dekates") xtitle("year") name("graph3_county", replace)) 
*graph export "${results}/Kisumu_county.png", as(png) name("Graph") replace
twoway (scatter dekate_variable year if county == 27 & harvest >0, graphregion(color(white))  title("Migori County")  ylabel(1(5)36) ytitle("") xtitle("year")  name("graph4_county", replace))

graph combine graph1_county graph2_county graph3_county graph4_county,  graphregion(color(white))
graph export "${results}/Graph_dekate.png", as(png) name("Graph") replace
