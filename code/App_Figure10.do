********************************************************************************
*Figure 10 Appendix
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

* Load only if not already in memory (App_Figure9 may have just loaded it)
do "${code}/_load.do" "${data}/data_figure2.dta"


**Generate plots for comparison


twoway (scatter dekate_variable year if ward == 2 & harvest >0,  graphregion(color(white)) title("Abogeta East Ward - 99% agri") ylabel(1(5)36) ytitle("dekates") xtitle("") name("graph1_Ward", replace))

twoway (scatter dekate_variable year if ward == 1012 & harvest >0,  graphregion(color(white))  title("Nangina Ward - 90% agri")  ylabel(1(5)36) ytitle("") xtitle("") name("graph2_Ward", replace) )  

twoway (scatter dekate_variable year if ward == 628 & harvest >0,  graphregion(color(white))  title("Kisii Central Ward - 80% agri")  ylabel(1(5)36) ytitle("dekates") xtitle("") name("graph3_Ward", replace))  

twoway (scatter dekate_variable year if ward == 444 & harvest >0,  graphregion(color(white))  title("Kangari Ward - 70% agri") ylabel(1(5)36) ytitle("") xtitle("") name("graph4_Ward", replace) ) 

graph combine graph1_Ward graph2_Ward graph3_Ward graph4_Ward , graphregion(color(white)) 
graph export "${results}/Graph_ward_dekate.png", as(png) name("Graph") replace
