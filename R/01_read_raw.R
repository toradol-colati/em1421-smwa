# 01 - Lettura dei file grezzi, nessuna pulizia sostanziale.
# Input : data/raw/wiki-RfA.txt.gz, data/raw/wikiElec.ElecBs3.txt.gz
# Output: data/processed/votes_raw.rds, data/processed/username_case_variants.csv
# Pacchetti: nessuno (R base).
#
# I due parser stanno in R/00_lib_data.R, cosi sono usabili anche dalla
# verifica indipendente (R/99_verifica_dati.R).
# Qui si fa solo il passaggio dal formato di testo alla tabella, piu la
# normalizzazione degli spazi negli username (vedi NOTA 1). Non si deduplica e non
# si decide niente di sostanziale: quello e il passo 02.

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

# --- esecuzione ---------------------------------------------------------------
votes_raw <- read_rfa(FILE_RFA)
dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)
saveRDS(votes_raw, file.path(DIR_PROCESSED, "votes_raw.rds"))

elec <- read_elec(FILE_ELEC)
saveRDS(elec, file.path(DIR_PROCESSED, "elec_raw.rds"))

cv <- case_variants(votes_raw)
write.csv(cv, file.path(DIR_PROCESSED, "username_case_variants.csv"), row.names = FALSE)

# Conteggi di controllo contro i totali pubblicati da SNAP.
n_voti   <- nrow(votes_raw)
n_utenti <- length(unique(c(votes_raw$SRC, votes_raw$TGT)))
cat("voti:                    ", n_voti,   " (SNAP: 198275)",
    if (n_voti == 198275) " OK" else " DIVERSO", "\n", sep = "")
cat("utenti distinti:         ", n_utenti, " (SNAP: 11381)",
    if (n_utenti == 11381) " OK" else " DIVERSO", "\n", sep = "")
# NOTA 3 - le coppie distinte sono 189.003 col trim e 189.004 senza: una sola
# coppia (December21st2012Freak -> Jeffrey Mall) compare con due grafie che
# differiscono solo per gli spazi. Quindi i totali pubblicati da SNAP non sono
# coerenti fra loro: 11.381 utenti e un conteggio post-trim, 189.004 coppie e
# pre-trim. Da dichiarare nella sezione dati del report.
cat("coppie votante-candidato:", nrow(unique(votes_raw[, c("SRC", "TGT")])),
    " (SNAP: 189004, pre-trim; col trim sono 189003)\n", sep = "")
cat("nomi unificando l'iniziale maiuscola: ",
    length(unique(capitalizza(c(votes_raw$SRC, votes_raw$TGT)))), "\n", sep = "")
cat("gruppi di grafie che differiscono solo per l'iniziale: ",
    length(unique(cv$nome_unificato)),
    " (elenco in data/processed/username_case_variants.csv)\n", sep = "")
cat("  di cui la persona e candidata sotto almeno una grafia: ",
    length(unique(cv$nome_unificato[cv$n_voti_ricevuti > 0])), "\n", sep = "")
cat("  di cui compaiono come CANDIDATO con due grafie diverse: ",
    length(unique(cv$nome_unificato[ave(cv$n_voti_ricevuti > 0, cv$nome_unificato,
                                        FUN = sum) > 1])),
    "  <- caso distruttivo per la ricostruzione dei tentativi\n", sep = "")

cat("\n--- wiki-Elec ---\n")
cat("elezioni:", nrow(elec$elections), " (SNAP: 2794)",
    if (nrow(elec$elections) == 2794) " OK" else " DIVERSO", "\n", sep = "")
cat("voti:", nrow(elec$votes), "\n", sep = "")
cat("promozioni:", sum(elec$elections$outcome == 1),
    "  respinte:", sum(elec$elections$outcome == 0), "  (SNAP: ~1200 / ~1500)\n")
cat("periodo:", format(min(elec$elections$closed_at, na.rm = TRUE), "%Y-%m-%d"), "->",
    format(max(elec$elections$closed_at, na.rm = TRUE), "%Y-%m-%d"), "\n")
cat("candidati distinti:", length(unique(elec$elections$candidate)),
    "  di cui con piu di un'elezione:",
    sum(table(elec$elections$candidate) > 1), "\n")
cat("date di chiusura mancanti:", sum(is.na(elec$elections$closed_at)), "\n")
