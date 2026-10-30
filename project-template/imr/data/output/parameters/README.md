# life_history.yaml

Starting values for the model, estimated in the data report (e.g. with ggFishPlots), written to
`data/output/model-input/life_history.yaml`:

```yaml
Linf: 110           # von Bertalanffy asymptotic length (cm)
K: 0.15             # von Bertalanffy growth coefficient (1/year)
t0: -0.5            # von Bertalanffy t0 (years)
walpha: 1.0e-5      # length-weight a (kg, cm)
wbeta: 3.0          # length-weight b
mat_l50: 55         # length at 50 % maturity (cm)        two sub-stocks only
mat_alpha: 0.2      # slope of the maturity ogive by length two sub-stocks only
mat_a50: 6          # age at 50 % maturity                 two sub-stocks only (initial split)
mat_a_alpha: 1      # slope of the maturity ogive by age   two sub-stocks only
init_length_cv: 0.1 # CV of length at age for the initial population
# Optional: initial mean length and sd by age instead of the growth curve
# init_length_at_age:
#   - {age: 1, ml: 12, ms: 2}
estimate_Linf: false
estimate_maturity: false
source: "Data report, section Life history"
```
