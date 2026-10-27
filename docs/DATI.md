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
  - [18. La verifica indipendente, e i quattro errori che ha trovato](#18-la-verifica-indipendente-e-i-quattro-errori-che-ha-trovato)
  - [19. Appendice: tutto il codice](#19-appendice-tutto-il-codice)

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

**Prima di attribuire il disaccordo ai due file, ho controllato se fossi io a causarlo.**
Se la mia ricostruzione spezzasse le elezioni, i votanti "mancanti" dal tentativo appaiato
dovrebbero ricomparire in un altro tentativo dello stesso candidato. Misurato: dei **20.025**
votanti presenti in un'elezione di wiki-Elec e assenti dal mio tentativo appaiato, solo
**140, lo 0,7%**, si trovano in un altro mio tentativo di quello stesso candidato. E unendo
*tutti* i tentativi di un candidato il Jaccard mediano **scende** (da 0,666 a 0,630) invece di
salire. **Quindi non sono io a disperderli: mancano davvero da wiki-RfA.**

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
3. **La mia ricostruzione contribuisce poco, ed è misurato.** Solo lo 0,7% dei votanti
   mancanti finisce in un tentativo adiacente. Resta il contributo dei 806 voti senza data che
   ho perso (§7(e)) e dei 627 voti ripetuti rimossi (§7(h)), ma non spiegano l'ordine di
   grandezza del disaccordo.
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

**Che cos'è.** **43 grafie** portano uno spazio iniziale o finale: `"Dream Focus "`,
`"Peripitus "`, `"Matthewrbowker "`, `"Noetica "`. Di queste, **21 collidono con la forma
pulita già presente nel file** — cioè lo stesso nome compare sia con lo spazio sia senza — e
sono quelle che fanno scendere il conteggio dei nomi distinti; le altre 22 compaiono solo con
lo spazio, quindi il trim le rinomina senza fonderle con nulla.

**Perché andava risolto.** Lo username *è* l'identità del nodo. Due grafie dello stesso nome
sono due nodi diversi per qualunque libreria di rete.

**Come.** `trimws()` su `SRC` e `TGT` in `read_rfa()`.

**Cosa sarebbe successo altrimenti.** I nodi distinti sarebbero 11.402 invece di **11.381**,
cioè il totale pubblicato da SNAP: 21 in più, esattamente le 21 grafie che collidono. Nelle
reti quelle 21 persone comparirebbero sdoppiate, con il grado spezzato fra le due copie. È il difetto che Mihretab aveva segnalato.

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

**Che cos'è.** Il file usa terminatori **CRLF**: 83.859 coppie di byte `0d 0a` solo nei primi
3 MB. wiki-RfA, per confronto, non ha CRLF da nessuna parte. Il file ha 128.016 righe.

**Perché sembrava un problema.** L'ultimo campo di ogni riga è proprio lo **username**, quindi
se il `\r` restasse attaccato ogni nome si porterebbe dietro un carattere invisibile e nessun
join fra i due file funzionerebbe.

**Come l'ho trattato.** `sub("\r$", "", lines)` subito dopo la lettura.

**ATTENZIONE — qui avevo scritto una cosa falsa, ed è stata la verifica a smentirmi.** In una
versione precedente di questo documento scrivevo che senza quella riga «nessun join avrebbe
funzionato». **Non è vero in R:** `readLines()` tratta `\r\n` come terminatore di riga e lo
toglie da sé. Misurato: su 128.016 righe lette, **zero** contengono un `\r`, e l'ultimo campo
di una riga `V` finisce con i byte `75 64 72 61 6d 61 6e` (`udraman`), senza `0d`.

Quindi il `sub()` è una **rete di sicurezza che non fa nulla** su questa piattaforma. Resta
scritto perché servirebbe davvero leggendo il file con `readBin`, con `scan(sep = "\n")`, o
con una connessione aperta in modalità binaria — ma **non è uno dei difetti che ho dovuto
risolvere**, ed elencarlo come tale era un errore. Il difetto vero legato alle grafie è il
successivo.

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
il **74,9%** invece dell'**89,8%**; un quarto delle elezioni sarebbe risultato non validabile
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

**Che cos'è.** Il formato di `DAT` è `"HH:MM, DD Month YYYY"`. Delle 188.908 date non vuote:
**181.828 hanno il mese in forma piena**, **7.077 lo hanno abbreviato a tre lettere**
(`Jan`, `Feb`, `Mar`, `Apr`, `Jun`, `Jul`, `Aug`, `Sep`, `Oct`, `Nov`, `Dec`), e **3 ce
l'hanno scritto male nella fonte**: `Janry`, `Julu`, `Mya`, un voto ciascuno.

*Nota sul conteggio, perché qui avevo sbagliato:* `May` compare 18.603 volte ed è
**identico nella forma piena e in quella abbreviata**, quindi non è un caso problematico e
non va contato fra gli abbreviati. In una versione precedente lo contavo, e dichiaravo 25.680
abbreviati invece di 7.077.

**Perché andava risolto.** Due ragioni, e la seconda è più grave della prima. Primo, un parser
che accetta solo il nome pieno perde le date abbreviate e quelle scritte male. Secondo,
`format = "%d %B %Y"` dipende da **`LC_TIME`**, cioè dalla lingua configurata sulla macchina:
lo stesso codice darebbe risultati diversi sul computer del docente, che deve poter eseguire
tutto.

**Come.** Una tabella dei mesi esplicita — nomi pieni, abbreviazioni e i tre errori — e la
costruzione della data in formato ISO, indipendente dal locale. In `parse_dat()`.

**Cosa sarebbe successo altrimenti.** **7.080 date** trasformate in `NA` **in silenzio**, cioè
il **3,7%** dei voti datati. Quei voti sarebbero finiti fra i "senza data", l'attribuzione li
avrebbe in parte dispersi, e la ricostruzione avrebbe lavorato su un file bucato senza che
nessuno se ne accorgesse. Dopo la correzione: **0 date presenti e non interpretabili**.

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

**Questa assunzione è stata verificata, e regge al 97,7%.** Il test: si prendono i candidati
che in wiki-Elec hanno **una sola** elezione — così non c'è ambiguità su quale elezione sia —
si recuperano in wiki-RfA i voti di quei votanti per quel candidato, e si guarda se `RES` è
costante. Su **1.522** elezioni esaminate, `RES` non è costante in **35, il 2,3%**. In quei 35
casi la mia regola spezza in due un'elezione sola: è un errore residuo misurato, non nullo, da
riportare.

*Nota su un test sbagliato che avevo fatto prima:* ripetendo la stessa verifica su **tutti** i
candidati, `RES` risulta non costante nel **15,0%** dei casi (307 su 2.048). È un artefatto:
i candidati con più elezioni condividono i votanti fra le proprie elezioni, quindi selezionare
i voti per appartenenza del votante tira dentro anche i voti dell'altra elezione, che hanno
legittimamente un `RES` diverso. Il numero valido è il 2,3%.

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

**Tre riserve metodologiche su questi numeri, che vanno dichiarate perché li rendono
ottimistici.**

1. **Non c'è separazione fra taratura e validazione.** La soglia e la regola sono state scelte
   massimizzando l'accordo con wiki-Elec (§9), e poi l'accordo con wiki-Elec è riportato come
   validazione. È lo stesso insieme di dati usato due volte: non è una verifica fuori
   campione. Attenuante: la scelta della soglia è risultata **indifferente** nel plateau 4–21
   giorni, quindi la taratura ha di fatto consumato pochissima informazione; e la concordanza
   dell'**esito** non dipende dalla taratura, perché l'esito viene da `RES`, che non è un
   parametro.
2. **L'appaiamento sceglie il tentativo che somiglia di più.** Per costruzione prende il
   massimo su tutti i tentativi del candidato, quindi l'accordo misurato è un **limite
   superiore**.
3. **Si validano solo i casi in cui la ricostruzione ha funzionato.** Un tentativo mal
   ricostruito ha un Jaccard basso, non supera la soglia di 0,5 e **esce dal campione di
   validazione**. Quindi il 99,45% è condizionato all'essere stato appaiato, e non si estende
   ai 1.915 tentativi senza riscontro. È una selezione sul risultato, e va detta.

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
totale, **ma non sono distribuiti uniformemente, ed è misurato**: toccano 161 candidati, di
cui il **78% sono candidati ripetuti**, contro una quota di ripetuti sul totale dei candidati
del **14%**. Concentrazione **5,6 volte** la base. Il motivo è meccanico: la regola di
attribuzione fallisce proprio quando un candidato ha più tentativi con lo stesso anno ed
esito, cioè sui ripresentati — **la popolazione che lo studio seleziona**. *Minaccia:* il
numero di votanti e `support_share` dei tentativi dei ripresentati. *Direzione:* sottostima
del numero di votanti, concentrata sul gruppo di interesse.

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

## 18. La verifica indipendente, e i quattro errori che ha trovato

`R/99_verifica_dati.R` **ricalcola ogni numero di questo documento partendo dai due file
grezzi**, senza usare nessun output intermedio della pipeline, e stampa `OK` o `DIVERSO`
accanto a ciascuno. Chiunque abbia i due file può eseguirlo e controllare, in un passo solo,
che le affermazioni qui sopra corrispondano ai dati. Verifica una sessantina di valori più
l'assunzione di metodo del §8. Il risultato è in `data/processed/99_verifica.txt`.

Scriverlo è servito: ha trovato **quattro affermazioni sbagliate** che erano in questo
documento, tutte ora corrette sopra.

**(a) «21 nomi hanno uno spazio finale».** Falso come formulato: le grafie con spazio sono
**43**; sono 21 quelle che **collidono** con la forma pulita, ed è per questo che il conteggio
dei nomi distinti scende di 21. Confondevo l'effetto con la causa.

**(b) «25.680 voti usano il mese abbreviato».** Falso: sono **7.077**. Contavo fra gli
abbreviati anche le 18.603 occorrenze di `May`, che è identico nella forma piena e in quella
corta e quindi non dà alcun problema. Di conseguenza era sbagliata anche la stima del danno:
un parser con `%B` perderebbe **7.080 date, il 3,7%**, non 25.683 pari al 13,6%.

**(c) «Senza togliere il `\r` nessun join funzionerebbe».** Falso in R: `readLines()` toglie
già il terminatore `\r\n`. Misurato: zero righe su 128.016 contengono un `\r` dopo la
lettura. Il file **ha** davvero i CRLF, ma per noi non era un difetto da risolvere: avevo
elencato fra i problemi risolti qualcosa che R risolveva da solo, e avevo inventato la
conseguenza.

**(d) «89,5% di candidati ritrovati normalizzando».** Il valore corretto è **89,8%**: la
misura precedente non applicava il `trimws` dentro la normalizzazione.

Oltre a queste, la verifica ha fatto emergere un test mal costruito — il 15,0% di `RES` non
costante, che ristretto ai casi non ambigui è **2,3%** (§8) — e ha permesso di sostituire
un'affermazione qualitativa con una misurata: i 806 voti persi si concentrano sui candidati
ripetuti **5,6 volte** più della base (§15(i)).

## 19. Appendice: tutto il codice

Quello che segue è il contenuto integrale dei file in `R/`, nell'ordine di esecuzione. Con i
due file di `data/raw/` e questo codice, chiunque può rifare l'intera elaborazione e ottenere
gli stessi numeri. **Questa appendice è generata automaticamente dai file veri** con
`R/98_genera_appendice.R`, quindi non può divergere dal codice che gira.

Ordine di esecuzione, dalla radice del repo:

```bash
Rscript R/01_read_raw.R
Rscript R/02_build_attempts.R
Rscript R/03_validate_outcomes.R
Rscript R/99_verifica_dati.R    # facoltativo: la verifica indipendente
```

<!-- INIZIO APPENDICE GENERATA -->

### `R/00_paths.R`

```r
# Percorsi e utilità comuni. Da eseguire dalla radice del repo (source(), non standalone).

DIR_RAW       <- file.path("data", "raw")
DIR_PROCESSED <- file.path("data", "processed")
DIR_FIGURES   <- file.path("output", "figures")

FILE_RFA  <- file.path(DIR_RAW, "wiki-RfA.txt.gz")
FILE_ELEC <- file.path(DIR_RAW, "wikiElec.ElecBs3.txt.gz")

stop_if_missing <- function(path) {
  if (!file.exists(path)) {
    stop("File assente: ", path, ". Vedi data/raw/README.md per il download.", call. = FALSE)
  }
  invisible(TRUE)
}
```

### `R/00_lib_data.R`

```r
# Funzioni condivise del data workstream. Sorgente per 02 e 03, non eseguibile
# da sola. Solo R base: nessuna dipendenza.

# --- parser dei due file -----------------------------------------------------
CAMPI <- c("SRC", "TGT", "VOT", "RES", "YEA", "DAT", "TXT")

read_rfa <- function(path) {
  stop_if_missing(path)
  lines <- readLines(gzfile(path), warn = FALSE, encoding = "UTF-8")
  keys  <- sub(":.*$", "", lines)
  vals  <- sub("^[A-Z]{3}:", "", lines)
  keep  <- keys %in% CAMPI
  # Controllo: le righe scartate devono essere solo i separatori vuoti. Se ne
  # vengono scartate di non vuote, sono commenti TXT su piu righe e il parser
  # perderebbe testo senza accorgersene.
  scartate_non_vuote <- sum(!keep & lines != "")
  if (scartate_non_vuote > 0) {
    warning("righe scartate non vuote: ", scartate_non_vuote,
            " (commenti TXT su piu righe?)")
  }
  keys <- keys[keep]; vals <- vals[keep]
  rec  <- cumsum(keys == "SRC")   # ogni SRC apre un nuovo record
  n_campi <- table(table(rec))
  if (length(n_campi) != 1L || names(n_campi)[1] != "7") {
    warning("record con un numero di campi diverso da 7: ", 
            paste(names(n_campi), n_campi, sep = "x", collapse = " "))
  }
  out <- as.data.frame(tapply(vals, list(rec, keys), identity),
                       stringsAsFactors = FALSE)
  # NOTA 1 - username: 21 nomi differiscono solo per spazi iniziali o finali.
  # Senza trimws() i nomi distinti sono 11.402; con trimws() sono 11.381, cioe
  # esattamente il totale pubblicato da SNAP. Il trim e quindi parte della
  # definizione dei nodi, non una pulizia opzionale.
  out$SRC <- trimws(out$SRC)
  out$TGT <- trimws(out$TGT)
  out$vote_id <- seq_len(nrow(out))
  out[, c("vote_id", CAMPI)]
}

# NOTA 2 - varianti di sola iniziale maiuscola. Su Wikipedia la prima lettera di
# uno username e sempre maiuscola, quindi "harej" e "Harej" sono lo stesso
# account. Il totale SNAP di 11.381 NON le unifica; unificandole si scende a
# 11.244. DECISIONE APERTA (riguarda entrambi i ruoli): unificare o no.
# Se non si unificano, 8 candidati risultano due persone diverse con un solo
# tentativo ciascuno e cadono fuori dai candidati ripetuti. Questa funzione
# produce l'elenco dei casi per decidere su dati, non a naso.
capitalizza <- function(s) {
  ifelse(s == "" | is.na(s), s,
         paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s))))
}

case_variants <- function(d) {
  nomi <- unique(c(d$SRC, d$TGT))
  gruppi <- split(nomi, capitalizza(nomi))
  amb <- gruppi[lengths(gruppi) > 1]
  if (length(amb) == 0) return(data.frame())
  do.call(rbind, lapply(names(amb), function(nm) {
    forme <- amb[[nm]]
    data.frame(
      nome_unificato = nm,
      grafia         = forme,
      n_voti_dati    = vapply(forme, function(f) sum(d$SRC == f), integer(1)),
      n_voti_ricevuti= vapply(forme, function(f) sum(d$TGT == f), integer(1)),
      anni_come_candidato = vapply(forme, function(f) {
        paste(sort(unique(d$YEA[d$TGT == f])), collapse = ";")
      }, character(1)),
      row.names = NULL, stringsAsFactors = FALSE
    )
  }))
}

# --- wiki-Elec ----------------------------------------------------------------
# Blocchi separati per elezione, campi separati da tabulazione:
#   E <0|1>                                      esito
#   T <YYYY-MM-DD HH:MM:SS>                      chiusura dell'elezione
#   U <id> <username>                            candidato
#   N <id> <username>                            proponente (puo mancare)
#   V <voto> <id> <YYYY-MM-DD HH:MM:SS> <username>   un voto per riga
# NOTA 4 - tre trappole in questo file, tutte sull'identita dei nodi:
#  (a) gli username sono TUTTI MINUSCOLI, mentre in wiki-RfA hanno la grafia
#      originale, e wiki-Elec usa UNDERSCORE dove wiki-RfA usa lo SPAZIO (408
#      nomi con underscore e 0 con spazio, contro 0 e 606 in wiki-RfA).
#      Normalizzando i nomi i candidati di wiki-Elec ritrovati in wiki-RfA
#      passano dal 74,9% all'89,5%: vedi norm_user() in 00_lib_data.R;
#  (b) il file e UTF-8 ma contiene byte corrotti: 19 righe su 128.017 non sono
#      UTF-8 valido, e sono tutte dello stesso utente (una sequenza troncata,
#      'eivind_f_<c3>yangen' invece di 'eivind_f_oyangen'). Senza intervento
#      substr() si ferma con "stringa multibyte non valida". Si scartano i byte
#      invalidi con iconv(sub = ""): convertire tutto da ISO-8859-1, come
#      sembrerebbe suggerire il fatto che 'iconv -f ISO-8859-1' riesca, e
#      SBAGLIATO, perche rovina i nomi che erano UTF-8 corretto (anarion ->
#      an\u00c3\u00a1rion);
#  (c) le righe finiscono in CRLF (128.016 righe su 128.022): senza togliere il
#      \r l'ultimo campo di ogni riga, cioe proprio lo username, si porta
#      dietro un carattere invisibile e nessun join funziona.
# Per confronto, in wiki-RfA non c'e CRLF: li i 21 nomi fuori posto hanno uno
# spazio in coda (es. "Dream Focus ", "Peripitus ").
read_elec <- function(path) {
  stop_if_missing(path)
  lines <- iconv(readLines(gzfile(path), warn = FALSE, skipNul = TRUE),
                 from = "UTF-8", to = "UTF-8", sub = "")   # (b)
  lines <- sub("\r$", "", lines)                      # (c)
  lines <- lines[!startsWith(lines, "#") & nzchar(lines)]
  tag   <- substr(lines, 1, 1)
  blocco <- cumsum(tag == "E")
  campo <- function(t) {
    i <- which(tag == t)
    data.frame(blocco = blocco[i], resto = sub("^.\t", "", lines[i]),
               stringsAsFactors = FALSE)
  }
  e <- campo("E"); tt <- campo("T"); u <- campo("U"); n <- campo("N")
  pezzi <- function(x, k) vapply(strsplit(x, "\t", fixed = TRUE),
                                 function(p) if (length(p) >= k) p[k] else NA_character_,
                                 character(1))
  elections <- data.frame(
    election_id = e$blocco,
    outcome     = as.integer(e$resto),                       # 1 promosso, 0 no
    closed_at   = as.POSIXct(tt$resto[match(e$blocco, tt$blocco)],
                             format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    candidate   = trimws(pezzi(u$resto[match(e$blocco, u$blocco)], 2)),
    nominator   = trimws(pezzi(n$resto[match(e$blocco, n$blocco)], 2)),
    stringsAsFactors = FALSE
  )
  iv <- which(tag == "V")
  pv <- strsplit(sub("^V\t", "", lines[iv]), "\t", fixed = TRUE)
  elec_votes <- data.frame(
    election_id = blocco[iv],
    vot   = as.integer(vapply(pv, `[`, character(1), 1)),
    voter = trimws(vapply(pv, function(p) if (length(p) >= 4) p[4] else NA_character_,
                          character(1))),
    dat   = as.POSIXct(vapply(pv, function(p) if (length(p) >= 3) p[3] else NA_character_,
                              character(1)),
                       format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    stringsAsFactors = FALSE
  )
  list(elections = elections, votes = elec_votes)
}

# --- identita degli utenti ----------------------------------------------------
# Chiave di confronto fra i due file e dentro ciascuno. Tre normalizzazioni, ognuna
# imposta da un difetto misurato, non per prudenza generica:
#  - trimws: in wiki-RfA 21 nomi hanno uno spazio in coda; senza trim i nodi
#    distinti sono 11.402 invece di 11.381, il totale pubblicato da SNAP;
#  - underscore -> spazio: wiki-Elec scrive "dream_focus", wiki-RfA "Dream Focus";
#  - tolower: wiki-Elec e tutto minuscolo. Su Wikipedia la prima lettera di uno
#    username e sempre maiuscola, quindi "harej" e "Harej" sono lo stesso account:
#    per il CONFRONTO fra i file tolower e corretto. Se usarlo anche DENTRO
#    wiki-RfA, unificando 137 gruppi di grafie, e una decisione aperta (vedi
#    CLAUDE.md): cambia il numero di nodi e la popolazione dei candidati ripetuti.
norm_user <- function(x, lower = TRUE) {
  x <- trimws(gsub("_", " ", x))
  if (lower) tolower(x) else x
}

# --- date ---------------------------------------------------------------------
# NOTA - il campo DAT di wiki-RfA ha la forma "HH:MM, DD Month YYYY", ma:
#  - 9.367 voti su 198.275 (4,7%) hanno DAT vuoto;
#  - 25.680 usano il mese abbreviato (Jan, Feb, ...);
#  - 3 hanno il mese scritto male nella fonte: "Janry", "Julu", "Mya".
# Un parser con format="%d %B %Y" dipenderebbe da LC_TIME (quindi darebbe
# risultati diversi sulla macchina del docente) e trasformerebbe in NA, senza
# dire niente, i 25.683 casi non canonici. Qui il mese e tradotto con una
# tabella esplicita, indipendente dal locale.
MESI <- c(
  january = 1, february = 2, march = 3, april = 4, may = 5, june = 6,
  july = 7, august = 8, september = 9, october = 10, november = 11, december = 12,
  jan = 1, feb = 2, mar = 3, apr = 4, jun = 6, jul = 7, aug = 8,
  sep = 9, oct = 10, nov = 11, dec = 12,
  janry = 1, julu = 7, mya = 5          # errori di battitura nella fonte
)

parse_dat <- function(x) {
  x <- trimws(x)
  m <- regmatches(x, regexec(
    "^([0-9]{1,2}):([0-9]{2}), ([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})$", x))
  ok <- lengths(m) == 6L
  out <- rep(NA_real_, length(x))
  if (any(ok)) {
    p <- do.call(rbind, m[ok])
    mese <- MESI[tolower(p[, 5])]
    iso <- sprintf("%s-%02d-%02d %02d:%02d:00",
                   p[, 6], mese, as.integer(p[, 4]),
                   as.integer(p[, 2]), as.integer(p[, 3]))
    out[ok] <- as.numeric(as.POSIXct(iso, format = "%Y-%m-%d %H:%M:%S", tz = "UTC"))
  }
  res <- as.POSIXct(out, origin = "1970-01-01", tz = "UTC")
  attr(res, "n_non_parsate") <- sum(!ok & nzchar(x))
  attr(res, "n_vuote")       <- sum(!nzchar(x))
  res
}

# --- ricostruzione dei tentativi ---------------------------------------------
# Due regole, da confrontare contro wiki-Elec in 03 invece di scegliere a naso.
#
# "gap_then_res": si ordina per data dentro il candidato e si apre un tentativo
#   quando il salto supera la soglia oppure cambia RES. SCARTATA dopo la verifica:
#   un singolo voto con RES diverso infilato in mezzo a un'elezione la spezza in
#   tre. Produceva 1.420 tentativi da un voto solo, concentrati su 95 candidati
#   (es. ABCD: quattro tentativi in una settimana con esito alternato -1,1,-1,1).
#   Resta implementata perche il confronto fra le due regole e un risultato.
#
# "res_then_gap": si raggruppa per (candidato, RES) e dentro ogni gruppo si apre
#   un tentativo quando il salto supera la soglia. I voti di due elezioni vicine
#   con esito diverso si separano per RES, e un voto isolato non fa danni.
#   E anche la regola del precedente pubblico (Kolczynska), che raggruppa per
#   candidato, anno ed esito. Qui l'anno NON si usa: YEA e inaffidabile, 1.875
#   voti hanno la data in un anno diverso da quello dichiarato, a blocchi
#   coerenti (es. Scienceman123, YEA 2008, voti datati marzo 2006).
#
# I voti senza data non possono essere ordinati: restano fuori e vengono
# attribuiti dopo, solo quando l'attribuzione e univoca (vedi 02).
ricostruisci_tentativi <- function(d, soglia_giorni, mode = "res_then_gap") {
  stopifnot(all(c("tgt", "vot", "res", "yea", "dat") %in% names(d)))
  stopifnot(mode %in% c("res_then_gap", "gap_then_res"))
  d <- d[!is.na(d$dat), ]
  if (nrow(d) == 0) return(d)
  if (mode == "res_then_gap") {
    d <- d[order(d$tgt, d$res, d$dat), ]
    n <- nrow(d)
    cambio_gruppo <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
  } else {
    d <- d[order(d$tgt, d$dat), ]
    n <- nrow(d)
    cambio_gruppo <- c(TRUE, d$tgt[-1] != d$tgt[-n] | d$res[-1] != d$res[-n])
    cambio_gruppo[1] <- TRUE
  }
  salto <- c(NA_real_, as.numeric(difftime(d$dat[-1], d$dat[-n], units = "days")))
  nuovo <- cambio_gruppo | (!cambio_gruppo & salto > soglia_giorni)
  nuovo[is.na(nuovo)] <- TRUE
  d$attempt_id <- cumsum(nuovo)
  # numero progressivo del tentativo dentro il candidato, in ordine di apertura
  ap <- tapply(as.numeric(d$dat), d$attempt_id, min)
  primo <- data.frame(attempt_id = as.integer(names(ap)), apertura = as.numeric(ap))
  primo$tgt <- d$tgt[match(primo$attempt_id, d$attempt_id)]
  primo <- primo[order(primo$tgt, primo$apertura), ]
  primo$attempt_no <- ave(primo$apertura, primo$tgt, FUN = seq_along)
  d$attempt_no <- primo$attempt_no[match(d$attempt_id, primo$attempt_id)]
  d
}

# --- deduplica ----------------------------------------------------------------
# Un votante puo comparire piu volte nello stesso tentativo: voto cambiato,
# oppure riga duplicata. Regola: si tiene il voto piu recente del votante in quel
# tentativo. Restituisce la tabella ripulita e il numero di righe tolte.
dedup_voti <- function(d) {
  o <- order(d$attempt_id, d$src, d$dat)
  d <- d[o, ]
  tieni <- !duplicated(d[, c("attempt_id", "src")], fromLast = TRUE)
  attr(d, "n_righe_tolte") <- sum(!tieni)
  structure(d[tieni, ], n_righe_tolte = sum(!tieni))
}

# --- tabella a livello di tentativo ------------------------------------------
costruisci_attempts <- function(v) {
  agg <- function(f, ...) tapply(..., v$attempt_id, f)
  a <- data.frame(
    attempt_id   = sort(unique(v$attempt_id)),
    stringsAsFactors = FALSE
  )
  idx <- match(a$attempt_id, v$attempt_id)
  a$candidate  <- v$tgt[idx]
  a$attempt_no <- v$attempt_no[idx]
  a$outcome    <- v$res[idx]                                  # -1 respinto, 1 approvato
  a$yea        <- v$yea[idx]
  spl <- split(seq_len(nrow(v)), v$attempt_id)
  spl <- spl[as.character(a$attempt_id)]
  a$opened_at    <- as.POSIXct(vapply(spl, function(i) min(as.numeric(v$dat[i])), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$closed_at    <- as.POSIXct(vapply(spl, function(i) max(as.numeric(v$dat[i])), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$n_votes      <- vapply(spl, length, 0L)
  a$n_support    <- vapply(spl, function(i) sum(v$vot[i] ==  1), 0L)
  a$n_oppose     <- vapply(spl, function(i) sum(v$vot[i] == -1), 0L)
  a$n_neutral    <- vapply(spl, function(i) sum(v$vot[i] ==  0), 0L)
  # quota di sostegno sui soli voti espressi a favore o contro (i neutri fuori dal
  # denominatore: e una convenzione, dichiarata, non l'unica possibile)
  a$support_share <- ifelse(a$n_support + a$n_oppose > 0,
                            a$n_support / (a$n_support + a$n_oppose), NA_real_)
  a$duration_days <- as.numeric(difftime(a$closed_at, a$opened_at, units = "days"))
  # flag di ambiguita
  a$flag_short      <- a$n_votes < 5          # pochi voti: forse frammento
  a$flag_long       <- a$duration_days > 14   # piu lungo di una RfA normale
  a$flag_year_clash <- FALSE                  # riempito sotto
  # due tentativi dello stesso candidato nello stesso anno con lo stesso esito:
  # sospetti di essere un unico tentativo spezzato dalla soglia.
  # L'anno si prende dalla DATA di apertura, non da YEA: YEA e inaffidabile
  # (1.875 voti hanno la data in un anno diverso da quello dichiarato) e usarlo
  # qui sarebbe incoerente con la scelta di non usarlo nella ricostruzione.
  a$anno_data <- as.integer(format(a$opened_at, "%Y"))
  key <- paste(a$candidate, a$anno_data, a$outcome)
  a$flag_year_clash <- key %in% key[duplicated(key)]
  a[order(a$candidate, a$attempt_no), ]
}
```

### `R/01_read_raw.R`

```r
# 01 - Lettura dei file grezzi, nessuna pulizia sostanziale.
# Input : data/raw/wiki-RfA.txt.gz, data/raw/wikiElec.ElecBs3.txt.gz
# Output: data/processed/votes_raw.rds, data/processed/username_case_variants.csv
# Pacchetti: nessuno (R base).
#
# I due parser stanno in R/00_lib_data.R, cosi sono usabili anche dalla
# verifica indipendente (R/99_verifica_dati.R).
# Qui si fa solo il passaggio dal formato di testo alla tabella, piu la
# normalizzazione degli spazi negli username (vedi NOTA 1). Non si deduplica e non
# si decide niente di sostanziale: quello e il passo 02.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

# --- esecuzione ---------------------------------------------------------------
votes_raw <- read_rfa(FILE_RFA)
dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)
saveRDS(votes_raw, file.path(DIR_PROCESSED, "votes_raw.rds"))

elec <- read_elec(FILE_ELEC)
saveRDS(elec, file.path(DIR_PROCESSED, "elec_raw.rds"))

cv <- case_variants(votes_raw)
write.csv(cv, file.path(DIR_PROCESSED, "username_case_variants.csv"), row.names = FALSE)

# Conteggi di controllo contro i totali pubblicati da SNAP.
n_voti   <- nrow(votes_raw)
n_utenti <- length(unique(c(votes_raw$SRC, votes_raw$TGT)))
cat("voti:                    ", n_voti,   " (SNAP: 198275)",
    if (n_voti == 198275) " OK" else " DIVERSO", "\n", sep = "")
cat("utenti distinti:         ", n_utenti, " (SNAP: 11381)",
    if (n_utenti == 11381) " OK" else " DIVERSO", "\n", sep = "")
# NOTA 3 - le coppie distinte sono 189.003 col trim e 189.004 senza: una sola
# coppia (December21st2012Freak -> Jeffrey Mall) compare con due grafie che
# differiscono solo per gli spazi. Quindi i totali pubblicati da SNAP non sono
# coerenti fra loro: 11.381 utenti e un conteggio post-trim, 189.004 coppie e
# pre-trim. Da dichiarare nella sezione dati del report.
cat("coppie votante-candidato:", nrow(unique(votes_raw[, c("SRC", "TGT")])),
    " (SNAP: 189004, pre-trim; col trim sono 189003)\n", sep = "")
cat("nomi unificando l'iniziale maiuscola: ",
    length(unique(capitalizza(c(votes_raw$SRC, votes_raw$TGT)))), "\n", sep = "")
cat("gruppi di grafie che differiscono solo per l'iniziale: ",
    length(unique(cv$nome_unificato)),
    " (elenco in data/processed/username_case_variants.csv)\n", sep = "")
cat("  di cui la persona e candidata sotto almeno una grafia: ",
    length(unique(cv$nome_unificato[cv$n_voti_ricevuti > 0])), "\n", sep = "")
cat("  di cui compaiono come CANDIDATO con due grafie diverse: ",
    length(unique(cv$nome_unificato[ave(cv$n_voti_ricevuti > 0, cv$nome_unificato,
                                        FUN = sum) > 1])),
    "  <- caso distruttivo per la ricostruzione dei tentativi\n", sep = "")

cat("\n--- wiki-Elec ---\n")
cat("elezioni:", nrow(elec$elections), " (SNAP: 2794)",
    if (nrow(elec$elections) == 2794) " OK" else " DIVERSO", "\n", sep = "")
cat("voti:", nrow(elec$votes), "\n", sep = "")
cat("promozioni:", sum(elec$elections$outcome == 1),
    "  respinte:", sum(elec$elections$outcome == 0), "  (SNAP: ~1200 / ~1500)\n")
cat("periodo:", format(min(elec$elections$closed_at, na.rm = TRUE), "%Y-%m-%d"), "->",
    format(max(elec$elections$closed_at, na.rm = TRUE), "%Y-%m-%d"), "\n")
cat("candidati distinti:", length(unique(elec$elections$candidate)),
    "  di cui con piu di un'elezione:",
    sum(table(elec$elections$candidate) > 1), "\n")
cat("date di chiusura mancanti:", sum(is.na(elec$elections$closed_at)), "\n")
```

### `R/02_build_attempts.R`

```r
# 02 - Ricostruzione dei tentativi: una riga per (candidato, tentativo).
# Input : data/processed/votes_raw.rds
# Output: data/processed/votes.rds     (una riga per voto validato, con attempt_id)
#         data/processed/attempts.rds  (una riga per tentativo)
#         data/processed/02_log.txt    (il registro delle quantita, per il report)
# Pacchetti: nessuno (R base).
#
# PRINCIPIO: non filtrare, segnalare. Ogni riga problematica resta nella tabella
# con una colonna-bandiera, cosi la decisione su cosa escludere la prende chi
# analizza, non chi pulisce. Le uniche righe che si perdono sono i voti senza
# data non attribuibili (contati nel log).
#
# La soglia e un PARAMETRO, non un'assunzione: 03_validate_outcomes.R la scegli
# confrontando la ricostruzione con le elezioni vere di wiki-Elec. Il valore qui
# e il default del precedente Kolczynska, usato se 03 non e ancora stato eseguito.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

SOGLIA_GIORNI   <- 7      # separazione fra due tentativi dello stesso candidato
MODE            <- "res_then_gap"  # regola di raggruppamento, vedi 00_lib_data.R
UNIFICA_INIZIALE <- FALSE # DECISIONE APERTA: unificare le varianti di sola
                          # iniziale maiuscola (harej/Harej). Vedi CLAUDE.md.
                          # FALSE = si resta sul conteggio SNAP (11.381 nodi).

log_righe <- character(0)
nota <- function(...) {
  s <- paste0(...)
  log_righe <<- c(log_righe, s)
  cat(s, "\n", sep = "")
}

# --- 1. voti grezzi, rinominati in minuscolo ---------------------------------
raw <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
d <- data.frame(
  vote_id = raw$vote_id,
  src = raw$SRC, tgt = raw$TGT,
  vot = as.integer(raw$VOT), res = as.integer(raw$RES),
  yea = as.integer(raw$YEA),
  stringsAsFactors = FALSE
)
nota("voti in ingresso: ", nrow(d))

if (UNIFICA_INIZIALE) {
  cap <- function(s) ifelse(s == "", s, paste0(toupper(substr(s,1,1)), substr(s,2,nchar(s))))
  d$src <- cap(d$src); d$tgt <- cap(d$tgt)
  nota("username: unificata l'iniziale maiuscola -> nodi distinti: ",
       length(unique(c(d$src, d$tgt))))
} else {
  nota("username: grafia SNAP conservata -> nodi distinti: ",
       length(unique(c(d$src, d$tgt))))
}

# --- 2. date -----------------------------------------------------------------
dd <- parse_dat(raw$DAT)
d$dat <- dd
d$dat_missing <- is.na(d$dat)
nota("voti con DAT vuoto: ", attr(dd, "n_vuote"),
     sprintf("  (%.2f%%)", 100 * attr(dd, "n_vuote") / nrow(d)))
nota("voti con DAT presente ma non interpretabile: ", attr(dd, "n_non_parsate"))

# su quali candidati cadono i voti senza data (punto debole 1 del contesto)
sd <- d[d$dat_missing, ]
nota("candidati toccati da voti senza data: ", length(unique(sd$tgt)))
nota("  di cui con un solo YEA fra i voti senza data: ",
     sum(tapply(sd$yea, sd$tgt, function(x) length(unique(x))) == 1))

# --- 3. righe identiche -------------------------------------------------------
chiavi <- paste(d$src, d$tgt, d$vot, d$res, d$yea, format(d$dat), sep = "\r")
n_ident <- sum(duplicated(chiavi))
nota("righe interamente identiche (stesso votante, candidato, voto, esito, anno, data): ",
     n_ident)

# --- 4. ricostruzione --------------------------------------------------------
v <- ricostruisci_tentativi(d, SOGLIA_GIORNI, MODE)
nota("regola: ", MODE, "; soglia: ", SOGLIA_GIORNI, " giorni")
nota("voti datati usati nella ricostruzione: ", nrow(v))
nota("tentativi ricostruiti: ", length(unique(v$attempt_id)))
nota("candidati con almeno un tentativo: ", length(unique(v$tgt)))

# --- 5. deduplica dentro il tentativo ----------------------------------------
v <- dedup_voti(v)
nota("voti rimossi perche lo stesso votante compare piu volte nello stesso ",
     "tentativo (tenuto il piu recente): ", attr(v, "n_righe_tolte"))
nota("voti validati: ", nrow(v))

# --- 6. tabella dei tentativi ------------------------------------------------
a <- costruisci_attempts(v)
nota("tentativi: ", nrow(a))
rip <- table(a$candidate)
nota("candidati ripetuti (2+ tentativi): ", sum(rip > 1),
     "   (il brief dichiara 414)")
nota("  di cui con 3+ tentativi: ", sum(rip > 2))
nota("coppie di tentativi consecutivi: ", sum(rip[rip > 1] - 1))
nota("tentativi segnalati: pochi voti (<5): ", sum(a$flag_short),
     " | durata >14gg: ", sum(a$flag_long),
     " | stesso candidato/anno/esito: ", sum(a$flag_year_clash))

# esito precedente, per i ripetuti
a$prev_outcome <- NA_integer_
for (cand in names(rip)[rip > 1]) {
  i <- which(a$candidate == cand)
  i <- i[order(a$attempt_no[i])]
  a$prev_outcome[i[-1]] <- a$outcome[i[-length(i)]]
}
nota("tentativi con un esito precedente noto: ", sum(!is.na(a$prev_outcome)))
nota("  preceduti da un rifiuto: ", sum(a$prev_outcome == -1, na.rm = TRUE))
nota("  preceduti da un successo: ", sum(a$prev_outcome == 1, na.rm = TRUE),
     "   (il brief dichiara 29 candidati 'previously successful')")

# --- 7. attribuzione dei voti senza data -------------------------------------
# Si attribuiscono solo quando l'attribuzione e univoca: il candidato ha un solo
# tentativo in quell'anno con quell'esito. Gli altri restano fuori, contati.
a$key <- paste(a$candidate, a$yea, a$outcome)
uniche <- a$key[!duplicated(a$key) & !(a$key %in% a$key[duplicated(a$key)])]
sd$key <- paste(sd$tgt, sd$yea, sd$res)
sd$attempt_id <- a$attempt_id[match(sd$key, a$key)]
sd$attempt_id[!(sd$key %in% uniche)] <- NA_integer_
nota("voti senza data attribuiti in modo univoco: ", sum(!is.na(sd$attempt_id)),
     " su ", nrow(sd))
nota("voti senza data non attribuibili (persi): ", sum(is.na(sd$attempt_id)))
a$key <- NULL

# --- 8. salvataggio ----------------------------------------------------------
v$dat_imputed <- FALSE
if (any(!is.na(sd$attempt_id))) {
  add <- sd[!is.na(sd$attempt_id), ]
  add$attempt_no  <- a$attempt_no[match(add$attempt_id, a$attempt_id)]
  add$dat_imputed <- TRUE
  add$key <- NULL
  comuni <- intersect(names(v), names(add))
  v <- rbind(v[, comuni], add[, comuni])
}
v <- v[order(v$attempt_id, v$src), ]
saveRDS(v, file.path(DIR_PROCESSED, "votes.rds"))
saveRDS(a, file.path(DIR_PROCESSED, "attempts.rds"))
writeLines(log_righe, file.path(DIR_PROCESSED, "02_log.txt"))
nota("scritti: votes.rds (", nrow(v), " righe), attempts.rds (", nrow(a), " righe)")
```

### `R/03_validate_outcomes.R`

```r
# 03 - Validazione della ricostruzione contro wiki-Elec, e scelta della soglia.
# Input : data/processed/votes_raw.rds, data/processed/elec_raw.rds,
#         data/processed/votes.rds, data/processed/attempts.rds
# Output: data/processed/03_soglia_sweep.csv, data/processed/03_match_wikielec.csv,
#         data/processed/attempts_validated.rds, data/processed/03_log.txt
# Pacchetti: nessuno (R base).
#
# COME SI APPAIA UN'ELEZIONE VERA A UN TENTATIVO RICOSTRUITO
# Per insieme di votanti, non per data. Due elezioni della stessa persona hanno
# insiemi di votanti molto diversi, quindi la sovrapposizione (Jaccard) le
# distingue; e il criterio non dipende da nessun campo data.
#
# La prima versione di questo script appaiava per vicinanza fra la chiusura
# ufficiale T di wiki-Elec e l'ultimo voto del tentativo. E SBAGLIATO, perche
# T e inaffidabile: la differenza fra T e l'ultimo voto DELLA STESSA ELEZIONE,
# dentro wiki-Elec, ha mediana 102 giorni, e il 54% delle elezioni ha T oltre 30
# giorni dopo il proprio ultimo voto (1.217 oltre 180 giorni; alcune hanno T
# PRIMA del proprio ultimo voto). Si vede anche dal fatto che il 78% delle
# elezioni risulta chiuso nel 2007, mentre i voti sono distribuiti su 2005-2007.
# Conseguenze dell'errore, tutte corrette da questa versione: la copertura
# risultava del 36% invece del 78%, comparivano 23 sotto-spezzature invece di 1,
# e si concludeva a torto che wiki-RfA non contenesse le elezioni di wiki-Elec.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

GRIGLIA  <- c(1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 18, 21, 28, 35, 45, 60)
MODI     <- c("res_then_gap", "gap_then_res")
J_MIN    <- 0.5   # sovrapposizione minima dei votanti per dire "e la stessa elezione"
SOGLIA_SCELTA <- 7

log_righe <- character(0)
nota <- function(...) { s <- paste0(...); log_righe <<- c(log_righe, s); cat(s, "\n", sep="") }
jac <- function(x, y) length(intersect(x, y)) / length(union(x, y))

raw  <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
elec <- readRDS(file.path(DIR_PROCESSED, "elec_raw.rds"))
d <- data.frame(src = raw$SRC, tgt = raw$TGT,
                vot = as.integer(raw$VOT), res = as.integer(raw$RES),
                yea = as.integer(raw$YEA), dat = parse_dat(raw$DAT),
                stringsAsFactors = FALSE)

ev <- elec$votes; ev$voter_k <- norm_user(ev$voter)
set_el <- split(ev$voter_k, ev$election_id)
ele <- elec$elections
ele$cand_k <- norm_user(ele$candidate)
ele$ult_voto <- as.POSIXct(vapply(
  split(as.numeric(ev$dat), ev$election_id)[as.character(ele$election_id)],
  function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz = "UTC"))]), 0),
  origin = "1970-01-01", tz = "UTC")

# --- diagnostica: T e inaffidabile ------------------------------------------
dT <- as.numeric(difftime(ele$closed_at, ele$ult_voto, units = "days"))
nota("wiki-Elec: ", nrow(ele), " elezioni, chiusure dichiarate da ",
     format(min(ele$closed_at), "%Y-%m-%d"), " a ", format(max(ele$closed_at), "%Y-%m-%d"),
     ", voti dal ", format(min(ele$ult_voto), "%Y-%m-%d"), ".")
nota("Il campo T (chiusura) e INAFFIDABILE: scarto fra T e l'ultimo voto della stessa")
nota("  elezione, mediana ", round(median(dT), 1), " giorni; oltre 30 giorni nel ",
     sprintf("%.0f%%", 100*mean(dT > 30)), " dei casi; oltre 180 giorni in ",
     sum(dT > 180), " elezioni; minimo ", round(min(dT), 1), " giorni (T prima dell'ultimo voto).")
nota("  Per questo l'appaiamento usa gli INSIEMI DI VOTANTI, non le date.\n")

# --- appaiamento per una data regola e soglia -------------------------------
valuta <- function(mode, soglia) {
  v <- ricostruisci_tentativi(d, soglia, mode)
  v$src_k <- norm_user(v$src)
  set_at <- split(v$src_k, v$attempt_id)
  idx <- match(as.integer(names(set_at)), v$attempt_id)
  info <- data.frame(attempt_id = as.integer(names(set_at)),
                     cand_k = norm_user(v$tgt[idx]), outcome = v$res[idx],
                     n_votes = lengths(set_at), stringsAsFactors = FALSE)
  per <- split(info$attempt_id, info$cand_k)
  best <- rep(NA_real_, nrow(ele)); bid <- rep(NA_integer_, nrow(ele))
  for (r in seq_len(nrow(ele))) {
    ids <- per[[ele$cand_k[r]]]; if (is.null(ids)) next
    s <- set_el[[as.character(ele$election_id[r])]]
    jj <- vapply(ids, function(k) jac(s, set_at[[as.character(k)]]), 0)
    best[r] <- max(jj); bid[r] <- ids[which.max(jj)]
  }
  ok <- !is.na(best) & best > J_MIN
  mo <- info$outcome[match(bid[ok], info$attempt_id)]
  # concordanza del numero di tentativi, solo sui candidati con TUTTE le
  # elezioni appaiate: farlo su tutti gonfia il risultato con accordi casuali
  per_c <- split(seq_len(nrow(ele)), ele$cand_k)
  pieni <- names(per_c)[vapply(per_c, function(ii) all(ok[ii]), TRUE)]
  n_vero <- table(ele$cand_k[ele$cand_k %in% pieni])
  n_mio  <- table(info$cand_k[info$cand_k %in% pieni])
  com <- intersect(names(n_vero), names(n_mio))
  data.frame(mode, soglia,
             n_tentativi = nrow(info),
             appaiate = sum(ok),
             quota_appaiate = mean(ok),
             jaccard_mediano = median(best[ok]),
             esito_concorde = mean((mo == 1) == (ele$outcome[ok] == 1)),
             sotto_spezzati = sum(duplicated(bid[ok])),
             cand_confrontabili = length(com),
             conteggio_concorde = mean(n_vero[com] == n_mio[com]),
             sovra = sum(n_mio[com] > n_vero[com]),
             sotto = sum(n_mio[com] < n_vero[com]),
             frammenti_lt5 = sum(info$n_votes < 5),
             stringsAsFactors = FALSE)
}

nota("sweep: ", length(MODI), " regole x ", length(GRIGLIA), " soglie...")
res <- do.call(rbind, lapply(MODI, function(m)
  do.call(rbind, lapply(GRIGLIA, function(s) valuta(m, s)))))
write.csv(res, file.path(DIR_PROCESSED, "03_soglia_sweep.csv"), row.names = FALSE)
pr <- res; for (cc in c("quota_appaiate","jaccard_mediano","esito_concorde","conteggio_concorde"))
  pr[[cc]] <- round(pr[[cc]], 4)
print(pr, row.names = FALSE)

rtg <- res[res$mode == "res_then_gap", ]
g <- function(s, col) rtg[[col]][rtg$soglia == s]
nota("\nSCELTA DELLA SOGLIA")
nota("  elezioni appaiate: ", g(4,"appaiate"), " a 4 giorni, ", g(7,"appaiate"), " a 7, ",
     g(21,"appaiate"), " a 21, ", g(60,"appaiate"), " a 60.")
nota("  conteggio dei tentativi esatto: ", sprintf("%.1f%%", 100*g(4,"conteggio_concorde")),
     " a 4 giorni, ", sprintf("%.1f%%", 100*g(7,"conteggio_concorde")), " a 7, ",
     sprintf("%.1f%%", 100*g(60,"conteggio_concorde")), " a 60.")
nota("  Entrambe le metriche sono piatte fra 4 e 21 giorni: la scelta NON e guidata")
nota("  dai dati, ed e questo il risultato di robustezza. Si tiene 7 giorni, valore")
nota("  del precedente pubblico (Kolczynska) e durata nominale di una RfA.")
nota("  Regola scartata (gap_then_res): a 7 giorni produce ",
     res$frammenti_lt5[res$mode=="gap_then_res" & res$soglia==7],
     " tentativi con meno di 5 voti contro ", g(7,"frammenti_lt5"), ".")

# --- passata finale ---------------------------------------------------------
nota("\n--- VALIDAZIONE con res_then_gap e soglia ", SOGLIA_SCELTA, " giorni ---")
v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
v$src_k <- norm_user(v$src); set_at <- split(v$src_k, v$attempt_id)
a$cand_k <- norm_user(a$candidate); per <- split(a$attempt_id, a$cand_k)
best <- rep(NA_real_, nrow(ele)); bid <- rep(NA_integer_, nrow(ele))
for (r in seq_len(nrow(ele))) {
  ids <- per[[ele$cand_k[r]]]; if (is.null(ids)) next
  s <- set_el[[as.character(ele$election_id[r])]]
  jj <- vapply(ids, function(k) jac(s, set_at[[as.character(k)]]), 0)
  best[r] <- max(jj); bid[r] <- ids[which.max(jj)]
}
ele$jaccard <- best; ele$mio_attempt <- ifelse(!is.na(best) & best > J_MIN, bid, NA)
ok <- !is.na(ele$mio_attempt)
nota("elezioni appaiate (Jaccard > ", J_MIN, "): ", sum(ok), " su ", nrow(ele),
     sprintf("  (%.1f%%)", 100*mean(ok)))
nota("  con Jaccard > 0.3: ", sum(best > 0.3, na.rm = TRUE),
     "   candidato assente da wiki-RfA: ", sum(is.na(best)),
     sprintf("  (%.1f%%)", 100*mean(is.na(best))))
nota("  Jaccard mediano sulle appaiate: ", round(median(best[ok]), 3))
mo <- a$outcome[match(ele$mio_attempt[ok], a$attempt_id)]
nota("CONCORDANZA DELL'ESITO: ", sprintf("%.2f%%", 100*mean((mo==1)==(ele$outcome[ok]==1))),
     "  (discordanti: ", sum((mo==1)!=(ele$outcome[ok]==1)), " su ", sum(ok), ")")
nota("tentativi distinti appaiati: ", length(unique(ele$mio_attempt[ok])), " su ", nrow(a),
     "; tentativi che assorbono 2 elezioni: ", sum(duplicated(ele$mio_attempt[ok])))
# disaccordo sui votanti, fra le due ricostruzioni della stessa elezione
mancanti_a_me <- mapply(function(r,k) length(setdiff(set_el[[as.character(r)]], set_at[[as.character(k)]])),
                        ele$election_id[ok], ele$mio_attempt[ok])
mancanti_a_loro <- mapply(function(r,k) length(setdiff(set_at[[as.character(k)]], set_el[[as.character(r)]])),
                          ele$election_id[ok], ele$mio_attempt[ok])
nota("disaccordo sui singoli votanti (mediane): wiki-Elec ne ha ", median(mancanti_a_me),
     " che io non ho, io ne ho ", median(mancanti_a_loro), " che loro non hanno,")
nota("  su una mediana di ", median(lengths(set_el)[as.character(ele$election_id[ok])]),
     " votanti per elezione. Numeri simili (uguali in ",
     sum(lengths(set_el)[as.character(ele$election_id[ok])] == a$n_votes[match(ele$mio_attempt[ok], a$attempt_id)]),
     " elezioni), liste diverse.")

a$elec_matched <- a$attempt_id %in% ele$mio_attempt[ok]
a$elec_outcome <- ele$outcome[match(a$attempt_id, ele$mio_attempt)]
a$elec_jaccard <- ele$jaccard[match(a$attempt_id, ele$mio_attempt)]
a$outcome_agrees <- ifelse(a$elec_matched, (a$outcome == 1) == (a$elec_outcome == 1), NA)
saveRDS(a, file.path(DIR_PROCESSED, "attempts_validated.rds"))
write.csv(ele[, c("election_id","candidate","outcome","closed_at","ult_voto",
                  "jaccard","mio_attempt")],
          file.path(DIR_PROCESSED, "03_match_wikielec.csv"), row.names = FALSE)
nota("LIMITE: la validazione copre ", sum(a$elec_matched), " tentativi su ", nrow(a),
     sprintf(" (%.0f%%)", 100*mean(a$elec_matched)),
     ". Fuori dal periodo di wiki-Elec, cioe dal 2008 al 2013, non esiste.")
nota("scritti: attempts_validated.rds, 03_match_wikielec.csv")
writeLines(log_righe, file.path(DIR_PROCESSED, "03_log.txt"))
```

### `R/99_verifica_dati.R`

```r
# 99 - Verifica indipendente delle affermazioni di docs/DATI.md.
# Ricalcola ogni numero PARTENDO DAI FILE GREZZI, senza usare gli output
# intermedi, e confronta con quanto dichiarato. Stampa OK o DIVERSO.
# Serve a chiunque voglia controllare il lavoro senza fidarsi.
# Input : data/raw/*.gz    Output: data/processed/99_verifica.txt

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

ko <- 0L; log_righe <- character(0)
chk <- function(etichetta, ottenuto, atteso, tol = 0) {
  esito <- if (is.na(ottenuto) || is.na(atteso)) "?" else
           if (abs(ottenuto - atteso) <= tol) "OK" else { ko <<- ko + 1L; "DIVERSO" }
  s <- sprintf("%-62s %12s  atteso %12s  %s", etichetta,
               format(ottenuto, big.mark = "."), format(atteso, big.mark = "."), esito)
  log_righe <<- c(log_righe, s); cat(s, "\n", sep = "")
}
sez <- function(t) { s <- paste0("\n== ", t, " =="); log_righe <<- c(log_righe, s); cat(s, "\n") }

# ---------------------------------------------------------------- wiki-RfA --
sez("wiki-RfA: lettura indipendente dal parser della pipeline")
L <- readLines(gzfile(FILE_RFA), warn = FALSE, encoding = "UTF-8")
k <- sub(":.*$", "", L); v <- sub("^[A-Z]{3}:", "", L)
keep <- k %in% c("SRC","TGT","VOT","RES","YEA","DAT","TXT")
chk("righe totali del file", length(L), 1586200)
chk("righe scartate che NON sono separatori vuoti", sum(!keep & L != ""), 0)
rec <- cumsum(k[keep] == "SRC")
chk("record (= voti)", max(rec), 198275)
chk("record con un numero di campi diverso da 7", sum(table(rec) != 7), 0)
D <- as.data.frame(tapply(v[keep], list(rec, k[keep]), identity), stringsAsFactors = FALSE)

sez("wiki-RfA: identita degli utenti")
tutti_raw <- c(D$SRC, D$TGT)
chk("utenti distinti SENZA trim", length(unique(tutti_raw)), 11402)
chk("utenti distinti CON trim (totale SNAP)", length(unique(trimws(tutti_raw))), 11381)
con_sp <- unique(tutti_raw)[unique(tutti_raw) != trimws(unique(tutti_raw))]
chk("grafie con spazio iniziale o finale", length(con_sp), 43)
chk("  di cui collidono con la forma pulita gia presente", sum(trimws(con_sp) %in% tutti_raw), 21)
chk("  riduzione dei nomi distinti", length(unique(tutti_raw)) - length(unique(trimws(tutti_raw))), 21)
chk("coppie votante-candidato SENZA trim (totale SNAP)",
    nrow(unique(D[, c("SRC","TGT")])), 189004)
Dt <- D; Dt$SRC <- trimws(Dt$SRC); Dt$TGT <- trimws(Dt$TGT)
chk("coppie votante-candidato CON trim", nrow(unique(Dt[, c("SRC","TGT")])), 189003)
chk("votanti distinti (con trim)", length(unique(Dt$SRC)), 10417)
chk("candidati distinti (con trim)", length(unique(Dt$TGT)), 3497)
chk("utenti che sono SIA votanti SIA candidati", length(intersect(unique(Dt$SRC), unique(Dt$TGT))), 2533)
chk("candidati che non hanno mai votato", length(setdiff(unique(Dt$TGT), unique(Dt$SRC))), 964)
cap <- function(s) ifelse(s == "", s, paste0(toupper(substr(s,1,1)), substr(s,2,nchar(s))))
chk("utenti unificando l'iniziale maiuscola", length(unique(cap(trimws(tutti_raw)))), 11244)
gr <- split(unique(trimws(tutti_raw)), cap(unique(trimws(tutti_raw))))
chk("gruppi di grafie che differiscono solo per l'iniziale", sum(lengths(gr) > 1), 137)
chk("  di cui la persona e candidata sotto almeno una grafia",
    sum(vapply(gr, function(f) length(f) > 1 && any(f %in% Dt$TGT), TRUE)), 90)
chk("  di cui il CANDIDATO compare con due grafie",
    sum(lengths(split(unique(Dt$TGT), cap(unique(Dt$TGT)))) > 1), 8)

sez("wiki-RfA: campi")
chk("voti favorevoli (VOT=1)",  sum(D$VOT ==  "1"), 144451)
chk("voti contrari (VOT=-1)",   sum(D$VOT == "-1"),  41176)
chk("voti neutri (VOT=0)",      sum(D$VOT ==  "0"),  12648)
chk("esito respinto (RES=-1)",  sum(D$RES == "-1"),  74987)
chk("esito approvato (RES=1)",  sum(D$RES ==  "1"), 123288)
chk("DAT vuoto", sum(D$DAT == ""), 9367)
dt <- parse_dat(D$DAT)
chk("DAT presente ma non interpretabile", attr(dt, "n_non_parsate"), 0)
mm <- sub("^.*, [0-9]{1,2} ([A-Za-z]+) [0-9]{4}$", "\\1", D$DAT[D$DAT != ""])
abbr <- c("Jan","Feb","Mar","Apr","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
chk("voti con mese abbreviato (May esclusa: identica alla forma piena)", sum(mm %in% abbr), 7077)
chk("  voti con mese 'May'", sum(mm == "May"), 18603)
chk("voti con mese scritto male nella fonte", sum(mm %in% c("Janry","Julu","Mya")), 3)
chk("date che un parser con %B perderebbe", sum(mm %in% abbr) + sum(mm %in% c("Janry","Julu","Mya")), 7080)
ya <- as.integer(format(dt, "%Y"))
chk("voti con anno della data diverso da YEA",
    sum(ya != as.integer(D$YEA), na.rm = TRUE), 1875)
chk("voti datati 2003", sum(ya == 2003, na.rm = TRUE), 155)
chk("voti datati 2013", sum(ya == 2013, na.rm = TRUE), 3348)
ch <- paste(D$SRC, D$TGT, D$VOT, D$RES, D$YEA, D$DAT, sep = "\r")
chk("righe interamente identiche", sum(duplicated(ch)), 595)
chk("commenti vuoti", sum(D$TXT == ""), 7190)
chk("lunghezza mediana del commento", median(nchar(D$TXT)), 98)
chk("lunghezza massima del commento", max(nchar(D$TXT)), 7610)
chk("commenti con marcatore in grassetto iniziale", sum(startsWith(D$TXT, "'''")), 162939)
chk("voti dati per votante: mediana", median(table(Dt$SRC)), 3)
chk("voti dati per votante: massimo", max(table(Dt$SRC)), 1661)
chk("voti ricevuti per candidato: mediana", median(table(Dt$TGT)), 41)
chk("voti ricevuti per candidato: massimo", max(table(Dt$TGT)), 987)

# --------------------------------------------------------------- wiki-Elec --
sez("wiki-Elec: difetti di formato")
raw_b <- readLines(gzfile(FILE_ELEC), warn = FALSE, skipNul = TRUE)
chk("righe lette da readLines()", length(raw_b), 128016)
chk("righe in cui readLines() LASCIA un CR", sum(grepl("\r", raw_b, fixed = TRUE)), 0)
con <- gzfile(FILE_ELEC, open = "rb"); bb <- readBin(con, "raw", 3e6); close(con)
chk("coppie di byte CRLF nei primi 3 MB del file", 
    sum(bb[-length(bb)] == as.raw(13) & bb[-1] == as.raw(10)), 83859)
chk("righe non valide come UTF-8",
    sum(is.na(iconv(raw_b, from = "UTF-8", to = "UTF-8"))), 19)
E <- read_elec(FILE_ELEC)
chk("elezioni", nrow(E$elections), 2794)
chk("voti", nrow(E$votes), 114040)
chk("votanti distinti", length(unique(E$votes$voter)), 6210)
chk("promozioni", sum(E$elections$outcome == 1), 1248)
chk("respinte", sum(E$elections$outcome == 0), 1546)
chk("candidati distinti", length(unique(E$elections$candidate)), 2391)
chk("proponente = UNKNOWN", sum(E$elections$nominator == "UNKNOWN"), 2117)
chk("autonomine dichiarate", sum(E$elections$nominator == E$elections$candidate), 85)
chk("voti per elezione: mediana", median(table(E$votes$election_id)), 34)
chk("voti per elezione: massimo", max(table(E$votes$election_id)), 370)
chk("voti favorevoli", sum(E$votes$vot == 1), 83962)
chk("voti contrari",   sum(E$votes$vot == -1), 23118)
chk("voti neutri",     sum(E$votes$vot == 0), 6960)
chk("date di chiusura mancanti", sum(is.na(E$elections$closed_at)), 0)
yv <- as.integer(format(E$votes$dat, "%Y"))
chk("voti con anno impossibile (>2008)", sum(yv > 2008), 11)
cat("  chiusure dichiarate: da", format(min(E$elections$closed_at)),
    "a", format(max(E$elections$closed_at)), "\n")
cat("  voti (anni plausibili): da", format(min(E$votes$dat[yv <= 2008])),
    "a", format(max(E$votes$dat[yv <= 2008])), "\n")
chk("elezioni chiuse prima di settembre 2004",
    sum(E$elections$closed_at < as.POSIXct("2004-09-01", tz = "UTC")), 0)
chk("elezioni chiuse nel 2007", sum(format(E$elections$closed_at, "%Y") == "2007"), 2180)

sez("wiki-Elec: il campo T e inaffidabile")
ul <- vapply(split(as.numeric(E$votes$dat), E$votes$election_id)[
               as.character(E$elections$election_id)],
             function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz="UTC"))]), 0)
dT <- as.numeric(difftime(E$elections$closed_at,
                          as.POSIXct(ul, origin="1970-01-01", tz="UTC"), units="days"))
chk("scarto T - ultimo voto: mediana (giorni)", round(median(dT)), 102, tol = 1)
chk("elezioni con T oltre 30 giorni dopo", sum(dT > 30), 1512)
chk("elezioni con T oltre 180 giorni dopo", sum(dT > 180), 1217)
chk("minimo dello scarto (T prima dell'ultimo voto)", round(min(dT)), -188, tol = 1)

sez("grafie fra i due file")
chk("wiki-Elec: candidati con underscore", sum(grepl("_", unique(E$elections$candidate))), 408)
chk("wiki-Elec: candidati con spazio",    sum(grepl(" ",  unique(E$elections$candidate))), 0)
chk("wiki-RfA: candidati con underscore", sum(grepl("_", unique(Dt$TGT))), 0)
chk("wiki-RfA: candidati con spazio",     sum(grepl(" ",  unique(Dt$TGT))), 606)
ec <- unique(E$elections$candidate); rc <- unique(tolower(Dt$TGT))
chk("candidati wiki-Elec trovati in wiki-RfA, match diretto (%)",
    round(100*mean(ec %in% rc), 1), 74.9, tol = 0.2)
chk("candidati wiki-Elec trovati normalizzando (%)",
    round(100*mean(norm_user(ec) %in% norm_user(rc)), 1), 89.5, tol = 0.2)

# ------------------------------------------------ assunzioni del metodo -----
sez("ASSUNZIONE: RES e una proprieta dell'elezione, non del voto")
# Per ogni elezione di wiki-Elec appaiata, i voti corrispondenti in wiki-RfA
# hanno tutti lo stesso RES? Se no, raggruppare per RES e sbagliato.
Dt$dat <- dt; Dt$kc <- norm_user(Dt$TGT); Dt$kv <- norm_user(Dt$SRC)
ev <- E$votes; ev$kv <- norm_user(ev$voter)
ele <- E$elections; ele$kc <- norm_user(ele$candidate)
set_el <- split(ev$kv, ev$election_id)
res_misti <- 0L; esaminate <- 0L
idx_c <- split(seq_len(nrow(Dt)), Dt$kc)
for (r in seq_len(nrow(ele))) {
  ii <- idx_c[[ele$kc[r]]]; if (is.null(ii)) next
  s <- set_el[[as.character(ele$election_id[r])]]
  jj <- ii[Dt$kv[ii] %in% s]
  if (length(jj) < 10) next
  esaminate <- esaminate + 1L
  if (length(unique(Dt$RES[jj])) > 1) res_misti <- res_misti + 1L
}
cat(sprintf("  elezioni esaminate (>=10 votanti ritrovati): %d\n", esaminate))
cat(sprintf("  di cui con RES NON costante fra i loro voti in wiki-RfA: %d (%.1f%%)\n",
            res_misti, 100*res_misti/esaminate))
cat("  NB: un valore alto invaliderebbe il raggruppamento per (candidato, RES).\n")
log_righe <- c(log_righe,
  sprintf("  elezioni esaminate: %d | con RES non costante: %d (%.1f%%)",
          esaminate, res_misti, 100*res_misti/esaminate))

sez("ESITO")
cat(if (ko == 0) "Tutte le affermazioni verificate coincidono.\n" else
    sprintf("%d affermazioni NON coincidono.\n", ko))
log_righe <- c(log_righe, if (ko == 0) "Tutte le affermazioni coincidono." else
               sprintf("%d affermazioni NON coincidono.", ko))
writeLines(log_righe, file.path(DIR_PROCESSED, "99_verifica.txt"))
```

### `R/98_genera_appendice.R`

```r
# 98 - Rigenera l'appendice di codice in docs/DATI.md dai file veri in R/.
# Da eseguire dopo ogni modifica agli script, cosi il codice nel documento non
# puo divergere da quello che gira. Non tocca il resto del documento.
FILES <- c("R/00_paths.R", "R/00_lib_data.R", "R/01_read_raw.R",
           "R/02_build_attempts.R", "R/03_validate_outcomes.R",
           "R/99_verifica_dati.R", "R/98_genera_appendice.R")
doc <- "docs/DATI.md"
testo <- readLines(doc, warn = FALSE)
i <- grep("^<!-- INIZIO APPENDICE GENERATA -->$", testo)
j <- grep("^<!-- FINE APPENDICE GENERATA -->$", testo)
stopifnot(length(i) == 1, length(j) == 1, j > i)
blocchi <- unlist(lapply(FILES, function(f) {
  c(paste0("### `", f, "`"), "",
    paste0("```r"), readLines(f, warn = FALSE), "```", "")
}))
out <- c(testo[seq_len(i)], "", blocchi, testo[j:length(testo)])
writeLines(out, doc)
cat("appendice rigenerata:", length(blocchi), "righe da", length(FILES), "file\n")
```

<!-- FINE APPENDICE GENERATA -->
