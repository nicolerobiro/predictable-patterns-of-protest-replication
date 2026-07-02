********************************************************************************
* _dcdh_table.do  --  reusable helpers for did_multiplegt_dyn result tables
*------------------------------------------------------------------------------
* Defines two programs:
*
*   dcdh_run   : runs one did_multiplegt_dyn specification, runs sotable to get
*                the Sup-t p-value, and stores every cell needed for the table
*                in r() :
*                   r(b)            average total effect (delta-hat)
*                   r(se)           its standard error
*                   r(stars)        significance stars for the coefficient
*                   r(p_placebo)    placebo joint p-value
*                   r(p_supt)       placebo Sup t-test p-value
*                   r(p_effects)    effects joint p-value
*                   r(switchers)    number of switchers
*                   r(nobs)         number of (switcher x period) observations
*
*   dcdh_post  : takes the cells from dcdh_run and posts them into a one-column
*                "fake" estimation set (via estadd/eststo) so several columns can
*                be combined with esttab into a LaTeX table that mirrors the
*                published layout (coef + SE on top, then the three p-values,
*                then FE indicator rows, then switchers / observations).
*
* These read the e()/r() returns left by did_multiplegt_dyn and sotable. Scalar
* names changed across package versions, so every harvested value is wrapped in
* capture with sensible fallbacks; if a value is genuinely unavailable the cell
* is left blank rather than aborting the table.
********************************************************************************

*------------------------------------------------------------------------------
* dcdh_run : run one spec and harvest the cells
*   Syntax mirrors did_multiplegt_dyn:  Y G T D [if] [, <options passed through>]
*   The caller passes the SAME options used elsewhere (effects(), placebo(),
*   cluster(), normalized, same_switchers, same_switchers_pl, controls(), ...).
*------------------------------------------------------------------------------
cap program drop dcdh_run
program define dcdh_run, rclass
    syntax varlist(min=4 max=4) [if] [in] , [*]

    * --- run the estimator -------------------------------------------------
    * Recent did_multiplegt_dyn builds print a malformed funding-acknowledgment
    * line that leaves a stray closing brace in the command stream, throwing
    * r(199) AFTER
    * the results (and mat_res_XX / e()) are already computed. We run the
    * estimator under capture noisily so the output still displays but that
    * trailing error does not abort the do-file; harvesting below still works
    * because the results matrix is already populated when the error fires.
    capture noisily did_multiplegt_dyn `varlist' `if' `in' , `options'
    local _dcdh_rc = _rc
    if (`_dcdh_rc' != 0 & `_dcdh_rc' != 199) {
        di as error "did_multiplegt_dyn failed with rc=`_dcdh_rc' (not the benign r(199) funding-line bug)."
    }

    * Snapshot what sotable and the matrix-row index need, straight after the
    * command, before any later e() read can change what these resolve to.
    *
    * e(placebo) and e(effects) hold NAME LISTS on this version, e.g.
    *   e(placebo) = "Placebo_1 Placebo_2 ... Placebo_5"
    *   e(effects) = "Effect_1 Effect_2 ... Effect_10"
    * sotable's pnames() wants the placebo NAMES, so we keep that string as-is.
    * For the mat_res_XX row index we need the effect COUNT (an integer), which
    * we get from the number of words in the e(effects) name list.
    local _plnames "`e(placebo)'"
    local _neff : word count `e(effects)'

    * --- average total effect (delta-hat) and its SE ------------------------
    * Primary source: e(b)/e(V) carry the average-total-effect as the first
    * (and, for the normalized total effect, the relevant) coefficient. We also
    * try the named scalars the command exposes.
    tempname b se
    scalar `b'  = .
    scalar `se' = .
    capture scalar `b'  = e(Av_tot_effect)
    capture scalar `se' = e(se_avg_total_effect)
    if (`b' == . ) capture scalar `b'  = e(effect_average)
    if (`se' == .) capture scalar `se' = e(se_effect_average)
    * last-resort fallback: first element of e(b)/sqrt of e(V)[1,1]
    if (`b' == .) {
        capture matrix _bb = e(b)
        capture scalar `b' = _bb[1,1]
    }
    if (`se' == .) {
        capture matrix _VV = e(V)
        capture scalar `se' = sqrt(_VV[1,1])
    }

    * --- significance stars on the coefficient (normal critical values) -----
    local stars ""
    capture {
        local t = abs(`b'/`se')
        if (`t' > invnormal(0.995)) local stars "***"
        else if (`t' > invnormal(0.975)) local stars "**"
        else if (`t' > invnormal(0.95))  local stars "*"
    }

    * --- placebo joint p-value and effects joint p-value --------------------
    tempname pplac peff
    scalar `pplac' = .
    scalar `peff'  = .
    capture scalar `pplac' = e(p_jointplacebo)
    capture scalar `peff'  = e(p_jointeffects)

    * --- number of switchers and observations (aggregate / average total) ---
    * The command leaves its results table in matrix mat_res_XX, columns
    * 1..6 = Estimate, SE, LB, UB, N, [col 6]. IMPORTANT: on the per-effect and
    * placebo rows, column 6 is the DISTINCT switcher count (e.g. 605). On the
    * AVERAGE-TOTAL-EFFECT row (row `effects'+1) column 6 is instead
    * "Switch x Periods" (e.g. 6050 = 605 x 10), while its column 5 is the
    * aggregate N (e.g. 10339).
    * So we take:
    *     observations = aggregate row, column 5   (mat_res_XX[`effects'+1, 5])
    *     switchers    = an EFFECT row,  column 6   (mat_res_XX[1, 6])
    tempname nsw nob
    scalar `nsw' = .
    scalar `nob' = .

    * number of dynamic effects actually estimated (from the snapshot above)
    local neff = `_neff'

    capture {
        local atrow = `neff' + 1
        scalar `nob' = mat_res_XX[`atrow', 5]   // aggregate N
        scalar `nsw' = mat_res_XX[1, 6]         // distinct switchers (effect row)
    }

    * fallbacks if the matrix is unavailable in this version
    if (`nsw' == .) capture scalar `nsw' = e(N_switchers_effect_average)
    if (`nsw' == .) capture scalar `nsw' = e(N_switchers)
    if (`nob' == .) capture scalar `nob' = e(N_effect_average)
    if (`nob' == .) capture scalar `nob' = e(N)

    * Diagnostic: list e() scalars and the results matrix so the exact source
    * can be confirmed.  Enable with:  global DCDH_DIAG 1
    if ("${DCDH_DIAG}" == "1") {
        di as text "{hline 60}"
        di as text "DCDH_DIAG for `1':  effects=`neff'  (avg-total row = `=`neff'+1')"
        capture matrix list mat_res_XX
        di as text "harvested -> switchers = " `nsw' "   N = " `nob'
        di as text "{hline 60}"
    }

    * --- Sup t-test (max-t) p-value on the placebos -------------------------
    * Pass the placebo NAMES captured right after estimation. sotable can fail
    * on some subsample/outcome specs (e.g. parts of Table 8 / App. Table 9)
    * with "VCE is not full rank" -> r(498), because the placebo
    * variance-covariance matrix is (near-)singular there. That is a property of
    * the data in that spec, not a bug: when it happens the Sup-t cannot be
    * computed over all placebos, so we trap the error and leave that one cell
    * blank rather than aborting the whole table.
    tempname psupt
    scalar `psupt' = .
    if ("`_plnames'" != "") {
        capture noisily sotable, pnames(`_plnames') normal
        if (_rc == 0) {
            capture scalar `psupt' = r(p)
            if (`psupt' == .) capture scalar `psupt' = r(pvalue)
            if (`psupt' == .) capture scalar `psupt' = r(p_value)
        }
        else {
            di as text "[dcdh_run] sotable could not compute Sup-t for this spec (rc=" _rc "); leaving the cell blank."
        }
    }

    * --- return everything --------------------------------------------------
    return scalar b         = `b'
    return scalar se        = `se'
    return local  stars     "`stars'"
    return scalar p_placebo = `pplac'
    return scalar p_supt    = `psupt'
    return scalar p_effects = `peff'
    return scalar switchers = `nsw'
    return scalar nobs      = `nob'
end


*------------------------------------------------------------------------------
* dcdh_post : turn the harvested cells into a stored "estimate" column
*   args: stored_name  "FE-row tokens"  [from r() left by dcdh_run]
*   The FE tokens are a space-free list of which indicator rows to tick, chosen
*   from: ward year dekyear  (ward FE, year FE, year x dekad FE). Add more as
*   needed; unticked rows are simply left blank.
*
*   We build a trivial 1-obs "regression" so esttab has a coefficient to print
*   (the delta-hat) with the harvested SE, then attach the p-values, FE ticks,
*   switchers and obs as added scalars/locals.
*------------------------------------------------------------------------------
cap program drop dcdh_post
program define dcdh_post
    args name feticks

    * Pull the harvested cells out of r() BEFORE any command overwrites r().
    local  b         = r(b)
    local  se        = r(se)
    local  stars     "`r(stars)'"
    local  p_placebo = r(p_placebo)
    local  p_supt    = r(p_supt)
    local  p_effects = r(p_effects)
    local  switchers = r(switchers)
    local  nobs      = r(nobs)

    * Post a 1-coefficient estimate set named "delta" so esttab prints b/se.
    tempname B V
    matrix `B' = (`b')
    matrix `V' = (`se'^2)
    matrix colnames `B' = delta
    matrix colnames `V' = delta
    matrix rownames `V' = delta
    ereturn post `B' `V'

    * the three test rows (skip if missing so esttab leaves the cell blank)
    if ("`p_placebo'" != "." & "`p_placebo'" != "") estadd scalar p_placebo = `p_placebo'
    if ("`p_supt'"    != "." & "`p_supt'"    != "") estadd scalar p_supt    = `p_supt'
    if ("`p_effects'" != "." & "`p_effects'" != "") estadd scalar p_effects = `p_effects'

    * FE indicator rows (word-based match on the feticks list)
    foreach tok of local feticks {
        if ("`tok'" == "ward")    estadd local ward_fe    "\checkmark"
        if ("`tok'" == "year")    estadd local year_fe    "\checkmark"
        if ("`tok'" == "dekyear") estadd local dekyear_fe "\checkmark"
    }

    * counts
    if ("`switchers'" != "." & "`switchers'" != "") estadd scalar switchers = `switchers'
    if ("`nobs'"      != "." & "`nobs'"      != "") estadd scalar nobs      = `nobs'

    * Snapshot the fully-decorated estimate set under the requested name.
    eststo `name'
end
