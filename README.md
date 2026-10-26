# EM1421 — Repeat Requests for Adminship

Progetto di gruppo per **EM1421 Social Media and Web Analytics**, Ca' Foscari, a.a. 2026/2027.
Docente: Pierluigi Zama Ramirez.

**Domanda (testo approvato dal docente, da non riscrivere senza scrivergli prima):**
> Among repeat Requests for Adminship candidates, how do changes in voter-community
> composition, support-coalition overlap and network position differ between previously
> rejected and previously successful candidates, and how are these changes associated with the
> next outcome?

Dati: SNAP **wiki-RfA** (voti RfA di Wikipedia, 2003 – maggio 2013) come fonte primaria, SNAP
**wiki-Elec** (elezioni fino a gennaio 2008) per validare gli esiti. Analisi interamente in R
(igraph, ggplot2). I risultati sono associazioni, non effetti causali.

Gruppo: **Bubi** (Umberto Toraldo, GitHub `toradol-colati`) e **Mihretab**.
Scadenza dal brief: **2 novembre 2026, 09:00 CET** (report PDF + codice + dati, più email di
conferma al docente).

---

## Se apri questa repo per la prima volta: leggi in questo ordine

| # | File | Perché |
|---|---|---|
| 1 | [docs/EM1421_RfA_contesto_nuova_chat.md](docs/EM1421_RfA_contesto_nuova_chat.md) | **Il documento fondamentale.** Stato del progetto, numeri, letteratura verificata, i problemi aperti e le 8 decisioni ancora da prendere (§11). Se leggi un solo file, leggi questo. |
| 2 | [CLAUDE.md](CLAUDE.md) | Cosa è cambiato dopo quel documento: proposta approvata, divisione del lavoro proposta, tre punti deboli aperti. Serve anche a istruire Claude Code, se lo usi. |
| 3 | [docs/MATERIALE_CORSO.md](docs/MATERIALE_CORSO.md) | Tutte le slide del corso sintetizzate: definizioni, formule, funzioni igraph, e dove il materiale vincola le nostre scelte di metodo. Usalo mentre sviluppi invece di riaprire i PDF. Le §11 e §12 sono le due da leggere prima di scrivere codice. |
| 4 | [docs/CODICE.md](docs/CODICE.md) | Il gemello del precedente, lato codice: cosa possiamo e dobbiamo scrivere oltre il codice delle slide, i requisiti perché il docente possa eseguirlo, le convenzioni del repo, gli idiomi R per ciò che le slide non coprono, e la checklist di consegna. Da leggere prima di scrivere il primo script. |
| 5 | [docs/EM1421_group_project_brief.pdf](docs/EM1421_group_project_brief.pdf) | Il brief inviato e approvato. |
| 6 | [docs/writing_your_project.txt](docs/writing_your_project.txt) + [docs/EM1421_projectsInstructions.txt](docs/EM1421_projectsInstructions.txt) | I criteri 01–08 con cui il docente valuta, e le regole formali (max 4 figure, 12.000–20.000 caratteri, niente codice nel report, ≥5 riferimenti scientifici, paragrafo sul contributo di ciascuno). |

Il resto di `docs/` sono le slide originali e i paper, lasciati come riferimento.

## Struttura della repo

```
CLAUDE.md                 aggiornamenti e istruzioni di lavoro
README.md                 questo file
R/                        script numerati, da eseguire in ordine
  00_paths.R              percorsi condivisi e controllo dei file mancanti
  01_read_raw.R           lettura dei due file SNAP, nessuna pulizia
  02_build_attempts.R     ricostruzione dei tentativi          [SCHELETRO]
  03_validate_outcomes.R  validazione esiti su wiki-Elec       [SCHELETRO]
  04_build_networks.R     rete di voto e proiezione di co-voto [SCHELETRO]
  05_measure_change.R     misure del cambiamento t -> t+1      [SCHELETRO]
  06_model_outcome.R      esito del tentativo successivo       [SCHELETRO]
  07_figures.R            le figure del report                 [SCHELETRO]
data/raw/                 file SNAP come scaricati (vedi il README dentro)
data/processed/           tabelle derivate, prodotte dagli script
output/figures/           figure
report/                   report PDF e sorgenti
docs/                     brief, istruzioni, slide, paper, note
```

**Gli script marcati [SCHELETRO] non contengono codice**: solo un'intestazione con input,
output e l'elenco delle decisioni ancora aperte per quel passo. Sono deliberatamente vuoti —
quelle sono scelte di metodo che dobbiamo prendere noi due, non da riempire di default.
`01_read_raw.R` è scritto ma **non ancora eseguito**: i file SNAP non sono in repo.

## Far partire tutto

1. Scaricare i due file SNAP in `data/raw/` — comandi pronti in
   [data/raw/README.md](data/raw/README.md). Vanno committati: la consegna richiede i dati
   insieme al codice, e stanno sotto il limite di GitHub (wiki-RfA ~15 MB).
2. Pacchetti R: `igraph`, `ggplot2`, `data.table`. Più `backbone` solo se decidiamo di usarlo
   (ma vedi `docs/MATERIALE_CORSO.md` §12: è fuori programma).
3. Dalla radice della repo, in ordine:

```bash
Rscript R/01_read_raw.R
```

Gli altri script si aggiungono alla sequenza quando li scriviamo. Tutti usano percorsi
relativi alla radice della repo e non installano pacchetti: il docente deve poterli eseguire
("it is your responsibility to deliver a code that can be tested by the instructor").

## Convenzioni

- `data/raw/` è **di sola lettura** per gli script. Ogni script scrive solo in
  `data/processed/` o in `output/`.
- Nessuna variabile osservata **durante** il tentativo t+1 entra come predittore dell'esito di
  t+1. Le variabili di coalizione di t+1 servono solo al confronto descrittivo, con modello
  nullo. È la regola "no leakage" del brief e il criterio 06 del docente.
- Script numerati, eseguibili in ordine, uno per passo del piano del brief.
- Nel report niente codice né descrizione del codice (regola §3 delle istruzioni).

## Stato e cosa manca

Fatto: struttura della repo, lettura del materiale del corso, sintesi in
`docs/MATERIALE_CORSO.md`.

Da fare, in ordine di dipendenza:
1. **Insieme, prima di scrivere codice:** lo schema delle tabelle `attempts` (una riga per
   tentativo) e `votes` (con id del tentativo), e le definizioni scritte delle due reti —
   nodo, arco, direzione, peso, voti neutri, finestra temporale.
2. **In parallelo e indipendenti:** la ricostruzione dei tentativi, ciascuno con la propria
   regola e senza guardare quella dell'altro; poi confronto dei conteggi e regola unica.
3. Poi i ruoli (Data member / Network member) — **ancora non assegnati**, vedi `CLAUDE.md`.
4. Insieme: figure (max 4), letteratura, report, revisione incrociata del codice.

Le decisioni ancora aperte sono elencate in
`docs/EM1421_RfA_contesto_nuova_chat.md` §11 e i vincoli che il corso impone su quelle
decisioni in `docs/MATERIALE_CORSO.md` §11.
