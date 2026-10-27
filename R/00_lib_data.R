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
  # NOTA 1 - username: la grafia NON e l'identita. Tre interventi, ognuno
  # imposto da un difetto misurato nel file:
  #  - 43 grafie hanno uno spazio iniziale o finale, e 21 di queste collidono con
  #    la forma pulita gia presente: senza trim i nomi distinti sono 11.402
  #    invece di 11.381, il totale pubblicato da SNAP;
  #  - un nome ha uno spazio doppio interno ("Salvio  giuliano") e collide con la
  #    forma a spazio singolo, gia presente;
  #  - un nome ha un marcatore invisibile in testa (U+200E, LEFT-TO-RIGHT MARK:
  #    "<U+200E>Jetijonez"), che lo renderebbe un nodo a se.
  # Dopo la normalizzazione i nomi distinti sono 11.380.
  out$SRC <- pulisci_nome(out$SRC)
  out$TGT <- pulisci_nome(out$TGT)
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
# Normalizzazione della GRAFIA dentro un singolo file: toglie i caratteri
# invisibili, collassa gli spazi ripetuti e taglia quelli ai bordi. Non tocca le
# maiuscole: quella e una decisione aperta (UNIFICA_INIZIALE in 02).
pulisci_nome <- function(x) {
  x <- gsub("[\u200b-\u200f\ufeff]", "", x)  # marcatori di direzione e simili
  x <- gsub("[[:space:]]+", " ", x)            # spazi ripetuti o esotici -> uno
  trimws(x)
}

norm_user <- function(x, lower = TRUE) {
  x <- pulisci_nome(gsub("_", " ", x))
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
  # Attenzione: superare il controllo di formato non basta. Un record ha
  # "31:29, 24 May 2008": l'ora 31 passa la regex ma as.POSIXct la rifiuta e
  # restituisce NA. La diagnostica deve contare i NA DOPO la costruzione della
  # data, non solo i formati non riconosciuti, altrimenti dichiara zero
  # quando non e zero (lo faceva).
  attr(res, "n_formato_non_valido") <- sum(!ok & nzchar(x))
  attr(res, "n_valori_impossibili") <- sum(ok & is.na(res))
  attr(res, "n_non_parsate")        <- sum(!ok & nzchar(x)) + sum(ok & is.na(res))
  attr(res, "n_vuote")              <- sum(!nzchar(x))
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
  # apertura e chiusura dai soli voti DATATI: i voti imputati non hanno data e
  # non devono spostare i confini del tentativo
  a$opened_at    <- as.POSIXct(vapply(spl, function(i) min(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$closed_at    <- as.POSIXct(vapply(spl, function(i) max(as.numeric(v$dat[i]), na.rm = TRUE), 0),
                               origin = "1970-01-01", tz = "UTC")
  a$n_votes      <- vapply(spl, length, 0L)
  a$n_support    <- vapply(spl, function(i) sum(v$vot[i] ==  1), 0L)
  a$n_oppose     <- vapply(spl, function(i) sum(v$vot[i] == -1), 0L)
  a$n_neutral    <- vapply(spl, function(i) sum(v$vot[i] ==  0), 0L)
  # autovoti: il candidato che vota nella propria RfA. Sono 103 nel file grezzo
  # e creano un cappio nella rete di voto; restano in tabella, segnalati.
  a$n_self_votes <- vapply(spl, function(i) sum(v$src[i] == v$tgt[i]), 0L)
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
