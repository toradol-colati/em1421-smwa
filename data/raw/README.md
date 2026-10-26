# data/raw

File SNAP come scaricati, compressi, non modificati. Nessuno script scrive qui.

| File | Fonte | Dimensione attesa | Copertura |
|---|---|---|---|
| `wiki-RfA.txt.gz` | https://snap.stanford.edu/data/wiki-RfA.html | 14.970.777 byte | 2003 – maggio 2013 |
| `wikiElec.ElecBs3.txt.gz` | https://snap.stanford.edu/data/wiki-Elec.html | 1.090.375 byte | 2.794 elezioni fino a gennaio 2008 |

Download:

```
curl -L -o data/raw/wiki-RfA.txt.gz https://snap.stanford.edu/data/wiki-RfA.txt.gz
curl -L -o data/raw/wikiElec.ElecBs3.txt.gz https://snap.stanford.edu/data/wikiElec.ElecBs3.txt.gz
```

Entrambi stanno sotto il limite GitHub dei 100 MB per file e vanno committati: la consegna
richiede i dati insieme al codice. Verificare la dimensione dopo il download: se è molto
minore, il file scaricato è una pagina di errore.

Citazioni dei dati:
- wiki-RfA: West, Paskov, Leskovec, Potts (2014), TACL 2: 297–310.
- wiki-Elec: Leskovec, Huttenlocher, Kleinberg (2010), CHI e WWW.
