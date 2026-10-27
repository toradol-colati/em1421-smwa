# Data workstream — documentazione completa

Stato al 27/10/2026. Prodotto da `R/01_read_raw.R` → `R/02_build_attempts.R` →
`R/03_validate_outcomes.R`, funzioni condivise in `R/00_lib_data.R`, solo R base, nessuna
dipendenza. Eseguibili in quest'ordine dalla radice del repo.

**Indice**
- [Parte I — I dati iniziali](#parte-i--i-dati-iniziali)
  - [1. Che cosa registrano questi dati](#1-che-cosa-registrano-questi-dati)
  - [2. Provenienza: la catena in quattro passaggi](#2-provenienza-la-catena-in-quattro-passaggi)
  - [3. File primario: `wiki-RfA.txt.gz`](#3-file-primario-wiki-rfatxtgz)
  - [4. File di validazione: `wikiElec.ElecBs3.txt.gz`](#4-file-di-validazione-wikielecelecbs3txtgz)
  - [5. Che cosa nei dati NON c'è](#5-che-cosa-nei-dati-non-cè)
  - [6. Perché le due ricostruzioni non combaciano](#6-perché-le-due-ricostruzioni-non-combaciano)
- [Parte II — Le elaborazioni](#parte-ii--le-elaborazioni)
  - [7. I nove difetti dei dati: problema, perché andava risolto, come, e cosa sarebbe successo altrimenti](#7-i-nove-difetti-dei-dati)
  - [8. La ricostruzione dei tentativi](#8-la-ricostruzione-dei-tentativi)
  - [9. La scelta della soglia](#9-la-scelta-della-soglia)
  - [10. La validazione](#10-la-validazione)
- [Parte III — L'output](#parte-iii--loutput)
  - [11. Le tabelle consegnate, colonna per colonna](#11-le-tabelle-consegnate-colonna-per-colonna)
  - [12. Caratteristiche strutturali da sapere prima di usarle](#12-caratteristiche-strutturali-da-sapere-prima-di-usarle)
- [Parte IV — Quel che resta](#parte-iv--quel-che-resta)
  - [13. Problemi ancora da risolvere](#13-problemi-ancora-da-risolvere)
  - [14. Questioni aperte, da decidere insieme](#14-questioni-aperte-da-decidere-insieme)
  - [15. Problemi che permangono e diventano limiti dichiarati](#15-problemi-che-permangono-e-diventano-limiti-dichiarati)
  - [16. Divergenza dai numeri del brief](#16-divergenza-dai-numeri-del-brief)
  - [17. Errori miei, trovati rivedendo il lavoro](#17-errori-miei-trovati-rivedendo-il-lavoro)

---

# Parte I — I dati iniziali

## 1. Che cosa registrano questi dati

**Elezioni ad amministratore di Wikipedia**, le *Requests for Adminship* (RfA).

Il meccanismo generatore: un utente viene candidato, oppure si autocandida, ad avere i poteri
di amministratore; si apre una pagina di discussione dove la comunità scrive **Support**,
**Oppose** o **Neutral** con un commento; dopo circa una settimana un *bureaucrat* la chiude e
decide se promuovere.

Da questo meccanismo discendono due proprietà che vincolano tutta l'interpretazione:

1. **Non è un'urna, è una discussione.** I voti sono pubblici, firmati e in ordine
   cronologico: chi vota vede chi ha già votato e cosa ha scritto. Da qui discende un **bias
   normativo** (conformità, *herding*), che non è un dettaglio ma una minaccia alla validità
   di costrutto: un arco di co-voto può riflettere conformità al voto già visibile anziché
   affinità fra i due votanti.
2. **La decisione finale non è un conteggio meccanico.** Il *bureaucrat* valuta il consenso,
   non applica una soglia aritmetica. Quindi `support_share` è un **indicatore** dell'esito,
   non la sua causa aritmetica.

**Avvertenza sulle fonti.** Il funzionamento della chiusura e la durata di circa sette giorni
sono **conoscenza di contesto**, non fatti leggibili o verificabili nei file. Se finiscono nel
report vanno citati da una fonte esterna. Dai file si leggono soltanto: i voti, il loro segno,
le loro date, l'esito, e i commenti.

## 2. Provenienza: la catena in quattro passaggi

```
Wikipedia
   └─> pagine RfA (testo pubblico, modificabile, archiviabile, cancellabile)
         └─> due gruppi di ricercatori di Stanford
             che le hanno raschiate e trasformate in file strutturati,
             in due momenti diversi e per due lavori diversi
               └─> SNAP — Stanford Network Analysis Project,
                   il repository di dataset di rete di Jure Leskovec
                     └─> noi, con i checksum SHA-256 in data/raw/SHA256SUMS.txt
```

Conseguenza da tenere presente in tutto il resto del documento: **non sono dati nostri e non
sono dati di Wikipedia.** Sono **due ricostruzioni di terzi**, fatte in momenti diversi
(un dump del gennaio 2008 per l'una, pagine lette fino al maggio 2013 per l'altra) e per
scopi diversi (reti con segno per l'una, sentiment nei commenti per l'altra). È questa la
ragione strutturale per cui in alcuni punti non combaciano, e il §6 misura esattamente in che
modo e di quanto.

**Verificabilità.** I due file sono in `data/raw/`, committati, con i checksum. Dimensioni
attese: 14.970.777 byte per wiki-RfA, 1.090.375 per wiki-Elec.

## 3. File primario: `wiki-RfA.txt.gz`

**Fonte:** West, R., Paskov, H. S., Leskovec, J. & Potts, C. (2014). *"Exploiting Social
Network Structure for Person-to-Person Sentiment Analysis"*. Transactions of the Association
for Computational Linguistics 2: 297–310.

**Scopo originale:** studiare il **sentiment** espresso nei commenti, non le ricandidature.
Noi lo usiamo per una domanda diversa dalla loro, che è esattamente ciò che le istruzioni del
corso consentono: *"you can rely on available datasets, provided that the research question
underlying the analysis is original"*.

**Unità di riga: il voto, non l'elezione.** Ogni voto è un record di **sette righe**
`CAMPO:valore`, e i record sono separati da una riga vuota. Il primo record del file,
letteralmente:

```
SRC:Steel1943
TGT:BDD
VOT:1
RES:1
YEA:2013
DAT:23:13, 19 April 2013
TXT:'''Support''' as co-nom.
```

| Campo | Contenuto | Dominio osservato |
|---|---|---|
| `SRC` | *source*: lo username di **chi vota** | 10.417 valori distinti |
| `TGT` | *target*: lo username del **candidato** | 3.497 valori distinti |
| `VOT` | il **voto**: `-1` contrario, `0` neutro, `1` favorevole | solo questi tre valori |
| `RES` | il **risultato dell'elezione**: `-1` respinta, `1` approvata. **Ripetuto identico su ogni voto della stessa elezione**, non è un attributo del voto | 74.987 righe a −1, 123.288 a 1 |
| `YEA` | l'**anno di apertura** dichiarato dell'elezione | 2003–2013. **Inaffidabile**, vedi §7(g) |
| `DAT` | **data e ora del voto**, formato `"HH:MM, DD Month YYYY"` | 9.367 vuoti, vedi §7(e) |
| `TXT` | il **commento** che accompagna il voto, testo libero | mediana 98 caratteri |

**Numerosità verificate sul file** (non prese dalla pagina SNAP, ricalcolate da noi):

| Grandezza | Valore | Confronto con quanto dichiara SNAP |
|---|---|---|
| Voti | **198.275** | 198.275, coincide |
| Utenti distinti (unione votanti e candidati) | **11.381** | 11.381, coincide — **ma solo applicando il trim**, §7(a) |
| Coppie votante–candidato distinte | **189.003** | SNAP dichiara 189.004, che è il conteggio **pre-trim**, §7(a) |
| Votanti distinti | 10.417 | — |
| Candidati distinti | 3.497 | — |
| Copertura temporale | **2003 – maggio 2013** | coincide |

**Copertura parziale agli estremi:** 155 voti nel 2003 e 3.348 nel 2013. Gli anni pieni sono
2004–2012. Il precedente pubblico di Kołczyńska scarta per questo il 2003 e il 2013.

**I commenti sono sostanziosi**, e questo apre una possibilità che però non usiamo: mediana 98
caratteri, media 172, massimo 7.610; solo il **3,6%** è vuoto; 162.939 su 198.275 contengono
un marcatore in grassetto del tipo `'''Support'''`. Un'analisi testuale sarebbe tecnicamente
possibile, ma non è nella domanda approvata.

## 4. File di validazione: `wikiElec.ElecBs3.txt.gz`

**Fonte:** Leskovec, J., Huttenlocher, D. & Kleinberg, J. (2010). *"Signed Networks in Social
Media"* (CHI) e *"Predicting Positive and Negative Links in Online Social Networks"* (WWW).
L'intestazione del file stesso rimanda al primo dei due.

**Costruito da un dump di Wikipedia del 3 gennaio 2008**, per studiare le **reti con segno**.

**A che cosa ci serve, esattamente.** Alla tua domanda «è l'unica ragione per cui questo file
ci serve?» la risposta è **no, le ragioni sono tre, e derivano tutte dalla stessa proprietà**
— qui le elezioni sono **già separate**, mentre in wiki-RfA no:

1. **Scegliere** la regola e la soglia di ricostruzione dei tentativi, confrontando le nostre
   ricostruzioni con elezioni di cui si conosce il confine (§9). Non solo validarle: scegliere.
2. **Validare gli esiti** in modo indipendente dalla fonte primaria (§10).
3. **Misurare l'errore** della nostra ricostruzione, cioè quantificare quante elezioni
   spezziamo o fondiamo per sbaglio. Senza un secondo file questo numero non esisterebbe e
   dovremmo dichiarare la ricostruzione come non verificata.

**Struttura: blocchi, uno per elezione, campi separati da tabulazione.** Il primo blocco del
file, letteralmente:

```
E	1
T	2004-09-21 01:15:53
U	30	cjcurrie
N	32	andyl
V	1	3	2004-09-14 16:26:00	ludraman
V	-1	25	2004-09-14 16:53:00	blankfaze
V	1	4	2004-09-14 17:08:00	gzornenplatz
V	0	26	2004-09-14 22:18:00	grunt
...
```

| Riga | Contenuto | Note |
|---|---|---|
| `E` | **esito**: `1` promosso, `0` non promosso | nessun valore mancante |
| `T` | **data di chiusura** dichiarata dell'elezione | **inaffidabile**, vedi §7(i) |
| `U` | **candidato**: id numerico e username | 2.391 candidati distinti |
| `N` | **proponente**: id numerico e username | **inutilizzabile**, vale letteralmente `UNKNOWN` in **2.117 elezioni su 2.794** (76%); autonomine dichiarate: 85 |
| `V` | un **voto** per riga: segno, id del votante, data e ora, username | 114.040 righe |

**Numerosità verificate sul file:**

| Grandezza | Valore | Confronto con quanto dichiara SNAP |
|---|---|---|
| Elezioni | **2.794** | 2.794, coincide |
| Voti | **114.040** | ~100.000, coerente |
| Votanti distinti | **6.210** | ~7.000, coerente |
| Promozioni / respinte | **1.248 / 1.546** | ~1.200 / ~1.500, coerente |
| Voti per elezione | mediana **34**, da 1 a 370 | — |
| Segno dei voti | 83.962 favorevoli, 23.118 contrari, 6.960 neutri | — |

**Il periodo: alla tua domanda «siamo sicuri?»** Sì per quello che è verificabile, ma la
formulazione va corretta, perché la risposta dipende da *quale* campo si guarda:

- Le **chiusure dichiarate** (`T`) vanno dal **17/09/2004 00:41** al **06/01/2008 02:18**,
  senza valori mancanti e senza nessuna chiusura prima di settembre 2004. Questo è misurato.
- Ma i **voti** cominciano prima: il più antico è del **28/03/2004**. Un'elezione chiusa a
  settembre 2004 contiene voti di marzo 2004, quindi dire "il file copre da settembre 2004" è
  falso se si parla di voti.
- E soprattutto: `T` è un campo **inaffidabile** (§7(i)), quindi qualunque affermazione sul
  periodo basata su `T` è fragile. L'affermazione solida è: **i voti vanno dal 28/03/2004 al
  06/01/2008**, con 11 voti che hanno anni impossibili (2061, 2063, 2064, 2065, 2067, 2070,
  2074, 2086, 2096, 2105) e vanno scartati.

**In ogni caso la correzione al documento di contesto resta valida e va fatta:** il periodo
**non è il 2003–2007**. Wikipedia ha avuto RfA dal 2003, ma questo file non le contiene.

## 5. Che cosa nei dati NON c'è

**(a) Nessun identificativo del tentativo in wiki-RfA.** È il buco che definisce tutto il
lavoro di questo workstream: 198.275 voti e nessun campo che dica quali appartengono alla
stessa elezione. Senza ricostruirlo il progetto non esiste, perché la domanda approvata parla
di candidati **ripetuti**.

Alla tua domanda «ma per sapere quali appartengono alla stessa elezione basta ricostruirlo
dalle date, giusto?»: **no, "basta" è troppo generoso, e per tre ragioni.**
1. Le date da sole non bastano: serve una **regola di raggruppamento**. Due elezioni dello
   stesso candidato possono avere voti vicinissimi nel tempo, e i loro voti nel file sono
   mescolati. La regola che funziona raggruppa per (candidato, `RES`) e *poi* usa il salto
   temporale; quella che sembra naturale, cioè scorrere le date e spezzare al cambio di `RES`,
   produce disastri misurabili (§8).
2. Serve una **soglia**, che è un parametro libero: va scelta, e io l'ho scelta confrontando
   il risultato con le elezioni vere (§9).
3. Il **4,7% dei voti non ha data**, `YEA` è inaffidabile, e alcune elezioni si sovrappongono
   nel tempo. Il risultato finale concorda con le elezioni vere nel 94,6% dei candidati
   confrontabili, non nel 100%: **resta un errore residuo, misurato ma non nullo.**

**(b) Nessun attributo dei candidati.** Non ci sono numero di contributi, anzianità, aree di
lavoro, uso delle *edit summary*.

Alla tua domanda «ma non dovrebbe essere un problema, giusto?»: **per la fattibilità no, come
limite sì, e va dichiarato con la direzione.** Non è un problema perché la nostra domanda è
sulla posizione di rete, non sul merito del candidato; e non potremmo né dovremmo replicare
Burke & Kraut, che usavano proprio quegli attributi. Ma è un **confondente non osservato**:
se i candidati più esperti hanno al tempo stesso una posizione di rete migliore e più
probabilità di passare, l'associazione che troveremo fra rete ed esito è **gonfiata verso
l'alto**. Il criterio 08 chiede esattamente questo: nominare il limite, dire quale risultato
minaccia e in quale direzione. Burke & Kraut 2008 è la citazione che dimostra che quegli
attributi contano.

**(c) Nessuna data di apertura o chiusura ufficiale in wiki-RfA.**

Alla tua domanda «`opened_at` e `closed_at` nelle mie tabelle sono il primo e l'ultimo voto,
che è un'approssimazione, ma approssimazione fatta da chi, e come?»: **l'ho fatta io**, nella
funzione `costruisci_attempts()` in `R/00_lib_data.R`, e consiste in questo: per ogni
tentativo, `opened_at` è il **minimo** e `closed_at` il **massimo** delle date dei voti di
quel tentativo. Niente di più sofisticato. Due conseguenze, e la seconda è spiacevole:

- `duration_days` è per costruzione **una sottostima** della durata vera: l'elezione si apre
  prima del primo voto e si chiude dopo l'ultimo.
- **Non posso quantificare l'errore di questa approssimazione.** L'unico riferimento esterno
  sarebbe `T` di wiki-Elec, che è inaffidabile (§7(i)): confrontando il mio `closed_at` con
  `T` otterrei scarti con mediana di circa cento giorni, ma misurerebbero il difetto di `T`,
  non il mio. Quindi l'approssimazione resta dichiarata e non misurata. Vedi §15.

**(d) Nessuna relazione sociale dichiarata.** Nessuna parentela, nessuna amicizia, nessun
*follow*. Qualunque rete costruiremo è fatta di **comportamenti** — chi ha votato chi — non di
legami sociali. Un voto non è un'amicizia, e la nostra rete non è "la rete sociale di
Wikipedia". Olteanu et al. 2019 §3.5 documenta che reti da legami dichiarati e reti da
interazioni hanno proprietà strutturali diverse: è la citazione da mettere accanto a questo
limite.

## 6. Perché le due ricostruzioni non combaciano

Questa sezione risponde alla tua richiesta di non liquidare la cosa con "in alcuni punti non
combaciano". Ecco di quanto e in che modo, misurato.

**Il metodo per confrontarle.** Appaiare un'elezione di wiki-Elec a un tentativo ricostruito da
wiki-RfA **per insieme di votanti**, non per data: si calcola la sovrapposizione di Jaccard
fra i due insiemi di votanti e si tiene il tentativo con la sovrapposizione massima. Due
elezioni diverse della stessa persona hanno votanti molto diversi, quindi il criterio le
distingue; e non dipende da nessun campo data, quindi non è contaminato dall'inaffidabilità
di `T`.

**Risultato: i due file descrivono in gran parte le stesse elezioni.**

| Misura | Valore |
|---|---|
| Elezioni di wiki-Elec appaiate a un tentativo (Jaccard > 0,5) | **2.168 su 2.794 — 77,6%** |
| Con criterio più permissivo (Jaccard > 0,3) | **2.352 — 84,2%** |
| Elezioni il cui candidato non compare affatto in wiki-RfA | **273 — 9,8%** |
| Jaccard mediano sulle appaiate | **0,666** |
| Tentativi miei che assorbono due elezioni distinte | **1** |

**Dove non combaciano: non sulle elezioni, sui singoli votanti.** Per la stessa elezione i due
file concordano sulla *dimensione* e divergono sulla *composizione*:

- mediana di 41 votanti per elezione in wiki-Elec, 39 nel mio tentativo appaiato;
- il numero di votanti è **identico in 1.296 elezioni** su 2.168; wiki-Elec ne ha di più in
  483 casi (22%), di meno in 389 (18%); rapporto mediano esattamente 1;
- ma **wiki-Elec ha in mediana 8 votanti che io non ho, e io ne ho 9 che wiki-Elec non ha**,
  su circa 41. Il disaccordo è **simmetrico** e vale circa un quinto dei nomi.

**Le cause plausibili del disaccordo**, in ordine di quanto sono sostenute:

1. **Momenti di raccolta diversi, su pagine che cambiano.** wiki-Elec viene da un dump del
   3 gennaio 2008, wiki-RfA da pagine lette fino a maggio 2013. Nel frattempo le pagine RfA
   vengono archiviate, spostate, rinominate, a volte cancellate, e i voti barrati o ritirati
   vengono riscritti. Due letture a cinque anni di distanza danno liste diverse. *Ipotesi
   coerente con i dati, non verificata direttamente.*
2. **Scopi diversi, quindi scelte di parsing diverse.** Chi cercava il sentiment ha tenuto il
   commento e la grafia originale dello username; chi costruiva reti con segno ha normalizzato
   i nomi in minuscolo e con underscore, e ha tenuto l'id numerico. Le due normalizzazioni
   sono incompatibili e vanno riconciliate a mano (§7(d)).
3. **La mia ricostruzione contribuisce.** I miei tentativi sono ricostruiti, quindi qualche
   voto può finire nel tentativo adiacente; e 806 voti senza data li ho persi (§7(e)). Parte
   dei "9 che io non ho" è mia responsabilità, non loro.
4. **I 273 candidati assenti** sono un'assenza vera: elezioni che wiki-RfA non contiene in
   nessuna forma.

**Conclusione, che corregge una mia affermazione precedente.** Avevo scritto che wiki-RfA non
è un soprainsieme di wiki-Elec e che il 61% delle elezioni mancava. **Era sbagliato**, ed era
un artefatto dell'appaiamento per data: wiki-RfA contiene la grande maggioranza delle elezioni
di wiki-Elec (77,6% appaiate con criterio stretto, 84,2% con criterio permissivo), e
l'assenza vera riguarda il 9,8%. Dettagli in §17.

---

# Parte II — Le elaborazioni

## 7. I nove difetti dei dati

Per ciascuno: che cos'è, **perché andava risolto**, come l'ho risolto, e **cosa sarebbe
successo se non l'avessi risolto**. Tutti trovati misurando, non per prudenza generica.

### (a) Spazi in coda agli username — wiki-RfA

**Che cos'è.** 21 nomi hanno uno spazio finale: `"Dream Focus "`, `"Peripitus "`,
`"Matthewrbowker "`, `"Noetica "`.

**Perché andava risolto.** Lo username *è* l'identità del nodo. Due grafie dello stesso nome
sono due nodi diversi per qualunque libreria di rete.

**Come.** `trimws()` su `SRC` e `TGT` in `read_rfa()`.

**Cosa sarebbe successo altrimenti.** I nodi distinti sarebbero 11.402 invece di **11.381**,
cioè il totale pubblicato da SNAP. Nelle reti, 21 persone comparirebbero sdoppiate, con il
grado spezzato fra le due copie. È il difetto che Mihretab aveva segnalato.

**Effetto collaterale, che è un risultato.** Le coppie votante–candidato distinte sono 189.003
col trim e **189.004** senza, perché una sola coppia — `December21st2012Freak → Jeffrey Mall` —
compare con due grafie che differiscono per gli spazi. Quindi **i totali pubblicati da SNAP
non sono coerenti fra loro**: 11.381 utenti è un conteggio post-trim, 189.004 coppie è
pre-trim. Va dichiarato nella sezione dati del report, dove il criterio 03 chiede numeri che
concordino fra loro.

### (b) Codifica di wiki-Elec

**Che cos'è.** 19 righe su 128.017 non sono UTF-8 valido, e sono **tutte dello stesso utente**:
una sequenza troncata, `eivind_f_<c3>yangen` invece di `eivind_f_øyangen`.

**Perché andava risolto.** `substr()` si ferma con *"stringa multibyte non valida"* e il file
non si legge affatto.

**Come.** `iconv(from = "UTF-8", to = "UTF-8", sub = "")`, che scarta i byte invalidi e
conserva tutto il resto.

**Cosa sarebbe successo altrimenti — e qui c'è una trappola in cui sono caduto.** La prima
soluzione che ho scritto convertiva tutto il file da ISO-8859-1, perché `iconv -f ISO-8859-1`
sul file riesce mentre `iconv -f UTF-8` fallisce. **Funziona e è sbagliata:** reinterpretare
come latin1 i byte che erano UTF-8 corretto rovina tutti i nomi accentati, `anárion` diventa
`anÃ¡rion`. Me ne sono accorto solo perché quel nome è comparso in una lista di candidati non
appaiati. Sarebbe passata inosservata e avrebbe prodotto nodi fantasma.

### (c) Terminatori di riga CRLF in wiki-Elec

**Che cos'è.** 128.016 righe su 128.017 finiscono in `\r\n`. wiki-RfA, per confronto, non ha
CRLF da nessuna parte.

**Perché andava risolto.** L'ultimo campo di ogni riga è proprio lo **username**, quindi ogni
nome si porta dietro un carattere invisibile.

**Come.** `sub("\r$", "", lines)` subito dopo la lettura, prima di qualunque parsing.

**Cosa sarebbe successo altrimenti.** **Nessun join fra i due file avrebbe funzionato**, e il
sintomo sarebbe stato "wiki-Elec e wiki-RfA non hanno utenti in comune", che si legge
facilmente come un fatto sui dati invece che come un bug. La validazione sarebbe risultata
impossibile.

### (d) Grafie incompatibili fra i due file

**Che cos'è.** wiki-Elec scrive gli username **tutti in minuscolo** e usa l'**underscore**
dove wiki-RfA usa lo **spazio**: 408 nomi con underscore e 0 con spazio in wiki-Elec, contro
0 con underscore e 606 con spazio in wiki-RfA.

**Perché andava risolto.** Stesso motivo di (c): senza riconciliare le grafie i due file non
si parlano.

**Come.** `norm_user()` in `R/00_lib_data.R`: `trimws`, poi underscore → spazio, poi
`tolower`. Usata **solo per il confronto fra i file**, non per riscrivere l'identità dentro
wiki-RfA.

**Cosa sarebbe successo altrimenti.** I candidati di wiki-Elec ritrovati in wiki-RfA sarebbero
il **74,9%** invece dell'**89,5%**; un quarto delle elezioni sarebbe risultato non validabile
per una ragione tipografica.

### (e) Voti senza data

**Che cos'è.** **9.367 voti su 198.275, il 4,72%**, hanno il campo `DAT` vuoto. Toccano 2.154
candidati distinti.

**Perché andava risolto.** La ricostruzione dei tentativi si basa sui salti temporali: un voto
senza data non si può ordinare, quindi non si può assegnare a un tentativo per via diretta.

**Come.** Restano fuori dalla ricostruzione e vengono attribuiti dopo, **solo quando
l'attribuzione è univoca**: il candidato ha un solo tentativo con quell'anno e quell'esito.
Così **8.562 sono attribuiti** e **806 persi** — le uniche righe che si perdono in tutta la
pipeline. I primi sono marcati `dat_imputed = TRUE` e restano distinguibili.

**Cosa sarebbe successo altrimenti.** Scartandoli tutti si perdeva il 4,7% dei voti, con
effetto non uniforme: cadono su 2.154 candidati, quindi avrebbero ridotto il conteggio dei
voti di alcuni tentativi in modo sistematico, falsando `support_share` e il numero di
votanti — che sono due variabili dell'analisi. Attribuendoli tutti a forza, invece, si
sarebbero inquinati i tentativi con voti non verificabili.

### (f) Mesi scritti in modi diversi, e tre scritti male

**Che cos'è.** Il formato di `DAT` è `"HH:MM, DD Month YYYY"`, ma **25.680 voti** usano il mese
abbreviato (`Jan`, `Feb`, …) e **3 hanno il mese scritto male nella fonte**: `Janry`, `Julu`,
`Mya`.

**Perché andava risolto.** Due ragioni, e la seconda è più grave della prima. Primo, un
parser che accetta solo il nome pieno perde 25.683 date. Secondo, `format = "%d %B %Y"`
dipende da **`LC_TIME`**, cioè dalla lingua configurata sulla macchina: lo stesso codice darebbe
risultati diversi sul computer del docente, che deve poter eseguire tutto.

**Come.** Una tabella dei mesi esplicita — nomi pieni, abbreviazioni e i tre errori — e la
costruzione della data in formato ISO, indipendente dal locale. In `parse_dat()`.

**Cosa sarebbe successo altrimenti.** 25.683 date trasformate in `NA` **in silenzio**, cioè il
13,6% dei voti datati. Quei voti sarebbero finiti fra i "senza data", l'attribuzione li
avrebbe in parte dispersi, e la ricostruzione dei tentativi avrebbe lavorato su un file bucato
senza che nessuno lo notasse. Dopo la correzione: **0 date presenti e non interpretabili**.

### (g) `YEA` non è affidabile

**Che cos'è.** **1.875 voti, lo 0,99%,** hanno la data in un anno diverso da quello dichiarato
da `YEA`, e non sono casi isolati: arrivano a **blocchi coerenti**. `Scienceman123` ha
`YEA` 2008 e voti datati marzo 2006; `Jor` ha `YEA` 2007 e voti datati marzo 2004; `Danny` ha
`YEA` 2007 e voti datati gennaio 2004. Le differenze sono −3, −2, −1 e +1 anni.

**Perché andava risolto.** Il precedente pubblico di Kołczyńska raggruppa per candidato,
**anno** ed esito. Se l'anno sbaglia a blocchi, quel raggruppamento spezza elezioni intere.

**Come.** La ricostruzione **non usa `YEA`**: raggruppa per (candidato, `RES`) e usa le date.
`YEA` resta in tabella come campo informativo, con l'avvertenza.

**Cosa sarebbe successo altrimenti.** Le elezioni di quei candidati sarebbero state spezzate
in due pezzi assegnati ad anni diversi, creando candidati falsamente "ripetuti" — che è
esattamente la popolazione che lo studio seleziona. Avremmo studiato artefatti.

**Dove `YEA` però resta inevitabile.** L'attribuzione dei voti senza data (§7(e)) usa la chiave
(candidato, `YEA`, esito), perché un voto senza data non ha nient'altro con cui essere
collocato. Rischio quantificato: fra i voti datati lo 0,99% ha `YEA` sbagliato; applicando la
stessa proporzione, **circa 85 degli 8.562 voti attribuiti possono finire nel tentativo
sbagliato**. Non è eliminabile senza le date. È un'altra ragione per escludere i
`dat_imputed` dalle analisi sensibili al tempo.

### (h) Righe identiche e voti ripetuti dello stesso votante

**Che cos'è.** **595 righe interamente identiche** (stesso votante, candidato, voto, esito,
anno, data). E, dopo la ricostruzione, **627 casi** in cui lo stesso votante compare più volte
nello stesso tentativo.

**Perché andava risolto.** Un votante che compare due volte conta due volte nel grado, nel
numero di votanti e in `support_share`; e nella rete crea un arco multiplo che va collassato.

**Come.** Si tiene **il voto più recente** del votante in quel tentativo. La regola è
dichiarata perché non è neutrale: l'ipotesi è che il votante abbia **cambiato voto**, e in quel
caso il duplicato è segnale, non rumore — Olteanu et al. 2019 §3.7 lo dice esplicitamente,
*"redundancy can also be a signal by itself"*.

**Cosa sarebbe successo altrimenti.** Il brief prevedeva di "deduplicare" senza specificare
come: tenendo il **primo** voto invece dell'ultimo si registrerebbe l'opinione che il votante
ha poi abbandonato, cioè il contrario del suo giudizio finale. Non tenendone conto affatto,
627 voti doppi gonfierebbero i conteggi.

### (i) `T` di wiki-Elec non è la data di chiusura

**Che cos'è.** Il campo `T` dovrebbe essere la chiusura dell'elezione. Confrontandolo con
**l'ultimo voto della stessa elezione, dentro lo stesso file**, lo scarto ha **mediana 102
giorni**; il **54%** delle elezioni ha `T` oltre 30 giorni dopo il proprio ultimo voto;
**1.217** oltre 180 giorni; e il minimo è **−188 giorni**, cioè alcune elezioni hanno `T`
*prima* del proprio ultimo voto. Lo si vede anche da un'incoerenza interna: il **78% delle
elezioni risulta chiuso nel 2007**, mentre i voti sono distribuiti su 2005, 2006 e 2007
(21.240, 44.702, 43.896).

**Perché andava risolto.** Perché è il campo su cui avevo basato tutta la validazione.

**Come.** L'appaiamento fra elezioni vere e tentativi ricostruiti **non usa più le date**: usa
la sovrapposizione degli insiemi di votanti (§6, §10).

**Cosa sarebbe successo altrimenti — ed è successo, prima di accorgermene.** La copertura
risultava del 36% invece del 78%; comparivano 23 "sotto-spezzature" invece di 1; e concludevo
a torto che wiki-RfA non contenesse le elezioni di wiki-Elec, scrivendolo come limite del
progetto. Un limite inventato è peggio di un limite non trovato. Vedi §17.

---

## 8. La ricostruzione dei tentativi

**La regola adottata — `res_then_gap`.** Si raggruppa per (**candidato**, **`RES`**) e dentro
ogni gruppo, ordinando per data, si apre un nuovo tentativo quando il salto fra due voti
consecutivi supera **7 giorni**. I voti senza data non partecipano e vengono attribuiti dopo
(§7(e)). Implementata in `ricostruisci_tentativi()`, `R/00_lib_data.R`.

Perché `RES` serve a raggruppare: `RES` è una proprietà dell'**elezione**, ripetuta su ogni
suo voto. Quindi due voti dello stesso candidato con `RES` diverso appartengono per forza a
due elezioni diverse, e raggruppare per `RES` separa automaticamente due elezioni vicine con
esito opposto, anche se i loro voti nel file sono mescolati.

**La regola scartata — `gap_then_res`.** Ordinare per data dentro il candidato e aprire un
tentativo al cambio di `RES` **oppure** al superamento della soglia. È la regola che sembra più
naturale, ed è quella che avevo scritto per prima. È sbagliata: un **singolo** voto con `RES`
diverso infilato dentro un'elezione la spezza in **tre** pezzi.

Il caso che me l'ha fatto capire è il candidato `ABCD`: quattro "tentativi" in una settimana di
marzo 2005, con esito alternato −1, 1, −1, 1, di cui uno composto da un solo voto. A parità di
soglia le due regole danno:

| | `gap_then_res` | `res_then_gap` |
|---|---|---|
| Tentativi ricostruiti | 5.402 | **4.082** |
| Tentativi con meno di 5 voti | 1.678 | **330** |
| Tentativi da **un solo voto** | 1.420, concentrati su 95 candidati | **pochi** |
| Tentativi preceduti da un successo | 729 | **56** |

I 1.420 tentativi da un voto solo sono il sintomo diagnostico: una regola che produce
millequattrocento elezioni da un voto su un file di 198.275 voti non sta ricostruendo
elezioni. Il confronto fra le due regole è in `03_soglia_sweep.csv` ed è esso stesso un
risultato da riportare: mostra che la scelta della regola conta molto più della scelta della
soglia.

## 9. La scelta della soglia

**La soglia non è assunta, è scelta sui dati.** wiki-Elec contiene 2.794 elezioni già
separate: è verità a terra. Ho provato **2 regole × 17 soglie**, da 1 a 60 giorni, e misurato
per ciascuna combinazione le elezioni appaiate, la concordanza dell'esito, le sotto-spezzature,
i frammenti, e la concordanza del **numero di tentativi per candidato**. Tutto in
`03_soglia_sweep.csv`.

**Il risultato è un compromesso piatto, non un massimo netto.** Con `res_then_gap`:

| Soglia | Elezioni appaiate | Conteggio dei tentativi esatto |
|---|---|---|
| 4 giorni | 1.949 | 94,3% |
| **7 giorni** | **1.947** | **94,6%** |
| 21 giorni | 1.947 | 94,8% |
| 60 giorni | 1.899 | 95,5% |

La concordanza del conteggio cresce con la soglia, perché fondere riduce le spezzature; ma le
elezioni appaiate **calano**, perché fondere distrugge elezioni distinte. **Fra 4 e 21 giorni
entrambe le metriche sono piatte: la scelta non è guidata dai dati, ed è questo il risultato
di robustezza da riportare.** Si tiene **7 giorni**, che è il valore del precedente pubblico
di Kołczyńska e la durata nominale di una RfA.

*Nota tecnica sui numeri di questa tabella:* lo sweep lavora sulla ricostruzione grezza, senza
deduplica e senza i voti senza data attribuiti, perché serve a confrontare regole e soglie fra
loro. I numeri della validazione finale (§10) sono più alti perché lì i voti attribuiti
rientrano e alzano le sovrapposizioni.

La concordanza del conteggio è calcolata **solo sui candidati le cui elezioni di wiki-Elec sono
tutte appaiate**. Calcolarla su tutti — come facevo in una prima versione — la gonfia con
accordi casuali: un candidato di cui wiki-RfA non ha l'elezione giusta ma ne ha un'altra
risulta "1 contro 1" e viene contato come concorde. Vedi §17(a).

## 10. La validazione

Con la regola `res_then_gap`, soglia 7 giorni, e appaiamento per insiemi di votanti:

| Misura | Valore |
|---|---|
| Elezioni di wiki-Elec appaiate (Jaccard > 0,5) | **2.168 su 2.794 — 77,6%** |
| **Concordanza dell'esito** | **99,45%** — 12 discordanti su 2.168 |
| Jaccard mediano sulle appaiate | 0,666 |
| Tentativi che assorbono due elezioni (sotto-spezzatura) | **1** |
| Tentativi con riscontro esterno | **2.167 su 4.082 — 53%** |
| Candidati di wiki-Elec assenti da wiki-RfA | 273 — 9,8% |

**Che cosa è validato e che cosa no.** È validato l'**esito** (al 99,45%) e, implicitamente,
la separazione dei tentativi, perché un'elezione si appaia solo se il mio tentativo ha
sostanzialmente i suoi stessi votanti. **Non** è validata: la durata, perché non ho una
chiusura ufficiale affidabile (§5(c), §7(i)); e nulla dal **2008 al 2013**, perché wiki-Elec
finisce in gennaio 2008 — e quel periodo è quasi metà dei nostri voti.

---

# Parte III — L'output

## 11. Le tabelle consegnate, colonna per colonna

### `data/processed/votes.rds` — 196.842 righe, una per voto validato

| Colonna | Tipo | Contenuto |
|---|---|---|
| `vote_id` | integer | posizione del voto nel file grezzo, per risalire alla fonte |
| `src` | character | votante, grafia SNAP con gli spazi in coda rimossi |
| `tgt` | character | candidato, stessa normalizzazione |
| `vot` | integer | **−1** contrario, **0** neutro, **1** favorevole |
| `res` | integer | esito del tentativo: −1 respinto, 1 approvato |
| `yea` | integer | anno dichiarato da SNAP. **Inaffidabile**, §7(g) |
| `dat` | POSIXct, UTC | data e ora del voto; `NA` se il voto era senza data |
| `dat_missing` | logical | il voto non aveva data nel file grezzo |
| `attempt_id` | integer | **chiave di join con `attempts`** |
| `attempt_no` | numeric | numero del tentativo dentro il candidato, in ordine di apertura |
| `dat_imputed` | logical | voto senza data attribuito al tentativo per via indiretta, §7(e) |

Da 198.275 voti grezzi a 196.842: 627 rimossi come voti ripetuti dello stesso votante nello
stesso tentativo (§7(h)) e 806 persi perché senza data e non attribuibili (§7(e)).

### `data/processed/attempts.rds` — 4.082 righe, una per tentativo

| Colonna | Tipo | Contenuto |
|---|---|---|
| `attempt_id` | integer | chiave primaria |
| `candidate` | character | candidato |
| `attempt_no` | numeric | 1, 2, 3… in ordine di apertura |
| `outcome` | integer | −1 respinto, 1 approvato |
| `yea` | integer | anno SNAP, inaffidabile |
| `opened_at` | POSIXct | **primo voto** del tentativo, non l'apertura ufficiale — §5(c) |
| `closed_at` | POSIXct | **ultimo voto** del tentativo, non la chiusura ufficiale — §5(c) |
| `n_votes` | integer | voti validati |
| `n_support`, `n_oppose`, `n_neutral` | integer | scomposizione per segno |
| `support_share` | numeric | `n_support / (n_support + n_oppose)`. **I neutri non sono nel denominatore**: convenzione dichiarata, non l'unica possibile — §14(b) |
| `duration_days` | numeric | `closed_at − opened_at`, quindi **sottostima** della durata vera |
| `flag_short` | logical | meno di 5 voti: possibile frammento — **333 casi** |
| `flag_long` | logical | più di 14 giorni: più lungo di una RfA normale — **4 casi** |
| `flag_year_clash` | logical | esiste un altro tentativo dello stesso candidato, stesso anno (preso dalla **data**, non da `yea`) e stesso esito: sospetto di spezzatura — **359 casi** |
| `prev_outcome` | integer | esito del tentativo precedente dello stesso candidato; `NA` al primo |

### `data/processed/attempts_validated.rds` — gli stessi 4.082 tentativi, più il riscontro esterno

Aggiunge `elec_matched` (logical), `elec_outcome`, `elec_jaccard`, `outcome_agrees`.
**2.167 tentativi su 4.082** hanno un riscontro in wiki-Elec.

### File di appoggio

| File | Contenuto |
|---|---|
| `03_soglia_sweep.csv` | la griglia 2 regole × 17 soglie con tutte le metriche |
| `03_match_wikielec.csv` | una riga per elezione di wiki-Elec: esito, `T`, ultimo voto, Jaccard, tentativo appaiato |
| `username_case_variants.csv` | i 137 gruppi di grafie che differiscono solo per l'iniziale, §14(a) |
| `02_log.txt`, `03_log.txt` | il registro di tutte le quantità, da cui pescare i numeri del report |

**Principio seguito in tutto l'output: non filtrare, segnalare.** Ogni riga problematica resta
in tabella con una colonna-bandiera, così la decisione su cosa escludere la prende chi
analizza, non chi pulisce, e il numero degli esclusi è disponibile per il report. In
particolare la tabella **non** è ristretta ai candidati ripetuti: se lo fosse, si perderebbero
i voti che un candidato ha **dato** nelle RfA altrui fra un tentativo e l'altro, che secondo
il §8.2 del documento di contesto sono l'unica informazione davvero nuova su un ripresentato.

## 12. Caratteristiche strutturali da sapere prima di usarle

**La rete di voto non è bipartita.** 10.417 votanti, 3.497 candidati, unione 11.381:
**2.533 utenti sono entrambe le cose**, cioè il **72,4% dei candidati ha votato almeno una
volta** nelle RfA altrui — mediana 19 voti dati, terzo quartile 57, massimo 1.232. 964
candidati non hanno mai votato. È questa proprietà a rendere misurabile il **grado uscente**
di un candidato, che è la variabile pre-t+1 non collineare con il tentativo precedente.

**Le distribuzioni hanno code pesanti.** Voti dati per votante: mediana **3**, media 19,
massimo **1.661**. Voti ricevuti per candidato: mediana **41**, media 56,7, massimo 987.
Conseguenze operative: un votante presente in 1.661 elezioni è co-votante di quasi tutti,
quindi la proiezione di co-voto avrà un hub che la rende densa; i modelli nulli vanno pesati
per l'attività del votante, altrimenti sono dominati dagli occasionali; e la media come
sintesi va giustificata.

**Il segno dei voti.** 144.451 favorevoli (72,9%), 41.176 contrari (20,8%), **12.648 neutri
(6,4%)**. I neutri non sono trascurabili: sono in tabella con `vot = 0`, non eliminati.

**Densità.** N = 11.381, 189.003 archi distinti, densità 0,00146: il regime sparso della
lezione 2, slide 29–30.

---

# Parte IV — Quel che resta

## 13. Problemi ancora da risolvere

Cose che si possono chiudere con lavoro, non decisioni.

**(a) I 12 esiti discordanti** fra la mia ricostruzione e wiki-Elec, su 2.168 appaiate. Sono
in `03_match_wikielec.csv`. Vanno guardati uno per uno: se la mia ricostruzione ha fuso due
elezioni con esito diverso sono errori miei; se `RES` in wiki-RfA contraddice `E` in
wiki-Elec è un difetto delle fonti, e allora va detto nel report che le due ricostruzioni
dissentono sull'esito in 12 casi su 2.168.

**(b) Il tentativo che assorbe due elezioni.** Uno solo, identificabile in
`03_match_wikielec.csv` come due righe che puntano allo stesso `mio_attempt`. Da spezzare a
mano o da escludere.

**(c) I 333 tentativi con meno di 5 voti.** Sono bandierati, non esclusi. Vanno guardati:
alcuni saranno chiusure anticipate vere (SNOW/NOTNOW), altri frammenti della ricostruzione.
La distinzione cambia il conteggio dei candidati ripetuti.

**(d) Il parser di wiki-Elec non estrae gli id numerici** dei votanti e dei candidati, solo gli
username. Gli id sarebbero una chiave più solida dentro wiki-Elec, anche se non aiutano a
collegarsi a wiki-RfA, che non li ha.

**(e) Gli 11 voti di wiki-Elec con anni impossibili** (2061–2105) sono esclusi dai calcoli
sulle date ma non segnalati in output.

## 14. Questioni aperte, da decidere insieme

Decisioni, non lavoro. Toccano entrambi i ruoli perché cambiano sia la popolazione dello
studio sia l'insieme dei nodi della rete.

**(a) Le varianti di sola iniziale maiuscola.** Su Wikipedia la prima lettera di uno username
è **sempre** maiuscola, quindi `harej` e `Harej` sono **lo stesso account**. SNAP non le
unifica: il totale di 11.381 le tiene separate. Unificandole i nodi scendono a **11.244**.
Ci sono **137 gruppi** di grafie (elenco completo in `username_case_variants.csv`); in **90**
la persona è candidata sotto almeno una grafia; e in **8 lo stesso candidato compare con due
grafie diverse**, in anni diversi:

| Candidato | Grafie e anni |
|---|---|
| Dustihowe | 2007 e 2008 |
| Imdanumber1 | 2006 e 2007 |
| Kylekieran | 2009 e 2011 |
| Maltesedog | 2005 e 2006 |
| Tdxiang | 2005 e 2006 |
| Xiner | 2006 e 2007 |
| Alexsautographs | due grafie nello stesso anno, 2010 |
| Nenyedi | due grafie nello stesso anno, 2007 |

**Se non si unificano, quegli 8 risultano due persone distinte con un solo tentativo ciascuna
e cadono fuori dai candidati ripetuti.** Cambia la popolazione dello studio, cioè il 414 del
brief. Nel codice è il parametro `UNIFICA_INIZIALE` in `R/02_build_attempts.R`, ora `FALSE`,
cioè si resta sul conteggio SNAP. **La mia proposta è unificare**, dichiarandolo come
scostamento da SNAP e riportando entrambi i conteggi.

**(b) Il denominatore di `support_share`.** Ora esclude i 12.648 neutri. L'alternativa è
includerli. La scelta va dichiarata nel report in ogni caso.

**(c) Che cosa escludere.** `flag_short` (333), `flag_long` (4), `flag_year_clash` (359) e i
voti `dat_imputed` (8.562) sono in tabella, non filtrati. Per le analisi sensibili al tempo i
`dat_imputed` probabilmente vanno esclusi (§7(g)). Il numero degli esclusi va nel report.

**(d) Il periodo.** Kołczyńska scarta 2003 e 2013 perché coperti solo in parte (155 e 3.348
voti). Da decidere se fare lo stesso, e con quale giustificazione scritta.

## 15. Problemi che permangono e diventano limiti dichiarati

Cose che **non** si possono risolvere con questi dati. Vanno nella sezione limiti del report,
ciascuna con il risultato che minaccia e la direzione, come chiede il criterio 08.

**(a) Nessuna validazione dal 2008 al 2013.** wiki-Elec finisce il 6 gennaio 2008. Oltre quella
data la ricostruzione dei tentativi non ha nessun riscontro esterno, e quel periodo contiene
circa metà dei nostri voti. *Minaccia:* tutti i risultati che riguardano i tentativi recenti.
*Direzione:* ignota, ed è questo il punto.

**(b) La durata dei tentativi è una sottostima non quantificabile.** `opened_at` e `closed_at`
sono il primo e l'ultimo voto, approssimazione fatta da me in `costruisci_attempts()`; e non
posso misurarne l'errore, perché l'unico riferimento esterno — `T` di wiki-Elec — è
inaffidabile (§7(i)). *Minaccia:* qualunque variabile costruita sulla durata o sulla
distanza temporale fra due tentativi. *Direzione:* `duration_days` è sistematicamente
inferiore al vero.

**(c) Nessun attributo del candidato, quindi un confondente non osservato.** Non abbiamo
contributi, anzianità, aree di lavoro. *Minaccia:* l'associazione fra posizione di rete ed
esito. *Direzione:* se i candidati più esperti hanno al tempo stesso una posizione di rete
migliore e più probabilità di passare, l'associazione è **gonfiata verso l'alto**. Citazione:
Burke & Kraut 2008, che mostra che quegli attributi predicono l'esito.

**(d) Bias normativo: i voti sono pubblici e sequenziali.** Chi vota vede i voti precedenti.
*Minaccia:* la validità di costrutto delle comunità di co-voto interpretate come coalizioni, e
l'indipendenza dei voti dentro `support_share`. *Direzione:* **gonfia** la coesione apparente
delle comunità. Citazione: Olteanu et al. 2019 §4.2, che documenta conformità e *herding* in
risposta alle valutazioni già visibili.

**(e) La rete è di comportamenti, non di legami sociali.** Un voto non è un'amicizia.
*Minaccia:* ogni lettura dei risultati in termini di "relazioni sociali". Citazione: Olteanu
et al. 2019 §3.5. *Direzione:* non applicabile, è un limite di interpretazione.

**(f) I due file dissentono su circa un quinto dei votanti di ogni elezione** (§6), e il
disaccordo è simmetrico. *Minaccia:* la precisione dei conteggi per tentativo.
*Direzione:* ignota, perché simmetrica.

**(g) I totali pubblicati da SNAP non sono coerenti fra loro** (§7(a)). *Minaccia:* la
riproducibilità dichiarata nella sezione dati. *Rimedio:* dichiarare quale conteggio si usa e
perché.

**(h) Circa 85 voti potrebbero essere attribuiti al tentativo sbagliato** (§7(g)).
*Minaccia:* i conteggi dei tentativi che li contengono. *Direzione:* ignota, ma l'ordine di
grandezza è lo 0,04% dei voti.

**(i) 806 voti persi** perché senza data e non attribuibili univocamente. Sono lo 0,4% del
totale, e non sono distribuiti uniformemente: cadono sui candidati con più tentativi nello
stesso anno, cioè **proprio sui ripresentati**. *Direzione:* sottostima del numero di votanti
dei tentativi di quei candidati.

## 16. Divergenza dai numeri del brief

| | Brief | Qui | Rapporto |
|---|---|---|---|
| Candidati ripetuti (2+ tentativi) | 414 | **484** | 1,17 |
| Previously rejected | 394 | **445** | 1,13 |
| Previously successful | 29 | **53** | 1,83 |
| Coppie di tentativi consecutivi | non dichiarato | **614** | — |
| Candidati con 3+ tentativi | non dichiarato | **90** | — |

I numeri del brief non sono mai stati riprodotti da nessuno, nemmeno dal gruppo — documento
di contesto §10 — quindi la divergenza non dimostra di per sé chi abbia sbagliato. Ma va
riconciliata, e il gruppo dei *previously successful* è il più divergente, con un rapporto
quasi doppio: coerente con il sospetto, già nel contesto, che quel gruppo sia in parte un
artefatto della ricostruzione.

La mia regola è esplicita, parametrica, e validata al 99,45% sugli esiti dove la validazione
è possibile. È il punto di partenza per il confronto, non una verità.

**Da chiarire con chi ha prodotto il 414:** con quale regola di separazione dei tentativi, con
quale trattamento dei voti duplicati, con quale normalizzazione degli username, e se il 2003 e
il 2013 erano inclusi.

## 17. Errori miei, trovati rivedendo il lavoro

Li elenco perché servono a leggere i numeri di questo documento, e perché tre di essi erano
già finiti in una versione precedente della documentazione e in un messaggio a Mihretab.

**(a) La metrica su cui avevo scelto la soglia era gonfiata.** Confrontavo il numero di
tentativi per candidato su *tutti* i candidati, inclusi quelli le cui elezioni di wiki-Elec non
erano appaiate: per quelli il confronto è "1 contro 1" per caso e veniva contato come
concordanza. Dichiaravo 93,6%. Ristretto ai candidati con tutte le elezioni appaiate, il
valore vero è intorno al 94,6%. La scelta della soglia non ne dipendeva, perché il plateau
resta, ma l'affermazione misurava un'altra cosa.

**(b) Appaiavo le elezioni per data, e il campo data di wiki-Elec è inaffidabile.** È l'errore
più grave. Usavo la vicinanza fra `T` e il mio `closed_at`; poi ho misurato `T` contro
l'ultimo voto della **stessa** elezione dentro wiki-Elec e ho trovato una mediana di **102
giorni** di scarto. Passando all'appaiamento per insiemi di votanti: le elezioni appaiate
salgono da 1.015 (36%) a **2.168 (77,6%)**, le sotto-spezzature scendono da 23 a **1**, e i
tentativi validati salgono da 992 a **2.167**.

**(c) Avevo scritto come limite del progetto una cosa falsa.** Dalla prima versione di (b)
avevo concluso che "il 61% delle elezioni di wiki-Elec non esiste in wiki-RfA" e che "wiki-RfA
non è un soprainsieme di wiki-Elec", con una tabella di copertura per anno (2006 al 28%, 2007
al 34%). **Era un artefatto dell'appaiamento per data.** La realtà misurata: 77,6% appaiate
con criterio stretto, 84,2% con criterio permissivo, e un'assenza vera del 9,8%. Un limite
inventato è peggio di un limite non trovato, perché finisce nel report e non si verifica più.

**(d) Avevo giustificato una conclusione con un'inferenza, non con una misura.** Scrivevo "i
volumi di voto dei due file sono comparabili, quindi non è una questione di scala". Il
ragionamento era debole e la conclusione sbagliata. Ora il confronto fra i due file si appoggia
su una misura diretta, la sovrapposizione degli insiemi di votanti (§6).

**(e) `flag_year_clash` usava `yea`**, cioè il campo che io stesso avevo dichiarato
inaffidabile e scartato dalla ricostruzione. Incoerenza interna. Ora usa l'anno preso dalla
data di apertura; il conteggio è passato da 374 a 359.

**(f) Avevo scelto la conversione di codifica sbagliata** per wiki-Elec, convertendo tutto da
ISO-8859-1 perché "funzionava". Rovinava i nomi accentati corretti. Vedi §7(b).

**Quello che resta non verificato, e sta scritto:** i 12 esiti discordanti e il tentativo che
assorbe due elezioni non li ho guardati caso per caso (§13(a), §13(b)).
