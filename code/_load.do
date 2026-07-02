********************************************************************************
* _load.do  --  conditional dataset loader (efficiency helper)
*------------------------------------------------------------------------------
* Loads a dataset ONLY if it is not already the one in memory. This is what
* lets the pipeline avoid re-reading the same .dta from disk for every
* consecutive script that uses the same sample.
*
* Usage:
*     local DSET "${cache}/_cache_analysis_80percent.dta"
*     do "${code}/_load.do" "`DSET'"
*
* The currently-loaded path is tracked in the global ${LOADED}. If it already
* matches the requested file, nothing is reloaded. Pass a second argument
* "force" to reload regardless.
********************************************************************************

args want force

if ("`force'" == "force" | "${LOADED}" != "`want'") {
    use "`want'", clear
    global LOADED "`want'"
    display as text "[_load] loaded: `want'"
}
else {
    display as text "[_load] already in memory, skipped reload: `want'"
}
