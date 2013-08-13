#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import re
import sys
import math
import feats
from feats import load_fasta

# formato de la linea de descripcion:
#   * comienza con un > (opcionalmente precedido de espacios
#   * (1) id: 3 letras + n { alfanum | _ | - }
#   * se ignoran otros caracteres hasta el fin de linea
#   >hsa-mir-123 Homo sapiens... etc
desc_fmt = r"^\s*>([a-zA-Z]{2,3}[\w_|+-]+)(\s.+)?\s*$"

# formato de la linea de secuencia:
#   * sólo se reconocen los caracteres GCAUTgcaut
#     opcionalmente rodeados de espacios
#   GCGCGAAUACUCUCCUAUAUAAACC... etc
seqn_fmt = r"^\s*([GCAUgcau]+)\s*$"

# formato de la linea de estructura secundaria:
#   * idem anterior, pero con caracteres .()
#   * puede estar terminada por un numero entre parentesis
#   ...(((((.((((...(((.(((((.....))))))...)).).. etc
snds_fmt = r"^\s*([.()]+)(\s+\((\s*-?[0-9.]+)\s*\))?\s*$"

# formato de un string de estructura *con más de un loop*
#   * no acepta otra cosa que .(), sin espacios, nada
#   ....(((((.((..))))))..((((...))))).))... etc
mult_fmt = r"[.(]+\)[.()]*\([.)]+"

# error máximo tolerado al comparar floats
ERROR_THR = 1E-14


def triplet_compare_fasta( set1files, set2files ):
    """
    Lee los archivos de entrada, correspondientes a los sets 1 y 2
    y muestra información comparando set1 con set2
    @param set1files: archivos del set 1
    @param set2files: archivos del set 2
    @rtype: None
    """

    set1 = list()
    set2 = list()

    # leo el contenido de los archivos
    set1 = load_fasta(set1files)
    set2 = load_fasta(set2files)

    if len(set1) < len(set2):
        '''make set1 always be the larger set'''
        tmp = set1
        set1 = set2
        set2 = tmp

    j = 0
    k = 0
    while j < len(set1) and k < len(set2):
        if set1[j][0] != set2[k][0]:
            print("{}: in set1 but not in set2".format(set1[j][0]))
            j = j+1
            continue

        #seq_length
        if set1[j][5] != set2[k][5]:
            print("{}: SEQ_LENGTH differ! ({},{})".format(
                set1[j][0],set1[j][5],set2[k][5]))

        #gc_content
        if abs(set1[j][6]-set2[k][6]) > ERROR_THR:
            print("{}: GC_CONTENT differ! ({:.15g},{:.15g})".format(
                set1[j][0],set1[j][6],set2[k][6]))

        #basepair
        if set1[j][7] != set2[k][7]:
            print("{}: BASEPAIR differ! ({},{})".format(
                set1[j][0],set1[j][7],set2[k][7]))

        #free_energy
        if abs(set1[j][4]-set2[k][4]) > ERROR_THR:
            print("{}: FREE_ENERGY differ! ({:.15g},{:.15g})".format(
                set1[j][0],set1[j][4],set2[k][4]))

        #len_bp_ratio
        if abs(set1[j][8]-set2[k][8]) > ERROR_THR:
            print("{}: LEN_BP_RATIO differ! ({:.15g},{:.15g})".format(
                set1[j][0],set1[j][8],set2[k][8]))
        
        j = j+1
        k = k+1

    print("compared {}/{} elements.".format(len(set1),len(set2)))




def triplet_validate_extra ( infile ):
    """
    Lee el archivo de entrada y compara las características extra (Xue)
    presentes en el archivo con las que hubieran sido generadas
    por el método propio, informando en caso que hubiera discrepancias
    entre ambas. SE IGNORA LA FEAT FREE_ENERGY, al no estar disponibles
    los archivos generados por RNAfold.
    @param infiles: archivo a validar
    @rtype: None
    """

    set1 = list()

    # leo el contenido de los archivos
    set1 = load_fasta(infile)
    
    j = -1
    while j < len(set1)-1:
        j = j+1

        xf = feats.triplet_feats_extra(set1[j][2],set1[j][3])

        if re.match( mult_fmt, set1[j][3]):
            print("{}: multi-loop but still present in database!!!".format(
                set1[j][0]))

        #seq_length
        if set1[j][5] != xf["seq_length"]:
            print("{}: SEQ_LENGTH differ! ({},{})".format(
                set1[j][0],set1[j][5],xf["seq_length"]))

        #gc_content
        if abs(set1[j][6]-xf["gc_content"]) > ERROR_THR:
            print("{}: GC_CONTENT differ! ({:.15g},{:.15g})".format(
                set1[j][0],set1[j][6],xf["gc_content"]))

        #basepair
        if set1[j][7] != xf["basepair"]:
            print("{}: BASEPAIR differ! ({},{})".format(
                set1[j][0],set1[j][7],xf["basepair"]))

        #len_bp_ratio
        if abs(set1[j][8]-xf["len_bp_ratio"]) > ERROR_THR:
            print("{}: LEN_BP_RATIO differ! ({:.15g},{:.15g})".format(
                set1[j][0],set1[j][9],xf["len_bp_ratio"]))
        

    print("validated {} elements.".format(j+1))




def triplet_compare_svm ( file1, file2 ):
    """
    Compara 2 archivos de triplets en formato libSVM.
    Imprime mensajes en pantalla para los errores encontrados.
    @param file1: el primer archivo a leer.
    @param file2: el segundo archivo a leer.
    @rtype: none
    """

    libsvm_ent = r"(\d+):([\d.]+)"
    
    str1 = ""
    str2 = ""

    if type(file1) is list:
        for f in file1:
            str1 += f.read()
    else:
        str1 = file1.read()

    if type(file2) is list:
        for f in file2:
            str2 += f.read()
    else:
        str2 = file2.read()

    # assert the number of vectors in each file is the same
    if len(str1.splitlines()) != len(str2.splitlines()):
        print("Files differ in size! Refusing to compare.")
        return

    i = 0
    # for each line in both files ...
    for j,k in zip(str1.splitlines(),str2.splitlines()):

        # assert the number of vector elements for the current line is the same
        if len(j.split()) != len(k.split()):
            print("Vector size invalid at line {}! Aborting.".format(i))
            return
        
        for l,m in zip(j.split(),k.split()):
            n = re.split(libsvm_ent,l)
            o = re.split(libsvm_ent,m)

            if int(n[1]) != int(o[1]):
                print("line {}: differing position: {} vs {}".format(
                    i,n[1],o[1]))
            if (float(n[2])-float(o[2])) > ERROR_THR:
                print("line {}: differing value for elem {}: {} vs {}".format(
                    i,n[1],n[2],o[2]))
            
        i = i+1

    print("{} svm-format lines compared.".format(i))




def mipred_load ( contents ):
    '''loads a miPred-formatted file and returns a matrix of int values
    (or float for mfe). Note that order of fields is important, as they're
    not validated by the headers'''

    full = False
    if len(contents.splitlines()[1].split()) == 54:
        full = True
    elif len(contents.splitlines()[1].split()) != 25:
        print("Unexpected number of features: {}!!!!!".format(
        len(contents.splitlines()[1].split())))
        return None

    out = []
    for line in contents.splitlines():
        fields = line.split()
        v = []
        if full:
            if fields[0] == "ID":
                '''ignore header line'''
                continue
         
            for i in range(1,24):
                '''read feats: Len, nt(4), G+C, A+U, dint(16),
                in that order'''
                v.append(int(fields[i]))

            v.append(int(float(fields[46]))) # pb
            v.append(float(fields[48])) # mfe

        else:
            if fields[0] == "Len":
                '''ignore header line'''
                continue
            
            for i in range(0,24):
                '''read feats: Len, nt(4), G+C, A+U, dint(16), pb
                in that order'''
                v.append(int(fields[i]))

            v.append(float(fields[24])) # mfe
        
        out.append(v)

    return out




def mipred_compare ( file1, file2 ):
    """
    Compara 2 archivos de features de miPred.
    Ignora los campos ID, %xx, Nxx, Q y D 
    Imprime mensajes en pantalla para las discrepancias encontradas.
    @param file1: el primer archivo a leer.
    @param file2: el segundo archivo a leer.
    @rtype: none
    """

    str1 = ""
    str2 = ""

    if type(file1) is list:
        for f in file1:
            str1 += f.read()
    else:
        str1 = file1.read()

    if type(file2) is list:
        for f in file2:
            str2 += f.read()
    else:
        str2 = file2.read()

    # check if files have a "full" (as miPred script output) set of feats
    # or a "partial" set as obtained with own algorithm

    feats1 = mipred_load(str1)
    feats2 = mipred_load(str2)
    
    # assert the number of vectors in each file is the same
    if len(feats1) != len(feats2):
        print("Files differ in number of elements! Refusing to compare.")
        return

    fieldnames = ("Len A C G U G+C A+U AA AC AG AU CA CC CG CU GA GC GG GU" +
                  " UA UC UG UU pb mfe").split()

    # for each line ...
    for r in range(len(feats1)):
        # for each integer column ...
        for c in range(24):
            # print message if discrepancies are found
            if feats1[r][c] != feats2[r][c]:
                print("entry {} feat {}: differing value: {} vs {}".format(
                    r,fieldnames[c],feats1[r][c],feats2[r][c]))
                print(feats1[r])
                print(feats2[r])
        
        # compare the last value (mfe)
        if (feats1[r][24]-feats2[r][24]) > ERROR_THR:
            print("entry {} feat mfe: differing value: {} vs {}".format(
                r,feats1[r][24],feats2[r][24]))

    print("{} miPred entries compared.".format(len(feats1)))




def upred_load ( contents ):
    '''loads a microPred-formatted file and returns a matrix of float values.
    Note that order of fields is important, as they're
    not validated by the headers'''

    full = False
    extra = False
    if len(contents.splitlines()[1].split()) == 49:
        full = True
    elif len(contents.splitlines()[1].split()) == 10:
        extra = True
    elif len(contents.splitlines()[1].split()) != 6:
        print("Unexpected number of features: {}!!!!!".format(
        len(contents.splitlines()[1].split())))
        print(contents.splitlines()[1])
        return None

    out = []
    for line in contents.splitlines():
        fields = line.split()
        v = []
        if full:
            if fields[0] == "ID":
                '''ignore header line'''
                continue
         
            for i in [18,31,21,42,43,44]:
                '''read feats: mfei1, mfei4, dp, au/l, gc/l, gu/l,
                in that order'''
                v.append(float(fields[i]))

            # extra features
            pgc = float(fields[1])
            # length = (dH/[dH/L]+dS/[dS/L]+Tm/[Tm/L])/3
            lng = ( float(fields[36])/float(fields[37]) +
                    float(fields[38])/float(fields[39]) +
                    float(fields[40])/float(fields[41]) ) / 3.0
            # mfe = ( MFEI1 * %G+C + dG ) * length / 2
            mfe = ( float(fields[18])*pgc + float(fields[20])) * lng / 2.0
            # basepair = ( mfe/MFEI4 + length*dP ) /2
            bp  = int((mfe/float(fields[31])+lng*float(fields[21]))/2.0)

            v.append(bp) # basepair
            v.append(mfe) # mfe
            v.append(pgc) # %G+C
            v.append(int(lng)) # length
            
        else:
            if fields[0] == "MFEI1":
                '''ignore header line'''
                continue
            
            for i in range(6):
                '''read feats: mfei1, mfei4, dp, au/l, gc/l, gu/l,
                in that order'''
                v.append(float(fields[i]))

            if extra:
                # extra features:
                v.append(  int(fields[6])) # basepair
                v.append(float(fields[7])) # mfe
                v.append(float(fields[8])) # %G+C
                v.append(  int(fields[9])) # length
        
        out.append(v)

    return out




def upred_compare ( file1, file2 ):
    """
    Compara 2 archivos de features de miPred.
    Ignora los campos ID, %xx, Nxx, Q y D 
    Imprime mensajes en pantalla para las discrepancias encontradas.
    @param file1: el primer archivo a leer.
    @param file2: el segundo archivo a leer.
    @rtype: none
    """

    str1 = ""
    str2 = ""

    if type(file1) is list:
        for f in file1:
            str1 += f.read()
    else:
        str1 = file1.read()

    if type(file2) is list:
        for f in file2:
            str2 += f.read()
    else:
        str2 = file2.read()

    # check if files have a "full" (as miPred script output) set of feats
    # or a "partial" set as obtained with own algorithm

    feats1 = upred_load(str1)
    feats2 = upred_load(str2)
    
    # assert the number of vectors in each file is the same
    if len(feats1) != len(feats2):
        print("Files differ in number of elements! Refusing to compare.")
        return

    num_feats = 10
    if len(feats1[0]) == 6 or len(feats2[0]) == 6:
        num_feats = 6
    elif len(feats1[0]) != 10 or len(feats2[0]) != 10:
        print("Invalid feature count ({}/{}). Please check input.".format(
            len(feats1[0]),len(feats2[0])))
        return

    fieldnames = "MFEI1 MFEI4 dP |A-U|/L |G-C|/L |G-U|/L bp MFE %G+C L".split()

    mismatch = [0,0,0,0,0,0,0,0,0,0]

    feat_error = [1E-5, # mfei1
                  1E-5, # mfei4
                  1E-4, # dP
                  ERROR_THR, # au/l
                  ERROR_THR, # gc/l
                  ERROR_THR, # gu/l
                  None, # base pairs (int)
                  1E-2, # mfe
                  1E-2, # %g+c
                  None] # length (int)
                  

    # for each line ...
    for r in range(len(feats1)):
        # for each column  ...
        for c in range(6):
            # print message if discrepancies are found
            if abs(feats1[r][c]-feats2[r][c]) > feat_error[c]:
                mismatch[c] += 1
                if verbosity > 1:
                    print("entry {} feat {}: differing value: {} vs {}".format(
                        r,fieldnames[c],feats1[r][c],feats2[r][c]))

        # should I copmare the extra features?
        if num_feats > 6:
            for c in [6,9]:
                if feats1[r][c] != feats2[r][c]:
                    mismatch[c] += 1
                    if verbosity > 1:
                        print("entry {} feat {}: differing value: {} vs {}".format(
                            r,fieldnames[c],feats1[r][c],feats2[r][c]))
            
            for c in [7,8]:
                # print message if discrepancies are found
                if abs(feats1[r][c]-feats2[r][c]) > feat_error[c]:
                    mismatch[c] += 1
                    if verbosity > 1:
                        print("entry {} feat {}: differing value: {} vs {}".format(
                            r,fieldnames[c],feats1[r][c],feats2[r][c]))


    print("{} miPred entries compared.".format(len(feats1)))

    if sum(mismatch) > 0:
        for f in range(10):
            if mismatch[f] > 0:
                print(" * feature {}: {} differences.".format(fieldnames[f],mismatch[f]))
        print(" "*60 + "VERIFY!!")
    else:
        print(" "*60 + "OK")




def rnafold_clean ( infile, outfile, d=0 ):
    """
    Lee el archivo de entrada y guarda un archivo FASTA eliminando
    la información de estructura secundaria calculada por RNAfold.
    @param infile: archivo(s) a leer
    @param outfile: archivo donde escribir la salida
    @param d: auxiliar para recursión, debe ser cero
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)

    # para cada entrada
    for l in f:
        # guardo la entrada en el archivo
        outfile.write('>' + l[0] + '\n' + l[2] + '\n' )




def rnafold_compare( set1files, set2files ):
    """
    Lee los archivos RNAfold (FASTA), correspondientes a los sets 1 y 2
    y muestra información comparando set1 con set2 en forma abreviada
    @param set1files: archivos del set 1
    @param set2files: archivos del set 2
    @rtype: None
    """

    set1 = list()
    set2 = list()

    # leo el contenido de los archivos
    set1 = load_fasta(set1files)
    set2 = load_fasta(set2files)

    if len(set1) < len(set2):
        '''make set1 always be the larger set'''
        tmp = set1
        set1 = set2
        set2 = tmp

    j = 0
    k = 0

    unmatched = []
    seq_len = []
    seq_cont = []
    str_len = []
    str_cont = []
    mfe = []
    mfeinvalid = []

    vb = verbosity
    
    while j < len(set1) and k < len(set2):

        if set1[j][0] != set2[k][0]:
            if verbosity > 1:
                print("{}: in set1 but not in set2".format(set1[j][0]))
            unmatched.append(set1[j][0])
            j = j+1
            continue

        # length of sequence
        if len(set1[j][2]) != len(set2[k][2]):
            if verbosity > 1:
                print("{}: different sequence length: {} vs {}".format(
                    set1[j][0],len(set1[j][2]),len(set2[k][2])))
            seq_len.append(set1[j][0])

        # sequence content
        elif set1[j][2] != set2[k][2]:
            if verbosity > 1:
                print("{}: differing sequence content!".format(set1[j][0]))
                if verbosity > 2:
                    print(set1[j][2])
                    print(set2[k][2])
            seq_cont.append(set1[j][0])

        # has rnafold info?
        if set1[j][3] and set2[k][3]:
            
            # secondary structure length
            if len(set1[j][3]) != len(set2[k][3]):
                if verbosity > 1:
                    print("{}: different structure length: {} vs {}".format(
                        set1[j][0],len(set1[j][2]),len(set2[k][2])))
                str_len.append(set1[j][0])

            elif set1[j][3] != set2[k][3]:
                if verbosity > 1:
                    print("{}: differing structure content!".format(
                        set1[j][0]))
                    if verbosity > 2:
                        print(set1[j][3])
                        print(set2[k][3])
                str_cont.append(set1[j][0])

        # free_energy
        if type(set1[j][4]) is not None and type(set2[k][4]) is not None:
            if abs(set1[j][4]-set2[k][4]) > ERROR_THR:
                if verbosity > 1:
                    print("{}: different mfe: {} vs {}".format(
                        set1[j][0],set1[j][4],set2[k][4]))
                mfe.append(set1[j][0])
        else:
            if verbosity > 1:
                print("{}: invalid mfe value: {},{}".format(
                    set1[j][0],set1[j][4],set2[k][4]))
            mfeinvalid.append(set1[j][0])

        j = j+1
        k = k+1

    print("Compared {}/{} elements:".format(len(set1),len(set2)))

    if verbosity > 0:
        if unmatched:
            print(" * Unmatched entries: " + (','.join(
                i for i in unmatched)))
        if seq_len:
            print(" * Differing seq length: " + (','.join(
                i for i in seq_len)))
        if seq_cont:
            print(" * Differing seq content: " + (','.join(
                i for i in seq_cont)))
        if str_len:
            print(" * Differing str length: " + (','.join(
                i for i in str_len)))
        if str_cont:
            print(" * Differing str content: " + (','.join(
                i for i in str_cont)))
        if mfe:
            print(" * Differing min free energy: " + (','.join(
                i for i in mfe)))
        if mfeinvalid:
            print(" * Invalid min free energy: " + (','.join(
                i for i in mfeinvalid)))
    else:
        if unmatched:
            print(" * {} unmatched entries.".format(len(unmatched)))
        if seq_len:
            print(" * {} entries differing in sequence length.".format(
                len(seq_len)))
        if seq_cont:
            print(" * {} entries differing in sequence content".format(
                len(seq_cont)))
        if str_len:
            print(" * {} entries differing in structure length".format(
                len(str_len)))
        if str_cont:
            print(" * {} entries differing in structure content.".format(
                len(str_cont)))
        if mfe:
            print(" * {} entries with different min free energy.".format(
                len(mfe)))
        if mfeinvalid:
            print(" * {} entries with invalid min free energy.".format(
                len(mfeinvalid)))

    if unmatched or seq_len or seq_cont or str_len or str_cont or mfe or mfeinvalid:
        print( " "*60 + "VERIFY!")
    else:
        print( " "*60 + "OK")




# wrappers para las funciones
def wrap_triplet_compare_fasta (obj):
    triplet_compare_fasta(obj.set1, obj.set2)

def wrap_triplet_compare_svm (obj):
    triplet_compare_svm(obj.set1, obj.set2)

def wrap_triplet_validate (obj):
    triplet_validate_extra(obj.infile)

def wrap_mipred_compare (obj):
    mipred_compare(obj.set1, obj.set2)

def wrap_micropred_compare (obj):
    upred_compare(obj.set1, obj.set2)

def wrap_rnafold_compare (obj):
    rnafold_compare(obj.set1, obj.set2)

def wrap_rnafold_clean (obj):
    rnafold_clean(obj.file, obj.outfile)


parser = argparse.ArgumentParser( description='Feature extraction tests.',
                                  prog='tests.py')

parser.add_argument( '--verbose', '-v',
                     action='count',
                     help='increase verbosity level')

subp   = parser.add_subparsers()

tripcmpsv = subp.add_parser('triplet',
                            description="compare two triplet-SVM files")
tripcmpfa = subp.add_parser('triplet_fasta',
                            description="compare 3SVM extra feats, FASTA")
miprcmp   = subp.add_parser('mipred',
                            description="compare two miPred-format files")
micrcmp   = subp.add_parser('micropred',
                            description="compare two microPred-format files")
rnafcmp   = subp.add_parser('rnafold',
                            description="compare two RNAfold-format files")
rnafclean = subp.add_parser('rnafold_clean',
                            description="strip RNAfold info, FASTA output")
tripval   = subp.add_parser('triplet_validate',
                            description="validate 3SVM extra feats, FASTA")


tripcmpfa.set_defaults(func=wrap_triplet_compare_fasta)
tripcmpsv.set_defaults(func=wrap_triplet_compare_svm)
miprcmp.set_defaults  (func=wrap_mipred_compare)
micrcmp.set_defaults  (func=wrap_micropred_compare)
rnafcmp.set_defaults  (func=wrap_rnafold_compare)
rnafclean.set_defaults(func=wrap_rnafold_clean)
tripval.set_defaults  (func=wrap_triplet_validate)


rnafclean.add_argument ( 'file',
                         type=argparse.FileType('r'),
                         nargs='*',
                         default=sys.stdin,
                         help='file(s) to read from' )
rnafclean.add_argument ( '--outfile', '-o',
                         type=argparse.FileType('w'),
                         nargs='?',
                         default=sys.stdout,
                         help="output file to write to" )

tripval.add_argument   ( 'infile',
                         type=argparse.FileType('r'),
                         nargs='*',
                         default=sys.stdin,
                         help='file(s) to read from' )

tripcmpsv.add_argument ( '--set1', '-1',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be considered as set 1' )
tripcmpsv.add_argument ( '--set2', '-2',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be read into the second set' )

tripcmpfa.add_argument ( '--set1', '-1',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be considered as set 1' )
tripcmpfa.add_argument ( '--set2', '-2',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be read into the second set' )

miprcmp.add_argument   ( '--set1', '-1',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be considered as set 1' )
miprcmp.add_argument   ( '--set2', '-2',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be read into the second set' )

micrcmp.add_argument   ( '--set1', '-1',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be considered as set 1' )
micrcmp.add_argument   ( '--set2', '-2',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be read into the second set' )

rnafcmp.add_argument   ( '--set1', '-1',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be considered as set 1' )
rnafcmp.add_argument   ( '--set2', '-2',
                         type=argparse.FileType('r'),
                         nargs='+',
                         required=True,
                         help='file(s) to be read into the second set' )



if __name__ == "__main__":
    verbosity = 0
    obj = parser.parse_args()
    if obj.verbose:
        verbosity = obj.verbose
    obj.func(obj)
