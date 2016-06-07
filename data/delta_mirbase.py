#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import re
import sys
import math
import gzip
import feats
from feats import load_fasta, mult_fmt, seqn_fmt


mirbase_fmt = r'^>([\w-]+)\s+(MI\d+)\s+.*$'


def gen_delta_mirbase ( fasta_in, diff_in, fasta_out ):
    '''Generate delta-mirbase dataset. Builds a new FASTA file keeping
    only those entries tagged NEW and SEQUENCE in corresponding
    miRBase "miRNA.diff" file'''

    '''Read diff file'''

    diff_str = None
    try:
        with gzip.open(diff_in, 'r') as f:
            diff_str = f.read()
    except IOError:
        try:
            with open(diff_in, 'r') as f:
                diff_str = f.read()
        except IOError:
            raise IOError('FATAL: Could not read diff file.')

    mirbase_ids = []
    for l in diff_str.splitlines():
        s = l.split()
        if 'NEW' in s or 'SEQUENCE' in s:
            mirbase_ids.append(s[0])


    '''Read FASTA file'''

    f = load_fasta ( fasta_in )


    '''Write output file'''

    written = dict( [(k,False) for k in mirbase_ids] )

    # 0.id 1.description 2.sequence 3.secstructure
    fmt = re.compile(mirbase_fmt)

    for l in f:
        if fmt.match(l[1]):
            mir_id = fmt.match(l[1]).group(2)
            # print(mir_id)
            if mir_id in mirbase_ids:
                i=4 if l[3] else 3
                fasta_out.write( '\n'.join(l[1:i]) + '\n' )
        else:
            sys.stderr.write("discarding entry {}: unrecognized description"
                             " format\n".format(l[0]))


def wrap_gen_delta_mirbase(obj):
    gen_delta_mirbase(obj.file, obj.diff_file, obj.out_file)


parser = argparse.ArgumentParser( description='miRBase diff utils.',
                                  prog='delta_mirbase.py')

parser.add_argument( '--diff-file', '-d', type=str,
                     required=True, help='miRBase diff file' )

parser.add_argument( '--out-file', '-o', type=argparse.FileType('w'),
                     nargs='?', default=sys.stdout,
                     help="output FASTA file" )

parser.add_argument( 'file', type=argparse.FileType('r'),
                     nargs='*', default=sys.stdin,
                     help='file(s) to read from' )

parser.set_defaults(func=wrap_gen_delta_mirbase)

if __name__ == "__main__":
    obj = parser.parse_args()
    obj.func(obj)
