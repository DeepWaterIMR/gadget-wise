# Model-input tables (the data contract)

Written by the data-loop (`02-0_data_loop.R`), read by `02-*.R`. One CSV per data set:

| File | Columns |
|---|---|
| `catches_<Fleet>.csv` | year, step, area, total_weight (kg) or number |
| `ldist_<Fleet>.csv` | year, step, area, length (cm), number |
| `aldist_<Fleet>.csv` | year, step, area, age, length (cm), number |
| `matp_<Fleet>.csv` | year, step, area, length (cm), maturity_stage (imm/mat), number |
| `index_<Name>.csv` | year, step, area, [length], weight or number, [lwr, upr] |
| `life_history.yaml` | see `../parameters/README.md` |

Fleet and index names are those in `config.yaml` (`MODEL$FLEETS`, `MODEL$LIKELIHOOD$indices`).
The tables are data: they are gitignored. Record where each came from in the data report.
