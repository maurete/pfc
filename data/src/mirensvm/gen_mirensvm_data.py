#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import sys

desc_fmt = r"^\s*(>.*)\s*$"
seqn_fmt = r"^\s*([GCAUTNgcautn]+)\s*$"

def linetype( l ):
    if re.match(r"^\s*$", l):
        return "blank"
    elif re.match(seqn_fmt, l):
        return "sequence"
    else:
        return "comment"

def gen_fasta( data ):
    out = ""
    for l in data.splitlines():
        typ = linetype(l)
        if typ == "comment":
            out = "{}>{}\n".format(out,l)
        elif typ == "sequence":
            out = "{}{}\n".format(out,l)
        else:
            continue
    return out

if __name__ == "__main__":
    fasta = gen_fasta(sys.stdin.read())
    with open("rfam91-aga.fa", "w") as f:
        f.write(fasta)
