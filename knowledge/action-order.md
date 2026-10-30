# Action order and timing

gadget3 runs the actions of each time step in a fixed order (`gadget3::g3_action_order`):

| Order | Name | What runs |
|---|---|---|
| -1 | initial | clock; initial conditions (first step only) |
| 0 | report_early | start-of-step reports (`dstart_*`) |
| 1 | time | stop check |
| 2 | migrate | migration |
| 3 | predate | **fleets and predators catch** |
| 4 | naturalmortality | natural mortality |
| 5 | grow | growth (and the maturing fraction) |
| 6 | spawn | spawning |
| 7 | mature | maturing fish move to the mature stock |
| 8 | renewal | **recruits added** |
| 9 | straying | (tag shedding) |
| 10 | likelihood | **data compared with the model** |
| 11 | report | end-of-step reports (`detail_*`, `hist_*`) |
| 12 | age | **ageing** (final step of the year) |
| 13 | quota | quota for the next year (projections) |

## Consequences that bite

1. **Fleet data see the stock before renewal.** Catch distributions compare the step's catch (order 3).
   Recruits of year Y (added at 8) are not in year-Y catches; with an annual step they are aged at 12
   and first appear in fleet data in Y + 1, one model age older than their recruitment age.
2. **Stock-based survey indices see the stock after renewal.** `g3l_abundancedistribution()` without
   fleets compares the stock at order 10, after renewal: a year-Y index includes the year-Y recruits.
   A real survey in year Y sees the fish born before Y, so the model's recruitment parameter `rec.Y`
   pairs with the year class born in Y − recruitment age. Decide and document whether to shift the
   index years (or the age data) and keep the convention consistent across indices and age data.
3. **Age data**: observed biological ages at the survey are compared with model ages at the predation
   step. Whether to add one to observed ages depends on the step structure and the recruitment age;
   check by plotting model length at age against observed length at age before deciding.
4. **Yearly data without a `step` column** are aggregated over all steps of the year and compared at
   the final step. Give indices an explicit `step`.
5. **Initial conditions** are set "as if at the previous step" (`age_offset = cur_step_size`), then the
   first step's predation, growth etc. run on top.
6. Two actions whose calls deparse identically collapse into one; vary an argument to run an action twice.

Full detail with source references: `skills/gadget-model/references/gadget3-reference.md`, section 2.
