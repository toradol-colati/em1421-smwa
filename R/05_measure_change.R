# 05 – Misura del cambiamento fra t e t+1.
# Input : data/processed/net_*.rds, data/processed/attempts_validated.rds
# Output: data/processed/features.rds
#
# Due blocchi, da tenere separati:
#   - PREDITTIVO: solo variabili note prima dell'apertura di t+1 (esito e quota di
#     sostegno a t, posizione del candidato nella rete fino a quel momento, voti dati
#     dal candidato nelle RfA altrui fra un tentativo e l'altro, tempo trascorso, anno).
#   - DESCRITTIVO: sostenitori in comune, nuovi sostenitori, diversita delle comunita.
#     Usano i voti di t+1, quindi non entrano mai nel modello; vanno confrontati con un
#     modello nullo che tiene fisso il numero di votanti.
#
# Controllo obbligatorio prima della regressione (contesto §8 punto 2): correlazione fra
# in-degree/centralita prima di t+1 e numero di votanti / quota di sostegno a t.
