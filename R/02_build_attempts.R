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
d$self_vote <- d$src == d$tgt
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

# --- 1b. date -----------------------------------------------------------------
dd <- parse_dat(raw$DAT)
d$dat <- dd
d$dat_missing <- is.na(d$dat)
nota("voti con DAT vuoto: ", attr(dd, "n_vuote"),
     sprintf("  (%.2f%%)", 100 * attr(dd, "n_vuote") / nrow(d)))
nota("voti con DAT presente ma non interpretabile: ", attr(dd, "n_non_parsate"))


# --- 1c. record senza votante ------------------------------------------------
# 1.661 record hanno SRC vuoto, e TUTTI hanno anche TXT vuoto e DAT vuoto:
# sono record fantasma del file, non voti. Toccano 926 candidati, concentrati
# nel 2006 (800). Se restassero in tabella sarebbero un NODO UNICO con 1.661
# archi uscenti verso 926 candidati, cioe un hub inesistente che falserebbe
# qualunque misura di centralita e la proiezione di co-voto. Non sono
# "segnalabili": un voto senza votante non e un arco. Si tolgono, e si salvano
# a parte perche niente sparisca in silenzio.
senza_votante <- d[d$src == "", ]
write.csv(senza_votante[, c("vote_id","tgt","vot","res","yea")],
          file.path(DIR_PROCESSED, "record_senza_votante.csv"), row.names = FALSE)
nota("record con SRC vuoto (nessun votante), rimossi: ", nrow(senza_votante),
     " su ", nrow(d), sprintf("  (%.2f%%)", 100*nrow(senza_votante)/nrow(d)))
nota("  candidati toccati: ", length(unique(senza_votante$tgt)),
     " | elenco in record_senza_votante.csv")
d <- d[d$src != "", ]
nota("voti con un votante identificabile: ", nrow(d))

# --- 1d. autovoti ------------------------------------------------------------
nota("autovoti (il candidato vota nella propria RfA): ", sum(d$src == d$tgt),
     "  -> restano in tabella con la colonna self_vote")


# su quali candidati cadono i voti senza data (punto debole 1 del contesto)
sd <- d[d$dat_missing, ]
nota("voti senza data, fra quelli con un votante: ", nrow(sd))
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

# --- 6. attribuzione dei voti senza data -------------------------------------
# Si attribuiscono solo quando l'attribuzione e univoca: il candidato ha un solo
# tentativo in quell'anno con quell'esito. Gli altri restano fuori, contati.
# Serve una tabella provvisoria dei tentativi, costruita sui soli voti datati,
# solo per sapere quali chiavi (candidato, anno, esito) sono univoche.
a <- costruisci_attempts(v)
a$key <- paste(a$candidate, a$yea, a$outcome)
uniche <- a$key[!duplicated(a$key) & !(a$key %in% a$key[duplicated(a$key)])]
sd$key <- paste(sd$tgt, sd$yea, sd$res)
sd$attempt_id <- a$attempt_id[match(sd$key, a$key)]
sd$attempt_id[!(sd$key %in% uniche)] <- NA_integer_
nota("voti senza data attribuiti in modo univoco: ", sum(!is.na(sd$attempt_id)),
     " su ", nrow(sd))
nota("voti senza data non attribuibili (persi): ", sum(is.na(sd$attempt_id)))
a$key <- NULL

# --- 7. tabella dei tentativi, sulla tabella dei voti COMPLETA ---------------
# ORDINE IMPORTANTE: i conteggi del tentativo (n_votes, n_support, ...,
# support_share) vanno calcolati DOPO aver reinserito i voti senza data
# attribuiti, altrimenti attempts.rds e votes.rds non concordano e
# support_share esclude in silenzio 8.562 voti. Era un bug, trovato dalla
# verifica degli invarianti (R/99b_verifica_output.R).
v$dat_imputed <- FALSE
if (any(!is.na(sd$attempt_id))) {
  add <- sd[!is.na(sd$attempt_id), ]
  add$attempt_no  <- a$attempt_no[match(add$attempt_id, a$attempt_id)]
  add$dat_imputed <- TRUE
  add$key <- NULL
  comuni <- intersect(names(v), names(add))
  v <- rbind(v[, comuni], add[, comuni])
}
# Seconda deduplica: un votante puo avere nello stesso tentativo sia un voto
# datato sia uno senza data che gli e stato attribuito. Si tiene quello DATATO,
# perche e verificabile; se ce ne sono solo imputati se ne tiene uno.
# La prima deduplica (passo 5) non poteva vederli, perche i voti senza data
# entrano solo qui: e un bug trovato dalla verifica degli invarianti
# (R/99b_verifica_output.R).
v <- v[order(v$attempt_id, v$src, v$dat_imputed, v$dat), ]
dup2 <- duplicated(v[, c("attempt_id", "src")])
nota("voti rimossi nella seconda deduplica (stesso votante, uno datato e uno ",
     "imputato nello stesso tentativo): ", sum(dup2))
v <- v[!dup2, ]
v <- v[order(v$attempt_id, v$src), ]

a_dated <- a
a <- costruisci_attempts(v)
a$n_votes_dated <- a_dated$n_votes[match(a$attempt_id, a_dated$attempt_id)]
a$n_votes_imputed <- a$n_votes - a$n_votes_dated

# l'esito precedente va ricalcolato sulla tabella definitiva
rip <- table(a$candidate)
a$prev_outcome <- NA_integer_
for (cand in names(rip)[rip > 1]) {
  i <- which(a$candidate == cand); i <- i[order(a$attempt_no[i])]
  a$prev_outcome[i[-1]] <- a$outcome[i[-length(i)]]
}
nota("tentativi: ", nrow(a), " (prima dell'attribuzione dei voti senza data: ",
     nrow(a_dated), ")")
nota("candidati ripetuti (2+ tentativi): ", sum(rip > 1), "   (il brief dichiara 414)")
nota("  di cui con 3+ tentativi: ", sum(rip > 2))
nota("coppie di tentativi consecutivi: ", sum(rip[rip > 1] - 1))
nota("tentativi segnalati: pochi voti (<5): ", sum(a$flag_short),
     " | durata >14gg: ", sum(a$flag_long),
     " | stesso candidato/anno/esito: ", sum(a$flag_year_clash))
nota("  preceduti da un rifiuto: ", sum(a$prev_outcome == -1, na.rm = TRUE),
     " | preceduti da un successo: ", sum(a$prev_outcome == 1, na.rm = TRUE))

saveRDS(v, file.path(DIR_PROCESSED, "votes.rds"))
saveRDS(a, file.path(DIR_PROCESSED, "attempts.rds"))
writeLines(log_righe, file.path(DIR_PROCESSED, "02_log.txt"))
nota("scritti: votes.rds (", nrow(v), " righe), attempts.rds (", nrow(a), " righe)")
