# Generated data

This directory is populated by `R/01_prepare_data.R`:

```powershell
& "C:\Program Files\R\R-4.5.2\bin\Rscript.exe" R\01_prepare_data.R
```

The `.rds`, `.csv` and `.txt` files in this folder are the validated snapshot
produced by the current pipeline. Rerunning the preparation overwrites them.
The original source data remain unchanged under `data/raw/`.
