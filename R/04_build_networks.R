# 04 – Costruzione delle reti (igraph).
# Input : data/processed/votes.rds, data/processed/attempts_validated.rds
# Output: data/processed/net_*.rds
#
# DECISIONE APERTA (contesto §11.4). Per ciascuna rete servono quattro scelte
# esplicite - nodo, arco, direzione, peso - piu finestra temporale:
#   - rete di voto: votante -> candidato, favorevoli e contrari separati,
#     voti neutri (VOT = 0) da trattare, finestra = tutto fino all'apertura di t+1;
#   - rete di co-voto votante-votante: cosa crea un arco e con che peso;
#     proiezione densa, estrarre il backbone (pacchetto backbone) contro un modello nullo;
#   - algoritmo di community detection;
#   - rete su cui si misura la brokerage e quale misura (vincoli di Burt o betweenness).
