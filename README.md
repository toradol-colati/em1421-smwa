# EM1421 – Repeat Requests for Adminship

Progetto di gruppo per EM1421 Social Media and Web Analytics (Ca' Foscari, a.a. 2026/2027).
Network change, prior outcomes and later success nelle candidature RfA ripetute di Wikipedia.

Gruppo: Bubi (Umberto Toraldo), Mihretab.

## Struttura

| Cartella | Contenuto |
|---|---|
| `data/raw/` | file SNAP come scaricati, non modificati (vedi `data/raw/README.md`) |
| `data/processed/` | tabelle derivate (`attempts`, `votes`, ...), prodotte dagli script in `R/` |
| `R/` | script numerati, da eseguire in ordine |
| `output/figures/` | figure per il report (max 4 figure/tabelle in totale) |
| `report/` | report in PDF e sorgenti |
| `docs/` | brief, istruzioni del corso, documento di contesto, letteratura |

## Come eseguire

1. Scaricare i due file SNAP in `data/raw/` (istruzioni in `data/raw/README.md`).
2. Dalla radice del repo, in ordine:

```
Rscript R/01_read_raw.R
Rscript R/02_build_attempts.R
Rscript R/03_validate_outcomes.R
Rscript R/04_build_networks.R
Rscript R/05_measure_change.R
Rscript R/06_model_outcome.R
Rscript R/07_figures.R
```

Tutti gli script usano percorsi relativi alla radice del repo e non installano pacchetti.

## Pacchetti R

`igraph`, `ggplot2`, `data.table`, `backbone` (proiezione di co-voto).

## Convenzioni

- Analisi interamente in R. Nel report niente codice né descrizione del codice.
- Nessuna variabile osservata durante il tentativo t+1 entra come predittore dell'esito di t+1.
- Ogni script scrive solo in `data/processed/` o `output/`, mai in `data/raw/`.
