# EM1421 – Progetto "Repeat Requests for Adminship": contesto per una nuova chat
Stato al 26 ottobre 2026. Allegare insieme a questo file:
1. EM1421_group_project_brief.pdf (il brief del progetto);
2. EM1421_projectsInstructions (regole del progetto);
3. writing_your_project (criteri 01–08 del docente);
4. extra-EM1421 (esempi di progetto);
5. slide introduttive del corso;
6. Ecarnot et al. 2015, guida alla scrittura;
7. la valutazione di Gemini (txt).


## 1. Istruzioni per Claude (leggere prima di rispondere)

- **Modo di lavorare:** brainstorm. Le scelte (domanda, metodi, definizione delle reti, variabili) le fanno lo studente e il collega. Tu proponi, verifichi e critichi.
- **Registro:** secco, diretto, tecnico, senza giri di parole.
- **Niente stime di durata** ("per fare X ci metti Y ore") e niente piani a calendario. Se serve un ordine, va per dipendenza logica.
- **Verifica prima di affermare:** controlla numeri, fonti e passaggi. Dichiara tu i punti deboli, prima che li trovi lo studente. Tieni sempre separato il verificato dal non verificato. Non attribuire a una fonte ciò che non dice.
- **Niente compiacenza:** se lo studente, il collega, il brief o un'altra IA sbagliano, dillo.
- **Obiezioni:** se lo studente obietta sul tuo modo di lavorare, rispondi all'obiezione. Non trasformarla in un altro compito.
- **Policy sull'IA del corso:** il testo vieta di usare l'IA generativa per concepire, redigere o sviluppare proposta e progetto. Lo studente riferisce che il docente ha chiarito a lezione che il supporto dell'IA è consentito e che conta saper interpretare correttamente i risultati. Non riaprire il tema.
- **Progetto abbandonato:** quello precedente dello studente per questo corso (percezione del "degrado architettonico" a Venezia sul web) non va riproposto.


## 2. Chi e cosa

- **Studente:** Bubi (Umberto Toraldo), laurea magistrale in Data Analytics a Ca' Foscari.
- **Corso:** EM1421 Social Media and Web Analytics, a.a. 2026/2027. Docente Pierluigi Zama Ramirez; slide di Fabiana Zollo.
- **Gruppo:** due persone. Il brief prevede due ruoli: "Data member" (preparazione dati e validazione degli esiti) e "Network member" (analisi di rete e modelli). In comune: letteratura, report, revisione del codice e presentazione. Quale ruolo abbia Bubi non è indicato.


## 3. Regole del progetto (dalle istruzioni ufficiali)

### Esame
- Orale con domande teoriche ed esercizi (30%) più discussione del progetto (70%).
- La discussione si fa solo se si supera la parte teorica.
- Gruppi da due: 7 minuti per obiettivo e risultati principali; slide facoltative.
- "Admission to the oral discussion is subject to compliance with the project requirements".

### Obiettivo (§1)
1. Domanda di ricerca motivata.
2. Almeno 5 pubblicazioni scientifiche in bibliografia.
3. Raccolta dei dati.
4. Metodi quantitativi, "paying particular attention to the visualization of the results".
5. Interpretazione dei risultati.
6. Limiti e bias.

### Dati (§2)
- Liberi e combinabili.
- "You can rely on available datasets, provided that the research question underlying the analysis is original."

### Specifiche (§3)
- Nel report niente codice né descrizione del codice.
- Tema concordato prima con il docente.
- Analisi interamente in R o Python.
- Al massimo 4 figure o tabelle in totale, con didascalia e richiamate nel testo.
- Bibliografia soprattutto scientifica, almeno 5 riferimenti.
- Per i gruppi da due:
  - un paragrafo sul contributo di ciascuno;
  - report tra 12.000 e 20.000 caratteri, spazi inclusi.

### Proposta (§4)
- Si invia con il modulo Moodle.
- "Please wait for approval before starting work on your project".

### Consegna (§5)
- Report in PDF, più codice commentato e dati, con tutti i file necessari a eseguirlo.
- "It is your responsibility to deliver a code that can be tested by the instructor."
- Scadenza: entro le 9:00 CET di due giorni prima dell'appello, con email di conferma al docente.

### Esempi del corso
- Sono cinque e ognuno ha una sola fonte dati: Twitter, Reddit, Staker News, Spotify, Amazon.
- Tutti usano la network analysis.


## 4. Criteri della guida "Writing your project" (citazioni)

- **01 Domanda:** deve essere chiaro "what would count as an answer". "A variable cannot sit on both sides of the question."
- **02 Motivazione:**
  - "A gap is something we do not know, not a method nobody has applied yet."
  - "Cite what you use, use what you cite."
- **03 Dati:** "A reader should be able to rebuild the dataset from the report: source, collection method, period, volumes, filters, and any sampling made for a specific analysis — with numbers that agree with each other."
- **04 Rete:**
  - "Every network needs four explicit choices — what a node is, what an edge is, whether edges are directed, and what (if anything) weights them — and each choice should make sense for the question."
  - "Write the node, edge, direction and weight in one or two sentences before any metric."
- **05 Metodi** (parafrasi): ogni metodo risponde a un passo della domanda, con una riga sul perché rispetto all'alternativa ovvia.
- **06 Errori:**
  - "Before modelling an index, check whether it is mostly a function of the predictor."
  - "Never use as predictor a variable that enters the definition of the outcome."
  - "If a model works almost perfectly, suspect leakage first."
  - "Ask: would I get this result even with random data?"
- **07 Risultati:**
  - "A result is a number with its uncertainty and a comparison point".
  - "Give a baseline: random, expected, or a comparison group."
- **08 Limiti:** "Name the limitation, say which result it threatens, and in which direction if you can."
- **Guida di scrittura** (Ecarnot et al. 2015, European Geriatric Medicine 6: 573–579):
  - formato IMRAD;
  - obiettivo formulato una volta e ripetuto identico;
  - risultati senza commenti;
  - citare la fonte originale.


## 5. Il progetto (dal brief del 26/10/2026)

**Titolo:** Repeat Requests for Adminship. Network change, prior outcomes and later success.

**Stato:** "The proposal has been drafted and preliminary data feasibility checks are complete. It has not yet been submitted or approved."

**Domanda (testo del brief):** "Among repeat Requests for Adminship candidates, how do changes in voter-community composition, support-coalition overlap and network position differ between previously rejected and previously successful candidates, and how are these changes associated with the next outcome?"

### Numeri del brief
- 198.275 voti grezzi.
- 11.381 votanti e candidati.
- 490 candidati ripetuti, così divisi: 451 previously rejected, 53 previously successful, 14 con entrambi gli esiti.
- I gruppi si sovrappongono: 451 + 53 − 14 = 490.

### Dati

| Fonte | File | Dimensione | Copertura | Ruolo |
|---|---|---|---|---|
| SNAP wiki-RfA | wiki-RfA.txt.gz | 14.970.777 byte | 2003 – maggio 2013 | Voti e commenti, dati primari |
| SNAP wiki-Elec | wikiElec.ElecBs3.txt.gz | 1.090.375 byte | 2.794 elezioni fino a gennaio 2008 | Validazione degli esiti |

**Audit flag del brief:** "The raw primary file contains duplicate vote rows, conflicting result labels and missing dates. Records will be deduplicated, outcomes validated and unresolved cases reported as ambiguous."

### Piano in quattro passi
1. **Preparare i dati.** Leggere i due file, normalizzare gli username, togliere i voti duplicati, ricostruire i tentativi separati con le date dei voti, validare gli esiti e segnare i casi irrisolvibili.
2. **Costruire la rete.** Gli utenti sono i nodi; un voto da votante a candidato è un arco diretto; sostegno e opposizione sono tenuti separati.
3. **Misurare il cambiamento.**
   - Comunità di votanti ricavate dal co-voto precedente.
   - Poi confronto tra un tentativo e l'altro di: sostenitori in comune, nuovi sostenitori, diversità delle comunità, centralità e brokerage.
4. **Studiare l'esito.**
   - Confronto descrittivo per esito precedente, poi una regressione logistica parsimoniosa sull'esito successivo.
   - "All predictors use only information available before that attempt begins."

### Altri punti del brief
- **Regola "No leakage":** "voting behaviour from attempt t+1 will never be used as a predictor of whether attempt t+1 succeeds. Those variables are used only for descriptive comparison."
- **Strumenti:** R con igraph e ggplot2. I risultati sono descritti come associazioni, non come effetti causali.
- **Scadenza nel brief:** "2 Nov 2026: Upload report, code and data by 09:00 CET; email the instructor to confirm." Per la regola dei due giorni l'appello sarebbe il 4/11: è una deduzione, non verificata.
- **Avvertenza del brief:** "The repeated-success group is small (about 29). It will be treated as a secondary descriptive comparison, while the main analysis focuses on all validated repeat candidates."


## 6. Fatti verificati sui dati (pagine SNAP, consultate il 26/10/2026)

### wiki-RfA
- Contiene i voti dall'inizio del processo RfA nel 2003 fino a maggio 2013.
- 11.381 utenti, 189.004 coppie votante–candidato distinte, 198.275 voti. I voti superano le coppie perché un candidato che si è ripresentato riceve più voti dallo stesso votante.
- Campi di ogni voto:

| Campo | Contenuto |
|---|---|
| SRC | votante |
| TGT | candidato |
| VOT | -1 contrario, 0 neutro, 1 favorevole |
| RES | esito: -1 respinto, 1 approvato |
| YEA | anno di inizio dell'elezione |
| DAT | data e ora del voto |
| TXT | commento |

- Non esiste un identificativo del tentativo: va ricostruito.
- Fonte: West, Paskov, Leskovec, Potts (2014), "Exploiting Social Network Structure for Person-to-Person Sentiment Analysis", Transactions of the ACL 2: 297–310.
- I totali 198.275 e 11.381 del brief sono quelli pubblicati da SNAP, cioè prima della pulizia.

### wiki-Elec
- Circa 2.800 elezioni, circa 100.000 voti, circa 7.000 utenti, dal dump del 3 gennaio 2008. Circa 1.200 promozioni e 1.500 no.
- Ogni elezione è un blocco già separato:

| Riga | Contenuto |
|---|---|
| E | esito: 1 promosso, 0 no |
| T | data di chiusura |
| U | candidato |
| N | chi lo ha proposto |
| V | voti, con votante e data |

- Fonti: Leskovec, Huttenlocher, Kleinberg (2010), "Signed Networks in Social Media", CHI; e "Predicting Positive and Negative Links in Online Social Networks", WWW.

### Precedente per ricostruire i tentativi
Un'analisi pubblica su wiki-RfA (Kołczyńska, GitHub) fa così:
- raggruppa per candidato, anno ed esito;
- apre un nuovo tentativo se passano più di 7 giorni tra due voti;
- usa solo gli anni 2004–2012, escludendo il 2003 e il 2013, coperti solo in parte.

### Non riprodotto
Il controllo finale e stato rifatto nella pipeline corrente; i conteggi definitivi sono documentati in `docs/DATA.md`.


## 7. Letteratura verificata (per il gap e per i 5 riferimenti)

**Burke, M. & Kraut, R. (2008).** "Mopping Up: Modeling Wikipedia Promotion Decisions". CSCW '08, pp. 27–36.
- Il numero di tentativi è usato come controllo: "each subsequent attempt has an 11.8% lower chance of success than the previous one" (p. 31).
- Altri predittori: edit sugli articoli, ampiezza dell'esperienza, anzianità, uso delle edit summary.

**Leskovec, J., Huttenlocher, D. & Kleinberg, J. (2010).** "Governance in Social Media: A Case Study of the Wikipedia Promotion Process". ICWSM.
- Scrive che "a single candidate can go up for election multiple times until he or she is elected", ma le ricandidature non le analizza.
- La comunicazione precedente tra candidato e votante aumenta la probabilità di voto favorevole: "the simple existence or non-existence of prior communication between C and V has a large effect."

**Picot-Clémente, R., Bothorel, C. & Jullien, N. (2015).** "Contribution, Social networking, and the Request for Adminship process in Wikipedia". OpenSym.
- Dati: RfA dal 1/1/2006 al 1/10/2007.
- Le misure di rete sulle pagine di discussione, insieme alle revisioni, predicono l'esito: random forest al 78% di accuratezza, contro il 75,6% di Burke e Kraut.
- Le ricandidature non le studia.

**Altri riferimenti utili**
- West et al. (2014), TACL: è la fonte del dataset.
- Leskovec, Huttenlocher, Kleinberg (2010), CHI e WWW: reti con voti positivi e negativi, sui dati wiki-Elec.
- Testi del corso: Easley & Kleinberg, "Networks, Crowds, and Markets"; Barabási, "Network Science".

**Contesto, non scientifico:** la pagina Wikipedia "RFA study" riporta statistiche sulle ricandidature solo per il 2015–2017, fuori dal periodo dei dati.

**Implicazione per il gap (criterio 02):** che le ricandidature abbiano meno successo è già noto (Burke & Kraut). Il gap va formulato su ciò che cambia tra un tentativo e l'altro, nella rete e nelle coalizioni, e su come questo si lega all'esito successivo.


## 8. Revisione di Claude: problemi, dal più grave

### 1. La seconda metà della domanda è circolare (criteri 01 e 06)
- Sostenitori in comune, nuovi sostenitori e diversità dei sostenitori si misurano con i voti del tentativo t+1. Ma l'esito di t+1 dipende da quei voti.
- Il brief li esclude come predittori, eppure la domanda chiede proprio come sono "associated with the next outcome".
- Il legame è meccanico soprattutto per i conteggi. Per le quote normalizzate è più debole, ma gli stessi voti stanno comunque dai due lati della domanda.
- La prima metà della domanda (il confronto per esito precedente) non ha questo problema.
- **Correzione proposta:** separare due domande.
  - **Predittiva:** solo variabili precedenti all'apertura di t+1. Per esempio: esito e quota di sostegno a t; posizione del candidato nella rete fino a quel momento; voti dati dal candidato nelle RfA altrui tra un tentativo e l'altro; tempo trascorso; anno.
  - **Descrittiva:** il cambiamento delle coalizioni, confrontato con un modello nullo che tiene fisso il numero di votanti.
- Oggi il passo 4 non elenca i predittori.

### 2. Il gruppo dei 29 "previously successful" è fragile
- Chi passa una RfA diventa amministratore, quindi ripresentarsi è un caso diverso (per esempio una riconferma dopo dimissioni o rimozione).
- Ipotesi non verificata: con etichette di esito in conflitto e tentativi ricostruiti dalle date, una parte dei 29 potrebbe essere un errore di ricostruzione.
- Opzioni:
  - controllarli a mano, visto che sono pochi;
  - oppure togliere il confronto dalla domanda e restare sui 394 respinti: chi passa al tentativo successivo e chi no.

### 3. La ricostruzione dei tentativi
- YEA è l'anno di inizio dell'elezione e RES compare su ogni voto.
- Ipotesi: due gruppi di voti con stesso candidato, stesso anno ed esito diverso possono essere due tentativi distinti, per esempio una bocciatura e una ripresentazione rapida. Trattarli come "conflicting labels" farebbe perdere proprio i casi che servono.
- Ipotesi: i voti "duplicati" possono essere voti cambiati dallo stesso votante. Serve una regola, per esempio tenere l'ultimo voto per votante e tentativo.
- wiki-Elec ha le elezioni già separate, con data di chiusura ed esito. Va usato per misurare l'errore della ricostruzione sul 2003–2007, non solo per controllare gli esiti.
- Sul 2008–2013 una validazione non esiste, e va dichiarato.

### 4. Le reti non sono specificate fino in fondo (criterio 04)
- **Rete di voto** (votante → candidato): mancano il peso, il trattamento dei voti neutri (VOT = 0) e la finestra di tempo (per esempio tutto fino all'apertura del tentativo).
- **Rete di co-voto** (votante–votante), quella da cui escono le comunità: non è definita.
  - Cosa crea un arco (votare allo stesso modo nella stessa elezione?) e con che peso.
  - Con quale algoritmo si cercano le comunità.
  - Le proiezioni di questo tipo sono dense: il pacchetto R backbone tiene solo gli archi significativi rispetto a un modello nullo.
- **Brokerage:** non è definita né la misura (vincoli di Burt o betweenness) né la rete su cui si calcola.

### 5. Unità di analisi e regressione
- I candidati sono 490, ma le coppie di tentativi consecutivi possono essere di più se qualcuno si è presentato tre o più volte.
- Le coppie dello stesso candidato non sono indipendenti: o se ne tiene una per candidato, o si raggruppa per candidato.
- Va contato quanti successi ci sono al tentativo successivo. Quel numero decide quante variabili regge la regressione: la regola pratica diffusa è di circa 10 eventi per variabile.

### 6. Manca un termine di confronto (criterio 07)
- Per esempio: il tasso di successo al primo tentativo, oppure un modello con solo esito precedente e anno.
- L'anno va controllato comunque, perché gli standard delle RfA sono cambiati nel tempo.

### 7. Il gap
Va riformulato come al punto 7 della letteratura.

### 8. Dipendenza dai tempi
La proposta non è ancora stata inviata. Le istruzioni chiedono di aspettare l'approvazione prima di iniziare, e la consegna indicata nel brief è il 2/11 alle 9:00.

### Possibile riscrittura della domanda (da decidere)
"Tra i candidati RfA respinti almeno una volta, i cambiamenti nella loro posizione nella rete di voto tra un tentativo e il successivo, misurati prima che il nuovo tentativo si apra, sono associati al successo del tentativo successivo?"

La parte sulle coalizioni resta descrittiva, con modello nullo.


## 9. La valutazione di Gemini (file txt) e il confronto

### Conclusione di Gemini
Progetto "pienamente fattibile e metodologicamente sensato". La matrice dei requisiti dà tutto "Conforme".

### Cose che Gemini afferma ma il brief non contiene
- **Una baseline:** Gemini parla di "Puntuale Inserimento di una Baseline" e di metriche di baseline attese "in assenza di riconfigurazione della coalizione". Nel brief non ci sono né modelli nulli né valori attesi.
- **Una bibliografia "Conforme":** il brief non elenca nessun riferimento; li indica solo come cosa da fare ("Five or more references").
- **Gruppi come partizione:** Gemini scrive "così suddivisi" e dà percentuali che sommano a 104,4% (95,2 + 7,0 + 2,2). In realtà i 9 stanno sia nei 394 che nei 29.
- **"Respinti al primo tentativo":** il brief dice "previously rejected", non "al primo tentativo".
- **Fattibilità "garantita":** Gemini la considera garantita perché è prevista una fase di pulizia. Prevedere la pulizia non garantisce niente.
- **"L'audit quantitativo":** Gemini chiama così i numeri del brief, ma 198.275 e 11.381 sono i totali pubblicati da SNAP, prima della pulizia.

### Cose che Gemini non vede
- La circolarità della seconda metà della domanda: anzi scrive "Assenza di Risultati Garantiti per Costruzione".
- Che wiki-Elec copre solo fino a gennaio 2008.
- Il problema concettuale dei 29.
- I rischi della ricostruzione dei tentativi.
- L'unità di analisi.
- La letteratura esistente sulle ricandidature (Burke & Kraut).
- I tempi.

### Cose utili di Gemini che Claude non aveva detto
- **Aggancio alla teoria:** omofilia, chiusura triadica, formazione delle coalizioni. Nel brief nessuna di queste è misurata: se si vuole usarle, vanno rese misurabili. L'omofilia compare negli esempi della guida del docente.
- **I 9 candidati con entrambi gli esiti** come confronto all'interno della stessa persona: con 9 casi resta descrittivo.
- **Grafici per il gruppo piccolo:** distribuzioni o boxplot con i punti sovrapposti.

### Dove Gemini ha ragione contro Claude
Sulla prima metà della domanda (il confronto per esito precedente) non c'è un risultato garantito per costruzione. La critica di Claude vale per la seconda metà.

### Termini di Gemini da non copiare nel report
- **"Disegno sperimentale":** lo studio è osservazionale.
- **"Type III errors" per la circolarità:** di solito l'espressione indica la risposta giusta alla domanda sbagliata.


## 10. Cose non verificate

- Cosa sono davvero i 29 (riconferme? errori di ricostruzione?).
- Se le "conflicting result labels" sono in realtà tentativi distinti nello stesso anno.
- Se i "duplicate vote rows" sono voti cambiati.
- Quanti successi ci sono al tentativo successivo.
- La data dell'appello: il 4/11 è dedotto dalla scadenza del 2/11.


## 11. Decisioni aperte (dello studente e del collega)

1. Tenere o togliere i 29 dalla domanda.
2. Riscrivere la domanda separando la parte predittiva da quella descrittiva.
3. L'elenco dei predittori del passo 4, tutti precedenti all'apertura del tentativo t+1.
4. Le definizioni delle due reti: nodi, archi, direzione, peso, voti neutri, finestra temporale, algoritmo per le comunità, misura di brokerage.
5. La regola di ricostruzione dei tentativi e la sua validazione su wiki-Elec.
6. Il termine di confronto o il modello nullo.
7. L'eventuale aggancio alla teoria del corso.
8. Bibliografia: almeno 5 voci, tra quelle verificate e quelle del gruppo.


## 12. Fonti

- SNAP wiki-RfA: https://snap.stanford.edu/data/wiki-RfA.html
- SNAP wiki-Elec: https://snap.stanford.edu/data/wiki-Elec.html
- Burke & Kraut 2008: https://collablab.northwestern.edu/CollabolabDistro/nucmc/p27-burke.pdf
- Leskovec, Huttenlocher & Kleinberg 2010 (ICWSM): https://arxiv.org/pdf/1004.3547
- Picot-Clémente, Bothorel & Jullien 2015: https://opensym.cs.fau.de/os2015/proceedings-files/p405-picot-clemente.pdf
- Kołczyńska, ricostruzione delle RfA: https://github.com/mkolczynska/martakolczynska/blob/master/content/post/wikipedia-rfa-toxicity-perspective.Rmd
- Wikipedia, RFA study: https://en.wikipedia.org/wiki/Wikipedia:RFA_study
