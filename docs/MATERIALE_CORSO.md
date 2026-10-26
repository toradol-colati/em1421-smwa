# EM1421 — Materiale del corso: riferimento di lavoro

Sintesi di tutti i file in `docs/`, letti il 26/10/2026. Serve a due cose insieme:
studiare per l'orale (30% teoria) e sviluppare il progetto senza riaprire i PDF.

I numeri di slide sono quelli dei PDF in `docs/`. Le formule sono riscritte in notazione
leggibile. Dove il materiale tocca una decisione aperta del progetto c'è un blocco
**→ Progetto**; quelli non sono decisioni prese, sono vincoli e precedenti. Le scelte di
metodo restano di Bubi e Mihretab (vedi `EM1421_RfA_contesto_nuova_chat.md` §11).

Indice:
1. Mappa dei file
2. Lezione 1 — Introduzione
3. Lezione 2 — Grafi: notazione e proprietà
4. Lezione 3 — Legami forti e deboli, buchi strutturali, partizione
5. Lezione 4 — Reti nei contesti: omofilia, affiliazione, selection vs influence
6. Lezione 5a/5b — igraph: ricettario
7. Lezione 6 — Reti di citazione: centralità e comunità applicate
8. Lezione 11 + Olteanu 2019 — Bias, errori metodologici, etica
9. Data visualization: le regole
10. Indice delle funzioni R insegnate
11. Le sei implicazioni che contano per il progetto
11-bis. Quanto codice si può scrivere oltre quello delle slide
12. Cosa il corso NON copre
13. Bibliografia citabile presente in docs/

---

## 1. Mappa dei file

| File | Cosa è | Serve al progetto |
|---|---|---|
| `1-EM1421.pdf` | Introduzione, reti sociali e informative | Marginale (contesto) |
| `2-EM1421.pdf` | Grafi: grado, matrice di adiacenza, cammini, componenti, small world | Definizioni di base |
| `3-EM1421.pdf` | Granovetter, chiusura triadica, ponti locali, buchi strutturali, Girvan-Newman | **Centrale** |
| `4-EM1421.pdf` | Omofilia e test, selection/influence, reti di affiliazione, chiusure | **Centrale** |
| `5-EM1421a.pdf` | igraph: costruzione, attributi, metriche | **Centrale** (codice) |
| `5-EM1421b.pdf` | igraph: bipartiti e proiezioni, layout, visualizzazione | **Centrale** (codice) |
| `6-EM1421.pdf` | Applicazione: rete di citazioni, centralità, comunità | **Centrale** (codice) |
| `11. Social Data - Biases...pdf` | Bias e insidie metodologiche | **Centrale** (limiti) |
| `Olteanu 2019.pdf` | Il paper su cui la lezione 11 è interamente basata | **Centrale** (citazione) |
| `Data Visualization - Good Practices.pdf` | Regole per i grafici | **Centrale** (4 figure) |
| `writing_your_project.txt` | Criteri 01–08 del docente | **Centrale** (struttura) |
| `EM1421_projectsInstructions.txt` | Regole formali del progetto | **Centrale** (vincoli) |
| `Writing a scientific article...txt` | Ecarnot et al. 2015, guida IMRAD | Scrittura |
| `extra-EM1421.txt` | Cinque esempi di progetto del corso | Riferimento |
| `Exam guidelines.pptx` | **Non è di questo corso**: è di "Digital HR & Organization", prof.ssa Annamaria Gimigliano. File finito in `docs/` per errore | No |
| `Introduction - EM1421 ... .txt` | Trascrizione della lezione 1 | Duplicato |
| `A review of sentiment computation methods with R packages.pdf` | Sentiment in R | No (altra lezione) |
| `Topic Modeling with BERTopic.pdf` | Topic modeling | No (altra lezione) |
| `Private_traits_in_digital_records.pdf` + `kosinski-et-al-2013-...pdf` | Kosinski et al. 2013, PNAS (doppia copia) | No (etica/predizione) |

---

## 2. Lezione 1 — Introduzione

Contenuto: nuovo spazio informativo, bias, algoritmi, polarizzazione, contagio sociale,
echo chamber, misinformazione. Poi: cos'è una rete, network science, reti sociali, reti
informative.

- **Polarizzazione di gruppo** (slide 19): quando persone che già pensano allo stesso modo
  discutono fra loro, rafforzano la posizione condivisa e finiscono su una posizione più
  estrema (Sunstein 1999; esperimento di Asch 1955).
- **Grafo** (slide 29-30): `G = (V, E)`; `|V| = N` dimensione, `|E| = L` numero di archi.
- **Network science** (31-33, def. da Barabási 2016): interdisciplinare, empirica e guidata
  dai dati, quantitativa. Scoperta chiave: architetture simili in domini diversi perché
  governate dagli stessi principi organizzativi.
- Esempi storici: **sociogrammi di Moreno** (37-39, 1934, primo esempio di SNA e di
  visualizzazione); **Karate Club di Zachary** (40-45, 34 membri, 2 anni, la scissione
  prevista quasi perfettamente da Girvan-Newman 2002: un solo nodo classificato male);
  **Chains of affection** (46-47, Bearman, Moody, Stovel 2004, reti sentimentali in un liceo).
- **Computational social science** (48-49, Lazer et al. 2009): la sociologia aveva gli
  strumenti ma li aveva affinati dove la raccolta dati era possibile (laboratorio, focus
  group, survey); i dati digitali cambiano la scala.
- **Numero di Dunbar** (50-56): limite cognitivo ~150 relazioni stabili; validato su Twitter
  da Gonçalves, Perra, Vespignani 2011 (1,7 M individui, 6 mesi): 100-200 relazioni stabili.
  Metafora della slide 56: il microblogging è come una calcolatrice da tasca, velocizza il
  calcolo ma non aumenta la capacità cognitiva.
- **Reti informative** (57-63): Adamic & Glance 2005 "Divided They Blog" (1.494 blog, 2 mesi
  prima delle presidenziali 2004; i blog conservatori si linkano fra loro più spesso e più
  densamente; due cluster ben separati); Del Vicario, Zollo et al. 2017 sul dibattito Brexit
  su Facebook (archi fra pagine definiti dall'interazione degli utenti con i contenuti).

**→ Progetto.** Due precedenti utili alla retorica dell'introduzione: Zachary (una
partizione di rete che prevede un evento sociale successivo) e Adamic & Glance (comunità
separate che si vedono dalla struttura). Entrambi sono "cambiamento sociale leggibile nella
rete", che è la nostra tesi. Il Brexit paper di Zollo mostra che archi definiti da
comportamento, non da amicizia dichiarata, sono accettati nel corso.

---

## 3. Lezione 2 — Grafi: notazione e proprietà

Base: ponti di Königsberg (slide 2-10). Euler 1735: un cammino che attraversa ogni ponte una
volta sola non può esistere su un grafo con più di due nodi di grado dispari; Königsberg ne
aveva quattro. Due messaggi (slide 10): alcuni problemi diventano trattabili se rappresentati
come grafo; i grafi hanno proprietà che vincolano o abilitano il loro comportamento.

**Grado** (17-20):
- non orientato: `L = (1/2) · Σ k_i`, grado medio `<k> = 2L/N`;
- orientato: `k_i = k_i^in + k_i^out`; `L = Σ k_i^in = Σ k_i^out`;
  `<k^in> = L/N = <k^out>`.

**Distribuzione del grado** (21-24): `p_k = N_k / N`, probabilità che un nodo scelto a caso
abbia grado k; `N_k = N · p_k`.

**Matrice di adiacenza** (25-28): `A_ij = 1` se c'è un arco da j a i. Grado dalla matrice:
non orientato `k_i = Σ_j A_ji`; orientato `k_i^in = Σ_j A_ij`, `k_i^out = Σ_j A_ji`.
G non orientato ⟺ A simmetrica; cappi ⟺ elementi non nulli sulla diagonale.

**Sparsità** (29-30): `|E|_max = N(N-1)/2`. Le reti reali sono sparse, `|E| << |E|_max`
(Zachary: N=34, |E|=78, max 561). Conseguenza pratica dichiarata nella slide: conviene
memorizzare la **lista degli archi**, non la matrice piena.

**Reti pesate** (31-32): `A_ij = w_ij`. Esempi di peso: minuti di telefonate, anni di
amicizia.

**Cammini e cicli** (33-39): un cammino è una sequenza di archi, la lunghezza è il numero di
archi; un ciclo è un cammino di almeno 3 archi che torna al nodo di partenza con tutti gli
altri distinti. I cicli danno ridondanza (ARPANET: percorsi alternativi).

**Connettività** (40-47): grafo connesso = esiste un cammino fra ogni coppia. Componente
connessa: ogni nodo raggiunge ogni altro **e** l'insieme non è parte di uno più grande.
Grafo disconnesso ⟺ matrice di adiacenza riordinabile in forma diagonale a blocchi.

**Componente gigante** (48-55): componente connessa che contiene una frazione significativa
dei nodi. Quando esiste, di solito è l'unica: basterebbe un arco a fondere due giganti, e
quell'arco in genere si forma.

**Distanze** (56-57): `d_ij` cammino più breve; nei grafi orientati spesso `d_ij ≠ d_ji`.
**Diametro** = massima distanza fra due nodi. **Lunghezza media di cammino** `<d>`, calcolata
solo su nodi nella stessa componente.

**Small world** (59-70): Milgram 1967, mediana 6 sulle 64 catene arrivate a destinazione
("six degrees of separation"). Leskovec & Horvitz 2008 su 240 M di utenti Microsoft IM:
componente gigante quasi totale, media stimata 6,6, mediana 7. Limiti dichiarati nella slide
68: traccia solo chi usa l'instant messaging, e gli archi sono conversazioni, non amicizie.
Bhagat et al. 2016 su Facebook: 3,57 passi medi.

**→ Progetto.** Tre cose operative. (a) La rete di voto è orientata e `d_ij ≠ d_ji`: la
distinzione in-degree / out-degree è esattamente il punto §8.2 del contesto (l'informazione
nuova su un ripresentato sta negli archi **uscenti**, i voti che lui dà nelle RfA altrui).
(b) `<d>` e diametro vanno calcolati sulla componente gigante, e la frazione di nodi fuori
va dichiarata. (c) La critica della slide 68 (archi di conversazione ≠ amicizia, e copertura
parziale della popolazione) è la stessa che va fatta a noi stessi: un voto non è un legame
sociale, e i votanti RfA non sono gli editor di Wikipedia.

---

## 4. Lezione 3 — Legami forti e deboli, buchi strutturali, partizione

### 4.1 Chiusura triadica e coefficiente di clustering

**Granovetter** (slide 3-4): intervistando chi aveva cambiato lavoro, scoprì che
l'informazione arrivava da **conoscenti**, non da amici intimi. Due prospettive: strutturale
(come quelle amicizie attraversano porzioni diverse della rete) e interpersonale.

**Chiusura triadica** (5-8, Rapoport 1953): se due persone hanno un amico in comune, è più
probabile che diventino amiche. Ragioni (15-18): **opportunità**, **fiducia**, **incentivo**.

**Coefficiente di clustering locale** (9-13):
`C_i = 2·L_i / (k_i·(k_i − 1))`, dove `L_i` = archi fra i vicini di i. Vale fra 0 e 1; è la
probabilità che due vicini di un nodo siano collegati fra loro. Medio sul grafo:
`<C> = (1/N) Σ C_i` (14).

### 4.2 Ponti, ponti locali, forza dei legami deboli

- **Ponte** (22): arco la cui rimozione mette i due estremi in componenti diverse. Rari nelle
  reti sociali reali (23).
- **Ponte locale** (24): arco i cui estremi non hanno amici in comune; rimuoverlo porta la
  loro distanza a > 2. **Span** = distanza che avrebbero senza quell'arco.
- (28) **Chiusura triadica e ponte locale sono opposti**: un arco è ponte locale esattamente
  quando non è lato di nessun triangolo.
- **Proprietà STC** (30-35): un nodo A **viola** la Strong Triadic Closure se ha legami forti
  con B e C e fra B e C non esiste alcun arco.
- **Teorema** (36-41): se A soddisfa STC e ha almeno due legami forti, allora ogni ponte
  locale di A è necessariamente un **legame debole**. Dimostrazione per assurdo nelle slide.
  Conclusione: i legami deboli collegano a informazione e opportunità nuove; il loro ruolo
  duale è la "forza dei legami deboli".
- **Onnela et al.** (45-56), rete di telefonate: forza del legame = minuti totali;
  **neighborhood overlap** di un arco A-B =
  `(# nodi vicini sia di A sia di B) / (# nodi vicini di almeno uno fra A e B)`.
  Vale 0 esattamente quando l'arco è un ponte locale. Risultati: l'overlap **cresce** con la
  forza del legame (52); rimuovendo gli archi dal più debole la componente gigante si sfalda
  bruscamente, dal più forte si riduce gradualmente (54-56) → i legami deboli tengono insieme
  le comunità.
- Tie strength su Facebook (57-61: comunicazione reciproca, unidirezionale, relazione
  mantenuta — categorie non mutuamente esclusive) e su Twitter (62-63, Huberman, Romero, Wu:
  legame forte = almeno due messaggi diretti).

### 4.3 Embeddedness, buchi strutturali, capitale sociale

- **Embeddedness** di un arco (69-75): numero di vicini in comune fra i due estremi. È il
  **numeratore** del neighborhood overlap; i ponti locali sono gli archi con embeddedness 0.
  Perché conta: i vicini comuni rendono l'interazione "pubblica", il cattivo comportamento ha
  conseguenze reputazionali, quindi più fiducia. Chi ha archi a embeddedness 0 corre più
  rischio ma ha meno vincoli.
- **Buchi strutturali** (76-81, Burt 1996): un nodo che sta fra due gruppi altrimenti
  disconnessi **colma un buco strutturale**. Vantaggi: accesso a informazione da fonti
  multiple, possibilità di idee nuove per combinazione, ruolo di **gatekeeper** (potere).
  Trade-off: meno protezione dall'embeddedness. Gli studi empirici citati legano il successo
  individuale all'accesso ai ponti locali.
- **Capitale sociale** (82): definizione difficile; Borgatti, Jones ed Everett la riassumono
  come proprietà di un gruppo o di un individuo, intrinseca al gruppo, o basata sulle
  interazioni del gruppo con l'esterno.

### 4.4 Betweenness e Girvan-Newman

- **Partizione di grafi** (84-93): due classi di metodi. **Divisivi**: identificare e
  rimuovere gli archi fra regioni dense (top-down). **Agglomerativi**: trovare nodi che
  appartengono alla stessa regione e fonderli (bottom-up).
- **Betweenness di un arco** (94-109): per ogni coppia di nodi connessi c'è 1 unità di flusso,
  divisa equamente fra tutti i cammini minimi; se ci sono k cammini minimi, `1/k` per
  ciascuno. La betweenness dell'arco è il flusso totale che trasporta.
- **Betweenness di un nodo** (110): stesso principio. Testuale: i nodi ad alta betweenness
  occupano ruoli critici, sono **i nodi che colmano buchi strutturali**.
- **Girvan-Newman** (111-122): (1) trovare l'arco o gli archi a betweenness massima e
  rimuoverli; (2) **ricalcolare** tutte le betweenness e ripetere; (3) procedere finché
  restano archi. Dà una gerarchia (dendrogramma).
- **Limite dichiarato** (122): funziona bene per reti di dimensione moderata, "few thousands
  nodes"; oltre, ricalcolare la betweenness a ogni passo è costoso. Alternative citate:
  approssimare la betweenness, o usare metodi agglomerativi.

Basata su Barabási cap. 2 e Easley-Kleinberg cap. 3.

**→ Progetto.** Qui c'è il vincolo più stretto di tutto il corso ed è il punto 1 della
sezione 11.

Qui c'è anche la risposta alla decisione §11.4 sulla **brokerage**: il corso lega
esplicitamente betweenness e buchi strutturali (slide 110), e insegna embeddedness e
neighborhood overlap. I **vincoli di Burt** (`constraint()` in igraph) non sono insegnati:
usarli è legittimo ma costa una difesa in più all'orale, a parità di significato.

E c'è un secondo precedente: il neighborhood overlap (47-50) è **esattamente la formula**
della sovrapposizione fra due insiemi di sostenitori che il progetto deve misurare fra t e
t+1 (archi in comune / archi dell'unione). Non va inventata una metrica nuova: è Jaccard, ed
è nel programma con questo nome.

---

## 5. Lezione 4 — Reti nei contesti

### 5.1 Omofilia e il suo test

**Omofilia** (slide 3-5): tendenza a essere simili ai propri amici — età, etnia, luogo,
lavoro, interessi, convinzioni. I legami, in aggregato, collegano persone simili. L'omofilia
dà anche una base **contestuale** alla chiusura triadica: se A-B e A-C esistono, B e C sono
probabilmente simili fra loro, quindi B-C ha probabilità elevata anche senza che sappiano di
avere A in comune.

**Test di omofilia** (6-22). Definizione di "assenza di omofilia": se si riassegnasse a caso
a ogni nodo l'attributo, rispettando le proporzioni osservate, il numero di archi eterogenei
non dovrebbe cambiare in modo significativo. Con frazione `p` di maschi e `q` di femmine, un
arco è cross-gender con probabilità `2pq`.

> **Homophily Test** (slide 14): se la frazione di archi cross-gender è significativamente
> **minore** di `2pq`, c'è evidenza di omofilia.

Esempio numerico (15-18): p = 6/9, q = 3/9, osservati 5 archi cross-gender su 18,
`2pq = 8/18` → attesi 8, osservati 5, evidenza di omofilia.

Tre note importanti (19-22): (a) il numero in una riassegnazione casuale **devia** dal valore
atteso, quindi serve una definizione operativa di "significativamente minore", cioè
quantificare la deviazione; (b) se la frazione è significativamente **maggiore** di `2pq` si
parla di **omofilia inversa**; (c) con attributi a più di due valori si contano gli archi
**eterogenei** e si confrontano con quelli attesi riassegnando i valori a caso con le
proporzioni osservate.

### 5.2 Selection e social influence

- **Selection** (23-24): le caratteristiche individuali guidano la formazione dei legami.
  Distinzione fra caratteristiche **immutabili** e **mutabili** (comportamenti, attività,
  interessi, opinioni).
- **Social influence** (25): i legami esistenti modellano le caratteristiche mutabili. È il
  rovescio della selection.
- **Il problema dell'identificazione** (26-31): uno snapshot singolo non separa i due
  effetti. Serve il longitudinale: osservare i cambiamenti di comportamento **dopo** i
  cambiamenti nei legami, contro i cambiamenti dei legami **dopo** i cambiamenti di
  comportamento. Esempio di Cohen e Kandel (adolescenti, rendimento e uso di droghe):
  entrambi gli effetti presenti, la social influence più moderata. Conseguenza pratica
  (29-30): se l'omofilia nasce da selection, un intervento sui soggetti non si propaga ai
  loro amici, perché cambiando comportamento cambiano anche la cerchia.

### 5.3 Reti di affiliazione

- **Foci** (32-33, Feld 1981): punti focali di interazione sociale — far parte di
  un'organizzazione, frequentare un posto, coltivare un interesse. Attività condivise
  aumentano la probabilità di interazione e quindi di un legame.
- **Rete di affiliazione** (34-38): grafo **bipartito**, un nodo per persona e uno per focus,
  arco se la persona partecipa al focus. Esempio: consigli di amministrazione. Due aziende
  risultano implicitamente collegate se la stessa persona siede in entrambi i consigli; due
  persone risultano collegate se siedono nello stesso consiglio.
- **Rete socio-affiliativa** (39-43): due tipi di arco, persona-persona e persona-focus.
  Tre tipi di chiusura:
  - **chiusura triadica**: A, B, C sono persone;
  - **focal closure**: A è un focus, B e C persone → due persone si collegano perché
    condividono un focus;
  - **membership closure**: A e B persone, C focus → B entra in un focus in cui l'amico A è
    già dentro (è una forma di social influence).

### 5.4 Come si misura la formazione dei legami: il metodo T(k)

**Procedura** (44-45), riusabile tale e quale:
1. prendere due snapshot della rete in tempi diversi;
2. per ogni k, identificare tutte le coppie di nodi con esattamente k amici in comune nel
   primo snapshot e **non** collegate direttamente;
3. definire `T(k)` = frazione di quelle coppie che risultano collegate nel secondo snapshot;
4. plottare `T(k)` in funzione di k.

Kossinets & Watts (47-51): 22.000 studenti, un anno di email, arco se si sono scambiati email
in entrambe le direzioni negli ultimi 60 giorni; media su molte coppie di snapshot a un
giorno di distanza. Risultato: `T(0)` quasi 0, poi crescita; il salto da 0 a 1 a 2 amici in
comune è più che proporzionale.

**La baseline** (52-54). Modello intenzionalmente semplificato: ogni amico in comune dà
indipendentemente probabilità `p` di formare il legame ogni giorno, quindi
`T_baseline(k) = 1 − (1 − p)^k`. Si disegna accanto ai dati (e anche traslata di uno,
`1 − (1 − p)^(k−1)`, data la debolezza del primo amico comune). I dati reali curvano **verso
l'alto** rispetto alla baseline → l'ipotesi di effetti indipendenti è troppo semplice.

- **Focal closure** (55-58): stessa procedura con il numero di **foci** condivisi (classi
  seguite insieme). Una classe condivisa ha circa lo stesso effetto assoluto di un amico
  comune, ma la curva piega **verso il basso** e si appiattisce: rendimenti decrescenti.
- **Membership closure** (59-63): probabilità di entrare in un focus in funzione del numero
  di amici già dentro. Misurata su LiveJournal e su **Wikipedia** (nodi = editor con pagina
  di discussione, arco = hanno comunicato su una talk page, focus = articolo editato).
  Cresce, con effetto marginale decrescente ma non trascurabile; più che doppia con due
  connessioni rispetto a una.

### 5.5 Selection vs influence su Wikipedia

(64-70) Rete: editor con talk page, arco se hanno comunicato. Similarità comportamentale fra
due editor =
`(# articoli editati da entrambi) / (# articoli editati da almeno uno)` — che è esattamente
il **neighborhood overlap** nella rete bipartita editor-articoli.

Risultato: le coppie che hanno comunicato sono significativamente più simili di quelle che non
lo hanno fatto (omofilia presente). Per separare selection e influence: per ogni coppia che ha
comunicato, si registra la similarità nel tempo, ponendo **t = 0 al primo contatto**. La
similarità cresce **sia prima sia dopo** il momento zero → entrambi gli effetti sono al
lavoro; la curva **non è simmetrica** attorno allo zero; i livelli sono molto più alti che
per le coppie che non hanno mai interagito.

Basata su Easley-Kleinberg cap. 4.

**→ Progetto.** Questa lezione risolve tre decisioni aperte, con il vocabolario del corso.

**(a) La rete di co-voto non è una costruzione ad hoc.** È la proiezione sui votanti del
grafo bipartito votanti × tentativi RfA: reti di affiliazione, slide 34-38, e la proiezione è
l'esempio attori-film della 5b. Il tentativo RfA **è** un focus nel senso di Feld. Dichiarare
nodo, arco, direzione e peso in questi termini copre il criterio 04 del docente e dà la
citazione teorica (Feld 1981, via Easley-Kleinberg cap. 4). La **focal closure** è il
meccanismo che rende sensata l'idea di coalizione: due votanti si "collegano" perché
condividono un tentativo.

**(b) Il modello nullo del §11.6 esiste già, in due forme.** Il test di omofilia (slide 6-22)
per la diversità di comunità dei sostenitori: riassegnare a caso i votanti alle comunità
mantenendo le proporzioni osservate, confrontare la diversità osservata con quella attesa. E
la nota della slide 19 va presa alla lettera: serve una misura della deviazione, non il solo
confronto con la media, quindi randomizzazione ripetuta e distribuzione nulla. La baseline di
Kossinets & Watts (52-54) è invece il **modello di come si presenta** un termine di
confronto, cioè il criterio 07 del docente ("a result is a number with its uncertainty and a
comparison point").

**(c) La cornice teorica della domanda è selection vs social influence, non la causalità.**
La nostra domanda è longitudinale per costruzione (t → t+1) e questo è un punto di forza da
dichiarare. Ma il tetto è quello della slide 70: si può dire che il cambiamento avviene prima
e dopo, e che la curva non è simmetrica. Non si può dire che la rete causa l'esito. Coerente
con il brief ("associations, not effects") e con Olteanu §7.4. In più, l'esempio del corso è
**su Wikipedia**: è il precedente interno al corso più vicino al nostro oggetto, ed è da
citare.

---

## 6. Lezioni 5a e 5b — igraph: ricettario

Fonti dichiarate: tutorial NetSciX di Katherine Ognyanova (kateto.net) e Arnold & Tilton,
*Humanities Data in R*, cap. 6.

### 6.1 Costruire un grafo

```r
library(igraph)
g <- graph.empty(directed = TRUE)
g <- g + vertex("Elizabeth II")           # aggiunta esplicita dei nodi
g <- g + edges("Elizabeth II", "Charles") # i nodi mancanti vengono creati in silenzio
g1 <- graph(edges = c(1,2, 2,3, 3,1), n = 3, directed = FALSE)
g3 <- graph(c("John","Jim", "Jim","Jill"))        # nodi con nome: n non serve
g4 <- graph(c(...), isolates = c("Jesse","Janis"))# nodi isolati
graph_from_literal(a---b, b---c)   # - non orientato, +- -+ orientato, ++ simmetrico, : insiemi
graph.edgelist(matrice_2_colonne, directed = FALSE)
graph_from_data_frame(d = links, vertices = nodes, directed = TRUE)
graph_from_incidence_matrix(matrice)   # bipartito
graph("Zachary")                        # grafi storici inclusi
```

**Intestazione di un oggetto igraph** (5a slide 8-9): quattro lettere. `D`/`U` orientato o
no, `N` con nomi, `W` pesato, `B` bipartito. Poi gli attributi: `(v/c)` vertice carattere,
`(e/n)` arco numerico, `(g/c)` grafo carattere.

### 6.2 Attributi

```r
E(g); V(g); g[]                       # archi, nodi, matrice
V(g)$name; V(g)$status <- c(...)      # leggere e scrivere attributi di nodo
E(g)$type <- "email"; E(g)$weight <- 10
vertex_attr(g); edge_attr(g); graph_attr(g)
set_vertex_attr(); set_edge_attr(); set_graph_attr(g,"name","Email Network")
delete_graph_attr(g, "company")
simplify(g, remove.loops = TRUE, remove.multiple = FALSE,
         edge.attr.comb = c(weight = "sum", type = "ignore"))   # sum, mean, min, max, ignore
as_edgelist(g, names = TRUE); as_adjacency_matrix(g, attr = "weight")
as_data_frame(g, what = "edges"); as_data_frame(g, what = "vertices")
```

**Archi multipli → peso** (5a slide 53), il pattern esatto insegnato:

```r
links <- aggregate(links[,3], by = links[,-3], sum)   # 3a colonna = peso
links <- links[order(links$from, links$to), ]
colnames(links)[4] <- "weight"
rownames(links) <- NULL
```

### 6.3 Metriche

```r
# struttura
diameter(g, directed = FALSE); get_diameter(g, directed = FALSE)
mean_distance(g, directed = FALSE); distances(g)
distances(g, v = V(g)[media == "NY Times"], to = V(g), weights = NA)
shortest_paths(g, from = ..., to = ..., output = "both")
edge_density(g, loops = FALSE)        # = ecount/(vcount*(vcount-1)) se orientato
reciprocity(g); dyad_census(g)        # $mut, $asym, $null
transitivity(g, type = "global"); transitivity(g, type = "local")
transitivity(as.undirected(g, mode = "collapse"))
triad_census(g)                       # 16 tipi di triade, Davis & Leinhardt 1972

# grado
degree(g, mode = "in" | "out" | "all" | "total")
degree_distribution(g, cumulative = TRUE, mode = "all")
hist(deg, breaks = 1:vcount(g)-1)

# centralità (res = punteggi dei nodi, + centralization + theoretical_max)
centr_degree(g, mode = "in", normalized = TRUE)
closeness(g, mode = "all", weights = NA);  centr_clo(g, mode = "all", normalized = TRUE)
betweenness(g, directed = TRUE, weights = NA); edge_betweenness(g, directed = TRUE, weights = NA)
centr_betw(g, directed = TRUE, normalized = TRUE)
evcent(g)$vector                      # eigenvector
hub_score(g, weights = NA)$vector; authority_score(g, weights = NA)$vector

# comunità e sottografi
edge.betweenness.community(g)         # Girvan-Newman; $membership, sizes()
induced.subgraph(g, insieme_di_nodi)
bipartite.projection(g_bipartito)     # $proj1, $proj2
delete_edges(g, E(g)[weight < soglia]); g - E(g)[E(g)$type == "hyperlink"]
```

**Nota sulla centralizzazione** (5a slide 79): `centr_*` restituisce il punteggio a livello di
grafo oltre a quelli dei nodi. È il modo insegnato per dire "quanto questa rete è centralizzata".

### 6.4 Bipartiti e proiezioni (5b slide 2-15)

Grafo bipartito: nodi divisibili in due insiemi disgiunti U e V, ogni arco collega un U a un
V. Due proiezioni possibili: una collega due nodi U se condividono un V, l'altra viceversa.
Esempio: film (U) e attori (V) → la proiezione sugli attori collega chi ha recitato nello
stesso film.

```r
net2 <- graph_from_incidence_matrix(as.matrix(links2))
table(V(net2)$type)          # FALSE/TRUE: i due modi
net2.bp <- bipartite.projection(net2)
plot(net2, vertex.label = NA, vertex.size = 7, layout = layout_as_bipartite)
```

### 6.5 Visualizzazione (5b slide 18-70)

Due modi equivalenti: passare le opzioni a `plot()`, oppure scriverle come attributi
dell'oggetto (`V(g)$color`, `V(g)$size`, `E(g)$width`, `E(g)$arrow.size`, `V(g)$label`).

```r
plot(g, edge.arrow.size=.4, edge.curved=.1, vertex.color="orange",
     vertex.frame.color="#555555", vertex.label=V(g)$media,
     vertex.label.color="black", vertex.label.cex=.7)
V(g)$color <- colrs[V(g)$media.type]          # colore per categoria
V(g)$size  <- V(g)$audience.size * 0.7        # dimensione per attributo
E(g)$width <- E(g)$weight / 6                 # spessore per peso
legend(x=-1.1, y=-1.1, c("Newspaper","Television","Online News"),
       pch=21, col="#777777", pt.bg=colrs, pt.cex=2.5, bty="n", ncol=1)
plot(g, vertex.shape="none", vertex.label=V(g)$media)   # solo etichette
heatmap(netm[,17:1], Rowv=NA, Colv=NA, col=palf(20), scale="none", margins=c(10,10))
```

**Layout** (5b 40-57): `layout_randomly`, `layout_in_circle`, `layout_on_sphere`,
`layout_with_fr` (Fruchterman-Reingold, "nice but slow, recommended up to ~1,000 vertices"),
`layout_with_kk` (Kamada-Kawai, buono per grafi connessi), `layout_with_lgl` (per grafi
grandi connessi), `layout_as_bipartite`. I force-directed sono **non deterministici**: per
riproducibilità serve `set.seed()` prima (lezione 6, slide 15).

Per confrontare due grafi, **fissare il layout una volta** e riusarlo (5b 67):
```r
l <- layout_with_fr(net)
plot(net.h, layout = l, main = "Tie: Hyperlink")
plot(net.m, layout = l, main = "Tie: Mention")
```

**Sfoltire gli archi** (5b 61-62), il passaggio chiave:
> "There are more sophisticated ways to extract the key edges, but for the purposes of this
> exercise we keep the edges whose weight is above the average"
```r
cut.off <- mean(links$weight)
net.sp  <- delete_edges(net, E(net)[weight < cut.off])
```

**→ Progetto.** La slide 61 è il precedente interno al corso per sfoltire la proiezione di
co-voto: il docente **ammette** che esistono modi più sofisticati (è lì che entrerebbe il
pacchetto `backbone`) e usa la soglia sul peso medio. Due conseguenze: una soglia sul peso è
difendibile all'orale perché è il metodo mostrato a lezione; e se si usa `backbone`, la slide
61 è il punto dove agganciarlo ("il modo più sofisticato a cui le slide alludono"), con una
riga di giustificazione. Nessuna delle due scelte è gratis: la soglia è arbitraria, il
backbone è fuori programma.

Nota operativa sulle figure: `layout_with_fr` è raccomandato fino a ~1.000 nodi. Qualunque
figura di rete del progetto va fatta su un sottografo, non sulla rete intera, e con
`set.seed()`.

---

## 7. Lezione 6 — Reti di citazione: applicazione

Da Arnold & Tilton cap. 6. Dati: Supreme Court Citation Network, ~216.000 citazioni fra
opinioni di maggioranza della Corte Suprema USA, in due colonne (chi cita, chi è citato).

**Il problema di partenza** (slide 2-5): contare le citazioni è ragionevole ma racconta solo
una parte. Esempio: 97 citazioni contro 18, ma i due articoli possono essere ugualmente
centrali nei rispettivi sottocampi; e le 18 possono essere di qualità media più alta. Serve la
struttura.

**Il passaggio di scala** (9-14). Il grafo completo ha 25.417 nodi e 216.738 archi. Testuale:
si può lavorare con un grafo di queste dimensioni in R, ma è molto più facile prenderne un
sottoinsieme. E, cruciale: **campionare 100 nodi a caso darebbe un grafo sparso e non
interessante**. Quindi si usa un criterio **tematico** esterno (il Supreme Court Database
assegna codici di materia ai casi) e si estrae il sottografo indotto:

```r
matchingCases <- which(themes$issue %in% c(20040, 20050))
H <- induced.subgraph(G, themes$usid[matchingCases])   # 132 nodi, 729 archi
```

**Centralità** (20-37):
- **degree**: nelle reti di citazione equivale a contare le citazioni;
- **eigenvector** (`evcent`): peso proporzionale alla somma dei pesi dei vicini. Top:
  347US483, Brown v. Board of Education. Nota (26): i punteggi **decadono molto in fretta** —
  nel loro esempio oltre il 90% dei nodi sotto 0,5 e mediana 0,11. Rimedio insegnato (27-30):
  binnare con `quantile()` e `cut()`, poi colorare con `heat.colors()`;
- **betweenness**: identifica i nodi che collegano parti disgiunte. Top di nuovo Brown, ma i
  tre successivi non sono nella top ten dell'eigenvector, e
  `cor(betweenCent, eigenCent) = 0.50`. Commento della slide 35: le due misure sono
  chiaramente distinte.

**Comunità** (39-44): `edge.betweenness.community(H)`, poi `sort(table(w$membership))`.
Nell'esempio: tre comunità grandi (22, 29, 39 membri), quattro piccole (≤ 6), 29 singleton.
Pattern di visualizzazione insegnato: colorare solo le comunità non banali (> 3 membri) e
lasciare bianchi gli orfani.

```r
V(H)$color <- rep("white", length(w$membership))
keepTheseCommunities <- names(sizes(w))[sizes(w) > 3]
matchIndex <- match(w$membership, keepTheseCommunities)
V(H)$color[!is.na(matchIndex)] <- rainbow(5)[matchIndex[!is.na(matchIndex)]]
```

**→ Progetto.** Due cose, ed entrambe pesano.

**(a) Il corso ha già affrontato il nostro problema di scala, e la risposta non è
campionare.** 25.417 nodi → sottografo indotto scelto per **criterio teorico** (la materia
del caso), non a caso. Tradotto: la proiezione di co-voto va ridotta per criterio
sostantivo — i votanti dei candidati ripetuti, o i votanti attivi nella finestra di t — e il
criterio va dichiarato. Questo rende Girvan-Newman praticabile restando dentro il programma,
e il precedente è della lezione 6, non una nostra invenzione.

**(b) `cor(betweenCent, eigenCent)` della slide 34 è il controllo che il contesto §8.2
chiede.** Il docente calcola la correlazione fra due misure di centralità e la commenta
**prima** di interpretarle. Noi dobbiamo fare lo stesso fra centralità e numero di votanti /
quota di sostegno a t, e mostrarlo: è nello stile del corso, e il criterio 06 lo impone
("before modelling an index, check whether it is mostly a function of the predictor").

Terza nota: la gestione dell'eigenvector che decade (slide 26-30) serve se si usa quella
misura su una rete di voto, dove l'in-degree è fortemente concentrato.

---

## 8. Lezione 11 + Olteanu 2019 — Bias, insidie metodologiche, etica

La lezione 11 è **interamente** basata su: Olteanu, A., Castillo, C., Diaz, F. & Kıcıman, E.
(2019). "Social data: Biases, methodological pitfalls, and ethical boundaries". *Frontiers in
Big Data* 2:13. Il PDF completo è in `docs/Olteanu 2019.pdf`.

### 8.1 Le domande di partenza (slide 2)

Quanto il comportamento osservato dentro un medium riflette il fenomeno reale studiato;
quanto i risultati di un medium si generalizzano ad altri; quanto il dataset di lavoro è
rappresentativo dei dati della piattaforma; quanto gli strumenti sono robusti a bias e
variazioni; se gli errori sono distribuiti uniformemente fra classi di dati.

### 8.2 La pipeline (slide 3-5)

Acquisizione e preparazione → processing (pulizia, organizzazione, feature) → analisi (la
scelta dipende dall'obiettivo: descrivere, inferire, predire, estrarre relazioni causali) →
valutazione e interpretazione. Nota della slide 5: l'interpretazione dipende dalle assunzioni
sul **significato** di ogni dato — se un legame sociale nasce da amicizia, se un "like"
equivale a un endorsement.

### 8.3 Le tre validità (Olteanu §2.3) — la struttura della sezione limiti

- **Construct validity**: le nostre misure misurano ciò che crediamo? Un'ipotesi è
  un'asserzione su un costrutto latente; la validità di costrutto chiede se un calcolo su un
  dataset misuri davvero quel costrutto. Olteanu nota che è riconosciuta come importante ma
  affrontata da pochi lavori.
- **Internal validity**: l'analisi porta correttamente dalle misure alle conclusioni?
  Include esplicitamente i bias introdotti **dalle procedure di pulizia dei dati**, l'uso di
  classificatori, assunzioni sbagliate sulle distribuzioni.
- **External validity**: quanto i risultati si generalizzano? Include la **ecological
  validity** e la **temporal validity**, cioè quanto i costrutti cambiano nel tempo
  invalidando le conclusioni.

### 8.4 Le categorie di bias

**Qualità dei dati** (slide 6-9): **sparsità** (molte misure seguono power law: facili sulla
testa, difficili sulla coda lunga); **rumore** (la distinzione fra rumore e segnale dipende
dalla domanda — Salganik 2017; Baeza-Yates 2013: spesso il problema non è trovare più dati ma
i dati giusti, perché più dati possono voler dire più rumore); **rappresentatività** (rispetto
a una popolazione offline, a un contenuto rilevante, o a un comportamento); **data bias** =
distorsione sistematica che compromette la rappresentatività, valutabile solo confrontando
campioni di riferimento diversi, perché un campione "assoluto" di solito non esiste.

| Categoria | Definizione (Olteanu) | Punti chiave |
|---|---|---|
| **Population biases** (§3.2) | Differenze demografiche o di caratteristiche fra la popolazione nel dataset e quella obiettivo | La relazione fra popolazione studiata e popolazione obiettivo è spesso **ignota**; utenti diversi usano i meccanismi della piattaforma in modo diverso; i proxy per i tratti personali variano in affidabilità |
| **Behavioral biases** (§3.3) | Differenze di comportamento fra piattaforme, contesti o dataset | **Interaction biases** (come gli utenti interagiscono fra loro), **content consumption biases** (si consuma più contenuto da chi pensa come noi → echo chamber), la natura del compito influenza le tracce, **self-selection e misreport** (autocensura, propensione a parlare di esperienze estreme o positive) |
| **Content production biases** (§3.4) | Differenze lessicali, sintattiche, semantiche, strutturali nei contenuti | L'uso della lingua varia; i fattori contestuali e le relazioni fra utenti modellano il linguaggio; popolazioni diverse hanno propensioni diverse a parlare di certi temi; il contenuto degli utenti "esperti" o popolari differisce da quello degli utenti comuni |
| **Linking biases** (§3.5) | Differenze negli attributi delle reti ottenute da connessioni, interazioni o attività | Gli attributi di rete influenzano comportamento e percezioni e viceversa; **i legami basati sul comportamento e quelli basati sulle connessioni dichiarate sono diversi** — la rete da legami espliciti è significativamente più densa di quella da interazioni, e in quella da interazioni il grado è più piccolo e limitato; la formazione dipende anche da fattori esterni (geografia) |
| **Temporal variations** (§3.6) | Differenze di popolazione o comportamento nel tempo | Salganik: cambia **chi** usa il sistema, **come** lo usa, e **il sistema stesso**. Fenomeni stagionali e periodici; fenomeni a insorgenza improvvisa; la granularità temporale può essere troppo fine o troppo grossa; i dataset **decadono** (contenuti cancellati, account protetti, sospesi, disattivati) |
| **Redundancy** (§3.7) | Dati singoli presenti in copie multiple, uguali (duplicati) o quasi | Distorce la quantificazione; fonti multiple (stessa entità da più account, più utenti dallo stesso account, account di organizzazioni); **"redundancy can also be a signal by itself"** |
| **Functional biases** (§4.1) | Conseguenza dei meccanismi e delle affordance specifiche della piattaforma | Ogni piattaforma ha le sue azioni possibili, incoraggiate, difficili o non supportate; design e feature modellano il comportamento (ridurre la finestra di risposta su Facebook → risposte più brevi, più rapide, più frequenti); gli algoritmi di ranking influenzano il comportamento; conta anche **come** i contenuti sono presentati |
| **Normative biases** (§4.2) | Conseguenza di norme scritte o aspettative su norme non scritte | Le norme variano fra piattaforme, comunità e contesti; **la consapevolezza di essere osservati cambia il comportamento** (effetto Hawthorne): si condividono opinioni impopolari più facilmente in spazi privati o anonimi (positivity bias); **"social conformity and herding happen in social platforms"**, con esempio esplicito delle **valutazioni e recensioni precedenti** e della lunghezza dei commenti; tendenza a conformarsi a punti di riferimento |
| **External biases** (§4.3) | Fattori fuori dalla piattaforma: status socioeconomico, orientamento ideologico, istruzione, pressione sociale, privacy, lingua, personalità, cultura | Gli elementi culturali si riflettono nei dataset; gli eventi di grande impatto si riflettono sui social |
| **Non-individual accounts** (§4.4) | Interazioni non prodotte da individui: organizzazioni, agenti automatici | Le organizzazioni producono molto contenuto (oltre il 60% negli eventi di crisi); non tutti i bot sono nocivi; **identificarli e rimuoverli può non bastare**, perché il loro comportamento influenza quello umano |

**Raccolta dati** (§5, slide 35-39): acquisizione (le piattaforme scoraggiano la raccolta
terza, l'accesso programmatico ha limiti, la piattaforma può non catturare tutto il rilevante
— produzione/interazione contro esposizione — e può non dare accesso a tutto ciò che cattura;
le strategie di campionamento sono spesso opache); querying (le API hanno espressività
limitata, un bisogno informativo si può operazionalizzare in modi diversi, la scelta di
keyword e hashtag forma il dataset); **filtering** (rimuovere le porzioni irrilevanti — ma
**"outliers are sometimes relevant for data analysis"**, e il filtraggio del testo può
limitare analisi successive: anche le stopword portano segnale).

**Processing** (§6, slide 40-42): **cleaning** (rilevare e correggere errori e incoerenze —
da non confondere con il filtering); **enrichment** (annotazione umana: annotatori
inaffidabili, linee guida povere, categorie mal progettate, informazione insufficiente;
oppure automatica); **aggregation** (strutturare e trasformare può nascondere o far emergere
pattern divergenti — aggregare per utente dà peso uguale a ogni utente, aggregare per tema dà
più peso agli utenti più attivi).

**Insidie metodologiche** (§7, slide 43-47): l'agenda di ricerca rischia di essere guidata
dall'accesso ai dati e agli strumenti, usando i dati come fonte di ipotesi invece che come
strumento per testarle. Analisi qualitative: generalizzabilità sacrificata al dettaglio,
sensibili ai bias di interpretazione. **Statistica descrittiva**: contare entità e calcolare
sintesi; i conteggi semplici **ingannano se non è chiaro cosa si conta e perché**; le analisi
di correlazione sono sensibili al bias e la sfida è distinguere ciò che correla da ciò che è
causalmente legato. Inferenza e predizione: la composizione di training e test influenza i
risultati; variabili obiettivo, etichette e rappresentazioni diverse portano a risultati
diversi.

**Studi osservazionali** (§7.4): il gold standard è l'esperimento randomizzato; quando non è
praticabile o è eticamente inaccettabile si usano dati osservazionali, ma determinare la
causalità è difficile anche con la sperimentazione attiva. Senza un esperimento naturale, gli
studi osservazionali soffrono dei confondenti non controllati. Metodi disponibili sotto
assunzioni forti: matched analysis, variabili strumentali, regression discontinuity,
differences-in-differences. L'assunzione chiave è l'**ignorability** (le covariate non
osservate sono indipendenti dal trattamento) e senza forte competenza di dominio è difficile
da sostenere. Caso citato: gli studi su influenza fra pari e contagio sociale soffrono di una
difficoltà ostinata a separare questi effetti dall'**omofilia** (Christakis & Fowler
sull'obesità, contestati da Lyons e da Shalizi & Thomas).

**Valutazione e interpretazione** (§8, slide 48-51): le **metriche** possono essere
inconcludenti o avere problemi di affidabilità e validità, e due metriche pensate per la
stessa cosa possono essere incoerenti (il numero di post come proxy dell'interesse riflette
la produzione, non la lettura). L'assunto che le tracce online riflettano fenomeni reali
**è stato contestato**: i post vanno interpretati come **comunicativi, non rappresentativi**;
il significato delle tracce cambia col contesto; i legami possono incorporare segnali sociali
diversi; condividere può essere endorsement, interesse, o disapprovazione. Le analisi non
dovrebbero restare confinate a un solo dataset o metodo. Infine: le pubblicazioni di risultati
negativi sono scarse; i **disclaimer sui limiti sono fondamentali** per la buona pratica; se
errori e bias non possono essere esclusi, i ricercatori **devono** discutere lacune e limiti
di dataset, metodi e assunzioni; serve condivisione di dati e strumenti.

**→ Progetto.** Questa lezione, da sola, scrive la sezione "limiti e bias" richiesta dal §1.6
delle istruzioni, e Olteanu 2019 è il quinto riferimento scientifico: è materiale del corso,
va citato.

La mappatura sul nostro caso, con il nome esatto della categoria da usare nel report:

| Categoria | Dove colpisce il progetto |
|---|---|
| **Redundancy** | I "duplicate vote rows" del brief. Olteanu avverte che la ridondanza può essere **segnale**: se sono voti cambiati dallo stesso votante, buttarli è perdere informazione. Serve una regola dichiarata (per esempio: tenere l'ultimo voto per votante e tentativo) e il conteggio di quanti casi sono. |
| **Normative biases** | **Il punto più serio, e non è nel documento di contesto.** Nelle RfA i voti sono **pubblici e sequenziali**: chi vota vede i voti già espressi. Olteanu documenta herding e conformità, con esempio esplicito delle valutazioni precedenti. Conseguenze: (1) la quota di sostegno non è la somma di giudizi indipendenti; (2) un arco di co-voto può riflettere conformità al voto già visibile, non affinità fra votanti. Minaccia la **construct validity** dell'idea di "coalizione", e nella direzione prevedibile: **gonfia** la coesione apparente delle comunità. Va scritto nei limiti con la direzione, come chiede il criterio 08. |
| **Temporal variations** | 2003–2013: cambia chi si candida, come si vota e il processo RfA stesso. È la giustificazione **con citazione** del controllo per anno (contesto §8.6). Copre anche il decadimento del dataset: i voti senza data e i record incompleti. |
| **Functional biases** | Il processo RfA è un'affordance: durata nominale ~7 giorni, chiusure anticipate (SNOW/NOTNOW), possibilità di cambiare voto. La **soglia di separazione dei tentativi dipende da una regola della piattaforma**, non dai dati; se la regola è cambiata nel periodo, la soglia unica è un'approssimazione. |
| **Linking biases** | La rete di voto è basata sul comportamento, non su connessioni dichiarate. Olteanu: le due cose danno reti con proprietà strutturali diverse. Un voto non è un legame sociale, e la nostra rete non è "la rete sociale di Wikipedia". |
| **Population biases** | I votanti RfA non sono gli editor di Wikipedia, né la popolazione del web. Nessuna generalizzazione oltre i votanti RfA del periodo. |
| **Data filtering** (§5.3) | Escludere 2003 e 2013 (precedente Kołczyńska) e togliere i voti senza data sono **filtri**: vanno contati, giustificati e messi nel report, non applicati in silenzio. "Outliers are sometimes relevant." |
| **Data cleaning** → internal validity | Ricostruzione dei tentativi e deduplica sono procedure di pulizia che possono **creare** il risultato. È esattamente il problema dei 29 "previously successful": se sono artefatti della ricostruzione, l'intero confronto secondario è un artefatto. Olteanu nomina i bias da cleaning come minaccia alla validità interna: è la citazione da mettere accanto a quel limite. |
| **Studi osservazionali** (§7.4) | Il tetto interpretativo. Associazioni, non effetti. E la difficoltà di separare influenza e omofilia è la stessa che abbiamo fra "la posizione di rete cambia l'esito" e "chi avrebbe comunque successo si muove in modo diverso nella rete". |
| **Descriptive statistics** (§7.2) | "Simple counts can mislead if it is unclear what is counted and why." Ogni conteggio del report (414, 394, 29, 9 e i nostri) va accompagnato dalla regola che lo produce. |

Sull'etica (§9, slide non dettagliate): i dati SNAP sono pubblici, anonimizzati solo per
username, e gli username sono reali. Nel report non servono nomi di utenti: non citarne
nessuno, nemmeno in esempio.

---

## 9. Data visualization: le regole

Deck di Ana Lucía Schmidt. Le regole, applicabili alle **massimo 4 figure o tabelle** del
report:

- **"ONE PLOT, ONE MESSAGE"** (slide 59). Con quattro figure in tutto, ogni figura deve
  rispondere a un passo della domanda.
- **Niente torte** (5): "PIE CHARTS: BETTER NOT"; se proprio, i numeri devono sommare.
  Meglio barre o waffle.
- **I boxplot nascondono informazione** (9). → per i gruppi piccoli (29 e 9 casi):
  distribuzione con i punti sovrapposti, non un box nudo.
- **Sapere cosa mostra la barra d'errore** (12): "very different data and distributions can
  have the same error bar".
- **Non sovrapporre** (16): giocare con alpha, dimensione, colori; heatmap o hexbin.
- **Non troncare né espandere gli assi senza pensarci** (24): si può esagerare o minimizzare
  una differenza, e cambiare l'interpretazione; vale in particolare per l'asse x. Asse y
  **sempre a zero** per barre e colonne.
- **Non tagliare l'asse temporale** (26).
- **Colore deliberato** (31): il colore è informazione da processare; metterlo quando dice
  qualcosa, togliere altrimenti.
- **Niente chart junk** (33), **niente 3D** (52).
- **Scalare i cerchi per area, non per raggio** (37).
- **Evitare il doppio asse** (39): spezzare in due grafici o sfaccettare.
- **"CORRELATION IS NOT CAUSATION"** (41).
- **Ordinare i dati** quando ha senso (44).
- **Scale comuni nelle sfaccettature** (47).

Nota: lo zero assoluto conta (22, esempio dei Fahrenheit).

**→ Progetto.** Combinato con il criterio 07 del docente ("a result is a number with its
uncertainty and a comparison point"), ogni figura deve mostrare tre cose: il valore, la sua
incertezza, e il termine di confronto (modello nullo o gruppo). Una figura che mostra solo
medie per gruppo non soddisfa né il docente né questo deck.

---

## 10. Indice delle funzioni R insegnate

Costruzione: `graph.empty`, `graph`, `graph_from_literal`, `graph.edgelist`,
`graph_from_data_frame`, `graph_from_incidence_matrix`, `make_empty_graph`,
`make_full_graph`, `make_tree`, `make_star`, `make_ring`, `sample_pa`.

Struttura e attributi: `V`, `E`, `vcount`, `ecount`, `vertex_attr`, `edge_attr`,
`graph_attr`, `set_vertex_attr`, `set_edge_attr`, `set_graph_attr`, `delete_graph_attr`,
`simplify`, `delete_edges`, `induced.subgraph`, `as_edgelist`, `as_adjacency_matrix`,
`get.adjacency`, `as_data_frame`, `as.undirected`, `ends`.

Metriche: `degree`, `degree_distribution`, `diameter`, `get_diameter`, `mean_distance`,
`distances`, `shortest_paths`, `edge_density`, `reciprocity`, `dyad_census`, `triad_census`,
`transitivity`.

Centralità: `centr_degree`, `closeness`, `centr_clo`, `betweenness`, `edge_betweenness`,
`centr_betw`, `evcent`, `hub_score`, `authority_score`.

Comunità e bipartiti: `edge.betweenness.community`, `sizes`, `bipartite.projection`.

Visualizzazione: `plot.igraph`, `layout_randomly`, `layout_in_circle`, `layout_on_sphere`,
`layout_with_fr`, `layout.fruchterman.reingold`, `layout_with_kk`, `layout_with_lgl`,
`layout_as_bipartite`, `heat.colors`, `rainbow`, `colorRampPalette`, `legend`, `heatmap`,
`pdf`/`dev.off`, `set.seed`.

**Non insegnate** e quindi da giustificare se usate: `cluster_louvain` e tutti gli altri
`cluster_*`, `constraint` (vincoli di Burt), `assortativity`, `similarity`,
`power_law_fit`, il pacchetto `backbone`, qualunque cosa di `ergm`/`statnet`.

---

## 11. Le sei implicazioni che contano per il progetto

Ordinate per quanto bloccano il lavoro. Nessuna è una decisione: sono i vincoli dentro cui
Bubi e Mihretab decidono (contesto §11).

**1. Girvan-Newman non gira sulla nostra rete, e il corso non insegna alternative.**
È l'unico algoritmo di comunità del programma (lez. 3 e 6) e la slide 3-122 lo dichiara
adatto a "few thousands nodes". La proiezione di co-voto su 11.381 votanti non ci rientra.
La via dentro il programma è quella della lezione 6 (slide 10-13): **sottografo indotto per
criterio sostantivo**, non campionamento casuale, perché "if 100 nodes were randomly sampled
from this graph, we would likely be left with a sparse and uninteresting graph". Criteri
possibili: solo i votanti dei candidati ripetuti; o solo i votanti attivi nella finestra
precedente a t+1. In alternativa, o in aggiunta, sfoltire gli archi (lez. 5b slide 61).
L'opzione "uso Louvain" è legittima ma è fuori programma e va difesa all'orale.

**2. La rete di co-voto va presentata come proiezione di una rete di affiliazione.**
Lez. 4 (32-43) + 5b (2-15). Il tentativo RfA è un **focus** nel senso di Feld; la proiezione
sui votanti è l'esempio attori-film. Copre il criterio 04 del docente con il vocabolario del
corso e dà la citazione teorica. Il meccanismo che giustifica l'idea di coalizione è la
**focal closure**.

**3. I modelli nulli richiesti dal criterio 07 sono già nelle slide.**
Test di omofilia con riassegnazione casuale e valore atteso `2pq`, esteso a più categorie
(lez. 4, 6-22) — e la slide 19 impone di quantificare la deviazione, quindi randomizzazione
ripetuta. Baseline a effetti indipendenti `1 − (1 − p)^k` di Kossinets & Watts (lez. 4,
52-54) come modello di presentazione. Il **neighborhood overlap** (lez. 3, 47-50) è già la
formula della sovrapposizione fra insiemi di sostenitori.

**4. Il controllo di correlazione prima della regressione è nello stile del corso.**
Lez. 6 slide 34: il docente calcola `cor(betweenCent, eigenCent) = 0.50` e commenta che le
misure sono distinte **prima** di interpretarle. Il contesto §8.2 teme che in-degree e
centralità prima di t+1 ricalchino numero di votanti e quota di sostegno a t: quella
correlazione va calcolata e mostrata. Il criterio 06 lo impone ("before modelling an index,
check whether it is mostly a function of the predictor").

**5. Il bias normativo è un limite nuovo e serio, da scrivere nel report.**
I voti RfA sono pubblici e sequenziali; Olteanu §4.2 documenta herding e conformità alle
valutazioni precedenti. Minaccia la validità di costrutto delle comunità di co-voto come
coalizioni, e ne gonfia la coesione apparente. Non era nel documento di contesto.

**6. La brokerage con gli strumenti del corso.**
Betweenness (lez. 3, 94-110, con il legame esplicito ai buchi strutturali), embeddedness e
neighborhood overlap sono nel programma; i vincoli di Burt no. A parità di significato, la
prima scelta costa meno da difendere.

---

## 11-bis. Quanto codice si può scrivere oltre quello delle slide

Domanda posta il 27/10: il codice nelle slide basta per fare il progetto, e si può scrivere
altro? Verificato sulle fonti. Risposta: **il codice delle slide non basta, e scrivere altro
è esplicitamente previsto.** Nessun documento del corso limita il codice a quello mostrato a
lezione.

### Cosa dicono i documenti

- **Istruzioni, §1 Goal** (testuale): "The goal of the project is to perform an original data
  analysis by **applying** tools, methods, and techniques addressed during the course."
  Il vincolo è che il progetto **applichi** le tecniche del corso, non che usi soltanto quelle.
- **Istruzioni, §3.3**: "The entire analysis should be performed in R or Python." Il solo
  vincolo tecnico esplicito. Nessuna lista di pacchetti ammessi, nessun divieto.
- **Istruzioni, §5**: il codice va commentato adeguatamente, con tutti i file esterni
  necessari; "it is your responsibility to deliver a code that can be tested by the
  instructor". Il criterio è che **giri**, non che assomigli alle slide.
- **`extra-EM1421` (esempi di progetto)**: "Projects should align with the course framework
  and apply the analytical skills covered in class" e, prima, "They are not meant to be
  replicated but serve as inspiration for developing unique and creative projects."
- **`writing_your_project`, criterio 05**, cita come esempio di buona metodologia un progetto
  passato: "The analysis used R and included several steps: 1. Text Vectorization - reports
  were converted to numerical form using TF-IDF. 2. Clustering - K means (k = 4) grouped
  reports into major themes." **TF-IDF e k-means non sono nelle slide di rete.** È un progetto
  accettato che usa metodi fuori dal codice mostrato a lezione.
- Sempre nel criterio 05, un altro esempio citato giustifica l'uso della media invece della
  mediana per una distribuzione a coda grassa e l'uso del logaritmo con il +1: ragionamento
  statistico che nelle slide non c'è.

### Quanto codice c'è davvero nelle slide

Misurato: in tutte le lezioni l'unico pacchetto caricato è **`igraph`**, cinque volte.
`library(ggplot2)` non appare mai; `ggplot` compare una sola volta in tutti i file di `docs/`,
ed è **nel nostro brief**, non nelle slide. I grafici delle slide sono in R base
(`plot.igraph`, `hist`, `heatmap`, `legend`, `pdf`/`dev.off`).

Per la manipolazione dei dati le slide danno due cose sole: `read.csv()` per leggere nodi e
archi da CSV, e il pattern `aggregate()` per collassare archi multipli in un peso
(5a slide 53). Niente altro: nessun join, nessuna deduplica, nessun parsing di formati non
tabellari, nessuna gestione di date.

### Cosa serve al progetto e nelle slide non c'è

| Serve | Nelle slide |
|---|---|
| Leggere un file a record di 7 righe `CAMPO:valore` da `.gz` (198.275 voti) | No: solo `read.csv` di CSV normali |
| Deduplicare i voti, tenere l'ultimo per votante e tentativo | No |
| Parsare date e ore, calcolare differenze in giorni, applicare la soglia dei 7 giorni | No |
| Ricostruire i tentativi raggruppando per candidato / anno / esito | No: solo `aggregate` su un peso |
| Parsare i blocchi di wiki-Elec (righe E, T, U, N, V) | No |
| Unire tabelle (voti con tentativi, tentativi con esiti validati) | No |
| Randomizzazione ripetuta per il modello nullo | No: il test di omofilia è spiegato a parole, senza codice |
| Regressione logistica | No (vedi §12) |
| `ggplot2`, promesso nel nostro brief | No |

### Conclusione operativa

1. Non c'è nessun macigno da temere: il vincolo è che l'analisi sia in R, che il codice giri
   e sia commentato, e che le **tecniche di rete** del corso siano applicate e sapute spiegare.
2. Il discrimine non è "quanto codice", è **l'orale**: la discussione del progetto vale il 70%
   ed è subordinata al superamento della parte teorica sui contenuti del corso. Qualunque cosa
   si scriva, va saputa difendere a voce. Una funzione fuori programma non è un problema se si
   sa dire cosa calcola e perché quella e non un'alternativa (criterio 05: "a one-line
   reason for choosing it over the obvious alternative").
3. Ne segue il criterio pratico di scelta: a parità di risultato, preferire lo strumento
   insegnato; quando non esiste, usare quello che serve e scrivere la riga di giustificazione.
   Il codice di manipolazione dei dati è neutro - nessuno chiede che `aggregate` o
   `data.table` siano "da programma", sono infrastruttura. La scelta che va difesa riguarda i
   **metodi**: algoritmo di comunità, misura di brokerage, modello nullo, regressione.
4. `ggplot2` è nel brief **approvato dal docente**: è coperto dall'approvazione, non va
   rinegoziato.

## 12. Cosa il corso NON copre

Verificato con ricerca testuale su tutte le lezioni. Zero occorrenze di:
- **regressione logistica**, modelli statistici, odds ratio, intervalli di confidenza. Per il
  corso i "metodi quantitativi" del §1.4 delle istruzioni sono le misure di rete. La
  regressione del passo 4 del brief è fuori programma: legittima, ma il peso del progetto
  deve restare sulla rete, e il modello deve essere parsimonioso e spiegabile a voce;
- **Louvain, Leiden, modularità**, blockmodel, ERGM;
- **`backbone`** o qualunque estrazione di backbone, e qualunque modello nullo per proiezioni
  bipartite. Il metodo mostrato per sfoltire è la soglia sul peso medio (5b, 61);
- **assortatività**;
- **reti con segno** (voti positivi/negativi) come oggetto teorico, nonostante il dataset sia
  firmato e nonostante Leskovec, Huttenlocher, Kleinberg 2010 sia la fonte di wiki-Elec. La
  scelta del brief di tenere separati sostegno e opposizione resta la più prudente;
- analisi testuale applicata alle reti. Sentiment e topic modeling sono in `docs/` ma come
  materiale di altre lezioni: il campo TXT di wiki-RfA renderebbe possibile un'analisi dei
  commenti, ma non è nella domanda approvata.

---

## 13. Bibliografia citabile presente in docs/

Riferimenti scientifici completi disponibili nei file, utilizzabili per il minimo di 5
richiesto dal §1.2 delle istruzioni:

- **Olteanu, A., Castillo, C., Diaz, F. & Kıcıman, E. (2019).** Social data: Biases,
  methodological pitfalls, and ethical boundaries. *Frontiers in Big Data* 2:13.
  PDF completo in `docs/`. Materiale del corso (lezione 11).
- **Kosinski, M., Stillwell, D. & Graepel, T. (2013).** Private traits and attributes are
  predictable from digital records of human behavior. *PNAS*. PDF completo in `docs/`
  (doppia copia). Fuori tema per questa domanda.
- **Ecarnot, F. et al. (2015).** Writing a scientific article: a step-by-step guide for
  beginners. *European Geriatric Medicine* 6: 573-579. In `docs/` come txt. Guida IMRAD.

Riferimenti citati nelle slide ma **senza PDF** in `docs/` (da recuperare se si citano,
"cite what you use, use what you cite"):
Granovetter 1973 sulla forza dei legami deboli; Rapoport 1953; Burt 1996 sui buchi
strutturali; Girvan & Newman 2002 (PNAS 99:7821-7826); Zachary 1977; Moreno 1934; Feld 1981
sui foci; Kossinets & Watts; Onnela et al.; Adamic & Glance 2005; Del Vicario, Zollo et al.
2017 (*Social Networks* 50); Lazer et al. 2009 (*Science* 323:721-723); Gonçalves, Perra &
Vespignani 2011; Leskovec & Horvitz 2008; Bearman, Moody & Stovel 2004 (*AJS* 110:44-91);
Davis & Leinhardt 1972; Sunstein 1999.

Testi di riferimento del corso: Easley, D. & Kleinberg, J. (2012), *Networks, Crowds, and
Markets*, Cambridge UP (bozza completa gratuita online); Barabási, A.-L. (2016), *Network
Science*, Cambridge UP. Le lezioni 2 e 3 sono basate sul cap. 2 di Barabási e sui cap. 2-3 di
Easley-Kleinberg; la 4 sul cap. 4 di Easley-Kleinberg; la 5a e la 6 su Arnold & Tilton (2015),
*Humanities Data in R*, cap. 6, e sul tutorial NetSciX di Katherine Ognyanova.
