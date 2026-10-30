# {{PROJECT_TITLE}}

A [gadget3](https://gadget-framework.github.io/gadget3/) model of {{STOCK_NAME}} (*{{STOCK_LATIN}}*)
in ICES {{ICES_AREAS}}, scaffolded with [gadget-wise](https://github.com/DeepWaterIMR/gadget-wise)
in the Icelandic format.

```r
source("00-setup/setup.R") # from the project root
```

Set the options at the top of `00-setup/setup.R`. With `read_data <- TRUE` the data scripts query
mfdb and write `data/*.Rdata`; with `FALSE` the snapshots are loaded. Output goes to `model/<vers>/`.
