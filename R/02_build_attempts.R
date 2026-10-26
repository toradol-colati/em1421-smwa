# 02 – Ricostruzione dei tentativi: una riga per (candidato, tentativo).
# Input : data/processed/votes_raw.rds
# Output: data/processed/attempts.rds, data/processed/votes.rds
#
# DECISIONE APERTA (contesto §11.5). Da scrivere prima del codice:
#   - schema di `attempts`: candidato, n. tentativo, apertura, chiusura,
#     esito validato, flag di ambiguità;
#   - schema di `votes`: con id del tentativo;
#   - regola di deduplica (ipotesi: tenere l'ultimo voto per votante e tentativo);
#   - soglia temporale di separazione fra tentativi (precedente Kolczynska: 7 giorni),
#     scelta e tarata su wiki-Elec 2003-2007, non solo validata;
#   - trattamento dei voti senza DAT.
# Divisione del lavoro (punto B): i due membri la scrivono in parallelo e
# indipendenti, poi confrontano i conteggi e fissano una regola unica.
