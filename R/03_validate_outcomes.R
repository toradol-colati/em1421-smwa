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
