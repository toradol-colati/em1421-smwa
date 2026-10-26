# 06 – Esito del tentativo successivo.
# Input : data/processed/features.rds
# Output: data/processed/model_*.rds
#
# Confronto descrittivo per esito precedente, poi regressione logistica parsimoniosa.
# Vincoli:
#   - nessun predittore osservato durante t+1;
#   - coppie di tentativi dello stesso candidato non indipendenti: una coppia per
#     candidato, oppure raggruppamento per candidato;
#   - contare i successi a t+1: circa 10 eventi per variabile;
#   - termine di confronto: tasso di successo al primo tentativo, o un modello con solo
#     esito precedente e anno;
#   - l'anno va controllato comunque (gli standard RfA sono cambiati nel tempo).
