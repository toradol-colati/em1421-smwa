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
