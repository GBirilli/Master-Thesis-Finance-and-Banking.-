# Determinants of Earnout Use in European M&A Deals

<p>
  <img src="https://img.shields.io/badge/Stata-17-blue" />
  <img src="https://img.shields.io/badge/Econometrics-Logit%20%7C%20MNLogit-informational" />
  <img src="https://img.shields.io/badge/Final%20Grade-110%2F110%20cum%20laude-brightgreen"" />
  <img src="https://img.shields.io/badge/University-Tor%20Vergata-blue" />
</p>

**Master Thesis · Finance & Banking · University of Rome Tor Vergata · 2026**

---

## Research Question

> *Do macroeconomic policy uncertainty (EPU) and market volatility (VSTOXX) increase the probability that M&A parties structure a deal with an earnout — and do the two forces amplify each other?*

Earnouts are contingent deferred payments: the seller receives an additional amount only if post-close performance targets are met. They are a natural risk-sharing solution under valuation disagreement. This project quantifies when and why parties choose them, using a dataset of European transactions sourced from Refinitiv (LSEG).

---

## Hypotheses

| | Hypothesis | Method |
|---|---|---|
| **H1** | High EPU × High VSTOXX jointly increase earnout probability | Binary logit with interaction term |
| **H2** | Uncertainty shifts payment structure away from all-cash | Multinomial logit (4-outcome discrete choice) |

Both are grounded in asymmetric information theory — when the future is genuinely unclear, deferring part of the price to post-close performance reduces the cost of valuation disagreement.

---

## Skills Demonstrated

### Quantitative & Econometric
- **Binary logit** with EPU × VSTOXX interaction; average marginal effects (AME) computed at percentile values of the moderating variable
- **Multinomial logit** for discrete choice across four payment structures (cash / stock / mixed / earnout)
- **Fixed effects** — sector (NAICS) and country — to absorb cross-sectional unobservables
- **Robustness checks** — four rolling windows (3m, 6m, 9m, 12m); dummy vs. continuous interaction specifications; earnout-vs-stock subsample logit
- **Model diagnostics** — ROC curve, AUC, classification table, VIF

### Data & Programming
- **Stata** — full pipeline from raw Excel to publication-ready LaTeX tables: `import`, `destring`, `encode`, `winsor2`, `estout`, `marginsplot`
- **Rolling window calculations** (3/6/9/12 months) automated via `foreach` loops and scalars
- **Winsorisation** at p1/p99 to reduce leverage of extreme observations
- **Median-based binary indicators** computed on unique announcement dates (avoids deal-count weighting bias)
- **Reproducible workflow** — relative paths, automatic package installation, full session log

### Financial & Domain Knowledge
- EPU index (Baker, Bloom & Davis 2016) and VSTOXX implied volatility as uncertainty proxies
- M&A payment structure theory: information asymmetry, adverse selection, contingent contracting
- Earnout valuation mechanics and their role in bridging bid-ask spreads under uncertainty
- Refinitiv (LSEG) deal database — variable selection, coverage decisions, and data cleaning

---

## Technical Stack

| Layer | Tools |
|---|---|
| Language | Stata 17 |
| Data sources | Refinitiv (LSEG), Baker-Bloom-Davis EPU, Eurex VSTOXX |
| Transformations | Log, winsorisation (p1/p99), rolling averages (3/6/9/12m) |
| Models | Binary logit, multinomial logit, AME, marginsplot |
| Fixed effects | NAICS sector, target country |
| Output | `estout` → LaTeX; `.gph` figures |

---

## Modelling Notes

**Logit over OLS** — the earnout decision is binary; logit with robust standard errors is standard in this literature (Barbopoulos & Sudarsanam, 2012; Cain et al., 2011).

**Interaction term** — EPU and VSTOXX capture distinct risks: policy-driven uncertainty vs. market-priced volatility. The interaction tests whether one amplifies the marginal effect of the other, consistent with a multiplicative information friction model.

**Median-split indicators** — preserve interpretability in AME plots and align with the directional framing of H1. Continuous interactions (Model II) serve as the robustness check.

**Fixed effects** — sector and country dummies (encoded categorically via `encode`) absorb industry-level and geography-level unobservables without requiring a panel structure, since deals are cross-sectional observations.

> **Data:** Raw `.xlsx` and `.dta` files are excluded (Refinitiv licensing). EPU indices are publicly available at [policyuncertainty.com](https://www.policyuncertainty.com/). VSTOXX data can be downloaded from [Eurex](https://www.eurex.com/).
---

## References

- Baker, S., Bloom, N., & Davis, S. (2016). Measuring Economic Policy Uncertainty. *QJE*, 131(4), 1593–1636.
- Barbopoulos, L., & Sudarsanam, S. (2012). Determinants of earnout financing in M&A. *Journal of Banking & Finance*, 36(3), 678–694.
- Cain, M., Denis, D., & Denis, D. (2011). Earnouts: A study of financial contracting in acquisition agreements. *JAE*, 51(1–2), 151–170.
- Datar, S., Frankel, R., & Wolfson, M. (2001). Earnouts: The effects of adverse selection and agency costs on acquisition techniques. *JLEO*, 17(1), 201–238.

---

## Contact

**Guido Birilli** · MSc Finance & Banking, University of Rome Tor Vergata  
[birilli.guido@gmail.com](mailto:birilli.guido@gmail.com) · [LinkedIn](https://www.linkedin.com/in/guido-birilli-344938233/)

*Thesis defended March 2026 
