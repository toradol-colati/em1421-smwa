# Funzioni condivise del data workstream. Sorgente per 02 e 03, non eseguibile
# da sola. Solo R base: nessuna dipendenza.

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
  # sospetti di essere un unico tentativo spezzato dalla soglia
  key <- paste(a$candidate, a$yea, a$outcome)
  a$flag_year_clash <- key %in% key[duplicated(key)]
  a[order(a$candidate, a$attempt_no), ]
}
