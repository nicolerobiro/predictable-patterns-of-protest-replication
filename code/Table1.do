********************************************************************************
*****************************  Table 1  ****************************************
***  Descriptive Statistics for Agricultural Wards                          ***
***  Single table, two panels:                                             ***
***     Panel A: types of conflict in wards (0km ward-level counts)         ***
***     Panel B: protests & riots in wards with 20km buffers                ***
********************************************************************************
*
* Uses the cached 80%-agri analysis sample. priots_0km and priots_20km are
* already built in 00_prepare_data.do, so they are NOT regenerated here.
* Requires ${cache}, ${results}.
*
* Every statistic is collected into a single matrix (one row per table line),
* then written out with estout in ONE pass so both panels share one body.
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

* priots_0km and priots_20km are already present in the cached file.

********************************************************************************
* Helper: append one summary line (Obs Sum Mean SD Min Max) to matrix T.
*   args: rowname  varname  [ifcond]
********************************************************************************
cap program drop _t1row
program define _t1row, rclass
    args rname vname ifc
    if ("`ifc'" == "") qui summarize `vname', detail
    else               qui summarize `vname' `ifc', detail
    tempname r
    matrix `r' = ( r(N), r(sum), r(mean), r(sd), r(min), r(max) )
    matrix rownames `r' = `rname'
    return matrix row = `r'
end

********************************************************************************
* Build the full table body, one row at a time, in the published order
********************************************************************************
* --- Panel A: types of conflict in wards (0km) ---
_t1row A_all      conflict_0km
matrix T = r(row)
_t1row A_prot     priots_0km
matrix T = T \ r(row)
_t1row A_vac      violence_civil_0km
matrix T = T \ r(row)
_t1row A_batt     battle_0km
matrix T = T \ r(row)
_t1row A_strat    stra_dev_0km
matrix T = T \ r(row)
_t1row A_expl     explosion_0km
matrix T = T \ r(row)

* --- Panel B: protests & riots in wards with 20km buffers ---
_t1row B_all      priots_20km
matrix T = T \ r(row)
_t1row B_h1       priots_20km "if harvest==1"
matrix T = T \ r(row)
_t1row B_h0       priots_20km "if harvest==0"
matrix T = T \ r(row)

matrix colnames T = Obs Sum Mean SD Min Max

********************************************************************************
* Export in ONE pass with estout's matrix mode.
*
* Per-column numeric formatting for a MATRIX goes inside matrix(T, fmt(...)),
* one Stata display format per column (this is the documented syntax; the
* cells("Obs(fmt())...") form is for estimation results only -> r(198)).
*   col order: Obs Sum Mean SD Min Max
*   %15.0gc = integer with thousands commas (the "c" modifier lives on g, not f)
********************************************************************************
estout matrix(T, fmt(%15.0gc %15.0gc %9.4f %9.4f %9.0f %9.0f)) ///
    using "${results}/table1.tex", replace ///
    style(tex) ///
    varlabels(A_all "All types of conflict" ///
              A_prot "Protests" ///
              A_vac "Violence against civilians" ///
              A_batt "Battle" ///
              A_strat "Strategic Development" ///
              A_expl "Explosion" ///
              B_all "Protests (20 km buffer)" ///
              B_h1 "Protests (20 km buffer) if harvest \$=1\$" ///
              B_h0 "Protests (20 km buffer) if harvest \$=0\$") ///
    collabels(none) mlabels(none) ///
    refcat(A_all "\emph{Panel A: Types of conflict in wards}" ///
           B_all "\emph{Panel B: Protests \& riots in wards with 20 km buffers}", nolabel) ///
    prehead("\begin{tabular}{l*{6}{r}}" "\toprule" ///
            " & Obs & Sum & Mean & SD & Min & Max \\" "\midrule") ///
    postfoot("\bottomrule" "\end{tabular}")

********************************************************************************
* On-screen version (same single table, plain formatting)
********************************************************************************
estout matrix(T, fmt(%15.0gc %15.0gc %9.4f %9.4f %9.0f %9.0f)), ///
    varlabels(A_all "All types of conflict" ///
              A_prot "Protests" ///
              A_vac "Violence against civilians" ///
              A_batt "Battle" ///
              A_strat "Strategic Development" ///
              A_expl "Explosion" ///
              B_all "Protests (20 km buffer)" ///
              B_h1 "Protests (20 km buffer) if harvest=1" ///
              B_h0 "Protests (20 km buffer) if harvest=0") ///
    collabels("Obs" "Sum" "Mean" "SD" "Min" "Max") mlabels(none) ///
    refcat(A_all "Panel A: Types of conflict in wards" ///
           B_all "Panel B: Protests & riots in wards with 20 km buffers", nolabel)
