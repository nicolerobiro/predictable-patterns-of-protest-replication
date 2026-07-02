********************************************************************************
*****************************  Table 2  ****************************************
***  Identifying Main Specification of Harvest on Protest                    ***
***  Coefficient with three stacked, starred SEs:                           ***
***     ( )  ward-clustered      [ ]  county-clustered      { }  Conley HAC  ***
********************************************************************************
*
* Uses the cached 80%-agri analysis sample. priots_20km, id_dek and year_dek
* are already built in 00_prepare_data.do, so they are NOT regenerated here.
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

* priots_20km, id_dek, year_dek are already present in the cached file.

********************************************************************************
* Helper: build a wrapped, starred SE string.
*   args: b se df open close [normal]
*   - df       : degrees of freedom for t-thresholds (use G-1 for clustered)
*   - open/close : "[" "]" or "{" "}"
*   - normal   : pass 1 to use normal critical values (acreg / asymptotic)
********************************************************************************
cap program drop mkse
program define mkse, rclass
    args b se df open close normal
    local t = abs(`b'/`se')
    local star ""
    if ("`normal'" == "1") {
        if (`t' > invnormal(0.995)) local star "***"
        else if (`t' > invnormal(0.95)) local star "**"
        else if (`t' > invnormal(0.90))  local star "*"
    }
    else {
        if (`t' > invttail(`df',0.005)) local star "***"
        else if (`t' > invttail(`df',0.05)) local star "**"
        else if (`t' > invttail(`df',0.10))  local star "*"
    }
    local s : di %5.3f `se'
    return local out "`open'`s'`close'`star'"
end

********************************************************************************
* (1) WARD-clustered models  ->  coefficient + parentheses SE + checkmarks
********************************************************************************
reghdfe priots_20km harvest, absorb(id year) cluster(id)
eststo m1_id
estadd local ward_fe "\checkmark"
estadd local year_fe "\checkmark"
sum priots_20km if harvest==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km harvest, absorb(id year dekate_variable) cluster(id)
eststo m2_id
estadd local ward_fe "\checkmark"
estadd local year_fe "\checkmark"
estadd local dekate_fe "\checkmark"
sum priots_20km if harvest==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km harvest, absorb(id#dekate_variable year) cluster(id)
eststo m3_id
estadd local ward_fe "\checkmark"
estadd local dekate_fexward_fe "\checkmark"
sum priots_20km if harvest==0 & e(sample)
estadd scalar mean_dv = r(mean)

reghdfe priots_20km harvest, absorb(id year#dekate_variable) cluster(id)
eststo m4_id
estadd local ward_fe "\checkmark"
estadd local dekate_fexyear_fe "\checkmark"
sum priots_20km if harvest==0 & e(sample)
estadd scalar mean_dv = r(mean)

********************************************************************************
* (2) COUNTY-clustered models  ->  brackets SE
********************************************************************************
reghdfe priots_20km harvest, absorb(id year) cluster(name1)
eststo m1_cty
reghdfe priots_20km harvest, absorb(id year dekate_variable) cluster(name1)
eststo m2_cty
reghdfe priots_20km harvest, absorb(id#dekate_variable year) cluster(name1)
eststo m3_cty
reghdfe priots_20km harvest, absorb(id year#dekate_variable) cluster(name1)
eststo m4_cty

********************************************************************************
* (3) CONLEY spatial-HAC models  ->  curly-brace SE
*     dist(40) = 40km spatial radius ; lag(1) = 1-year serial correlation
********************************************************************************

/* 

We recommend using R or Python to run the conley standard errors, given that in stata it takes several hours to days until the regressions are done. For completeness you can find the stata code below folllowed by a Python version

drop if lat_adm == .  // deleting two rows which are missing in all variables and therefore were not accounted for in previous regressions but acreg has a problem with them

acreg priots_20km harvest, id(id) time(end_t) spatial ///
    latitude(lat_adm) longitude(lon_adm) dist(40) lag(1) hac ///
    pfe1(id) pfe2(year)
eststo m1_con

acreg priots_20km harvest, id(id) time(end_t) spatial ///
    latitude(lat_adm) longitude(lon_adm) dist(40) lag(1) hac ///
    pfe1(id) pfe2(year) partial(dekate_variable)
eststo m2_con

acreg priots_20km harvest, id(id) time(end_t) spatial ///
    latitude(lat_adm) longitude(lon_adm) dist(40) lag(1) hac ///
    pfe1(id_dek) pfe2(year)
eststo m3_con

acreg priots_20km harvest, id(id) time(end_t) spatial ///
    latitude(lat_adm) longitude(lon_adm) dist(40) lag(1) hac ///
    pfe1(id) pfe2(year_dek)
eststo m4_con


Python Version

##
## Reproduces:
##   acreg priots_20km harvest, id(id) time(end_t) spatial \
##       latitude(lat_adm) longitude(lon_adm) dist(40) lag(1) hac \
##       pfe1(...) pfe2(...)
##
##   dist(40) -> 40 km spatial Bartlett cutoff
##   lag(1)   -> 1-period temporal Bartlett cutoff
##   hac      -> spatial + serial combined (Conley-HAC)
##
## Strategy: absorb the fixed effects with pyfixest (fast HDFE), then build the
## Conley-HAC meat matrix from the residualised score. The pairwise spatial
## structure is computed ONCE with a BallTree (haversine), so it does not
## recompute the kernel four times the way looping acreg does.
###############################################################################
 
# pip install pandas numpy scipy scikit-learn pyfixest pyreadstat
import numpy as np
import pandas as pd
import pyfixest as pf
from sklearn.neighbors import BallTree
 
ANALYSIS = r"U:/Conflict/Data/0_Analysis Final/analysis data"
df = pd.read_stata(f"{ANALYSIS}/database_final_80percent.dta")
 
df["priots_20km"] = df["protests_20km"] + df["riots_20km"]
df["id_dek"]   = df.groupby(["id", "dekate_variable"]).ngroup()
df["year_dek"] = df.groupby(["year", "dekate_variable"]).ngroup()
 
EARTH_KM   = 6371.0
DIST_CUT   = 40.0     # km   (acreg dist(40))
LAG_CUT    = 1        # time periods (acreg lag(1))
 
def conley_hac_se(data, fe_terms):
    """Point estimate via pyfixest; Conley spatial+serial HAC SE for 'harvest'."""
    fml = "priots_20km ~ harvest | " + " + ".join(fe_terms)
    fit = pf.feols(fml, data=data)
    b   = fit.coef()["harvest"]
 
    # residual and the single-regressor score after FE partialling.
    # demean harvest within the same FE so the score is the partialled-out X.
    d = data.copy()
    d["_resid"] = fit.resid()
    Xr = pf.feols("harvest ~ 1 | " + " + ".join(fe_terms), data=d).resid()
    d["_score"] = Xr * d["_resid"].values
    bread = 1.0 / np.sum(Xr.values**2)        # (X'X)^-1 for single regressor
 
    lat = np.radians(d["lat_adm"].values)
    lon = np.radians(d["lon_adm"].values)
    coords = np.column_stack([lat, lon])
    tree = BallTree(coords, metric="haversine")
    radius = DIST_CUT / EARTH_KM              # haversine radius in radians
 
    score = d["_score"].values
    tvar  = d["end_t"].values
    unit  = d["id"].values
 
    meat = 0.0
    # spatial Bartlett: neighbours within 40 km, weight 1 - d/cutoff
    ind, dist = tree.query_radius(coords, r=radius, return_distance=True)
    for i in range(len(score)):
        dk = dist[i] * EARTH_KM
        w  = 1.0 - dk / DIST_CUT
        meat += score[i] * np.sum(w * score[ind[i]])
 
    # serial Bartlett within unit: |Δt| <= LAG_CUT, weight 1 - |Δt|/(lag+1)
    order = np.lexsort((tvar, unit))
    su, st, ss = unit[order], tvar[order], score[order]
    for lag in range(1, LAG_CUT + 1):
        wt = 1.0 - lag / (LAG_CUT + 1)
        same = (su[lag:] == su[:-lag]) & (np.abs(st[lag:] - st[:-lag]) == lag)
        meat += 2.0 * wt * np.sum(ss[lag:][same] * ss[:-lag][same])
 
    var = bread * meat * bread
    se  = np.sqrt(var)
    t   = b / se
    p   = 2 * (1 - _ndtr(abs(t)))
    return b, se, t, p
 
def _ndtr(x):
    from scipy.stats import norm
    return norm.cdf(x)
 
specs = {
    "(1) id, year":          ["id", "year"],
    "(2) id, year, dekade":  ["id", "year", "dekate_variable"],
    "(3) id#dekade, year":   ["id_dek", "year"],
    "(4) id, year#dekade":   ["id", "year_dek"],
}
 
rows = []
for label, fe in specs.items():
    b, se, t, p = conley_hac_se(df, fe)
    rows.append({"spec": label, "b": b, "conley_se": se, "t": t, "p": p})
 
print(pd.DataFrame(rows).to_string(index=False))


*/

********************************************************************************
* Build starred, wrapped SE strings and attach to the ward-clustered models
********************************************************************************
foreach n in 1 2 3 4 {
    * --- county-clustered: t-thresholds with G-1 df, brackets ---
    est restore m`n'_cty
    local Gc = e(N_clust)
    mkse (_b[harvest]) (_se[harvest]) (`=`Gc'-1') "[" "]"
    local cty`n' "`r(out)'"

/*     * --- Conley: normal critical values (asymptotic), braces ---
    est restore m`n'_con
    mkse (_b[harvest]) (_se[harvest]) (1e6) "{" "}" 1
    local con`n' "`r(out)'"
*/
    * --- attach to ward-clustered model for display ---
    est restore m`n'_id
    estadd local cty_se "`cty`n''"
   * estadd local con_se "`con`n''"
    eststo m`n'_id
}

* Column 1: show only the ward-clustered ( ) SE -> blank the [ ] and { } rows
est restore m1_id
eststo m1_id

********************************************************************************
* Export: stacked SEs, no labels on SE rows, no divider line
********************************************************************************
esttab m1_id m2_id m3_id m4_id  using "table2.tex", replace ///
    onecell cells(b(fmt(3) star) se(fmt(3) par)) keep(harvest) ///
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    prefoot("") ///
    stats(cty_se con_se N mean_dv ward_fe year_fe dekate_fe dekate_fexward_fe dekate_fexyear_fe, ///
        fmt(0 0 %9.0fc 2 0 0 0 0 0) ///
        labels(" " "  " "Observations" "Mean non-harvest" ///
               "Ward FE" "Year FE" "Dekade FE" "Dekade $\times$ Ward FE" "Dekade $\times$ Year FE"))

* On-screen version (same layout)
esttab m1_id m2_id m3_id m4_id, ///
    onecell cells(b(fmt(3) ) se(fmt(3) par star)) keep(harvest) ///
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    prefoot("") ///
    stats(cty_se con_se N mean_dv ward_fe year_fe dekate_fe dekate_fexward_fe dekate_fexyear_fe, ///
        fmt(0 0 %9.0fc 2 0 0 0 0 0) ///
        labels(" " "  " "Observations" "Mean non-harvest" ///
               "Ward FE" "Year FE" "Dekade FE" "Dekade $\times$ Ward FE" "Dekade $\times$ Year FE"))
