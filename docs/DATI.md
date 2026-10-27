# Data workstream: cosa consegno, com'è fatto, come ci sono arrivato

Stato al 27/10/2026. Prodotto da `R/01_read_raw.R`, `R/02_build_attempts.R`,
`R/03_validate_outcomes.R` (funzioni condivise in `R/00_lib_data.R`), solo R base.
Eseguibili in ordine dalla radice del repo.

Principio seguito in tutto: **non filtrare, segnalare.** Ogni riga problematica resta
nella tabella con una colonna-bandiera, così chi analizza decide cosa escludere. Le uniche
righe perse sono 806 voti senza data non attribuibili, contate sotto.

---

## 1. Le due tabelle consegnate

### `data/processed/votes.rds` — 196.842 righe, una per voto validato

| Colonna | Tipo | Contenuto |
|---|---|---|
| `vote_id` | integer | id del voto nel file grezzo, per risalire alla fonte |
| `src` | character | votante, grafia SNAP con gli spazi in coda rimossi |
| `tgt` | character | candidato, stessa normalizzazione |
| `vot` | integer | **−1 contrario, 0 neutro, 1 favorevole** |
| `res` | integer | esito del tentativo: −1 respinto, 1 approvato |
| `yea` | integer | anno dichiarato da SNAP. **Non affidabile**, vedi §4 |
| `dat` | POSIXct (UTC) | data e ora del voto; `NA` se imputato |
| `dat_missing` | logical | il voto non aveva data nel file grezzo |
| `attempt_id` | integer | **chiave di join con `attempts`** |
| `attempt_no` | numeric | numero del tentativo dentro il candidato, in ordine di apertura |
| `dat_imputed` | logical | voto senza data attribuito al tentativo per via indiretta (§5) |

### `data/processed/attempts.rds` — 4.082 righe, una per tentativo

| Colonna | Tipo | Contenuto |
|---|---|---|
| `attempt_id` | integer | chiave primaria |
| `candidate` | character | candidato |
| `attempt_no` | numeric | 1, 2, 3… in ordine di apertura |
| `outcome` | integer | −1 respinto, 1 approvato |
| `yea` | integer | anno SNAP (non affidabile) |
| `opened_at`, `closed_at` | POSIXct | primo e ultimo voto del tentativo |
| `n_votes` | integer | voti validati |
| `n_support`, `n_oppose`, `n_neutral` | integer | scomposizione per segno |
| `support_share` | numeric | `n_support / (n_support + n_oppose)`. **I neutri non sono nel denominatore**: è una convenzione dichiarata, non l'unica possibile |
| `duration_days` | numeric | `closed_at − opened_at` |
| `flag_short` | logical | meno di 5 voti: possibile frammento (330 casi) |
| `flag_long` | logical | più di 14 giorni: più lungo di una RfA normale (4 casi) |
| `flag_year_clash` | logical | un altro tentativo dello stesso candidato, anno ed esito esiste (374 casi): sospetto di spezzatura |
| `prev_outcome` | integer | esito del tentativo precedente dello stesso candidato, `NA` al primo |

### `data/processed/attempts_validated.rds` — gli stessi tentativi più il confronto con wiki-Elec

Aggiunge `elec_matched` (logical), `elec_outcome`, `elec_closed_at`, `outcome_agrees`.
858 tentativi su 4.082 hanno un riscontro in wiki-Elec.

### File di appoggio

- `03_soglia_sweep.csv` — la griglia soglia × regola con tutte le metriche (§6).
- `03_match_wikielec.csv` — una riga per elezione di wiki-Elec, con distanza e esito.
- `username_case_variants.csv` — i 137 gruppi di grafie, per la decisione aperta (§7).
- `02_log.txt`, `03_log.txt` — il registro delle quantità, da cui pescare i numeri del report.

---

## 2. Quello che avevo all'inizio

Due file compressi da SNAP, checksum SHA-256 in `data/raw/SHA256SUMS.txt`:

- **wiki-RfA** (14.970.777 byte): 198.275 voti in record di 7 righe `CAMPO:valore`
  separati da riga vuota. Nessun identificativo del tentativo: è la cosa da ricostruire.
- **wiki-Elec** (1.090.375 byte): 2.794 elezioni già separate in blocchi, con esito e data
  di chiusura, da **set 2004 a gen 2008**.

Verificati i totali pubblicati da SNAP: 198.275 voti **esatto**, 11.381 utenti distinti
**esatto** (ma solo col trim, §3), 2.794 elezioni **esatto**, 1.248 promozioni e 1.546
respinte (SNAP dichiara ~1.200 e ~1.500).

**Correzione al documento di contesto:** wiki-Elec non copre il 2003–2007 ma il
**17/09/2004 – 06/01/2008**.

---

## 3. I difetti dei dati e come li ho risolti

Sei problemi, tutti trovati misurando, non per prudenza generica.

**(a) Spazi in coda agli username — wiki-RfA.** 21 nomi hanno uno spazio finale
(`"Dream Focus "`, `"Peripitus "`). Senza `trimws()` i nodi distinti sono 11.402 invece di
11.381. È il difetto che Mihretab aveva segnalato; il trim fa parte della definizione dei
nodi, non è una pulizia opzionale.
**Effetto collaterale trovato:** le coppie votante–candidato distinte sono 189.003 col trim
e 189.004 senza, perché una sola coppia (`December21st2012Freak → Jeffrey Mall`) compare con
due grafie. Quindi **i totali pubblicati da SNAP non sono coerenti fra loro**: 11.381 è
post-trim, 189.004 è pre-trim. Da dichiarare nella sezione dati del report.

**(b) Codifica di wiki-Elec.** 19 righe su 128.017 non sono UTF-8 valido, tutte dello stesso
utente (sequenza troncata). `substr()` si ferma con "stringa multibyte non valida". Risolto
scartando i byte invalidi con `iconv(sub = "")`. **Attenzione:** convertire tutto da
ISO-8859-1 "funziona" ma è sbagliato, perché rovina i nomi che erano UTF-8 corretto
(`anárion` → `anÃ¡rion`).

**(c) Terminatori CRLF in wiki-Elec.** 128.016 righe su 128.017. Senza togliere il `\r`
l'ultimo campo di ogni riga — che è proprio lo username — si porta dietro un carattere
invisibile e nessun join funziona. wiki-RfA invece non ha CRLF.

**(d) Grafie diverse fra i due file.** wiki-Elec è **tutto minuscolo** e usa
**underscore** dove wiki-RfA usa lo **spazio** (408 nomi con underscore e 0 con spazio,
contro 0 e 606 in wiki-RfA). Normalizzando (`norm_user()`: trim, underscore→spazio,
minuscolo) i candidati di wiki-Elec ritrovati in wiki-RfA passano dal **74,9% all'89,5%**.

**(e) Date.** Formato `"HH:MM, DD Month YYYY"`, ma: **9.367 voti (4,72%) senza data**;
25.680 con il mese abbreviato; e **3 con il mese scritto male nella fonte** (`Janry`,
`Julu`, `Mya`). Un parser con `format = "%d %B %Y"` dipenderebbe da `LC_TIME` — quindi
darebbe risultati diversi sulla macchina del docente — e trasformerebbe in `NA` senza dire
niente 25.683 date. Risolto con una tabella dei mesi esplicita, indipendente dal locale.
Dopo la correzione: **0 date presenti e non interpretabili**.
In wiki-Elec, 11 voti hanno anni impossibili (2061–2105).

**(f) Righe identiche e voti ripetuti.** 595 righe interamente identiche. E 627 voti rimossi
perché lo stesso votante compare più volte nello stesso tentativo: **regola adottata, si
tiene il voto più recente**, perché l'ipotesi più plausibile è che abbia cambiato voto, e
in quel caso il duplicato è segnale, non rumore (Olteanu §3.7: *"redundancy can also be a
signal by itself"*).

---

## 4. Peculiarità da sapere prima di usare le tabelle

**`yea` non è affidabile.** 1.875 voti (0,99%) hanno la data in un anno diverso da quello
dichiarato da `YEA`, e non isolati: a blocchi coerenti (es. `Scienceman123`, `YEA` 2008, voti
datati marzo 2006; `Jor`, `YEA` 2007, voti datati marzo 2004). Le **date** sono coerenti, è
`YEA` a sbagliare. Per questo la ricostruzione **non usa l'anno**, al contrario del
precedente pubblico di Kołczyńska che raggruppa per candidato, anno ed esito.

**La rete di voto non è bipartita.** 10.417 votanti, 3.497 candidati, unione 11.381:
**2.533 utenti sono entrambe le cose**, cioè il 72,4% dei candidati ha votato almeno una
volta nelle RfA altrui (mediana 19 voti dati, massimo 1.232). 964 candidati non hanno mai
votato. È questa proprietà a rendere misurabile il grado uscente di un candidato.

**Code pesanti.** Voti dati per votante: mediana 3, media 19, **massimo 1.661**. Voti
ricevuti per candidato: mediana 41, media 56,7, massimo 987. Un votante presente in 1.661
elezioni è co-votante di quasi tutti: va tenuto presente sia per i modelli nulli, che vanno
pesati per l'attività, sia per la densità della proiezione di co-voto.

**Segno dei voti.** 144.451 favorevoli (72,9%), 41.176 contrari (20,8%), **12.648 neutri
(6,4%)**. I neutri non sono trascurabili: sono in tabella con `vot = 0` e la decisione su
cosa farne è di chi analizza.

---

## 5. La ricostruzione dei tentativi: la regola e perché questa

**Regola adottata (`res_then_gap`):** si raggruppa per (candidato, `res`) e dentro ogni
gruppo si apre un nuovo tentativo quando il salto fra due voti consecutivi supera **7
giorni**. I voti senza data non si possono ordinare, quindi restano fuori e vengono
attribuiti dopo.

**Regola scartata (`gap_then_res`):** ordinare per data dentro il candidato e aprire un
tentativo al cambio di `res` oppure al superamento della soglia. Sembra più naturale ed è
sbagliata: un singolo voto con `res` diverso infilato dentro un'elezione la spezza in tre.
Produceva **1.420 tentativi da un solo voto**, concentrati su 95 candidati — per esempio
`ABCD`, quattro "tentativi" in una settimana di marzo 2005 con esito alternato
−1, 1, −1, 1. A parità di soglia: 1.678 tentativi con meno di 5 voti contro 330, ed errore
medio sul conteggio dei tentativi di 0,69 contro 0,071.

Il confronto fra le due regole è esso stesso un risultato ed è in
`03_soglia_sweep.csv`.

**Attribuzione dei voti senza data.** Si attribuiscono solo quando l'attribuzione è univoca:
il candidato ha un solo tentativo con quell'anno e quell'esito. **8.562 su 9.368 attribuiti**,
**806 persi** — le uniche righe che si perdono in tutta la pipeline. Sono marcati
`dat_imputed = TRUE`: chi analizza può escluderli, e per le finestre temporali probabilmente
deve.

---

## 6. La soglia non è assunta, è scelta sui dati

wiki-Elec contiene 2.794 elezioni già separate con data di chiusura: è verità a terra. Ho
provato **2 regole × 17 soglie** (da 1 a 60 giorni) e misurato, sul periodo coperto:
la quota di elezioni ritrovate, la concordanza dell'esito, e la concordanza del **numero di
tentativi per candidato**.

Risultato: `res_then_gap` domina su ogni metrica, e la concordanza del conteggio è massima
al 93,6% ma **il plateau va da 5 a 35 giorni**. Cioè la ricostruzione è **insensibile alla
soglia** in quella fascia: è un risultato di robustezza, e la ragione per tenere 7 giorni,
che è il valore del precedente pubblico e la durata nominale di una RfA.

**Validazione degli esiti: 99,54% di concordanza** sulle elezioni ritrovate (4 discordanti
su 869).

**Il limite grosso, da dichiarare nel report.** Solo il **31%** delle elezioni di wiki-Elec
si ritrova in wiki-RfA con la chiusura entro un giorno (869 su 2.794; 273 elezioni hanno un
candidato che in wiki-RfA non compare affatto). La copertura per anno di chiusura è 40% nel
2004, 43% nel 2005, 25% nel 2006, 31% nel 2007, 38% nel 2008. I volumi di voto dei due file
sono comparabili, quindi non è una questione di scala: **wiki-RfA non è un soprainsieme di
wiki-Elec**. Conseguenza: la validazione riguarda 858 tentativi su 4.082, e sul **2008–2013
non esiste alcuna validazione**.

---

## 7. Decisioni aperte, che non prendo da solo

**(a) Varianti di sola iniziale maiuscola.** Su Wikipedia la prima lettera di uno username è
sempre maiuscola, quindi `harej` e `Harej` sono **lo stesso account**. SNAP non le unifica:
il totale di 11.381 le tiene separate. Unificandole i nodi scendono a **11.244**. Ci sono
**137 gruppi** (elenco in `username_case_variants.csv`); in 90 la persona è candidata sotto
almeno una grafia, e in **8 lo stesso candidato compare con due grafie diverse**, in anni
diversi: Dustihowe 2007/2008, Imdanumber1 2006/2007, Kylekieran 2009/2011, Maltesedog
2005/2006, Tdxiang 2005/2006, Xiner 2006/2007, più Alexsautographs e Nenyedi nello stesso
anno.
**Se non si unificano, quegli 8 risultano due persone distinte con un tentativo ciascuna e
cadono fuori dai candidati ripetuti.** Cambia la popolazione dello studio e l'insieme dei
nodi della rete, quindi è una decisione di entrambi i ruoli. Nel codice è il parametro
`UNIFICA_INIZIALE` in `R/02_build_attempts.R`, ora `FALSE` (si resta sul conteggio SNAP).
La mia proposta: unificare, dichiarandolo come scostamento da SNAP e riportando i due
conteggi.

**(b) Il denominatore di `support_share`.** Ora esclude i neutri. Alternativa: includerli.

**(c) Cosa escludere.** I tentativi con `flag_short`, `flag_long`, `flag_year_clash` e i voti
con `dat_imputed` sono in tabella, non filtrati. La decisione su cosa tenere è di chi
analizza, e il numero degli esclusi va nel report.

---

## 8. Divergenza dai numeri del brief

| | Brief | Qui | Rapporto |
|---|---|---|---|
| Candidati ripetuti | 414 | **484** | 1,17 |
| Previously rejected | 394 | **445** | 1,13 |
| Previously successful | 29 | **53** | 1,83 |
| Coppie di tentativi consecutivi | non dichiarato | **614** | — |

I numeri del brief non sono mai stati riprodotti da nessuno, nemmeno dal gruppo (documento
di contesto §10), quindi la divergenza non è di per sé un errore di una parte o dell'altra.
Ma va riconciliata, e il gruppo dei "previously successful" è il più divergente — coerente
con il sospetto, già nel contesto, che quel gruppo sia in parte un artefatto della
ricostruzione. La mia regola è esplicita, parametrica e validata al 99,5% sugli esiti dove
la validazione è possibile: è il punto di partenza per il confronto, non una verità.

Da chiarire con chi ha prodotto il 414: con quale regola di separazione dei tentativi, con
quale trattamento dei duplicati, e se gli username erano normalizzati.
