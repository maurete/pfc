#!/usr/bin/env python
# -*- coding: utf-8 -*-

import re
import sys

desc_fmt = r"^\s*(>.*)\s*$"
seqn_fmt = r"^\s*([GCAUTNgcautn]+)\s*$"

def linetype( l ):
    if re.match(r"^\s*$", l):
        return "blank"
    elif re.match(seqn_fmt, l) or re.match(desc_fmt,l):
        return "data"
    else:
        return "comment"

def partition ( data ):
    output = []
    output.append([])
    lasttyp = "comment"
    for line in data.splitlines():
        typ = linetype(line)
        if typ == "blank":
            continue
        elif typ == "comment":
            if lasttyp != "comment":
                output.append([])
                lasttyp = "comment"
        elif typ == "data":
            output[-1].append(line)
            lasttyp = "data"
    return output

def datatype( l ):
    if re.match(seqn_fmt, l):
        return "sequence"
    elif re.match(desc_fmt,l):
        return "description"
    else:
        return "unknown"

def test_part( p ):
    for e in p:
        last = None
        for l in e:
            if last == None:
                if datatype(l) != "description":
                    raise Exception("error: data begins with a non-description line")
                last = "description"
            else:
                if datatype(l) != last:
                    last = datatype(l)
                else:
                    raise Exception("error: contiguous same-type line")

def is_real( desc ):
    if desc.strip()[0:5] in [ ">hsa-", ">cfa-", ">mmu-", ">rno-", ">cel-", ">dme-" ]:
        return True
    return False

def realpseudo( part ):
    test_part(part)
    real = []
    pseudo = []
    for e in part:
        real.append([])
        pseudo.append([])
        li = 0
        while li < len(e):
            if is_real(e[li]):
                real[-1].extend(e[li:li+2])
            else:
                pseudo[-1].extend(e[li:li+2])
            li = li+2
    return real, pseudo

def write_files( real, pseudo):
    names = [ "hsa-test", "hsa", "cel-test", "cel", "dme-test", "dme",
              "rno-test", "rno", "cfa-test", "cfa", "ignore", "mmu-test",
              "mmu", "ignore" ]

    for i in range(len(names)):
        if names[i] == "ignore":
            continue
        with open("{}-real.fa".format(names[i]), "w") as f:
            f.writelines( "{}\n".format(l) for l in real[i] )
            print ("wrote {} entries for {}-real.fa".format(len(real[i])/2,names[i]))
        with open("{}-pseudo.fa".format(names[i]), "w") as f:
            f.writelines( "{}\n".format(l) for l in pseudo[i] )
            print ("wrote {} entries for {}-pseudo.fa".format(len(pseudo[i])/2,names[i]))

if __name__ == "__main__":
    part = partition(sys.stdin.read())
    (real, pseudo) = realpseudo(part)
    write_files(real, pseudo)
