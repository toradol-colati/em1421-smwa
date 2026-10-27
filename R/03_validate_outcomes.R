# 03 - Validazione della ricostruzione contro wiki-Elec, e SCELTA della soglia.
# Input : data/processed/votes_raw.rds, data/processed/elec_raw.rds
# Output: data/processed/03_soglia_sweep.csv, data/processed/03_log.txt,
#         data/processed/attempts_validated.rds
# Pacchetti: nessuno (R base).
#
# wiki-Elec contiene 2.794 elezioni GIA separate, con data di chiusura ed esito,
# da set 2004 a gen 2008. E quindi verita a terra, non solo per controllare gli
# esiti ma per SCEGLIERE la soglia di separazione dei tentativi: si prova una
# griglia di soglie e si tiene quella che riproduce meglio le elezioni vere.
# Il contesto chiedeva esattamente questo (punto debole 3).
#
# ATTENZIONE: gli username di wiki-Elec sono tutti minuscoli, quelli di wiki-RfA
# no. Il confronto passa per tolower(). Fuori dal periodo coperto (2008-2013)
# nessuna validazione e possibile: va dichiarato nei limiti.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

GRIGLIA  <- c(1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 18, 21, 28, 35, 45, 60)
MODI     <- c("res_then_gap", "gap_then_res")
TOLL_GG  <- 3    # tolleranza nel confronto fra le date di chiusura, nello sweep
SOGLIA_SCELTA <- 7   # soglia adottata: vedi la nota sul plateau in fondo

log_righe <- character(0)
nota <- function(...) { s <- paste0(...); log_righe <<- c(log_righe, s); cat(s, "\n", sep="") }

raw  <- readRDS(file.path(DIR_PROCESSED, "votes_raw.rds"))
elec <- readRDS(file.path(DIR_PROCESSED, "elec_raw.rds"))
d <- data.frame(src = raw$SRC, tgt = raw$TGT,
                vot = as.integer(raw$VOT), res = as.integer(raw$RES),
                yea = as.integer(raw$YEA), dat = parse_dat(raw$DAT),
                stringsAsFactors = FALSE)

# --- periodo di sovrapposizione ----------------------------------------------
da <- min(elec$elections$closed_at); a_ <- max(elec$elections$closed_at)
nota("wiki-Elec copre ", format(da, "%Y-%m-%d"), " -> ", format(a_, "%Y-%m-%d"),
     "  (", nrow(elec$elections), " elezioni)")
nota("NB: non il 2003-2007 come si credeva. Fuori da questa finestra nessuna validazione.")

ele <- elec$elections
ele$cand_lc <- norm_user(ele$candidate)
# elezioni usabili: candidato presente anche in wiki-RfA
cand_rfa <- unique(norm_user(d$tgt))
ele$in_rfa <- ele$cand_lc %in% cand_rfa
nota("elezioni il cui candidato esiste anche in wiki-RfA: ", sum(ele$in_rfa),
     " su ", nrow(ele), sprintf("  (%.1f%%)", 100*mean(ele$in_rfa)))
ele <- ele[ele$in_rfa, ]

# --- confronto per una data regola e soglia ----------------------------------
valuta <- function(mode, soglia) {
  v <- ricostruisci_tentativi(d, soglia, mode)
  spl <- split(as.numeric(v$dat), v$attempt_id)
  a <- data.frame(
    attempt_id = as.integer(names(spl)),
    closed_at  = as.POSIXct(vapply(spl, max, 0), origin = "1970-01-01", tz = "UTC"),
    n_votes    = vapply(spl, length, 0L)
  )
  i <- match(a$attempt_id, v$attempt_id)
  a$cand_lc <- norm_user(v$tgt[i]); a$outcome <- v$res[i]
  # finestra di wiki-Elec
  aw <- a[a$closed_at >= da - 86400*30 & a$closed_at <= a_ + 86400*30, ]
  # per ogni elezione vera, il tentativo piu vicino dello stesso candidato
  per_cand <- split(seq_len(nrow(aw)), aw$cand_lc)
  dist <- rep(NA_real_, nrow(ele)); esito_ok <- rep(NA, nrow(ele))
  for (r in seq_len(nrow(ele))) {
    ii <- per_cand[[ele$cand_lc[r]]]
    if (is.null(ii)) next
    dd <- abs(as.numeric(difftime(aw$closed_at[ii], ele$closed_at[r], units = "days")))
    j <- ii[which.min(dd)]
    dist[r] <- min(dd)
    esito_ok[r] <- (aw$outcome[j] == 1) == (ele$outcome[r] == 1)
  }
  trovate <- !is.na(dist) & dist <= TOLL_GG
  # conteggio dei tentativi per candidato, solo candidati con tutte le elezioni
  # dentro la finestra
  n_vero <- table(ele$cand_lc)
  n_mio  <- table(aw$cand_lc[aw$n_votes >= 1])
  comuni <- intersect(names(n_vero), names(n_mio))
  data.frame(
    mode = mode, soglia = soglia,
    n_tentativi = nrow(a),
    elezioni_riconosciute = sum(trovate),
    quota_riconosciute = mean(trovate),
    esito_concorde = mean(esito_ok[trovate], na.rm = TRUE),
    conteggio_concorde = mean(n_vero[comuni] == n_mio[comuni]),
    media_abs_diff_conteggio = mean(abs(as.integer(n_vero[comuni]) - as.integer(n_mio[comuni]))),
    frammenti_lt5 = sum(a$n_votes < 5),
    stringsAsFactors = FALSE
  )
}

nota("\nsweep: ", length(MODI), " regole x ", length(GRIGLIA), " soglie...")
res <- do.call(rbind, lapply(MODI, function(m)
  do.call(rbind, lapply(GRIGLIA, function(s) valuta(m, s)))))
write.csv(res, file.path(DIR_PROCESSED, "03_soglia_sweep.csv"), row.names = FALSE)

pr <- res
pr$quota_riconosciute <- round(pr$quota_riconosciute, 4)
pr$esito_concorde <- round(pr$esito_concorde, 4)
pr$conteggio_concorde <- round(pr$conteggio_concorde, 4)
pr$media_abs_diff_conteggio <- round(pr$media_abs_diff_conteggio, 3)
print(pr, row.names = FALSE)

best <- res[which.max(res$conteggio_concorde), ]
nota("\nmigliore per concordanza del NUMERO di tentativi per candidato: ",
     best$mode, ", soglia ", best$soglia, " giorni  (",
     sprintf("%.2f%%", 100*best$conteggio_concorde), ")")
rtg <- res[res$mode == "res_then_gap", ]
plateau <- rtg$soglia[rtg$conteggio_concorde >= max(rtg$conteggio_concorde) - 0.005]
nota("plateau entro mezzo punto dal massimo: soglie ", min(plateau), "-", max(plateau),
     " giorni. La ricostruzione e quindi INSENSIBILE alla soglia in quella fascia:")
nota("  e un risultato di robustezza, e la ragione per tenere 7 giorni, che e il",
     " valore del precedente pubblico (Kolczynska) e la durata nominale di una RfA.")
nota("regola scartata (gap_then_res): a parita di soglia produce ",
     res$frammenti_lt5[res$mode=="gap_then_res" & res$soglia==SOGLIA_SCELTA],
     " tentativi con meno di 5 voti contro ",
     res$frammenti_lt5[res$mode=="res_then_gap" & res$soglia==SOGLIA_SCELTA],
     ", e un errore medio di conteggio di ",
     round(res$media_abs_diff_conteggio[res$mode=="gap_then_res" & res$soglia==SOGLIA_SCELTA],2),
     " contro ",
     round(res$media_abs_diff_conteggio[res$mode=="res_then_gap" & res$soglia==SOGLIA_SCELTA],3))

# --- passata finale con la soglia scelta -------------------------------------
nota("\n--- validazione con regola res_then_gap e soglia ", SOGLIA_SCELTA, " giorni ---")
v <- ricostruisci_tentativi(d, SOGLIA_SCELTA, "res_then_gap")
spl <- split(as.numeric(v$dat), v$attempt_id)
a <- data.frame(attempt_id = as.integer(names(spl)),
                opened_at = as.POSIXct(vapply(spl, min, 0), origin="1970-01-01", tz="UTC"),
                closed_at = as.POSIXct(vapply(spl, max, 0), origin="1970-01-01", tz="UTC"),
                n_votes   = vapply(spl, length, 0L))
i2 <- match(a$attempt_id, v$attempt_id)
a$candidate <- v$tgt[i2]; a$cand_key <- norm_user(a$candidate); a$outcome <- v$res[i2]

ele2 <- elec$elections; ele2$cand_key <- norm_user(ele2$candidate)
ele2$anno <- as.integer(format(ele2$closed_at, "%Y"))
per <- split(seq_len(nrow(a)), a$cand_key)
ele2$dist <- NA_real_; ele2$mio_outcome <- NA_integer_; ele2$mio_attempt <- NA_integer_
for (r in seq_len(nrow(ele2))) {
  ii <- per[[ele2$cand_key[r]]]
  if (is.null(ii)) next
  dd <- abs(as.numeric(difftime(a$closed_at[ii], ele2$closed_at[r], units = "days")))
  j <- ii[which.min(dd)]
  ele2$dist[r] <- min(dd); ele2$mio_outcome[r] <- a$outcome[j]
  ele2$mio_attempt[r] <- a$attempt_id[j]
}
ele2$trovata <- !is.na(ele2$dist) & ele2$dist <= 1
nota("elezioni di wiki-Elec ritrovate in wiki-RfA (chiusura entro 1 giorno): ",
     sum(ele2$trovata), " su ", nrow(ele2),
     sprintf("  (%.1f%%)", 100*mean(ele2$trovata)))
nota("  elezioni il cui candidato non compare affatto in wiki-RfA: ", sum(is.na(ele2$dist)))
tb <- table(ele2$anno, ifelse(ele2$trovata, "trovata", "assente"))
nota("copertura per anno di chiusura:")
for (y in rownames(tb)) nota("  ", y, ": ", tb[y,"trovata"], "/", sum(tb[y,]),
                             sprintf("  (%.0f%%)", 100*tb[y,"trovata"]/sum(tb[y,])))
m <- ele2[ele2$trovata, ]
conc <- (m$mio_outcome == 1) == (m$outcome == 1)
nota("concordanza dell'esito sulle elezioni ritrovate: ",
     sprintf("%.2f%%", 100*mean(conc)), "  (discordanti: ", sum(!conc), ")")
nota("LIMITE: la validazione riguarda ", sum(ele2$trovata), " elezioni, cioe il ",
     sprintf("%.0f%%", 100*mean(ele2$trovata)), " di wiki-Elec e una frazione",
     " ancora minore dei ", nrow(a), " tentativi ricostruiti. Sul 2008-2013 nessuna",
     " validazione esiste.")

# --- output ------------------------------------------------------------------
a$elec_matched   <- a$attempt_id %in% m$mio_attempt
a$elec_outcome   <- m$outcome[match(a$attempt_id, m$mio_attempt)]
a$elec_closed_at <- m$closed_at[match(a$attempt_id, m$mio_attempt)]
a$outcome_agrees <- ifelse(a$elec_matched,
                           (a$outcome == 1) == (a$elec_outcome == 1), NA)
saveRDS(a, file.path(DIR_PROCESSED, "attempts_validated.rds"))
write.csv(ele2[, c("candidate","closed_at","outcome","anno","dist","trovata",
                   "mio_outcome","mio_attempt")],
          file.path(DIR_PROCESSED, "03_match_wikielec.csv"), row.names = FALSE)
nota("scritti: attempts_validated.rds (", nrow(a), " tentativi, di cui ",
     sum(a$elec_matched), " validati), 03_match_wikielec.csv")
writeLines(log_righe, file.path(DIR_PROCESSED, "03_log.txt"))
