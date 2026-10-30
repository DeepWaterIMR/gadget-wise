# Synthetic example

`config.yaml` for a synthetic two-sub-stock "cod" with one fishery and one survey. Use it to try the
scaffold and as a template for a real stock:

```r
source("scaffold.R")
scaffold_gadget("examples/synthetic/config.yaml", "../syn-gadget")              # IMR format
source("config/make_synthetic_data.R")
make_synthetic_data("examples/synthetic/config.yaml", "../syn-gadget/data/output/model-input")
```

Change `LAYOUT: iceland` for the Icelandic format (synthetic snapshots:
`config/make_synthetic_iceland.R`). The numbers mean nothing.
