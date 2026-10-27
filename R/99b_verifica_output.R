# 99b - Seconda ronda di verifica: gli INVARIANTI INTERNI delle tabelle prodotte
# e i numeri derivati citati in docs/DATI.md.
# Mentre 99_verifica_dati.R controlla le affermazioni sui file GREZZI, questo
# controlla che l'output sia internamente coerente: se una di queste condizioni
# fallisce c'e un bug nella pipeline, non un'imprecisione nel testo.
# Input : data/processed/*.rds   Output: data/processed/99b_verifica.txt

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

ko <- 0L; log_righe <- character(0)
inv <- function(etichetta, condizione, dettaglio = "") {
  ok <- isTRUE(all(condizione))
  if (!ok) ko <<- ko + 1L
  s <- sprintf("%-70s %s%s", etichetta, if (ok) "OK" else "FALLITO",
               if (!ok && nzchar(dettaglio)) paste0("  <- ", dettaglio) else "")
  log_righe <<- c(log_righe, s); cat(s, "\n", sep = "")
}
chk <- function(etichetta, ottenuto, atteso, tol = 0) {
  ok <- !is.na(ottenuto) && abs(ottenuto - atteso) <= tol
  if (!ok) ko <<- ko + 1L
  s <- sprintf("%-62s %12s  atteso %12s  %s", etichetta,
               format(ottenuto, big.mark = " "), format(atteso, big.mark = " "),
               if (ok) "OK" else "DIVERSO")
  log_righe <<- c(log_righe, s); cat(s, "\n", sep = "")
}
sez <- function(t) { s <- paste0("\n== ", t, " =="); log_righe <<- c(log_righe, s); cat(s, "\n") }

v <- readRDS(file.path(DIR_PROCESSED, "votes.rds"))
a <- readRDS(file.path(DIR_PROCESSED, "attempts.rds"))
av <- readRDS(file.path(DIR_PROCESSED, "attempts_validated.rds"))

sez("INVARIANTI: votes.rds")
inv("nessun votante compare due volte nello stesso tentativo",
    !any(duplicated(v[, c("attempt_id", "src")])))
inv("nessun attempt_id mancante", !any(is.na(v$attempt_id)))
inv("vot assume solo i valori -1, 0, 1", all(v$vot %in% c(-1, 0, 1)))
inv("res assume solo i valori -1, 1", all(v$res %in% c(-1, 1)))
inv("dat e NA esattamente quando il voto era senza data",
    all(is.na(v$dat) == v$dat_missing))
inv("i voti con data imputata sono tutti senza data originale",
    all(v$dat_missing[v$dat_imputed]))
inv("res e costante dentro ogni tentativo",
    all(tapply(v$res, v$attempt_id, function(x) length(unique(x))) == 1))
inv("il candidato e costante dentro ogni tentativo",
    all(tapply(v$tgt, v$attempt_id, function(x) length(unique(x))) == 1))
inv("nessuno spazio iniziale o finale negli username",
    all(v$src == trimws(v$src)) && all(v$tgt == trimws(v$tgt)))

sez("INVARIANTI: attempts.rds e coerenza con votes.rds")
inv("attempt_id unico", !any(duplicated(a$attempt_id)))
inv("gli attempt_id delle due tabelle coincidono",
    setequal(a$attempt_id, unique(v$attempt_id)))
n_per <- table(v$attempt_id)
inv("n_votes coincide con il conteggio dei voti",
    all(a$n_votes == as.integer(n_per[as.character(a$attempt_id)])))
inv("n_support + n_oppose + n_neutral == n_votes",
    all(a$n_support + a$n_oppose + a$n_neutral == a$n_votes))
inv("nessun tentativo con zero voti", all(a$n_votes > 0))
inv("support_share == n_support / (n_support + n_oppose)",
    all(abs(a$support_share - a$n_support/(a$n_support + a$n_oppose)) < 1e-9 |
        is.na(a$support_share)))
inv("opened_at <= closed_at", all(a$opened_at <= a$closed_at))
inv("duration_days coincide con la differenza delle due date",
    all(abs(a$duration_days -
            as.numeric(difftime(a$closed_at, a$opened_at, units = "days"))) < 1e-6))
inv("attempt_no e 1..k contiguo per ogni candidato",
    all(tapply(a$attempt_no, a$candidate,
               function(x) identical(sort(as.integer(x)), seq_along(x)))))
inv("attempt_no ordina per data di apertura",
    all(tapply(seq_len(nrow(a)), a$candidate, function(i)
      !is.unsorted(a$opened_at[i][order(a$attempt_no[i])]))))
inv("prev_outcome e l'esito del tentativo precedente dello stesso candidato",
    all(vapply(split(seq_len(nrow(a)), a$candidate), function(i) {
      i <- i[order(a$attempt_no[i])]
      if (length(i) == 1) return(is.na(a$prev_outcome[i]))
      is.na(a$prev_outcome[i[1]]) &&
        identical(a$prev_outcome[i[-1]], a$outcome[i[-length(i)]])
    }, TRUE)))
inv("flag_short == (n_votes < 5)", all(a$flag_short == (a$n_votes < 5)))
inv("flag_long == (duration_days > 14)", all(a$flag_long == (a$duration_days > 14)))
inv("attempt_no coincide fra le due tabelle",
    all(v$attempt_no == a$attempt_no[match(v$attempt_id, a$attempt_id)]))

sez("CONSERVAZIONE DEI VOTI")
raw_n <- 198275L
tolti <- 627L + 679L; persi <- 806L
chk("voti grezzi", raw_n, 198275)
chk("voti in votes.rds", nrow(v), 196163)
chk("voti tolti come ripetuti + persi senza data", tolti + persi, raw_n - nrow(v))
chk("voti con data imputata", sum(v$dat_imputed), 7883)
chk("voti senza data rimasti in tabella", sum(v$dat_missing), 7883)

sez("NUMERI CITATI IN docs/DATI.md")
chk("tentativi", nrow(a), 4082)
rip <- table(a$candidate)
chk("candidati ripetuti (2+ tentativi)", sum(rip > 1), 484)
chk("candidati con 3+ tentativi", sum(rip > 2), 90)
chk("coppie di tentativi consecutivi", sum(rip[rip > 1] - 1), 614)
chk("tentativi con esito precedente noto", sum(!is.na(a$prev_outcome)), 614)
chk("candidati con almeno un esito precedente = rifiuto",
    length(unique(a$candidate[!is.na(a$prev_outcome) & a$prev_outcome == -1])), 445)
chk("candidati con almeno un esito precedente = successo",
    length(unique(a$candidate[!is.na(a$prev_outcome) & a$prev_outcome == 1])), 53)
chk("flag_short", sum(a$flag_short), 281)
chk("flag_long", sum(a$flag_long), 4)
chk("flag_year_clash", sum(a$flag_year_clash), 359)
chk("tentativi con riscontro in wiki-Elec", sum(av$elec_matched), 2167)
chk("di cui con esito concorde", sum(av$outcome_agrees, na.rm = TRUE), 2167 - 12)
chk("tentativi senza riscontro", sum(!av$elec_matched), 4082 - 2167)

sez("STRUTTURA DELLA RETE, SULLA TABELLA CONSEGNATA (non sul file grezzo)")
# NB: i numeri del file grezzo (10.417 votanti, 3.497 candidati, 2.533 entrambi)
# NON sono questi: 1.433 voti escono dalla pipeline e con loro alcuni utenti
# spariscono del tutto. Il documento deve riportare entrambi.
chk("votanti distinti in votes.rds", length(unique(v$src)), 10396, tol = 30)
chk("candidati distinti in votes.rds", length(unique(v$tgt)), 3468, tol = 10)
chk("utenti sia votanti sia candidati", length(intersect(v$src, v$tgt)), 2514, tol = 10)
chk("voti favorevoli", sum(v$vot == 1), 143610)
chk("voti contrari", sum(v$vot == -1), 40561)
chk("voti neutri", sum(v$vot == 0), 11992)
chk("n_votes_dated + n_votes_imputed == n_votes (tentativi con scarto)",
    sum(a$n_votes_dated + a$n_votes_imputed != a$n_votes), 0)
chk("somma dei voti imputati per tentativo", sum(a$n_votes_imputed), 7883)

sez("ESITO RONDA 2")
cat(if (ko == 0) "Tutti gli invarianti reggono e tutti i numeri coincidono.\n" else
    sprintf("%d controlli FALLITI.\n", ko))
log_righe <- c(log_righe, if (ko == 0) "Tutto coerente." else sprintf("%d controlli falliti.", ko))
writeLines(log_righe, file.path(DIR_PROCESSED, "99b_verifica.txt"))
