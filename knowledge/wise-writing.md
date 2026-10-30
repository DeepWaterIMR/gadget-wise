# The wise-writing contract

gadget-wise owns the gadget3 model, its code, its diagnostics and the gadget-specific content of
documents. wise-writing owns the project skeleton, scientific style, Quarto conventions, document
templates (data report, assessment report, benchmark report, advice sheet, manuscript) and rendering.

- `scaffold.R` calls wise-writing's `scaffold_document()` and overlays the gadget layer; there is one
  copy of shared infrastructure.
- Documents: use `academic-style`, `academic-conventions` and the document skill
  (`academic-data-report`, `academic-assessment-report`, `academic-benchmark-report`,
  `academic-advice-sheet`). gadget-specific sections come from `docs/gadget/` partials (`gadget-report`).
- Presentations: wise-presentations `make-presentation` / `review-presentation`.
- R code: `r-code-style`. Package setup: `r-package-setup`.
- Numbers in text come from the model folder by inline R, never typed in.
