# 99 - Verifica indipendente delle affermazioni di docs/DATI.md.
# Ricalcola ogni numero PARTENDO DAI FILE GREZZI, senza usare gli output
# intermedi, e confronta con quanto dichiarato. Stampa OK o DIVERSO.
# Serve a chiunque voglia controllare il lavoro senza fidarsi.
# Input : data/raw/*.gz    Output: data/processed/99_verifica.txt

source(file.path("R", "00_paths.R"))
source(file.path("R", "00_lib_data.R"))

ko <- 0L; log_righe <- character(0)
chk <- function(etichetta, ottenuto, atteso, tol = 0) {
  esito <- if (is.na(ottenuto) || is.na(atteso)) "?" else
           if (abs(ottenuto - atteso) <= tol) "OK" else { ko <<- ko + 1L; "DIVERSO" }
  s <- sprintf("%-62s %12s  atteso %12s  %s", etichetta,
               format(ottenuto, big.mark = "."), format(atteso, big.mark = "."), esito)
  log_righe <<- c(log_righe, s); cat(s, "\n", sep = "")
}
sez <- function(t) { s <- paste0("\n== ", t, " =="); log_righe <<- c(log_righe, s); cat(s, "\n") }

# ---------------------------------------------------------------- wiki-RfA --
sez("wiki-RfA: lettura indipendente dal parser della pipeline")
L <- readLines(gzfile(FILE_RFA), warn = FALSE, encoding = "UTF-8")
k <- sub(":.*$", "", L); v <- sub("^[A-Z]{3}:", "", L)
keep <- k %in% c("SRC","TGT","VOT","RES","YEA","DAT","TXT")
chk("righe totali del file", length(L), 1586200)
chk("righe scartate che NON sono separatori vuoti", sum(!keep & L != ""), 0)
rec <- cumsum(k[keep] == "SRC")
chk("record (= voti)", max(rec), 198275)
chk("record con un numero di campi diverso da 7", sum(table(rec) != 7), 0)
D <- as.data.frame(tapply(v[keep], list(rec, k[keep]), identity), stringsAsFactors = FALSE)

sez("wiki-RfA: identita degli utenti")
tutti_raw <- c(D$SRC, D$TGT)
chk("utenti distinti SENZA trim", length(unique(tutti_raw)), 11402)
chk("utenti distinti CON trim (totale SNAP)", length(unique(trimws(tutti_raw))), 11381)
chk("utenti distinti dopo la normalizzazione completa", length(unique(pulisci_nome(tutti_raw))), 11380)
con_sp <- unique(tutti_raw)[unique(tutti_raw) != trimws(unique(tutti_raw))]
chk("grafie con spazio iniziale o finale", length(con_sp), 43)
chk("  di cui collidono con la forma pulita gia presente", sum(trimws(con_sp) %in% tutti_raw), 21)
chk("  riduzione dei nomi distinti", length(unique(tutti_raw)) - length(unique(trimws(tutti_raw))), 21)
chk("coppie votante-candidato SENZA trim (totale SNAP)",
    nrow(unique(D[, c("SRC","TGT")])), 189004)
# Dt: gli stessi dati con i nomi normalizzati come fa read_rfa(). D resta grezzo,
# cosi si possono verificare entrambi gli stadi.
Dt <- D; Dt$SRC <- pulisci_nome(D$SRC); Dt$TGT <- pulisci_nome(D$TGT)
chk("coppie votante-candidato dopo la normalizzazione", nrow(unique(Dt[, c("SRC","TGT")])), 189001)
chk("votanti distinti normalizzati (compreso il nodo vuoto)", length(unique(Dt$SRC)), 10416)
chk("candidati distinti", length(unique(Dt$TGT)), 3497)
chk("utenti che sono SIA votanti SIA candidati", length(intersect(unique(Dt$SRC), unique(Dt$TGT))), 2533)
chk("candidati che non hanno mai votato", length(setdiff(unique(Dt$TGT), unique(Dt$SRC))), 964, tol = 5)
cap <- function(s) ifelse(s == "", s, paste0(toupper(substr(s,1,1)), substr(s,2,nchar(s))))
chk("utenti unificando l'iniziale maiuscola", length(unique(cap(pulisci_nome(tutti_raw)))), 11243)
gr <- split(unique(trimws(tutti_raw)), cap(unique(trimws(tutti_raw))))
chk("gruppi di grafie che differiscono solo per l'iniziale", sum(lengths(gr) > 1), 137)
chk("  di cui la persona e candidata sotto almeno una grafia",
    sum(vapply(gr, function(f) length(f) > 1 && any(f %in% Dt$TGT), TRUE)), 90)
chk("  di cui il CANDIDATO compare con due grafie",
    sum(lengths(split(unique(Dt$TGT), cap(unique(Dt$TGT)))) > 1), 8)

sez("wiki-RfA: campi")
chk("voti favorevoli (VOT=1)",  sum(D$VOT ==  "1"), 144451)
chk("voti contrari (VOT=-1)",   sum(D$VOT == "-1"),  41176)
chk("voti neutri (VOT=0)",      sum(D$VOT ==  "0"),  12648)
chk("esito respinto (RES=-1)",  sum(D$RES == "-1"),  74987)
chk("esito approvato (RES=1)",  sum(D$RES ==  "1"), 123288)
chk("DAT vuoto", sum(D$DAT == ""), 9367)
dt <- parse_dat(D$DAT)
chk("DAT presente ma non interpretabile", attr(dt, "n_non_parsate"), 0)
mm <- sub("^.*, [0-9]{1,2} ([A-Za-z]+) [0-9]{4}$", "\\1", D$DAT[D$DAT != ""])
abbr <- c("Jan","Feb","Mar","Apr","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
chk("voti con mese abbreviato (May esclusa: identica alla forma piena)", sum(mm %in% abbr), 7077)
chk("  voti con mese 'May'", sum(mm == "May"), 18603)
chk("voti con mese scritto male nella fonte", sum(mm %in% c("Janry","Julu","Mya")), 3)
chk("date che un parser con %B perderebbe", sum(mm %in% abbr) + sum(mm %in% c("Janry","Julu","Mya")), 7080)
ya <- as.integer(format(dt, "%Y"))
chk("voti con anno della data diverso da YEA",
    sum(ya != as.integer(D$YEA), na.rm = TRUE), 1875)
chk("voti datati 2003", sum(ya == 2003, na.rm = TRUE), 155)
chk("voti datati 2013", sum(ya == 2013, na.rm = TRUE), 3348)
ch <- paste(D$SRC, D$TGT, D$VOT, D$RES, D$YEA, D$DAT, sep = "\r")
chk("righe interamente identiche", sum(duplicated(ch)), 595)
chk("commenti vuoti", sum(D$TXT == ""), 7190)
chk("lunghezza mediana del commento", median(nchar(D$TXT)), 98)
chk("lunghezza massima del commento", max(nchar(D$TXT)), 7610)
chk("commenti con marcatore in grassetto iniziale", sum(startsWith(D$TXT, "'''")), 162939)
chk("voti dati per votante: mediana", median(table(Dt$SRC)), 3)
chk("voti dati per votante: massimo, ESCLUSI i record fantasma", max(table(Dt$SRC[Dt$SRC != ""])), 1232)
chk("voti ricevuti per candidato: mediana", median(table(Dt$TGT)), 41)
chk("voti ricevuti per candidato: massimo", max(table(Dt$TGT)), 987)

# --------------------------------------------------------------- wiki-Elec --
sez("wiki-Elec: difetti di formato")
raw_b <- readLines(gzfile(FILE_ELEC), warn = FALSE, skipNul = TRUE)
chk("righe lette da readLines()", length(raw_b), 128016)
chk("righe in cui readLines() LASCIA un CR", sum(grepl("\r", raw_b, fixed = TRUE)), 0)
con <- gzfile(FILE_ELEC, open = "rb"); bb <- readBin(con, "raw", 3e6); close(con)
chk("coppie di byte CRLF nei primi 3 MB del file", 
    sum(bb[-length(bb)] == as.raw(13) & bb[-1] == as.raw(10)), 83859)
chk("righe non valide come UTF-8",
    sum(is.na(iconv(raw_b, from = "UTF-8", to = "UTF-8"))), 19)
E <- read_elec(FILE_ELEC)
chk("elezioni", nrow(E$elections), 2794)
chk("voti", nrow(E$votes), 114040)
chk("votanti distinti", length(unique(E$votes$voter)), 6210)
chk("promozioni", sum(E$elections$outcome == 1), 1248)
chk("respinte", sum(E$elections$outcome == 0), 1546)
chk("candidati distinti", length(unique(E$elections$candidate)), 2391)
chk("proponente = UNKNOWN", sum(E$elections$nominator == "UNKNOWN"), 2117)
chk("autonomine dichiarate", sum(E$elections$nominator == E$elections$candidate), 85)
chk("voti per elezione: mediana", median(table(E$votes$election_id)), 34)
chk("voti per elezione: massimo", max(table(E$votes$election_id)), 370)
chk("voti favorevoli", sum(E$votes$vot == 1), 83962)
chk("voti contrari",   sum(E$votes$vot == -1), 23118)
chk("voti neutri",     sum(E$votes$vot == 0), 6960)
chk("date di chiusura mancanti", sum(is.na(E$elections$closed_at)), 0)
yv <- as.integer(format(E$votes$dat, "%Y"))
chk("voti con anno impossibile (>2008)", sum(yv > 2008), 11)
cat("  chiusure dichiarate: da", format(min(E$elections$closed_at)),
    "a", format(max(E$elections$closed_at)), "\n")
cat("  voti (anni plausibili): da", format(min(E$votes$dat[yv <= 2008])),
    "a", format(max(E$votes$dat[yv <= 2008])), "\n")
chk("elezioni chiuse prima di settembre 2004",
    sum(E$elections$closed_at < as.POSIXct("2004-09-01", tz = "UTC")), 0)
chk("elezioni chiuse nel 2007", sum(format(E$elections$closed_at, "%Y") == "2007"), 2180)

sez("wiki-Elec: il campo T e inaffidabile")
ul <- vapply(split(as.numeric(E$votes$dat), E$votes$election_id)[
               as.character(E$elections$election_id)],
             function(x) max(x[x < as.numeric(as.POSIXct("2009-01-01", tz="UTC"))]), 0)
dT <- as.numeric(difftime(E$elections$closed_at,
                          as.POSIXct(ul, origin="1970-01-01", tz="UTC"), units="days"))
chk("scarto T - ultimo voto: mediana (giorni)", round(median(dT)), 102, tol = 1)
chk("elezioni con T oltre 30 giorni dopo", sum(dT > 30), 1512)
chk("elezioni con T oltre 180 giorni dopo", sum(dT > 180), 1217)
chk("minimo dello scarto (T prima dell'ultimo voto)", round(min(dT)), -188, tol = 1)

sez("grafie fra i due file")
chk("wiki-Elec: candidati con underscore", sum(grepl("_", unique(E$elections$candidate))), 408)
chk("wiki-Elec: candidati con spazio",    sum(grepl(" ",  unique(E$elections$candidate))), 0)
chk("wiki-RfA: candidati con underscore", sum(grepl("_", unique(Dt$TGT))), 0)
chk("wiki-RfA: candidati con spazio",     sum(grepl(" ",  unique(Dt$TGT))), 606)
ec <- unique(E$elections$candidate); rc <- unique(tolower(Dt$TGT))
chk("candidati wiki-Elec trovati in wiki-RfA, match diretto (%)",
    round(100*mean(ec %in% rc), 1), 74.9, tol = 0.2)
chk("candidati wiki-Elec trovati normalizzando (%)",
    round(100*mean(norm_user(ec) %in% norm_user(rc)), 1), 89.8, tol = 0.2)

# ---------------------------------------- igiene: le trappole classiche -----
# Questa sezione non verifica affermazioni: cerca attivamente la categoria di
# problemi "basilari" che e facile non vedere. Ogni riga e un difetto che, se
# presente e non trattato, produce nodi fantasma, archi inventati o conteggi
# sbagliati. I valori attesi sono quelli misurati e trattati; se cambiano,
# qualcosa nei dati o nel codice e cambiato e va guardato.
sez("IGIENE: le trappole classiche")
uu_raw <- unique(c(D$SRC, D$TGT))            # grafia originale del file
uu     <- unique(c(Dt$SRC, Dt$TGT))          # dopo pulisci_nome()
chk("nomi vuoti fra i nodi (qui i record fantasma ci sono ancora)", sum(uu == ""), 1)
chk("RECORD FANTASMA: voti con SRC vuoto", sum(Dt$SRC == ""), 1661)
chk("  di questi, quanti hanno anche TXT vuoto", sum(Dt$SRC == "" & Dt$TXT == ""), 1661)
chk("  candidati che esistono SOLO grazie a record fantasma",
    length(setdiff(unique(Dt$TGT[Dt$SRC == ""]), unique(Dt$TGT[Dt$SRC != ""]))), 6)
chk("nomi con spazi multipli interni, PRIMA della pulizia", sum(grepl("  ", uu_raw)), 1)
chk("  e dopo la pulizia", sum(grepl("  ", uu)), 0)
chk("nomi con caratteri invisibili, PRIMA della pulizia",
    sum(grepl("[\u200b-\u200f\ufeff]", uu_raw)), 1)
chk("  e dopo la pulizia", sum(grepl("[\u200b-\u200f\ufeff]", uu)), 0)
chk("nomi con tabulazione o a capo", sum(grepl("[\t\r\n]", uu)), 0)
chk("nomi con spazio non separabile U+00A0", sum(grepl("\u00a0", uu)), 0)
chk("nomi con entita HTML", sum(grepl("&[a-z]+;|&#[0-9]+;", uu)), 0)
chk("nomi con underscore (wiki-RfA non ne usa)", sum(grepl("_", uu)), 0)
chk("nomi non ASCII (legittimi)", sum(grepl("[^\x01-\x7f]", uu, perl = TRUE)), 78)
chk("AUTOVOTI: il candidato vota nella propria RfA", sum(Dt$SRC == Dt$TGT), 103)
chk("voti con TGT vuoto", sum(Dt$TGT == ""), 0)
chk("VOT fuori da {-1,0,1}", sum(!(D$VOT %in% c("-1","0","1"))), 0)
chk("RES fuori da {-1,1}", sum(!(D$RES %in% c("-1","1"))), 0)
chk("YEA fuori da 2003-2013", sum(!(as.integer(D$YEA) %in% 2003:2013)), 0)
chk("date prima del 2003", sum(dt < as.POSIXct("2003-01-01", tz = "UTC"), na.rm = TRUE), 0)
chk("date dopo maggio 2013 (fine dichiarata della copertura)",
    sum(dt > as.POSIXct("2013-05-31 23:59", tz = "UTC"), na.rm = TRUE), 75)

sez("IGIENE: wiki-Elec")
chk("votanti duplicati dentro la stessa elezione",
    sum(duplicated(paste(E$votes$election_id, E$votes$voter))), 0)
chk("elezioni senza alcun voto", nrow(E$elections) - length(unique(E$votes$election_id)), 0)
chk("elezioni con un solo voto", sum(table(E$votes$election_id) == 1), 97)
chk("il candidato vota nella propria elezione",
    sum(norm_user(E$votes$voter) == norm_user(
      E$elections$candidate[match(E$votes$election_id, E$elections$election_id)])), 72)
chk("username vuoti fra i votanti", sum(E$votes$voter == "" | is.na(E$votes$voter)), 0)
chk("due elezioni con stesso candidato e stessa chiusura",
    sum(duplicated(paste(E$elections$candidate, E$elections$closed_at))), 0)

# ------------------------------------------------ assunzioni del metodo -----
sez("ASSUNZIONE: RES e una proprieta dell'elezione, non del voto")
# Per ogni elezione di wiki-Elec appaiata, i voti corrispondenti in wiki-RfA
# hanno tutti lo stesso RES? Se no, raggruppare per RES e sbagliato.
Dt$dat <- dt; Dt$kc <- norm_user(Dt$TGT); Dt$kv <- norm_user(Dt$SRC)
ev <- E$votes; ev$kv <- norm_user(ev$voter)
ele <- E$elections; ele$kc <- norm_user(ele$candidate)
set_el <- split(ev$kv, ev$election_id)
res_misti <- 0L; esaminate <- 0L
idx_c <- split(seq_len(nrow(Dt)), Dt$kc)
for (r in seq_len(nrow(ele))) {
  ii <- idx_c[[ele$kc[r]]]; if (is.null(ii)) next
  s <- set_el[[as.character(ele$election_id[r])]]
  jj <- ii[Dt$kv[ii] %in% s]
  if (length(jj) < 10) next
  esaminate <- esaminate + 1L
  if (length(unique(Dt$RES[jj])) > 1) res_misti <- res_misti + 1L
}
cat(sprintf("  elezioni esaminate (>=10 votanti ritrovati): %d\n", esaminate))
cat(sprintf("  di cui con RES NON costante fra i loro voti in wiki-RfA: %d (%.1f%%)\n",
            res_misti, 100*res_misti/esaminate))
cat("  NB: un valore alto invaliderebbe il raggruppamento per (candidato, RES).\n")
log_righe <- c(log_righe,
  sprintf("  elezioni esaminate: %d | con RES non costante: %d (%.1f%%)",
          esaminate, res_misti, 100*res_misti/esaminate))

sez("ESITO")
cat(if (ko == 0) "Tutte le affermazioni verificate coincidono.\n" else
    sprintf("%d affermazioni NON coincidono.\n", ko))
log_righe <- c(log_righe, if (ko == 0) "Tutte le affermazioni coincidono." else
               sprintf("%d affermazioni NON coincidono.", ko))
writeLines(log_righe, file.path(DIR_PROCESSED, "99_verifica.txt"))
