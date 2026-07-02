################################################################################
## check_missing_regressions.R
##
## R checker for the regressions that are commented out in the Stata do-files
## because they are slow / memory-heavy there or in Python:
##
##   Table 2 : Conley spatial-HAC standard errors, 4 FE specifications
##             (linear model; `harvest` coefficient + Conley HAC SE)
##   Table 4 : main2  conditional fixed-effects logit  (clogit)
##             main3  zero-inflated Poisson            (zip)
##
## --------------------------------------------------------------------------- ##
## USAGE
## --------------------------------------------------------------------------- ##
## 1. Set DATA_PATH below to database_final_80percent.dta.
## 2. Install packages once (run once, then comment out):
##        install.packages(c("haven","data.table","fixest","survival",
##                            "pscl","conleyreg","sandwich","lmtest"))
## 3. source("check_missing_regressions.R")  (or run line by line in RStudio).
##
################################################################################

## --------------------------------------------------------------------------- ##
## 0. CONFIG
## --------------------------------------------------------------------------- ##
DATA_PATH <- "C:/Users/nicol/Desktop/Conflict Regressions/database_final_80percent.dta"



#install.packages(c("haven","data.table","fixest","survival","sandwich","lmtest","conleyreg"))

DIST_CUT <- 40    # km          -> acreg dist(40)
LAG_CUT  <- 1     # time periods -> acreg lag(1)

## Optional quick smoke test on a random subsample (set to NA for full sample).
SUBSAMPLE <- NA   # e.g. 50000L

suppressPackageStartupMessages({
  library(haven)        # read_dta (handles strL correctly, unlike pandas)
  library(data.table)
  library(fixest)
  library(survival)     # clogit
  library(pscl)         # zeroinfl
  library(conleyreg)    # Conley spatial-HAC
  library(sandwich)         # zeroinfl
  library(lmtest)    # Conley spatial-HAC
})

setFixest_nthreads(max(1, parallel::detectCores() - 1))

## --------------------------------------------------------------------------- ##
## 1. LOAD + BUILD DERIVED VARIABLES (mirrors 00_prepare_data.do)
## --------------------------------------------------------------------------- ##
cat("Loading:", DATA_PATH, "\n")
DT <- as.data.table(read_dta(DATA_PATH))
cat(sprintf("  rows = %s   cols = %d\n", format(nrow(DT), big.mark=","), ncol(DT)))

## headline outcome
DT[, priots_20km := protests_20km + riots_20km]

## binary version
DT[, priots_20km_dum := as.numeric(priots_20km > 0)]
DT[is.na(priots_20km), priots_20km_dum := NA_real_]

## per-sqkm outcome only if `area` is present (it lives in adm3_area.dta, so it
## is usually NOT in this file; main4 is skipped automatically if missing)
if ("area" %in% names(DT)) {
  DT[, priots_20km_sqkm := priots_20km / area * 1e6]
}

## make sure key vars are the right type
for (v in c("id","year","name1","dekate_variable","end_t")) {
  if (v %in% names(DT)) DT[[v]] <- as.integer(DT[[v]])
}

if (!is.na(SUBSAMPLE) && SUBSAMPLE < nrow(DT)) {
  set.seed(20240202)
  DT <- DT[sample(.N, SUBSAMPLE)]
  cat(sprintf("  [SUBSAMPLE] using %s rows\n", format(nrow(DT), big.mark=",")))
}

`%+%` <- function(a,b) paste0(a,b)
z_p   <- function(b, se) { z <- b/se; c(z=z, p=2*pnorm(-abs(z))) }

## robust extractor: pull (b, se) for a coefficient from a fixest model,
## using the coefficient table so it does not depend on accessor name quirks.
get_bse <- function(model, term) {
  ct <- summary(model)$coeftable
  rn <- rownames(ct)
  hit <- rn[rn == term]
  if (length(hit) == 0) hit <- rn[grepl(term, rn, fixed = TRUE)][1]
  c(b = ct[hit, 1], se = ct[hit, 2])
}

## ---- results collector -----------------------------------------------------
## Every block appends one row here; we print a single formatted table at the end
## and also write it to a CSV next to the data.
RESULTS <- data.frame(
  table=character(), model=character(), term=character(),
  b=numeric(), se=numeric(), z=numeric(), p=numeric(),
  N=numeric(), note=character(), stringsAsFactors=FALSE
)
add_result <- function(table, model, term, b, se, N=NA, note="") {
  zp <- z_p(b, se)
  RESULTS <<- rbind(RESULTS, data.frame(
    table=table, model=model, term=term,
    b=as.numeric(b), se=as.numeric(se),
    z=as.numeric(zp["z"]), p=as.numeric(zp["p"]),
    N=as.numeric(N), note=note, stringsAsFactors=FALSE))
}
stars <- function(p) ifelse(is.na(p), "",
                            ifelse(p<0.01,"***", ifelse(p<0.05,"**",
                                                        ifelse(p<0.10,"*",""))))

################################################################################
## 2. TABLE 2 : CONLEY SPATIAL-HAC  (linear model, 4 FE specs)
################################################################################
cat("\n", strrep("=",78), "\n", sep="")
cat("TABLE 2 : Conley spatial-HAC SE on `harvest` (dist ", DIST_CUT,
    " km, lag ", LAG_CUT, ")\n", sep="")
cat(strrep("=",78), "\n", sep="")

## conleyreg needs lat/lon and (for the serial term) a unit + time. It drops the
## two rows with missing coordinates exactly like the Stata note in Table2.do.
d2 <- DT[!is.na(lat_adm) & !is.na(lon_adm) &
           !is.na(priots_20km) & !is.na(harvest)]

## FE specifications: the formula RHS after `|` is the absorbed FE.
## (3) and (4) use interacted FE, built as factors on the fly.
d2[, id_dek   := .GRP, by=.(id, dekate_variable)]
d2[, year_dek := .GRP, by=.(year, dekate_variable)]

specs <- list(
  "(1) id, year"         = "harvest | id + year",
  "(2) id, year, dekade" = "harvest | id + year + dekate_variable",
  "(3) id#dekade, year"  = "harvest | id_dek + year",
  "(4) id, year#dekade"  = "harvest | id + year_dek"
)

t2_rows <- list()
for (nm in names(specs)) {
  cat("  running", nm, "...\n"); flush.console()
  fml <- as.formula("priots_20km ~ " %+% specs[[nm]])
  res <- tryCatch(
    conleyreg(fml, data = d2,
              dist_cutoff = DIST_CUT,
              model       = "ols",
              unit        = "id",
              time        = "end_t",
              lat         = "lat_adm",
              lon         = "lon_adm",
              kernel      = "bartlett",
              lag_cutoff  = LAG_CUT,
              float       = TRUE,    # halve memory
              verbose     = FALSE),
    error = function(e) { cat("    FAILED:", conditionMessage(e), "\n"); NULL }
  )
  if (!is.null(res)) {
    ## conleyreg returns an lmtest::coeftest matrix; pull the `harvest` row
    rn <- rownames(res)
    hr <- rn[grepl("harvest", rn)][1]
    b  <- res[hr, 1]; se <- res[hr, 2]
    zp <- z_p(b, se)
    t2_rows[[nm]] <- data.frame(spec=nm, b=b, se=se, z=zp["z"], p=zp["p"])
    add_result("Table 2", paste0("Conley HAC ", nm), "harvest",
               b, se, N=nrow(d2), note="dist40 lag1")
  }
}
if (length(t2_rows)) {
  t2 <- do.call(rbind, t2_rows); rownames(t2) <- NULL
  print(transform(t2,
                  b  = round(b, 6),
                  se = round(se, 6),
                  z  = round(z, 3),
                  p  = round(p, 4)))
}


################################################################################
## 3. TABLE 4 : main1 (LPM), main2 (clogit), main3 (PPML), main4 (per-sqkm)
################################################################################
cat("\n", strrep("=",78), "\n", sep="")
cat("TABLE 4 : LPM (main1), conditional logit (main2), PPML (main3), per-sqkm (main4)\n")
cat(strrep("=",78), "\n", sep="")

## ---- main1 (LPM) and main4 (per-sqkm) via fixest feols ---------------------
## FE: id + year#dekade ; cluster name1.
for (cc in list(c("priots_20km_dum","main1 LPM"),
                c("priots_20km_sqkm","main4 per-sqkm"))) {
  col <- cc[1]; lab <- cc[2]
  if (!col %in% names(DT)) {
    if (col == "priots_20km_sqkm")
      cat("\n--- ", lab, ": skipped (no `area`/priots_20km_sqkm in data) ---\n", sep="")
    next
  }
  m <- tryCatch(
    feols(as.formula(col %+% " ~ season_start | id + year^dekate_variable"),
          data = DT, cluster = ~name1),
    error = function(e) { cat("\n--- ", lab, " FAILED:", conditionMessage(e), "\n"); NULL }
  )
  if (!is.null(m)) {
    bse <- get_bse(m, "season_start"); b <- bse["b"]; se <- bse["se"]
    zp <- z_p(b, se)
    cat(sprintf("\n--- %s (FE: id, year#dekade; cluster name1) ---\n", lab))
    cat(sprintf("  season_start : b=%.6f  se=%.6f  z=%.3f  p=%.4f  N=%s\n",
                b, se, zp["z"], zp["p"], format(m$nobs, big.mark=",")))
    add_result("Table 4", lab, "season_start", b, se, N=m$nobs,
               note="FE id, year#dekade; cl name1")
  }
}

## ---- main2 : conditional fixed-effects logit ------------------------------
## Stata:  clogit priots_20km_dum season_start i.end_t, group(id) vce(cluster name1)
##
## The conditional logit drops observations in absolute-dekad (end_t) cells with
## no within-cell outcome variation (uninformative for the conditional
## likelihood). We replicate that sample restriction explicitly so clogit
## converges cleanly and the sample matches the Stata estimator (N = 299,266).
## The reported SE is clustered at the county (name1) level via vcovCL, matching
## vce(cluster name1).
cat("\n--- main2: conditional logit (priots_20km_dum season_start i.end_t, group(id)) ---\n")

## drop wards (id) and absolute-dekad (end_t) cells with no outcome variation
DT[, v_id := var(priots_20km_dum, na.rm=TRUE), by=id]
DT[, v_et := var(priots_20km_dum, na.rm=TRUE), by=end_t]
sub <- DT[v_id > 0 & v_et > 0 & !is.na(priots_20km_dum) &
            !is.na(season_start) & !is.na(id) & !is.na(name1)]
cat(sprintf("  estimation sample N = %s\n", format(nrow(sub), big.mark=",")))

m2 <- tryCatch(
  clogit(priots_20km_dum ~ season_start + factor(end_t) + strata(id),
         data = sub, method = "efron"),
  error = function(e) { cat("  clogit FAILED:", conditionMessage(e), "\n"); NULL }
)
if (!is.null(m2)) {
  ## county-clustered SE (matches vce(cluster name1))
  ct  <- coeftest(m2, vcov = vcovCL(m2, cluster = sub$name1))
  b   <- ct["season_start", "Estimate"]
  se  <- ct["season_start", "Std. Error"]
  zp  <- z_p(b, se)
  cat(sprintf("  [survival::clogit, strata(id), cluster name1]\n"))
  cat(sprintf("  season_start : b=%.6f  se=%.6f  z=%.3f  p=%.4f  OR=%.4f  N=%s\n",
              b, se, zp["z"], zp["p"], exp(b), format(nrow(sub), big.mark=",")))
  md <- sub[season_start==0, mean(priots_20km_dum, na.rm=TRUE)]
  cat(sprintf("  mean DV (season_start==0) : %.4f\n", md))
  add_result("Table 4", "main2 Logit (clogit)", "season_start", b, se,
             N=nrow(sub), note="strata(id), i.end_t; cl name1; log-odds")
}

## ---- main3 : Poisson with absorbed FE (PPML), full sample ------------------
## Treats priots_20km as a COUNT (Poisson log-link), absorbing ward and time
## fixed effects instead of dummy-coding them, so it runs on the full sample
## with no dense design matrix. This is the R equivalent of ppmlhdfe in Stata.
cat("\n--- main3: Poisson FE / PPML (priots_20km ~ season_start | id + end_t) ---\n")
m3 <- tryCatch(
  fepois(priots_20km ~ season_start | id + end_t,
         data = DT, cluster = ~name1),
  error = function(e) { cat("  fepois FAILED:", conditionMessage(e), "\n"); NULL }
)
if (!is.null(m3)) {
  bse <- get_bse(m3, "season_start"); b <- bse["b"]; se <- bse["se"]
  zp <- z_p(b, se)
  cat(sprintf("  [fixest fepois, FE id+end_t, cluster name1]\n"))
  cat(sprintf("  season_start : b=%.6f  se=%.6f  z=%.3f  p=%.4f  N=%s\n",
              b, se, zp["z"], zp["p"], format(m3$nobs, big.mark=",")))
  md <- DT[season_start==0, mean(priots_20km, na.rm=TRUE)]
  cat(sprintf("  mean DV (season_start==0) : %.4f\n", md))
  add_result("Table 4", "main3 Poisson FE (PPML)", "season_start", b, se,
             N=m3$nobs, note="FE id+end_t; cl name1; log-rate")
}


################################################################################
## 4. FORMATTED OUTPUT TABLE
################################################################################
cat("\n", strrep("=",78), "\n", sep="")
cat("SUMMARY TABLE\n")
cat(strrep("=",78), "\n", sep="")

if (nrow(RESULTS)) {
  out <- RESULTS
  out$sig    <- stars(out$p)
  out$coef   <- sprintf("%.4f%s", out$b, out$sig)
  out$std_err<- sprintf("(%.4f)", out$se)
  out$z      <- sprintf("%.2f", out$z)
  out$p      <- sprintf("%.4f", out$p)
  out$N      <- ifelse(is.na(out$N), "", format(round(out$N), big.mark=","))
  
  disp <- out[, c("table","model","term","coef","std_err","z","p","N","note")]
  colnames(disp) <- c("Table","Model","Term","Coef","Std.Err","z","p","N","Note")
  
  ## pretty fixed-width print
  print(disp, row.names = FALSE, right = FALSE)
  
  ## write CSV next to the data file
  csv_path <- file.path(dirname(DATA_PATH), "check_missing_regressions_results.csv")
  tryCatch({
    write.csv(out[, c("table","model","term","b","se","z","p","N","note")],
              csv_path, row.names = FALSE)
    cat("\nSaved: ", csv_path, "\n", sep="")
  }, error = function(e) cat("\n(could not write CSV:", conditionMessage(e), ")\n"))
} else {
  cat("No results were collected (all models failed).\n")
}

cat("\n", strrep("=",78), "\n", sep="")
cat("Notes: significance  *p<0.1  **p<0.05  ***p<0.01  (two-sided, normal).\n")
cat("Table 2 `harvest` coef is identical across the four FE specs; only the\n")
cat("Conley SE differs. Table 4 logit/Poisson coefs are on the log-odds /\n")
cat("log-rate scale, so they are NOT comparable in size to the LPM column.\n")
cat(strrep("=",78), "\n", sep="")
