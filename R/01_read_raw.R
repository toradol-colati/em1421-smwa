# 01 - Lettura dei file grezzi, nessuna pulizia sostanziale.
# Input : data/raw/wiki-RfA.txt.gz, data/raw/wikiElec.ElecBs3.txt.gz
# Output: data/processed/votes_raw.rds, data/processed/username_case_variants.csv
# Pacchetti: nessuno (R base).
#
# Qui si fa solo il passaggio dal formato di testo alla tabella, piu la
# normalizzazione degli spazi negli username (vedi NOTA 1). Non si deduplica e non
# si decide niente di sostanziale: quello e il passo 02.

source(file.path("R", "00_paths.R"))

# --- wiki-RfA -----------------------------------------------------------------
# Record di 7 righe "CAMPO:valore", separati da una riga vuota.
# SRC votante | TGT candidato | VOT -1/0/1 | RES -1/1 | YEA anno di apertura |
# DAT data e ora del voto | TXT commento.
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
  # NOTA 1 - username: 21 nomi differiscono solo per spazi iniziali o finali.
  # Senza trimws() i nomi distinti sono 11.402; con trimws() sono 11.381, cioe
  # esattamente il totale pubblicato da SNAP. Il trim e quindi parte della
  # definizione dei nodi, non una pulizia opzionale.
  out$SRC <- trimws(out$SRC)
  out$TGT <- trimws(out$TGT)
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
