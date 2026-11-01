"""Minimal reader for R .rds files (XDR, version 2/3): enough for data frames and lists."""
import gzip
import struct

import numpy as np
import pandas as pd

NA_INT = -2147483648


class _R:
    def __init__(self, buf):
        self.b, self.p, self.refs = buf, 0, []

    def i(self):
        v = struct.unpack_from(">i", self.b, self.p)[0]
        self.p += 4
        return v

    def d(self, n):
        v = np.frombuffer(self.b, ">f8", n, self.p).astype(float)
        self.p += 8 * n
        return v

    def ints(self, n):
        v = np.frombuffer(self.b, ">i4", n, self.p).astype(np.int64)
        self.p += 4 * n
        return v

    def item(self):
        flags = self.i()
        t = flags & 0xFF
        has_attr, has_tag = flags & 512, flags & 1024
        if t == 254 or t == 242:   # NILVALUE / EMPTYENV
            return None
        if t in (253, 252, 251):   # GLOBALENV, UNBOUND, MISSINGARG
            return None
        if t == 255:               # REFSXP
            idx = flags >> 8
            if idx == 0:
                idx = self.i()
            return self.refs[idx - 1]
        if t == 1:                 # SYMSXP
            s = self.item()
            self.refs.append(("sym", s))
            return ("sym", s)
        if t == 9:                 # CHARSXP
            n = self.i()
            if n == -1:
                return None
            s = self.b[self.p:self.p + n].decode("utf-8", "replace")
            self.p += n
            return s
        if t in (2, 6):            # LISTSXP / LANGSXP: pairlist
            out = []
            while True:
                attr = self.item() if has_attr else None
                tag = self.item() if has_tag else None
                car = self.item()
                out.append((tag[1] if isinstance(tag, tuple) else tag, car))
                flags = self.i()
                t2 = flags & 0xFF
                if t2 == 254:
                    break
                if t2 not in (2, 6):
                    self.p -= 4
                    out.append((None, self.item()))
                    break
                has_attr, has_tag = flags & 512, flags & 1024
            return ("pairlist", out)
        if t == 238:               # ALTREP
            info = self.item()
            state = self.item()
            attr = self.item()
            cls = info[1][0][1][1]
            if cls == "compact_intseq":
                n, start, step = state
                val = np.arange(start, start + step * n, step).astype(np.int64)
            elif cls == "compact_realseq":
                n, start, step = state
                val = np.arange(start, start + step * n, step).astype(float)
            elif cls.startswith("wrap_"):
                val = state[1][0][1] if isinstance(state, tuple) else state[0]
            elif cls == "deferred_string":
                val = np.array([str(x) for x in state[1][0][1]], dtype=object)
            else:
                raise ValueError("unsupported ALTREP " + cls)
            return self._attach(val, attr)
        if t == 4:                 # ENVSXP
            locked = self.i()
            env = {}
            self.refs.append(env)
            self.item(); self.item(); self.item(); self.item()
            if has_attr:
                self.item()
            return env
        if t in (10, 13):          # LGLSXP / INTSXP
            n = self.i()
            val = self.ints(n)
        elif t == 14:              # REALSXP
            n = self.i()
            val = self.d(n)
        elif t == 16:              # STRSXP
            n = self.i()
            val = np.array([self.item() for _ in range(n)], dtype=object)
        elif t in (19, 20):        # VECSXP / EXPRSXP
            n = self.i()
            val = [self.item() for _ in range(n)]
        elif t == 24:              # RAWSXP
            n = self.i()
            val = self.b[self.p:self.p + n]
            self.p += n
        elif t == 25:              # S4
            val = None
        else:
            raise ValueError(f"unsupported SEXP type {t} at {self.p}")
        if t == 10:
            val = np.where(val == NA_INT, -1, val)
            val = pd.array(np.where(val == -1, None, val == 1), dtype="boolean")
        attr = self.item() if has_attr else None
        return self._attach(val, attr)

    @staticmethod
    def _attach(val, attr):
        if attr is None:
            return val
        a = dict(attr[1])
        cls = a.get("class")
        cls = list(cls) if cls is not None else []
        if "factor" in cls:
            lev = list(a["levels"])
            codes = np.asarray(val)
            return pd.Categorical.from_codes(np.where(codes == NA_INT, -1, codes - 1), lev)
        if "data.frame" in cls:
            names = list(a["names"])
            cols = {}
            for nm, col in zip(names, val):
                if isinstance(col, np.ndarray) and col.dtype.kind == "i":
                    col = pd.array(np.where(col == NA_INT, None, col), dtype="Int64")
                cols[nm] = col
            return pd.DataFrame(cols)
        if "POSIXct" in cls:
            return pd.to_datetime(np.asarray(val, float), unit="s", errors="coerce")
        if "Date" in cls:
            return pd.to_datetime(np.asarray(val, float), unit="D", errors="coerce")
        if isinstance(val, list) and "names" in a:
            return dict(zip(list(a["names"]), val))
        return val


def read_rds(path):
    with gzip.open(path) as f:
        buf = f.read()
    r = _R(buf)
    assert buf[:2] == b"X\n"
    r.p = 2
    version = r.i(); r.i(); r.i()
    if version == 3:
        n = r.i()
        r.p += n
    return r.item()
