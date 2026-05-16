/* =============================================================================
   Determinants of Earnout Use in European M&A Deals
   MSc Thesis – Finance & Banking, University of Rome Tor Vergata
   
   Research question: How do EPU and VSTOXX affect earnout adoption and
   payment structure choice in European M&A (2000–2023)?
   
   Hypotheses:
     H1 – Higher EPU × VSTOXX → higher probability of earnout
     H2 – Uncertainty shifts payment structure away from cash
   ============================================================================= */

version 17.0
set more off
capture log close
log using "logs/earnout_analysis.log", replace text

/* --------------------------------------------------------------------------
   0. ENVIRONMENT SETUP
   -------------------------------------------------------------------------- */
* Install required packages if missing
foreach pkg in estout winsor2 {
    capture which `pkg'
    if _rc == 111 ssc install `pkg', replace
}

/* --------------------------------------------------------------------------
   1. LOAD & SAVE RAW DATA
   -------------------------------------------------------------------------- */
clear all
import excel "data/Deals_Results_report_EU.xlsx", firstrow case(lower) clear
save "data/raw_deals.dta", replace

/* --------------------------------------------------------------------------
   2. RENAME VARIABLES
   -------------------------------------------------------------------------- */
rename announcementdate         announcement_date
rename dealsizemmusd            deal_value_mm
rename dealtype                 deal_type
rename transactiontype          ma_type
rename crossborder              cross_border
rename cashconsideration        cash_pct
rename stockconsideration       stock_pct
rename contingentpayment        contingent_pct
rename earnout_flag             earnout_dummy
rename contingentpaymentmm      earnout_value_mm
rename countrytargetissuer      target_country
rename naicssectortargetissuer  target_sector
rename privatetargetflag        private_target
rename crosssectorflag          cross_sector

/* --------------------------------------------------------------------------
   3. OUTCOME: EARNOUT DUMMY
   -------------------------------------------------------------------------- */
destring earnout_dummy, replace
replace  earnout_dummy = 0 if missing(earnout_dummy)
label variable earnout_dummy "=1 if deal includes earnout provision"

/* --------------------------------------------------------------------------
   4. DEAL SIZE
   -------------------------------------------------------------------------- */
gen ln_deal_value = ln(deal_value_mm) if deal_value_mm > 0
label variable ln_deal_value "Log deal value (USD mm)"

/* --------------------------------------------------------------------------
   5. EARNOUT VALUE & RATIO
   -------------------------------------------------------------------------- */
destring earnout_value_mm, replace ignore("NA" "na" "N/A" "." " " "-")
replace  earnout_value_mm = 0 if missing(earnout_value_mm)
gen earnout_to_deal = earnout_value_mm / deal_value_mm if deal_value_mm > 0
label variable earnout_to_deal "Earnout as share of total deal value"

/* --------------------------------------------------------------------------
   6. BINARY DEAL CHARACTERISTICS
   -------------------------------------------------------------------------- */
* Cross-border
gen cross_border_num = (cross_border == "Yes") if !missing(cross_border)
drop cross_border
rename cross_border_num cross_border
label variable cross_border    "=1 if target and acquirer in different countries"

* Private target
destring private_target, replace
label variable private_target  "=1 if target is a private firm"

* Cross-sector
destring cross_sector, replace
label variable cross_sector    "=1 if deal crosses 2-digit NAICS boundary"

/* --------------------------------------------------------------------------
   7. PAYMENT STRUCTURE: CASH, STOCK, MIXED, EARNOUT
   -------------------------------------------------------------------------- */
* Clean stock percentage
clonevar stock_pct_str = stock_pct
replace  stock_pct_str = "" if stock_pct_str == "-"
destring stock_pct_str, gen(stock_pct_num) ignore("NA" "," "-")
drop stock_pct_str

* Ensure cash percentage is numeric (was imported numeric; guard against missing)
capture confirm numeric variable cash_pct
if _rc {
    destring cash_pct, replace ignore("NA" "," "-")
}
replace cash_pct    = 0 if missing(cash_pct)
replace stock_pct_num = 0 if missing(stock_pct_num)

* Mutually exclusive categories (earnout overrides structure flags)
gen pay_structure = .
replace pay_structure = 1 if cash_pct    >= 99 & earnout_dummy == 0
replace pay_structure = 2 if stock_pct_num >= 99 & earnout_dummy == 0
replace pay_structure = 3 if missing(pay_structure) & earnout_dummy == 0
replace pay_structure = 4 if earnout_dummy == 1
label define pay_lbl 1 "Cash Only" 2 "Stock Only" 3 "Mixed" 4 "Earnout"
label values pay_structure pay_lbl
label variable pay_structure "Payment structure category"

/* --------------------------------------------------------------------------
   8. MACRO-UNCERTAINTY VARIABLES
      Rolling windows: 3, 6, 9, 12 months
      Steps per window:
        a) log-transform (EPU, VSTOXX)
        b) winsorise at 1st/99th to reduce extreme-value influence
        c) binary "high" indicator (above historical median computed on
           unique announcement dates to avoid deal-count weighting)
   -------------------------------------------------------------------------- */
foreach m in 3 6 9 12 {

    * Log-transform raw rolling averages
    gen log_epu_roll_`m'm    = ln(EPUEURollingavg`m'm)      if EPUEURollingavg`m'm      > 0
    gen log_vstoxx_roll_`m'm = ln(VSTOXXRolling`m'monthavg) if VSTOXXRolling`m'monthavg > 0

    * Winsorise at deal level
    winsor2 log_epu_roll_`m'm log_vstoxx_roll_`m'm, replace cuts(1 99)

    * Compute medians on unique dates (avoids overweighting busy deal months)
    preserve
        keep announcement_date log_epu_roll_`m'm log_vstoxx_roll_`m'm
        duplicates drop announcement_date, force
        quietly summarize log_epu_roll_`m'm, detail
        scalar epu_med_`m' = r(p50)
        quietly summarize log_vstoxx_roll_`m'm, detail
        scalar vstoxx_med_`m' = r(p50)
    restore

    * Binary above-median indicators
    gen high_log_epu_roll_`m'm    = (log_epu_roll_`m'm    > epu_med_`m')    ///
        if !missing(log_epu_roll_`m'm)
    gen high_log_vstoxx_roll_`m'm = (log_vstoxx_roll_`m'm > vstoxx_med_`m') ///
        if !missing(log_vstoxx_roll_`m'm)

    scalar drop epu_med_`m' vstoxx_med_`m'

    label variable log_epu_roll_`m'm           "Log EPU (`m'm rolling avg, winsorised)"
    label variable log_vstoxx_roll_`m'm        "Log VSTOXX (`m'm rolling avg, winsorised)"
    label variable high_log_epu_roll_`m'm      "=1 if EPU above median (`m'm window)"
    label variable high_log_vstoxx_roll_`m'm   "=1 if VSTOXX above median (`m'm window)"
}

* Convenience aliases for 12m window (used in sensitivity tables)
foreach stub in log_epu log_vstoxx high_log_epu high_log_vstoxx {
    clonevar `stub'_lag = `stub'_roll_12m
}

/* --------------------------------------------------------------------------
   9. FIXED EFFECTS
   -------------------------------------------------------------------------- */
encode target_sector,  gen(target_sector_cat)
encode target_country, gen(target_country_cat)

/* --------------------------------------------------------------------------
   10. SAVE CLEAN ANALYTICAL DATASET
   -------------------------------------------------------------------------- */
save "data/analytical_dataset.dta", replace

/* --------------------------------------------------------------------------
   11. DESCRIPTIVE STATISTICS
   -------------------------------------------------------------------------- */
* Summary table
estpost summarize earnout_dummy ln_deal_value cross_border private_target ///
    cross_sector log_epu_roll_6m log_vstoxx_roll_6m, detail
esttab using "tables/descriptives.tex", ///
    cells("mean(fmt(3)) sd(fmt(3)) p25(fmt(3)) p50(fmt(3)) p75(fmt(3)) count(fmt(0))") ///
    label replace nonumber

* Cross-tabulations
foreach var in cross_border private_target cross_sector {
    tab earnout_dummy `var', row chi2
}
tab pay_structure

/* --------------------------------------------------------------------------
   12. H1 – DETERMINANTS OF EARNOUT USE (LOGIT)
       Primary window: 6 months
   -------------------------------------------------------------------------- */

* --- Model I: Dummy interaction (high EPU × high VSTOXX) ---
logit earnout_dummy i.high_log_epu_roll_6m##i.high_log_vstoxx_roll_6m ///
    ln_deal_value cross_border private_target cross_sector ///
    i.target_sector_cat i.target_country_cat, vce(robust)
estimates store H1_m1

* Average marginal effect of EPU at each VSTOXX level
margins, dydx(high_log_epu_roll_6m) over(high_log_vstoxx_roll_6m)
marginsplot, title("AME of EPU on Earnout Probability (6m window)") ///
    xtitle("High VSTOXX") ytitle("AME of High EPU") yline(0) ///
    saving("figures/H1_margins_dummy.gph", replace)

* --- Model II: Continuous interaction (log EPU × log VSTOXX) ---
logit earnout_dummy c.log_epu_roll_6m##c.log_vstoxx_roll_6m ///
    ln_deal_value cross_border private_target cross_sector ///
    i.target_sector_cat i.target_country_cat, vce(robust)
estimates store H1_m2

* AME of EPU at 25th, 50th, 75th percentile of VSTOXX
quietly summarize log_vstoxx_roll_6m, detail
margins, dydx(log_epu_roll_6m) ///
    at(log_vstoxx_roll_6m=(r(p25) r(p50) r(p75)))

* --- Model diagnostics ---
* ROC curve
quietly logit earnout_dummy i.high_log_epu_roll_6m##i.high_log_vstoxx_roll_6m ///
    ln_deal_value cross_border private_target cross_sector ///
    i.target_sector_cat i.target_country_cat, vce(robust)
predict p_hat, pr
lroc, nograph
roctab earnout_dummy p_hat

* Classification table at 0.5 threshold
estat classification, cutoff(0.5)
drop p_hat

/* --------------------------------------------------------------------------
   13. H1 – SENSITIVITY: 3m, 9m, 12m WINDOWS
   -------------------------------------------------------------------------- */
foreach m in 3 9 {
    * Dummy specification
    logit earnout_dummy i.high_log_epu_roll_`m'm##i.high_log_vstoxx_roll_`m'm ///
        ln_deal_value cross_border private_target cross_sector ///
        i.target_sector_cat i.target_country_cat, vce(robust)
    estimates store H1_`m'm_dummy

    * Continuous specification
    logit earnout_dummy c.log_epu_roll_`m'm##c.log_vstoxx_roll_`m'm ///
        ln_deal_value cross_border private_target cross_sector ///
        i.target_sector_cat i.target_country_cat, vce(robust)
    estimates store H1_`m'm_cont
}

* 12m (using alias variables for clarity)
logit earnout_dummy i.high_log_epu_lag##i.high_log_vstoxx_lag ///
    ln_deal_value cross_border private_target cross_sector ///
    i.target_sector_cat i.target_country_cat, vce(robust)
estimates store H1_12m_dummy

/* --------------------------------------------------------------------------
   14. H2 – PAYMENT STRUCTURE UNDER UNCERTAINTY (MULTINOMIAL LOGIT)
       Base outcome: Cash Only (1)
   -------------------------------------------------------------------------- */
mlogit pay_structure i.high_log_epu_roll_6m##i.high_log_vstoxx_roll_6m ///
    ln_deal_value cross_border private_target cross_sector ///
    i.target_sector_cat, base(1) vce(robust)
estimates store H2_mlogit

* Average marginal effects for Stock Only (2), Mixed (3), Earnout (4)
foreach cat in 2 3 4 {
    margins, dydx(high_log_epu_roll_6m high_log_vstoxx_roll_6m ///
        cross_border private_target cross_sector) ///
        predict(outcome(`cat')) post
    estimates store H2_AME_alt`cat'
}

* Predicted earnout probability across EPU × VSTOXX combinations
margins high_log_epu_roll_6m#high_log_vstoxx_roll_6m, ///
    predict(outcome(4)) atmeans
marginsplot, title("Predicted Earnout Probability by EPU and VSTOXX Level") ///
    saving("figures/H2_predicted_prob.gph", replace)

/* --------------------------------------------------------------------------
   15. SUPPLEMENTARY: EARNOUT vs STOCK (non-cash subsample)
       Tests whether EPU favours earnouts specifically over stock consideration
   -------------------------------------------------------------------------- */
gen non_cash_deal      = (stock_pct_num > 0 | earnout_dummy == 1)
gen earnout_vs_stock   = earnout_dummy if non_cash_deal == 1
label variable earnout_vs_stock "=1 if earnout (vs stock), non-cash deals only"

logit earnout_vs_stock i.high_log_epu_roll_6m##i.high_log_vstoxx_roll_6m ///
    ln_deal_value cross_border private_target cross_sector ///
    i.target_sector_cat if non_cash_deal == 1, vce(robust)
estimates store H_supp_earnout_vs_stock

margins, dydx(high_log_epu_roll_6m) over(high_log_vstoxx_roll_6m)

/* --------------------------------------------------------------------------
   16. EXPORT RESULTS TABLES
   -------------------------------------------------------------------------- */
* H1 main results
esttab H1_m1 H1_m2 using "tables/H1_logit_6m.tex", ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs replace ///
    title("H1 – Determinants of Earnout Use (6m window)") ///
    mtitles("Dummy interaction" "Continuous interaction")

* H1 sensitivity
esttab H1_3m_dummy H1_3m_cont H1_9m_dummy H1_9m_cont H1_12m_dummy ///
    using "tables/H1_sensitivity.tex", ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs replace ///
    title("H1 – Robustness: 3m, 9m, 12m rolling windows") ///
    mtitles("3m dum." "3m cont." "9m dum." "9m cont." "12m dum.")

* H2 multinomial logit
esttab H2_mlogit using "tables/H2_mlogit.tex", ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    label booktabs replace ///
    title("H2 – Multinomial Logit: Payment Structure Choice (base = Cash)")

log close

/* =============================================================================
   END OF DO-FILE
   ============================================================================= */
