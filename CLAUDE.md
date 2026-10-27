# EM1421 – Repeat Requests for Adminship

Contesto completo: `docs/EM1421_RfA_contesto_nuova_chat.md` (stato al 26/10/2026, leggerlo prima di tutto).
Brief del progetto: `docs/EM1421_group_project_brief.pdf`.
Questo file aggiunge solo ciò che è cambiato o è stato deciso dopo quel documento.

## Istruzioni per Claude
- Registro secco, diretto, tecnico. Niente stime di durata, niente piani a calendario: ordine per dipendenza logica.
- Brainstorm: le scelte di metodo le fanno Bubi e Mihretab. Tu proponi, verifichi, critichi.
- Verifica prima di affermare; separa verificato e non verificato; dichiara tu i punti deboli. Niente compiacenza.
- Analisi interamente in R (igraph, ggplot2). Nel report niente codice.

## Aggiornamenti al 26/10/2026 (sera)
- **Proposta approvata** dal docente con la domanda del brief così com'è. La domanda NON va riscritta senza scrivere prima al docente.
  - Conseguenza: la circolarità della seconda metà (§8.1 del contesto) si risolve nell'analisi, non nella domanda. Variabili di coalizione di t+1 → solo descrittive, con modello nullo. Regressione → solo variabili note prima dell'apertura di t+1.
  - I 29 "previously successful" restano (sono nella domanda approvata) come confronto secondario descrittivo. Vanno controllati a mano: se sono errori di ricostruzione, va scritto nei limiti.
- **Gruppo:** Bubi (GitHub `toradol-colati`) e Mihretab (GitHub `mihretabworku`).
- **Divisione del lavoro: PROPOSTA, non ancora concordata.**
  - A. Insieme, prima del codice: schema delle tabelle `attempts` (una riga per tentativo: candidato, n. tentativo, apertura, chiusura, esito validato, flag ambiguità) e `votes` (con id tentativo); definizioni scritte delle reti (nodi, archi, direzione, peso, voti neutri, finestra temporale).
  - B. In parallelo e indipendenti: ricostruzione dei tentativi, ciascuno con la propria regola, senza guardare quella dell'altro. Poi confronto dei conteggi e regola unica.
  - C. Data member: validazione su wiki-Elec (2003–2007), controllo dei 29, voti senza data, confronto descrittivo con modello nullo. Network member: rete di voto e proiezione di co-voto (backbone), comunità, centralità, brokerage, regressione.
  - D. Insieme: figure (max 4), letteratura, report, revisione incrociata del codice.
  - Ruoli non ancora assegnati.

## Punti deboli aperti (non nel documento di contesto)
1. **Voti senza data:** la soglia dei 7 giorni usa DAT. Contare quanti sono e su quali candidati cadono; attribuibili solo se il candidato ha un solo tentativo in quell'anno YEA o se RES li separa.
2. **Posizione di rete prima di t+1 ≈ funzione di t:** per un ripresentato gli archi entranti prima di t+1 vengono quasi tutti da t, quindi in-degree e centralità ricalcano numero di votanti e quota di sostegno a t. Controllare la correlazione prima di metterli insieme in regressione. L'informazione nuova è negli archi uscenti (voti dati dal candidato nelle RfA altrui tra un tentativo e l'altro).
3. **Soglia dei 7 giorni:** RfA chiuse in anticipo (SNOW/NOTNOW) seguite da un rientro rapido possono fondersi col tentativo precedente. Usare wiki-Elec 2003–2007 anche per scegliere la soglia, non solo per validarla.

## Verificato sui dati il 27/10/2026
Documentazione completa: `docs/DATI.md`. Qui solo i fatti che cambiano il documento di
contesto.
- **198.275 voti** e **11.381 utenti** di wiki-RfA riprodotti esatti, ma gli utenti solo
  applicando `trimws()`: 21 nomi hanno uno spazio in coda. I totali SNAP non sono coerenti
  fra loro (11.381 e post-trim, 189.004 coppie e pre-trim).
- **wiki-Elec non copre il 2003-2007**: i voti vanno dal 28/03/2004 al 06/01/2008.
  2.794 elezioni, 114.040 voti, 1.248 promozioni e 1.546 respinte, tutti riprodotti.
- **Il campo T (chiusura) di wiki-Elec e inaffidabile**: scarto mediano di 102 giorni dal
  proprio ultimo voto, 54% oltre 30 giorni. Non usarlo per niente.
- **YEA di wiki-RfA e inaffidabile**: 1.875 voti hanno la data in un anno diverso, a blocchi.
  La ricostruzione dei tentativi non lo usa.
- **I due file descrivono in gran parte le stesse elezioni**: appaiando per insiemi di votanti,
  77,6% con Jaccard > 0,5 e 84,2% con Jaccard > 0,3; assenti il 9,8%