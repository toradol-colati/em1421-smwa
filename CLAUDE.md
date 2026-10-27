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

## Verificato sui dati il 27/10/2026 (`R/01_read_raw.R` sui file SNAP veri)
I file sono nel branch `codex/team-workplan`, checksum SHA-256 in `data/raw/SHA256SUMS.txt`.
- **198.275 voti**: riprodotto esatto.
- **11.381 utenti distinti**: riprodotto esatto, **ma solo applicando `trimws()`** agli
  username. 21 nomi differiscono solo per spazi iniziali o finali; senza trim vengono 11.402.
  Il trim fa quindi parte della definizione dei nodi, non e una pulizia opzionale.
- **189.004 coppie votante-candidato**: e il conteggio **pre-trim**. Col trim sono 189.003,
  perche una sola coppia (`December21st2012Freak -> Jeffrey Mall`) compare con due grafie che
  differiscono per gli spazi. **I totali pubblicati da SNAP non sono coerenti fra loro**:
  11.381 e post-trim, 189.004 e pre-trim. Da dichiarare nella sezione dati del report.
- Il file ha 198.275 record di esattamente 7 campi ciascuno, zero righe non vuote scartate:
  nessun commento TXT su piu righe, il parser non perde testo.
- **Varianti di sola iniziale maiuscola.** Su Wikipedia la prima lettera di uno username e
  sempre maiuscola, quindi `harej` e `Harej` sono lo stesso account. SNAP non le unifica.
  137 gruppi di grafie, elenco in `data/processed/username_case_variants.csv`; unificandole
  i nomi scendono a 11.244. In 90 gruppi la persona e candidata sotto almeno una grafia, e in
  **8 gruppi lo stesso candidato compare con due grafie diverse**, in anni diversi
  (Dustihowe 2007/2008, Imdanumber1 2006/2007, Kylekieran 2009/2011, Maltesedog 2005/2006,
  Tdxiang 2005/2006, Xiner 2006/2007) o nello stesso anno (Alexsautographs 2010,
  Nenyedi 2007). **Se non si unificano, questi 8 risultano due persone distinte con un solo
  tentativo ciascuna e cadono fuori dai candidati ripetuti**: cambia la popolazione dello
  studio, cioe il 414. DECISIONE APERTA, riguarda entrambi i ruoli.

## Non verificato
- Conteggi 414 / 394 / 29 / 9 ed esiti dell'audit: nessuno li ha rifatti fuori dal gruppo.
- Esistenza e regola del codice dei "feasibility checks" del brief.
- Data dell'appello (4/11 dedotto dalla consegna del 2/11, 09:00 CET).
- L'affermazione che il parser produca colonne annidate di tipo lista: non riprodotta.
  Eseguito `R/01_read_raw.R` su R 4.5.1 in sessione pulita, tutte e 7 le colonne sono
  `character` e `is.list()` e FALSE per tutte. Da chiarire con Mihretab come l'ha ottenuto.

## Repo
- Remote: `toradol-colati/em1421-smwa` (privata). Collaboratori: `mihretabworku` con permesso di scrittura (invitato il 27/10/2026).
- Struttura creata: `data/raw/` (file SNAP, da scaricare: vedi `data/raw/README.md`), `data/processed/`, `R/` (script numerati `00`–`07`), `output/figures/`, `report/`, `docs/`.
- I file SNAP compressi stanno sotto il limite GitHub (wiki-RfA ~15 MB): vanno in `data/raw/` e si committano, perché la consegna richiede i dati insieme al codice.
- `data/raw/` è di sola lettura per gli script. Ogni script scrive solo in `data/processed/` o `output/`.
- Gli script `02`–`07` sono scheletri: ogni file elenca in testa le decisioni ancora aperte. Non implementarle senza che Bubi e Mihretab le abbiano fissate.
