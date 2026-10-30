# Data snapshots

`data/*.Rdata`, written by the `00-setup/setup-*-data.R` scripts with `read_data <- TRUE` and
loaded by `setup.R` otherwise: `fleet_data.Rdata` (`<fleet>_landings`), `catchdistribution_data.Rdata`
(`ldist.<fleet>`, `aldist.<fleet>`, `matp.<fleet>`), `indices.Rdata` (`<survey>.SI`) and
`init_param.Rdata` (`lw.constants`, `init.cv`, `mat.l50`, `mat.a50`, `growth_vals`). Each data object
is a list with one element per bootstrap replicate (`[[1]]` for the standard data). Gitignored.
