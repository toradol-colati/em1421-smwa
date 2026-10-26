# Cosa dice il materiale del corso, e cosa implica per il progetto

Lettura di tutti i file in `docs/` (26/10/2026). Riferimenti per numero di slide.
Qui non si decide niente: si mette in fila ciò che il corso insegna e dove tocca le
decisioni aperte (contesto §11).

## 1. Il vincolo più stretto: il corso insegna UN SOLO algoritmo di comunità

- Lezione 3 (slide 83-122) e lezione 6 (slide 39-44): community detection = **Girvan-Newman**,
  rimozione iterativa degli archi a betweenness massima. In R: `edge.betweenness.community()`.
- Nessun'altra tecnica di partizione è insegnata: niente Louvain, niente Leiden, niente
  ottimizzazione di modularità, niente blockmodel, niente ERGM.
- Lezione 3 slide 122, testualmente: il metodo "works well for networks of moderate size
  (few thousands nodes)"; per reti più grandi "computing the betweenness at each step is
  expensive".

**Implicazione, da risolvere prima di scrivere il codice delle comunità.** La proiezione di
co-voto sui votanti ha un ordine di 10^4 nodi (11.381 utenti SNAP) e, se non sfoltita, un
numero di archi enorme. Girvan-Newman non ci gira. Le vie d'uscita, in ordine di costo:
1. ridurre i nodi prima della proiezione (solo i votanti attivi nella finestra di t, o solo i
   votanti dei candidati ripetuti): la rete scende a dimensioni dove GN è praticabile;
2. estrarre il backbone (pacchetto `backbone`) e poi usare GN su ciò che resta;
3. usare un algoritmo non insegnato (Louvain) e giustificarlo in una riga.
La 3 è legittima in sé, ma l'esame è orale con domande teoriche sugli argomenti del corso:
un metodo fuori programma va saputo difendere. La 1 e la 2 restano dentro il programma.
Decisione di Bubi e Mihretab.

## 2. La rete di co-voto ha già un nome nel corso: rete di affiliazione

- Lezione 4 (slide 32-43): i **foci** di Feld, le **reti di affiliazione** come grafi bipartiti
  persone-contesti, e le tre chiusure: triadica, **focal closure** (due persone si collegano
  perché condividono un focus), **membership closure**.
- Lezione 5b (slide 2-15): grafo bipartito in igraph, attributo `type`,
  `graph_from_incidence_matrix()`, proiezioni con `bipartite.projection()`.

**Implicazione.** La rete di co-voto non va introdotta come costruzione ad hoc: è la
proiezione sui votanti del grafo bipartito votanti x tentativi RfA, cioè esattamente
l'esempio attori-film della lezione 5b slide 4. Questo copre il criterio 04 della guida del
docente (nodo, arco, direzione, peso dichiarati) usando il vocabolario del corso, e dà la
citazione teorica (Feld 1981, via Easley & Kleinberg cap. 4).

## 3. Il modello nullo che serve è già nelle slide, due volte

Il contesto §11.6 chiede "il termine di confronto o il modello nullo". Il corso ne dà due
schemi, entrambi riusabili quasi parola per parola:

- **Test di omofilia** (lezione 4, slide 6-22). Riassegnare a caso l'attributo dei nodi
  mantenendo le proporzioni osservate, e confrontare il numero di archi eterogenei con il
  valore atteso (2pq nel caso binario). Esteso a più di due valori: slide 21-22.
  Usabile per la diversità delle comunità dei sostenitori: se assegno a caso i votanti alle
  comunità con le proporzioni osservate, quanta diversità mi aspetto? Confronto con quella
  osservata.
- **Baseline di Kossinets & Watts** (lezione 4, slide 44-54). Si calcola la quantità
  osservata in funzione di k, si disegna accanto la curva di un modello a effetti
  indipendenti `1-(1-p)^k`, e si guarda da che parte devia il dato reale.
  È il modello di come si presenta un baseline, e soddisfa il criterio 07 ("give a baseline:
  random, expected, or a comparison group").

## 4. La brokerage: il corso dà la teoria E la misura

- Lezione 3 slide 64-82: **embeddedness** di un arco (numero di vicini in comune),
  **local bridge** = arco con embeddedness 0, **neighborhood overlap** (Onnela et al.,
  slide 47-50), **buchi strutturali** di Burt (slide 76-81), capitale sociale (slide 82).
- Lezione 3 slide 110: "nodes of high betweenness occupy critical roles in the network -
  nodes that span structural holes". Il corso quindi **collega esplicitamente betweenness e
  buchi strutturali**.
- In R sono insegnate `betweenness()`, `edge_betweenness()` (5a slide 980-997),
  `transitivity()` locale e globale (5a slide 902-909). I **vincoli di Burt**
  (`constraint()`) non sono insegnati.

**Implicazione** sulla decisione §11.4 (quale misura di brokerage): betweenness e
neighborhood overlap sono dentro il programma e il corso le lega ai buchi strutturali;
`constraint()` di Burt no. A parità di senso, la prima scelta costa meno da difendere.

## 5. Centralità: cosa è insegnato e cosa no

Insegnate, con il codice: `degree()` con `mode="in"/"out"/"all"` e `centr_degree()`
(5a slide 948-951), `closeness()` (5a 959-963), `betweenness()` (5a 980-988),
`evcent()` eigenvector (6 slide 23-25), hub e authority di Kleinberg (5a 1008-1022),
PageRank citato come esempio (6 slide 21). `transitivity()`, `dyad_census()`.

Due dettagli utili:
- Lezione 6 slide 34: il docente calcola `cor(betweenCent, eigenCent)` = 0.50 e commenta che
  le due misure sono distinte. È il precedente interno al corso per il controllo di
  correlazione che il contesto §8.2 chiede prima di mettere centralità e numero di votanti
  nella stessa regressione: va fatto e va mostrato.
- Lezione 6 slide 26-30: l'eigenvector centrality decade molto in fretta (nel loro esempio
  il 90% dei nodi sotto 0.5, mediana 0.11). Se si usa, va binnata o trasformata.

## 6. Selection vs social influence: la cornice teorica giusta per la domanda

Lezione 4 slide 23-31 e 64-70. Selection = le caratteristiche individuali formano i legami;
social influence = i legami formano le caratteristiche. Snapshot singolo non li distingue
(slide 26): serve il **longitudinale**, cioè guardare i cambiamenti dopo i cambiamenti.

**Implicazione.** La domanda del progetto è longitudinale per costruzione (t -> t+1), e questo
è un punto di forza da dichiarare, non da nascondere. Ma attenzione: l'esempio del corso
(slide 64-70, proprio su **editor di Wikipedia**) mostra che la similarità cresce sia prima sia
dopo il primo contatto; la curva non è simmetrica attorno allo zero, e questo è il massimo che
si può dire. Non si può concludere causalità. Coerente con il brief ("associations, not
effects") e con Olteanu §7.4.

## 7. Lezione 11 + Olteanu 2019: la sezione "limiti e bias" si scrive da qui

Lezione 11 è interamente basata su Olteanu, Castillo, Diaz, Kiciman (2019),
"Social data: Biases, methodological pitfalls, and ethical boundaries", *Frontiers in Big Data*
2:13. Il PDF completo è in `docs/Olteanu 2019.pdf`. **È il quinto riferimento scientifico
che serve al progetto, ed è materiale del corso: va citato.**

Le categorie che colpiscono questo progetto, con il nome esatto da usare:

| Categoria (Olteanu) | Dove colpisce il progetto |
|---|---|
| **Redundancy** (§3.7) | i "duplicate vote rows" del brief. Olteanu: la ridondanza distorce la quantificazione, ma "can also be a signal by itself". Se i duplicati sono voti cambiati, sono segnale, non rumore. |
| **Temporal variations** (§3.6) | 2003-2013: cambiano chi usa il sistema, come lo usa e il sistema stesso. È la giustificazione, con citazione, del controllo per anno (contesto §8.6). |
| **Functional biases** (§4.1) | il processo RfA è un'affordance: finestra di ~7 giorni, chiusure anticipate SNOW/NOTNOW. La soglia di ricostruzione dei tentativi dipende da una regola della piattaforma, non dai dati. |
| **Normative biases** (§4.2) | **il punto più serio.** Nelle RfA i voti sono pubblici e sequenziali. Olteanu: "social conformity and herding happen in social platforms. Prior ratings and reviews..." Quindi la quota di sostegno non è la somma di giudizi indipendenti, e gli archi di co-voto possono riflettere conformità al voto già visibile, non affinità fra votanti. Minaccia l'interpretazione delle comunità di co-voto come coalizioni. Va dichiarato con la direzione: gonfia la coesione apparente delle comunità. |
| **Linking biases** (§3.5) | "behavior-based and connection-based social links are different": la rete di voto è di comportamento, non di amicizia dichiarata. Un voto non è un legame sociale. |
| **Population biases** (§3.2) | i votanti RfA non sono gli editor di Wikipedia, né gli utenti del web. Nessuna generalizzazione oltre i votanti RfA. |
| **Data filtering** (§5.3) | "outliers are sometimes relevant": escludere 2003 e 2013 (precedente Kolczynska) e togliere i voti senza data sono filtri che vanno contati e giustificati, non applicati in silenzio. |

Le tre validità di Olteanu §2.3 danno la struttura della sezione limiti, meglio del semplice
elenco:
- **construct validity**: un voto favorevole misura "sostegno"? una comunità di co-voto misura
  una "coalizione"? (qui entra il bias normativo);
- **internal validity**: la ricostruzione dei tentativi e la deduplica sono scelte di pulizia
  che possono creare il risultato. Olteanu dice esattamente questo: i bias introdotti dalle
  procedure di cleaning sono minacce alla validità interna. È il nostro problema dei 29.
- **external validity**, inclusa la **temporal validity**: wiki-Elec valida solo fino a
  gennaio 2008; sul 2008-2013 non c'è validazione.

Olteanu §8.3: "disclaimers about the limitations of an analysis are fundamental to good
practice... Need for data and tools sharing". Coerente con la consegna di codice e dati.

## 8. Le figure: regole operative (slide "Data Visualization - Good Practices")

Il deck è di Ana Lucia Schmidt. Regole che toccano le nostre 4 figure al massimo:
- "ONE PLOT, ONE MESSAGE" (slide 59);
- "BOXPLOTS CAN HIDE INFORMATION" (slide 9) -> coerente con l'idea di sovrapporre i punti per
  il gruppo dei 29 e dei 9;
- "MAKE SURE YOU KNOW WHAT THE ERROR BAR IS PLOTTING. Also note very different data and
  distributions can have the same error bar" (slide 12);
- asse y a zero per barre e colonne; non troncare né l'asse y né l'asse temporale (24, 26);
- niente torte (5), niente 3D (52), niente chart junk (33), niente doppio asse: sfaccettare (39);
- non sovrapporre troppo: alpha, dimensione, hexbin (16);
- colore solo se porta informazione (31); ordinare i dati quando ha senso (44); scale comuni
  nelle sfaccettature (47);
- "CORRELATION IS NOT CAUSATION" (41).

## 9. Materiale in docs/ che NON serve a questo progetto

- `A review of sentiment computation methods with R packages.pdf`, `Topic Modeling with
  BERTopic.pdf`: sentiment e topic extraction. Il campo TXT (commenti dei voti) di wiki-RfA
  renderebbe possibile un'analisi testuale, ma non è nella domanda approvata e non va aggiunta
  a quattro giorni dalla consegna. Restano utili per la parte teorica dell'orale (30%).
- `Private_traits_in_digital_records.pdf` e `kosinski-et-al-2013-...pdf`: lo stesso lavoro
  (Kosinski, Stillwell, Graepel 2013, PNAS). Tema etico/predittivo, fuori dalla nostra domanda.
- Lezioni 1 e 2: introduzione, notazione dei grafi, grado medio, Koenigsberg. Niente che tocchi
  le decisioni aperte.

## 10. Cosa NON ho trovato nel materiale

Verificato con ricerca testuale su tutti i file:
- nessuna menzione di regressione logistica, modelli statistici, odds ratio, intervalli di
  confidenza. I "metodi quantitativi" richiesti dal §1.4 delle istruzioni, per il corso,
  sono le misure di rete. La regressione del passo 4 del brief è fuori dal programma:
  legittima, ma va tenuta parsimoniosa e spiegabile, e il peso del progetto resta sulla rete.
- nessuna menzione di `backbone`, estrazione di backbone o modelli nulli per proiezioni
  bipartite. Se si usa, è un'aggiunta nostra da giustificare.
- nessuna menzione di assortatività, ERGM, modelli a blocchi.
- niente sulle reti con segno (voti positivi/negativi) come oggetto teorico, nonostante
  il dataset sia firmato e nonostante Leskovec et al. 2010 sia la fonte di wiki-Elec.
  Separare sostegno e opposizione, come fa il brief, resta la scelta prudente.
