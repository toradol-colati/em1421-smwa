# EM1421 — Il codice del progetto: mandato, confini, convenzioni

File gemello di `MATERIALE_CORSO.md`. Quello riguarda i **contenuti** da studiare e applicare;
questo riguarda il **codice**: cosa possiamo scrivere, cosa dobbiamo scrivere, come va scritto
perché il docente lo possa eseguire.

Qui non si decide nessun metodo. Le scelte di metodo stanno in
`EM1421_RfA_contesto_nuova_chat.md` §11 e i vincoli che il corso impone su quelle scelte in
`MATERIALE_CORSO.md` §11. Qui c'è l'infrastruttura.

Indice:
1. Il mandato
2. Cosa danno le slide: il codice come base
3. Cosa dobbiamo scrivere noi
4. Per i metodi il riferimento restano le slide
5. "A code that can be tested by the instructor": requisiti concreti
6. Convenzioni del repo
7. Idiomi R per ciò che le slide non coprono
8. Mappa degli script
9. Checklist prima della consegna
10. Rischi noti

---

## 1. Il mandato

Cinque principi, con la fonte di ciascuno. I primi quattro sono citazioni dai documenti
ufficiali; il quinto è la conseguenza operativa che ne traiamo noi.

1. **"Perform an original data analysis by applying tools, methods, and techniques addressed
   during the course."** — Istruzioni §1. Il vincolo è **applicare** le tecniche del corso,
   non usare soltanto quelle.
2. **"The entire analysis should be performed in R or Python."** — Istruzioni §3.3.
   **Noi usiamo R.** È l'unico vincolo tecnico esplicito di tutto il regolamento: nessuna
   lista di pacchetti ammessi, nessun divieto.
3. **"It is your responsibility to deliver a code that can be tested by the instructor."** —
   Istruzioni §5. Il codice va commentato adeguatamente e accompagnato da tutti i file
   esterni necessari. Il criterio di accettazione è che **gira**, non che assomigli alle slide.
   Vedi §5 di questo file per cosa significa in pratica.
4. **"They are not meant to be replicated but serve as inspiration for developing unique and
   creative projects."** — `extra-EM1421`, sugli esempi di progetto. Gli esempi sono
   ispirazione, non uno stampo.
5. **I blocchi di codice nelle slide sono una base e un punto di riferimento, ma il codice del
   progetto può — e di fatto deve — essere più ampio.** Non è una concessione che ci prendiamo:
   è la conseguenza dei quattro punti sopra, e c'è un precedente esplicito. Il criterio 05
   della guida del docente cita come esempio di buona metodologia un progetto passato che
   scrive: *"The analysis used R and included several steps: 1. Text Vectorization — reports
   were converted to numerical form using TF-IDF. 2. Clustering — K means (k = 4) grouped
   reports into major themes."* Né TF-IDF né k-means sono nel codice delle slide. Un altro
   esempio citato lì giustifica l'uso della media invece della mediana su una distribuzione a
   coda grassa e il logaritmo con il +1: ragionamento statistico assente dalle slide.
6. **Per i metodi, il punto di riferimento sono i contenuti delle slide.** Vedi §4.

Nessun documento del corso limita il codice a quello mostrato a lezione. Verificato su
`EM1421_projectsInstructions.txt`, `writing_your_project.txt`, `extra-EM1421.txt` e su tutte
le lezioni.

---

## 2. Cosa danno le slide: il codice come base

Misurato su tutti i PDF delle lezioni. **L'unico pacchetto caricato in tutto il corso è
`igraph`**, cinque volte. `library(ggplot2)` non appare mai: `ggplot` compare una sola volta
in tutto `docs/`, ed è nel **nostro** brief. I grafici delle slide sono in R base.

Quello che le slide coprono, per compito:

| Compito | Cosa danno le slide |
|---|---|
| Costruire un grafo | `graph_from_data_frame`, `graph.edgelist`, `graph_from_incidence_matrix`, `graph`, `graph_from_literal`, `make_*` |
| Attributi | `V()$x`, `E()$x`, `vertex_attr`, `edge_attr`, `set_*_attr`, `simplify` con `edge.attr.comb` |
| Leggere dati | `read.csv()` di CSV di nodi e archi. **Nient'altro.** |
| Pesi da archi multipli | un pattern con `aggregate()` (5a slide 53) |
| Struttura | `degree`, `degree_distribution`, `diameter`, `mean_distance`, `distances`, `shortest_paths`, `edge_density`, `reciprocity`, `dyad_census`, `triad_census`, `transitivity` |
| Centralità | `centr_degree`, `closeness`/`centr_clo`, `betweenness`/`edge_betweenness`/`centr_betw`, `evcent`, `hub_score`, `authority_score` |
| Comunità | `edge.betweenness.community` e `sizes()` — **solo questo** |
| Bipartiti | `graph_from_incidence_matrix`, `bipartite.projection`, `layout_as_bipartite` |
| Ridurre la rete | `induced.subgraph` (lez. 6, criterio sostantivo), `delete_edges` su soglia di peso (5b slide 61) |
| Grafici | `plot.igraph`, i `layout_*`, `hist`, `heatmap`, `legend`, `heat.colors`, `rainbow`, `colorRampPalette`, `quantile`+`cut` per binnare, `pdf()`/`dev.off()`, `set.seed` |

Elenco completo delle funzioni, con il codice esatto mostrato a lezione, in
`MATERIALE_CORSO.md` §6 e §10.

**Come usiamo questa base.** Per ogni misura di rete che il progetto calcola, se esiste la
funzione mostrata a lezione usiamo quella, con lo stesso nome e gli stessi argomenti delle
slide. Non è conformismo: è ciò che rende il codice difendibile all'orale in dieci secondi
invece che in tre minuti.

**Attenzione all'API vecchia.** Le slide usano nomi dell'API di igraph precedenti alla
versione 2: `evcent`, `edge.betweenness.community`, `bipartite.projection`,
`graph_from_incidence_matrix`, `graph.edgelist`, `get.adjacency`. Su igraph 2.x questi nomi
funzionano ancora ma emettono avvisi di deprecazione, e i nomi correnti sono
`eigen_centrality`, `cluster_edge_betweenness`, `bipartite_projection`,
`graph_from_biadjacency_matrix`, `graph_from_edgelist`, `as_adjacency_matrix`.
**Non verificato sulla nostra macchina: igraph non è ancora installato** (controllato il
27/10/2026: R 4.5.1, `ggplot2` 4.0.0, `data.table` 1.17.8, `igraph` e `backbone` assenti).
Da appurare al primo run. Regola: nel codice usiamo i nomi che funzionano senza avvisi sulla
versione che installiamo, e se divergono da quelli delle slide mettiamo il nome delle slide
nel commento, così il docente riconosce la funzione. Esempio:

```r
# comunita con Girvan-Newman (slide: edge.betweenness.community)
com <- cluster_edge_betweenness(g)
```

---

## 3. Cosa dobbiamo scrivere noi

Tutto ciò che sta fra il file scaricato e la riga di dati pronta per `igraph`. Le slide
partono da CSV già puliti di nodi e archi; noi partiamo da due file in formato proprietario
con duplicati, etichette in conflitto e date mancanti.

| Serve al progetto | Nelle slide | Dove lo scriviamo |
|---|---|---|
| Leggere record di 7 righe `CAMPO:valore` da `.gz`, 198.275 voti | no | `R/01_read_raw.R` |
| Parsare i blocchi di wiki-Elec (righe `E`, `T`, `U`, `N`, `V`) | no | `R/01_read_raw.R` |
| Normalizzare gli username | no | `R/01_read_raw.R` |
| Deduplicare i voti con una regola dichiarata | no | `R/02_build_attempts.R` |
| Parsare date e ore, differenze in giorni, soglia di separazione | no | `R/02_build_attempts.R` |
| Ricostruire i tentativi (candidato, numero, apertura, chiusura, esito, flag) | no: solo `aggregate` su un peso | `R/02_build_attempts.R` |
| Unire tabelle (voti × tentativi, tentativi × esiti validati) | no | `R/02`, `R/03` |
| Misurare l'errore della ricostruzione contro wiki-Elec | no | `R/03_validate_outcomes.R` |
| Costruire la rete per finestra temporale (tutto fino all'apertura di t+1) | no | `R/04_build_networks.R` |
| Randomizzazione ripetuta per il modello nullo | no: il test di omofilia è spiegato a parole, senza codice | `R/05_measure_change.R` |
| Sovrapposizione fra insiemi di sostenitori (Jaccard / neighborhood overlap) | la formula sì, il codice no | `R/05_measure_change.R` |
| Correlazione fra predittori prima di modellare | il pattern sì (`cor`, lez. 6 slide 34) | `R/05` o `R/06` |
| Regressione logistica | no, e non è nel programma (vedi `MATERIALE_CORSO.md` §12) | `R/06_model_outcome.R` |
| Figure con `ggplot2` | no | `R/07_figures.R` |

Questo codice è **infrastruttura**, non metodo: nessuno ci chiederà se `aggregate`, `merge` o
`data.table` sono "da programma". Quello che va difeso sono le scelte di metodo del §4.

---

## 4. Per i metodi il riferimento restano le slide

La libertà del §1 vale sull'implementazione, non sulla sostanza. Il criterio di scelta, in
ordine:

1. **Se il corso insegna il metodo, usiamo quello.** Comunità: `cluster_edge_betweenness`
   (Girvan-Newman) è l'unico algoritmo insegnato. Brokerage: betweenness, embeddedness,
   neighborhood overlap. Centralità: quelle della lezione 5a/6. Modello nullo: la
   riassegnazione casuale del test di omofilia (lez. 4) e la baseline di Kossinets & Watts.
2. **Se il corso non lo insegna ma serve, lo usiamo e scriviamo la riga di giustificazione.**
   Criterio 05 della guida: *"a one-line reason for choosing it over the obvious
   alternative"*. Riguarda la regressione logistica, il pacchetto `backbone`, e qualunque
   `cluster_*` diverso da edge betweenness.
3. **Se una scelta rende il risultato garantito per costruzione, non si usa.** Criterio 06:
   *"never use as predictor a variable that enters the definition of the outcome"*,
   *"if a model works almost perfectly, suspect leakage first"*, *"would I get this result
   even with random data?"*.

Vincoli già noti, da `MATERIALE_CORSO.md` §11, che toccano il codice:

- **Girvan-Newman non gira sulla proiezione di co-voto intera** (11.381 votanti): le slide lo
  dichiarano adatto a poche migliaia di nodi. La via dentro il programma è `induced.subgraph`
  con un criterio sostantivo (lez. 6 slide 10-13), non il campionamento casuale. Il criterio
  va scritto nel codice **e** nel report.
- `layout_with_fr` è raccomandato fino a ~1.000 nodi: le figure di rete vanno su un sottografo,
  con `set.seed()`.
- `evcent` decade in fretta: se la usiamo, binnarla come nella lezione 6 (slide 26-30).

Fuori programma, da giustificare o evitare: `cluster_louvain` e gli altri `cluster_*`,
`constraint` (vincoli di Burt), `assortativity`, `similarity`, il pacchetto `backbone`,
qualunque cosa di `ergm`/`statnet`.

---

## 5. "A code that can be tested by the instructor": requisiti concreti

Il §5 delle istruzioni è una promessa verificabile. Tradotta in requisiti:

1. **Percorsi relativi alla radice del repo.** Mai un percorso assoluto, mai
   `setwd("/Users/umbertotoraldo/...")`. Si eseguono gli script dalla radice; i percorsi si
   compongono con `file.path()`. Già impostato in `R/00_paths.R`.
2. **Nessuna installazione automatica.** Gli script non chiamano `install.packages()`: il
   docente decide cosa installare sulla sua macchina. I pacchetti necessari vanno dichiarati
   in `README.md` e nell'intestazione di ogni script.
3. **Nessuna chiamata di rete.** Il download dei dati SNAP non è dentro gli script: i file
   stanno in `data/raw/` e sono committati, come chiede "include all external files necessary
   to run the code". Se SNAP cambia o va offline, il codice gira comunque.
4. **Errore chiaro invece di errore oscuro.** Se un file manca, si ferma con un messaggio che
   dice quale file e dove prenderlo (`stop_if_missing()` in `R/00_paths.R`), non con
   "cannot open connection".
5. **Ordine di esecuzione esplicito e lineare.** Script numerati, ciascuno legge da
   `data/processed/` ciò che il precedente ha scritto. Nessuna dipendenza implicita
   dall'ambiente: niente variabili create a mano in console, niente `.RData` salvato.
6. **Seed fissato** dove c'è casualità: layout force-directed, randomizzazioni del modello
   nullo, qualunque campionamento. `set.seed()` all'inizio dello script, non sparso.
7. **Esecuzione pulita da sessione vuota.** Il test è: `Rscript R/0X_....R` uno dopo l'altro
   in una sessione nuova, da terminale, su una macchina dove non abbiamo mai lavorato. Se
   serve qualcosa che abbiamo in memoria, non gira.
8. **Tempi ragionevoli.** Se un passo è lento (Girvan-Newman, randomizzazioni ripetute), va
   scritto nel commento in testa allo script quanto ci mette e, se ha senso, salvato il
   risultato in `data/processed/` così i passi successivi non lo ricalcolano.
9. **Commenti adeguati**: cosa fa il blocco e perché quella scelta, non la parafrasi della
   riga. Il codice commentato è nella consegna; la **descrizione** del codice nel report è
   vietata (§3.1). Due destinazioni diverse: la motivazione tecnica sta nel commento, quella
   metodologica nel report senza nominare funzioni.
10. **`sessionInfo()`** registrato una volta in `data/processed/` o in `report/`, così si sa
    con quali versioni i numeri del report sono stati prodotti.

---

## 6. Convenzioni del repo

- **Un file per passo**, numerato `00`–`07`, eseguibile in ordine. Nuovi passi: nuovo numero,
  non un file che fa due cose.
- **`data/raw/` è di sola lettura.** Ogni script scrive solo in `data/processed/` o `output/`.
- **Intestazione obbligatoria** in ogni script: cosa fa, input, output, pacchetti richiesti,
  e le decisioni ancora aperte se è uno scheletro.
- **Nessun numero magico nel corpo del codice.** Soglie e parametri (la soglia dei giorni, il
  numero di randomizzazioni, i tagli) stanno in costanti con nome in testa allo script, così
  si vedono e si cambiano in un posto.
- **Niente output nel repo che non sia riproducibile** dagli script: `data/processed/` e
  `output/figures/` si rigenerano.
- **Regola "no leakage" nel codice, non solo nel report.** Le variabili di t+1 e quelle
  precedenti a t+1 stanno in oggetti separati e con nomi che lo dicono (per esempio prefissi
  `pre_` e `post_`). Non si costruisce un unico data frame da cui poi "si ricorda" di
  escludere colonne: è così che la leakage entra.
- **Nomi in inglese** per oggetti e colonne (`attempts`, `votes`, `support_share`), commenti
  in italiano. Coerente con i dati e con il report.
- **Il codice si rivede a vicenda** (punto D della divisione del lavoro): chi non ha scritto
  uno script lo esegue da sessione pulita prima di considerarlo finito.

---

## 7. Idiomi R per ciò che le slide non coprono

Infrastruttura, non metodo: ogni scelta sostantiva è lasciata come segnaposto. Da adattare,
non da copiare a occhi chiusi.

**Leggere un formato a record non tabellare** (è il pattern già in `R/01_read_raw.R`): si
legge tutto, si separano chiave e valore, si apre un record a ogni ricomparsa del primo
campo, si rimodella in largo.

```r
lines <- readLines(gzfile(path), warn = FALSE, encoding = "UTF-8")
keys  <- sub(":.*$", "", lines)
vals  <- sub("^[A-Z]{3}:", "", lines)
rec   <- cumsum(keys == "SRC")        # ogni SRC apre un nuovo record
```

**Parsare blocchi delimitati** (wiki-Elec): stessa idea, con `split()` sull'indice di blocco.

```r
blocco <- cumsum(keys == "E")
per_elezione <- split(data.frame(keys, vals), blocco)
```

**Date**: `as.POSIXct()` con il formato esplicito e `tz = "UTC"`, mai il parsing automatico.
Differenze con `difftime(..., units = "days")`, che è esplicito su cosa restituisce.

```r
dat <- as.POSIXct(x, format = "%H:%M, %d %B %Y", tz = "UTC")
gap <- as.numeric(difftime(dat[-1], dat[-length(dat)], units = "days"))
```

**Aprire un nuovo gruppo quando il salto supera una soglia** — lo scheletro della
ricostruzione dei tentativi, con la soglia come costante:

```r
SOGLIA_GIORNI <- NA_real_   # DECISIONE APERTA: da tarare su wiki-Elec 2003-2007
nuovo_tentativo <- c(TRUE, gap > SOGLIA_GIORNI)
id_tentativo    <- cumsum(nuovo_tentativo)
```

**Tenere un solo record per chiave** (voti cambiati dallo stesso votante): ordinare e prendere
l'ultimo, con la regola scritta nel commento.

```r
# regola: a parita di votante e tentativo si tiene il voto piu recente
v <- v[order(v$attempt_id, v$voter, v$dat), ]
v <- v[!duplicated(v[, c("attempt_id", "voter")], fromLast = TRUE), ]
```

**Sovrapposizione fra due insiemi di sostenitori** (è il neighborhood overlap della lezione 3,
slide 47-50):

```r
jaccard <- function(a, b) length(intersect(a, b)) / length(union(a, b))
```

**Modello nullo per randomizzazione**: la statistica osservata, poi B ripetizioni con
l'etichetta mescolata, poi la posizione dell'osservato nella distribuzione nulla. La slide 19
della lezione 4 chiede esattamente questo ("one needs a definition of significantly less of").

```r
set.seed(1)
B <- 1000
oss  <- statistica(dati)
nulla <- replicate(B, statistica(transform(dati, gruppo = sample(gruppo))))
c(osservato = oss, media_nulla = mean(nulla),
  p_empirico = (1 + sum(nulla <= oss)) / (B + 1))
```

**Correlazione fra predittori prima di modellare** (il pattern della lezione 6, slide 34, che
il criterio 06 impone):

```r
cor(features$in_degree_pre, features$n_voters_t, use = "complete.obs")
```

**Figure**: `ggplot2` con salvataggio esplicito di dimensioni e dpi, così la figura nel report
è quella che abbiamo visto.

```r
p <- ggplot(d, aes(x = gruppo, y = valore)) +
  geom_boxplot(outlier.shape = NA) +          # il box nasconde: i punti sopra
  geom_jitter(width = 0.15, alpha = 0.5) +    # deck dataviz, slide 9 e 16
  labs(x = NULL, y = "...", caption = NULL) +
  theme_minimal(base_size = 11)
ggsave(file.path(DIR_FIGURES, "fig1.png"), p, width = 7, height = 4.5, dpi = 300)
```

**Figura di rete** (sottografo, seed fissato, layout calcolato una volta):

```r
set.seed(1)
h <- induced_subgraph(g, nodi_scelti)        # criterio sostantivo, non casuale
l <- layout_with_fr(h)                        # raccomandato fino a ~1.000 nodi
pdf(file.path(DIR_FIGURES, "fig2.pdf"), 7, 7)
plot(h, layout = l, vertex.label = NA, vertex.size = 4)
dev.off()
```

Per confrontare due reti nella stessa figura, **lo stesso oggetto `l`** per entrambe
(lez. 5b slide 67), altrimenti il confronto visivo non significa nulla.

---

## 8. Mappa degli script

| Script | Cosa usa delle slide | Cosa aggiunge |
|---|---|---|
| `00_paths.R` | — | percorsi relativi, controllo dei file mancanti |
| `01_read_raw.R` | — | parser dei due formati SNAP, normalizzazione username, conteggi di controllo (attesi 198.275 voti e 11.381 utenti) |
| `02_build_attempts.R` | l'idea di `aggregate` | deduplica, date, soglia, ricostruzione dei tentativi, schema `attempts` e `votes` |
| `03_validate_outcomes.R` | — | confronto con wiki-Elec, tasso di errore della ricostruzione, controllo a mano dei 29, conteggio dei voti senza data |
| `04_build_networks.R` | `graph_from_data_frame`, `graph_from_incidence_matrix`, `bipartite_projection`, `simplify`, `induced_subgraph`, `delete_edges` | finestra temporale, separazione sostegno/opposizione, trattamento dei voti neutri, riduzione della rete con criterio dichiarato |
| `05_measure_change.R` | `degree`, `betweenness`, `transitivity`, `cluster_edge_betweenness`, `sizes`, `cor` | Jaccard fra insiemi di sostenitori, randomizzazione del modello nullo, separazione `pre_`/`post_` |
| `06_model_outcome.R` | `cor` | regressione logistica (fuori programma, da giustificare), raggruppamento per candidato, conteggio degli eventi per variabile |
| `07_figures.R` | `plot.igraph`, `layout_with_fr`, `set.seed`, `pdf`/`dev.off` | `ggplot2`, `ggsave`, le regole del deck di data visualization |

---

## 9. Checklist prima della consegna

Sul codice (il report ha la sua, nei criteri 01-08 della guida del docente):

- [ ] da una cartella clonata pulita, `Rscript R/01...` fino a `R/07...` in ordine, senza errori
- [ ] nessun percorso assoluto, nessun `setwd()`, nessun `install.packages()`, nessuna chiamata di rete
- [ ] i due file SNAP sono in `data/raw/` e committati, con le dimensioni attese
- [ ] ogni script ha intestazione con input, output e pacchetti
- [ ] soglie e parametri sono costanti con nome, non numeri sparsi
- [ ] `set.seed()` dove c'è casualità
- [ ] `sessionInfo()` salvato
- [ ] i numeri del report coincidono con quelli che gli script stampano (criterio 03: "with numbers that agree with each other")
- [ ] ogni figura del report è prodotta da `R/07_figures.R`, non ritoccata a mano
- [ ] l'altro ha eseguito il codice da sessione pulita (revisione incrociata, punto D)
- [ ] il report non contiene codice né descrizione del codice (§3.1)
- [ ] nessun username di Wikipedia citato nel report

---

## 10. Rischi noti

1. **Girvan-Newman che non termina.** Non lanciarlo sulla proiezione intera "per vedere".
   Prima la riduzione con criterio sostantivo, poi il conteggio di nodi e archi, poi
   l'algoritmo. Se non torna in tempi utili, è il segnale che il criterio di riduzione va
   rivisto, non che serve più pazienza.
2. **Leakage per comodità.** Un unico data frame con tutte le variabili e poi "ricordarsi" di
   escludere quelle di t+1 nella formula del modello. Oggetti separati, prefissi diversi.
3. **Numeri che divergono fra codice e report.** Succede quando una soglia cambia e il report
   non viene rigenerato. Ogni numero del report deve esistere come output di uno script.
4. **Il parser che sembra funzionare.** 198.275 voti e 11.381 utenti sono i totali pubblicati
   da SNAP: se `01_read_raw.R` ne stampa altri, il parser è rotto, non i dati. I conteggi di
   controllo sono già nello script.
5. **Avvisi di deprecazione di igraph** presi per errori, o il contrario. Al primo run si
   decide la lista dei nomi da usare e si resta su quella (vedi §2).
6. **Figure ritoccate a mano.** Non riproducibili, e il docente esegue il codice.
