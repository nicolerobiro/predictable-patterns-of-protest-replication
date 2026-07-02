********************************************************************************
*****************************  Table 4  ****************************************
***  Model Specification Variation (LPM / Logit / Poisson / per sqkm)        ***
********************************************************************************
*
* Uses the cached 80%-agri analysis sample. priots_20km, priots_20km_dum and
* priots_20km_sqkm (incl. the adm3_area merge) are all built in
* 00_prepare_data.do, so they are NOT regenerated here.
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

**********************************************
*** Table 4 : Model Specification Variation
**********************************************
est clear

* priots_20km, priots_20km_dum, priots_20km_sqkm are already in the cache.

reghdfe priots_20km_dum season_start , absorb(id year#dekate_variable) cluster(name1)
est store main1
estadd local ward_fe =   "\checkmark"
estadd local dekad_year_fe =  "\checkmark"
sum priots_20km_dum if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

/* Similar to conley standard erros these commands take a long time to run. Therefore we recommend to go to Python

clogit priots_20km_dum season_start i.end_t, group(id) vce(cluster  name1)
est store main2
estadd local ward_fe =   "\checkmark"
estadd local dekad_year_fe =  "\checkmark"
sum priots_20km_dum if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)

zip priots_20km season_start i.end_t i.id, inflate(priots_20km) vce(cluster  name1)
est store main3
estadd local ward_fe =   "\checkmark"
estadd local dekad_year_fe =  "\checkmark"
sum priots_20km if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


################################ Python Code ##################################
# pip install pandas numpy statsmodels pyreadstat patsy
import numpy as np
import pandas as pd
import statsmodels.api as sm
from statsmodels.formula.api import ols  # only for design-matrix building
from patsy import dmatrix
 
ANALYSIS = r"U:/Conflict/Data/0_Analysis Final/analysis data"
df = pd.read_stata(f"{ANALYSIS}/database_final_80percent.dta")
 
# ensure the categorical time / id / cluster vars are proper categoricals
for c in ["end_t", "id", "name1"]:
    df[c] = df[c].astype("category")
 
###############################################################################
## main2 : conditional (fixed-effects) logit grouped by id, clustered on name1
###############################################################################
# ConditionalLogit takes the group via `groups=`; build X without an intercept
# (the group effect is conditioned out) and with i.end_t dummies.
m2 = df.dropna(subset=["priots_20km_dum", "season_start", "end_t", "id", "name1"]).copy()
 
y2 = m2["priots_20km_dum"].astype(float).values
X2 = dmatrix("0 + season_start + C(end_t)", m2, return_type="dataframe")
 
clogit = sm.ConditionalLogit(y2, X2, groups=m2["id"].values)
res_clogit = clogit.fit(
    cov_type="cluster",
    cov_kwds={"groups": m2["name1"].values},
    disp=False,
)
print("=== main2: conditional logit (clogit) ===")
print(res_clogit.summary())
 
b2  = res_clogit.params["season_start"]
se2 = res_clogit.bse["season_start"]
mean_dv2 = m2.loc[m2["season_start"] == 0, "priots_20km_dum"].mean()
print(f"\nseason_start: b={b2:.6f}  se={se2:.6f}  mean_dv(season_start==0)={mean_dv2:.3f}")
 
###############################################################################
## main3 : zero-inflated Poisson, count part = season_start + i.end_t + i.id
##         inflation part = priots_20km (mirrors Stata inflate(priots_20km))
###############################################################################
m3 = df.dropna(subset=["priots_20km", "season_start", "end_t", "id", "name1"]).copy()
 
y3 = m3["priots_20km"].astype(float).values
 
# count (main) design: season_start + i.end_t + i.id, with intercept
X3 = dmatrix("season_start + C(end_t) + C(id)", m3, return_type="dataframe")
 
# inflation design: the outcome itself, as in Stata inflate(priots_20km)
Z3 = dmatrix("priots_20km", m3, return_type="dataframe")  # intercept + priots_20km
 
zip_mod = sm.ZeroInflatedPoisson(
    endog=y3,
    exog=X3,
    exog_infl=Z3,
    inflation="logit",
)
res_zip = zip_mod.fit(
    cov_type="cluster",
    cov_kwds={"groups": m3["name1"].values},
    maxiter=200,
    disp=False,
)
 
# pull the season_start coefficient from the count part
b3  = res_zip.params["season_start"]
se3 = res_zip.bse["season_start"]
mean_dv3 = m3.loc[m3["season_start"] == 0, "priots_20km"].mean()
print("\n=== main3: zero-inflated Poisson (zip) ===")
print(f"season_start: b={b3:.6f}  se={se3:.6f}  mean_dv(season_start==0)={mean_dv3:.3f}")
 

*/ 

reghdfe priots_20km_sqkm  season_start, absorb(id year#dekate_variable) cluster(name1)
est store main4
estadd local ward_fe =   "\checkmark"
estadd local dekad_year_fe =  "\checkmark"
sum priots_20km_sqkm if season_start==0 & e(sample)
estadd scalar mean_dv = r(mean)


esttab main* using "table4.tex", replace ///
   cells(b(fmt(6) star) se(fmt(6) par)) onecell keep(season_start) ///
    coeflabel(season_start "Start of Season") ///
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    mtitles("LPM" "Logit" "Poisson" "Per sqkm") ///
    stats(N mean_dv ward_fe dekad_year_fe, fmt(%9.0fc 3 0 0) ///
        labels("Observations" "Mean DV" ///
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast  collabels(none)

* On-screen version
esttab main*  , ///
   cells(b(fmt(6) star) se(fmt(6) par)) onecell keep(season_start) ///
    coeflabel(season_start "Start of Season") ///
    label nonotes star(* 0.1 ** 0.05 *** 0.01) compress ///
    mtitles("LPM" "Logit" "Poisson" "Per sqkm") ///
    stats(N mean_dv ward_fe dekad_year_fe, fmt(%9.0fc 3 0 0) ///
        labels("Observations" "Mean DV" ///
               "Ward FE" "Dekate $\times$ Year FE")) legend obslast  collabels(none)
