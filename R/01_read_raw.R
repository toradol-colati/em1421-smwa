# 01 – Lettura dei file grezzi, nessuna pulizia.
# Input : data/raw/wiki-RfA.txt.gz, data/raw/wikiElec.ElecBs3.txt.gz
# Output: data/processed/votes_raw.rds, data/processed/elec_raw.rds
# Qui non si deduplica e non si decide niente: solo dal formato di testo a tabella.

source(file.path("R", "00_paths.R"))

# --- wiki-RfA -----------------------------------------------------------------
# Record di 7 righe "CAMPO:valore", separati da una riga vuota.
# SRC votante | TGT candidato | VOT -1/0/1 | RES -1/1 | YEA anno di apertura |
# DAT data e ora del voto | TXT commento.
read_rfa <- function(path) {
  stop_if_missing(path)
  lines <- readLines(gzfile(path), warn = FALSE, encoding = "UTF-8")
  keys  <- sub(":.*$", "", lines)
  vals  <- sub("^[A-Z]{3}:", "", lines)
  keep  <- keys %in% c("SRC", "TGT", "VOT", "RES", "YEA", "DAT", "TXT")
  keys  <- keys[keep]; vals <- vals[keep]
  # Ogni occorrenza di SRC apre un nuovo record.
  rec <- cumsum(keys == "SRC")
  wide <- tapply(vals, list(rec, keys), identity)
  out <- as.data.frame(wide, stringsAsFactors = FALSE)
  out$vote_id <- seq_len(nrow(out))
  out
}

# --- wiki-Elec ----------------------------------------------------------------
# Blocchi già separati per elezione: E esito (1/0), T data di chiusura,
# U candidato, N proponente, V un voto per riga.
# TODO (Data member): parser dei blocchi -> tabella elezioni + tabella voti.

votes_raw <- read_rfa(FILE_RFA)
dir.create(DIR_PROCESSED, showWarnings = FALSE, recursive = TRUE)
saveRDS(votes_raw, file.path(DIR_PROCESSED, "votes_raw.rds"))

cat("voti letti:", nrow(votes_raw), "\n")
cat("utenti distinti (SRC u TGT):",
    length(unique(c(votes_raw$SRC, votes_raw$TGT))), "\n")
# Atteso dalle pagine SNAP, prima della pulizia: 198.275 voti, 11.381 utenti.
