#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import re
import sys
import random
import math

# formato de la linea de descripcion:
#   * comienza con un > (opcionalmente precedido de espacios
#   * (1) id: 3 letras + n { alfanum | _ | - }
#   * se ignoran otros caracteres hasta el fin de linea
#   >hsa-mir-123 Homo sapiens... etc
desc_fmt = r"^\s*>([a-zA-Z]{3}[\w_-]+)([\s|].+)?\s*$"

# formato de la linea de secuencia:
#   * sólo se reconocen los caracteres GCAUTgcaut
#     opcionalmente rodeados de espacios
#   GCGCGAAUACUCUCCUAUAUAAACC... etc
seqn_fmt = r"^\s*([GCAUTgcaut]+)\s*$"

# formato de la linea de estructura secundaria:
#   * idem anterior, pero con caracteres .()
#   * puede estar terminada por un numero entre parentesis
#   ...(((((.((((...(((.(((((.....))))))...)).).. etc
snds_fmt = r"^\s*([.()]+)(\s+\((\s*-?[0-9.]+)\s*\))?\s*$"

# formato de un string de estructura *con más de un loop*
#   * no acepta otra cosa que .(), sin espacios, nada
#   ....(((((.((..))))))..((((...))))).))... etc
mult_fmt = r"[.(]+\)[.()]*\([.)]+"




def load_file ( f ):
    """
    Lee el archivo pasado como parámetro y lo guarda en un diccionario.
    @param f: el archivo a leer.
    @return: el diccionario con los items leídos del archivo.
    @rtype: dict
    """

    # en entries guardo cada entrada leida
    entries = dict()

    # si f es una lista de archivos
    # hago recursion con cada elem
    if type(f) is list:
        for li in f:
            entries.update(load_file(li))
    else:

        # variables auxiliares
        lineno = 0
        cur_dsc = None
        cur_seq = ""
        cur_st2 = ""
        id_ = ""

        # leo cada linea del archivo
        for line in f:
            lineno += 1
            # si leo una linea de descripcion
            if re.match(desc_fmt, line):
                # si no es la primera iteracion
                if cur_dsc:
                    # obtengo el id
                    id_ = re.split(desc_fmt, cur_dsc)[1]
                    # guardo la entrada en el dict 
                    entries[id_] = (cur_dsc, cur_seq, cur_st2)
                        
                # asigno el valor actual a la
                # linea de descripcion y reseteo las otras
                lll = line.replace( '''''', '')
                cur_dsc = lll[:-1]
                cur_seq = ""
                cur_st2 = ""
            
            # si leo una linea de secuencia
            elif re.match(seqn_fmt, line):
                # agrego el pedazo de secuencia
                # al final de la variable cur_seq
                cur_seq += re.split(seqn_fmt,line)[1]
            
            # si leo una linea de estructura secundaria
            elif re.match(snds_fmt, line):
                # separo la linea segun la regexp
                split = re.split(snds_fmt, line)
                # guardo al parte de estruct secund al
                # final de la var cur_st2
                cur_st2 += split[1]
                
                # si al final la linea contene la free energy
                if split[3]:
                    # la agrego al final de la linea de descripcion
                    cur_dsc += " FREE_ENERGY {}".format(split[3])

            # si no entiendo la linea, escribo una advertencia
            else:
                sys.stderr.write("WARNING: {}: ignoring line {:d}\n".format(
                        f.name,lineno))

        # si lei algo del for anterior, me queda
        # la ultima entrada sin guardar:
        if cur_dsc:
            # obtengo el id
            id_ = re.split(desc_fmt, cur_dsc)[1]
            # guardo la entrada en el dict 
            entries[id_] = (cur_dsc, cur_seq, cur_st2)
        
            # asigno el valor actual a la
            # linea de descripcion y reseteo las otras
            cur_dsc = line[:-1]
            cur_seq = ""
            cur_st2 = ""

    return entries




def strip ( infile, outfile, d=0 ):
    """
    Lee el archivo de entrada y guarda sólo aquellas entradas
    que no contengan múltiples loops en el archivo de salida.
    @param infile: archivo(s) a leer
    @param outfile: archivo donde escribir la salida
    @param d: auxiliar para recursión, debe ser cero
    @rtype: None
    """

    # leo el archivo
    seq = load_file(infile)

    # para cada entrada
    for val in seq.values():
        # testeo multiples loops
        if re.match( mult_fmt, val[2]):
            pass
        # si solo hay un loop
        else:
            # guardo la entrada en el archivo
            outfile.write(val[0] + '\n' +
                          val[1] + '\n' +
                          val[2] + '\n')




def count ( infile, d=0 ):
    """
    Lee el (los) archivo(s) de entrada y cuenta el número de
    entradas, detallando cuáles tiene estructura secundaria.
    @param infile: archivo(s) a leer
    @param d: auxiliar para recursión, debe ser cero
    @rtype: None
    """

    # variables donde cuento
    num_desc_lines = 0
    num_seqn_lines = 0
    num_str2_lines = 0

    # si infile es una lista de archivos
    # hago recursion con cada elem
    if type(infile) is list:
        for li in infile:
            (d,s,s2) = count(li, d+1)
            num_desc_lines += d
            num_seqn_lines += s
            num_str2_lines += s2

    # si solo me pasaron un archivo
    else:
        # cargo el archivo
        seq = load_file(infile)

        # cuento las entradas en el diccionario
        for val in seq.values():
            num_desc_lines += 1
            # chequeo si tiene la secuencia
            if val[1]:
                num_seqn_lines += 1
            # chequeo si tiene la estructura secundaria
            if val[2]:
                num_str2_lines += 1

        # imprimo las cuentas para el archivo actual
        print('''{}:
{:>10d} description lines
{:>10d} sequence lines
{:>10d} secondary-structure lines
'''.format(infile.name,
           num_desc_lines,
           num_seqn_lines,
           num_str2_lines))

        return (num_desc_lines,
                num_seqn_lines,
                num_str2_lines)
    
    # imprimo las cuentas totales
    print('''
total:
{:>10d} description lines
{:>10d} sequence lines
{:>10d} secondary-structure lines
'''.format(num_desc_lines,
           num_seqn_lines,
           num_str2_lines))




def compare( set1files, set2files ):
    """
    Lee los archivos de entrada, correspondientes a los sets 1 y 2
    y muestra información comparando set1 con set2
    @param set1files: archivos del set 1
    @param set2files: archivos del set 2
    @rtype: None
    """

    set1 = dict()
    set2 = dict()

    # leo el contenido de los archivos
    set1.update(load_file(set1files))
    set2.update(load_file(set2files))
    
    # los dict se pueden restar: set1-set2 devuelve un nuevo dict
    # con los elementos de set1 que no estan en set2
    entries_only_set1 = set(set1.keys()) - set(set2.keys())
    entries_only_set2 = set(set2.keys()) - set(set1.keys())

    # en estas variables cuento diferencias de secuencia/estructura
    differing_sequences = 0
    differing_secondary = 0

    # para cada elemento de la interseccion
    for key in set(set1.keys()) & set(set2.keys()):
        # si coinciden, no hago nada
        if set1[key] == set2[key]:
            pass

        else:
            # si difiere la secuencia, la cuento
            if set1[key][1] != set2[key][1]:
                differing_sequences += 1

            # si difiere la estructura, cuento
            if set1[key][2] != set2[key][2]:
                differing_secondary += 1

            # modo super-verbose imprime entrada tras entrada
            if verbosity > 1 and set1[key][1:2] != set2[key][1:2]:                
                print( "set1: {}".format(set1[key]) )
                print( "set2: {}".format(set2[key]) )

    # modo verbose muestra elementos unicos en cada conjunto
    if verbosity > 0:
        if len(entries_only_set1) > 0:
            print ("\nentries in set 1 but not in set 2:")
            for e in entries_only_set1:
                print ("{}".format(e))
        if len(entries_only_set2) > 0:
            print ("\nentries in set 2 but not in set 1:")
            for e in entries_only_set2:
                print ("{}".format(e))

    # muestro la informacion recopilada, salgo
    print('''{:>10d} entries read into set1
{:>10d} entries read into set2
{:>10d} entries have different sequences
{:>10d} entries have different secondary structure
{:>10d} entries in set1 not found in set2
{:>10d} entries in set2 not found in set1
'''.format(len(set1),
           len(set2),
           differing_sequences,
           differing_secondary,
           len(entries_only_set1),
           len(entries_only_set2)))




def triplet ( sequence, structure, normalize = True ):
    """
    Calcula el 32-vector de frecuencia de triplets según el
    procedimiento explicado en Xue et al.
    @param sequence: string de secuencia (long. N)
    @param structure: string de estructura secundaria (long. N)
    @return: 32-vector, cada elemento tiene el nro de ocurrencias para el triplet
    @rtype: list
    """

    # las longitudes deben coincidir
    if len(sequence) != len(structure):
        raise Exception( "sequence and structure differ in length!" )

    # occur mapea triplet: nro de ocurrencias,
    # por ej: occur['G.(('] = 2
    occur = dict()
    occur['total'] = 0

    # inicializo los elementos en 0
    for n in 'GCUA':
        for s in ['...', '..(', '.(.', '.((', '(..', '(.(', '((.', '(((']:
            occur[n + s] = 0

    # busco limites de areas a considerar (ver paper)
    ll = structure.find('(')
    lr = structure.rfind('(')
    rl = structure.find(')')
    rr = structure.rfind(')')

    ll = max(1,ll)
    rr = min(len(structure)-2,rr)

    # si lr > rl probablemente haya mas de un loop
    if lr > rl:
        raise Exception("couldn't guess hairpin structure (more than one loop?)")

    # convierto todos los parentesis a '('
    structure = structure.replace(')','(')

    # recorro la secuencia: para cada triplet sumo 1 al bucket correspondiente
    for i in list(range(ll,lr+1)) + list(range(rl,rr+1)):
        occur[sequence[i] + structure[i-1:i+2]] += 1
        occur['total'] += 1

    vector = []
    tot = float(occur['total'])

    # finalmente genero el vector de ocurrencias
    for n in 'GCUA':
        for s in ['...', '..(', '.(.', '.((', '(..', '(.(', '((.', '(((']:
            if normalize:
                vector.append(occur[n + s] / tot)
            else:
                vector.append(occur[n + s])
            
    return vector




def svmout ( infile, outfile, label ):
    """
    Genera el archivo de entrada para libsvm, etiquetando
    a todos los elementos con la etiqueta 'label' (int)
    @param infile: archivo(s) de entrada (formato FASTA)
    @param outfile: archivo de salida (formato libsvm)
    @param label: etiqueta para los elementos de salida (int)
    @rtype: None
    """

    # leo el archivo
    seq = load_file(infile)

    # para cada elemento leido
    for val in seq.values():
        # si es multiloop, paso
        if re.match( mult_fmt, val[2]):
            pass
            
        else:
            # obtengo el vector de frecuencias de triplets
            v = triplet(val[1], val[2])
            # escribo la etiqueta al arch. de salida
            outfile.write("{:d}".format(label))
            # para cada i de 1 a 32
            for i in range(len(v)):
                if v[i] != 0:
                    # escribo i:v[i] 
                    outfile.write( " {:d}:{:f}".format(i+1,v[i]) )

            # escribo un retorno de linea
            outfile.write('\n')




def fannout ( infile, outfile, label ):
    """
    Genera el archivo de entrada para libfann, etiquetando
    a todos los elementos con la etiqueta 'label' (int)
    @param infile: archivo(s) de entrada (formato FASTA)
    @param outfile: archivo de salida (formato libfann)
    @param label: etiqueta para los elementos de salida (int)
    @rtype: None
    """

    # leo el archivo
    seq = load_file(infile)

    # escribo el número de patrones, entradas y salidas
    outfile.write("{:d} {:d} {:d}\n".format(len(seq), 32, 1))

    # para cada elemento leido
    for val in seq.values():
        # si es multiloop, paso
        if re.match( mult_fmt, val[2]):
            pass
            
        else:
            # obtengo el vector de frecuencias de triplets
            v = triplet(val[1], val[2])
            # para cada input de 1 a 32
            for i in v:
                # escribo v[i]
                outfile.write( "{:f} ".format(i) )

            # escribo la etiqueta (salida esperada) al arch. de salida
            outfile.write("\n{:d}\n".format(label))




def partition ( infile, outfile1, outfile2, s1=None, s2=None, d=0 ):
    """
    Particiona los elementos de entrada en dos archivos de salida.
    Las particiones se generan sampleando aleatoriamente y no tienen
    elementos en común.
    @param infile: archivo(s) de entrada
    @param outfile1: archivo de salida partición 1
    @param outfile2: archivo de salida partición 2
    @param s1: número de elementos en la part 1 (default 70%)
    @param s2: número de elementos en la part 2 (default 30%)
    @param d: auxiliar de recursión. No especificar!
    @rtype: None
    """

    # aca leo las entradas
    entries = load_file(infile)

    random.seed()

    # valores por defecto para s1, s2
    if not s1:
        s1 = math.floor(len(entries) * 0.7)
    if not s2:
        s2 = math.ceil(len(entries) * 0.3)

    # sampleo elementos para part1
    p1k = random.sample(entries.keys(), s1)

    # sampleo elementos para part2 (que manera más guay de hacerlo :)
    p2k = random.sample([k for k in entries.keys() if k not in p1k], s2)

    # mañas de python
    if type(outfile1) is list:
        outfile1 = outfile1[0]
    if type(outfile2) is list:
        outfile2 = outfile2[0]
        
    # escribo los archvos de salida
    for k in p1k:
        outfile1.write(entries[k][0] + '\n' +
                       entries[k][1] + '\n' +
                       entries[k][2] + '\n')
    for k in p2k:
        outfile2.write(entries[k][0] + '\n' +
                       entries[k][1] + '\n' +
                       entries[k][2] + '\n')

    outfile1.close()
    outfile2.close()




# wrapper para las funciones
def wrap_strip (obj):
    strip(obj.file, obj.outfile)

def wrap_count(obj):
    count(obj.file)

def wrap_compare(obj):
    compare(obj.set1, obj.set2)

def wrap_svmout (obj):
    svmout(obj.file, obj.outfile, obj.label)

def wrap_fannout (obj):
    fannout(obj.file, obj.outfile, obj.label)

def wrap_part (obj):
    partition(obj.file, obj.outfile1, obj.outfile2, obj.size1, obj.size2)


parser = argparse.ArgumentParser( description='FASTA file format manipulation utility.',
                                  prog='fautil')

parser.add_argument( '--verbose', '-v',
                     action='count',
                     help='increase verbosity level')

subp   = parser.add_subparsers()
countp = subp.add_parser('count',
                         #aliases=['contar'],
                         description="count entries in input files")
cmppar = subp.add_parser('compare',
                         #aliases=['cmp', 'comparar'],
                         description="compare two sets of files")
strp   = subp.add_parser('strip',
                         #aliases=['singloop'],
                         description="strip multiloop entries from input")
svmp   = subp.add_parser('svm',
                         #aliases=['svmout'],
                         description="convert to libsvm format")
fannp  = subp.add_parser('fann',
                         #aliases=['svmout'],
                         description="convert to libfann format")
partp  = subp.add_parser('part',
                         #aliases=['partition'],
                         description="partition input file into two output sets")

countp.add_argument('file',
                    type=argparse.FileType('r'),
                    nargs='*',
                    default=sys.stdin,
                    help='input file(s)')
cmppar.add_argument('--set1', '-1',
                    type=argparse.FileType('r'),
                    nargs='+',
                    required=True,
                    help='file(s) to be considered as set 1')
cmppar.add_argument('--set2', '-2',
                    type=argparse.FileType('r'),
                    nargs='+',
                    required=True,
                    help='file(s) to be counted in the second set')
strp.add_argument  ('file',
                    type=argparse.FileType('r'),
                    nargs='*',
                    default=sys.stdin,
                    help='file(s) to read from')
strp.add_argument  ('--outfile', '-o',
                    type=argparse.FileType('w'),
                    nargs='?',
                    default=sys.stdout,
                    help="output file to write")
svmp.add_argument  ('file',
                    type=argparse.FileType('r'),
                    nargs='*',
                    default=sys.stdin,
                    help='file(s) to read from')
svmp.add_argument  ('--outfile', '-o',
                    type=argparse.FileType('w'),
                    nargs='?',
                    default=sys.stdout,
                    help="output file to write")
svmp.add_argument  ('--label', '-l',
                    type=int,
                    nargs='?',
                    default=-1,
                    help="label for the dataset (default = -1)")
fannp.add_argument ('file',
                    type=argparse.FileType('r'),
                    nargs='*',
                    default=sys.stdin,
                    help='file(s) to read from')
fannp.add_argument ('--outfile', '-o',
                    type=argparse.FileType('w'),
                    nargs='?',
                    default=sys.stdout,
                    help="output file to write")
fannp.add_argument ('--label', '-l',
                    type=int,
                    nargs='?',
                    default=-1,
                    help="label for the dataset (default = -1)")
partp.add_argument ('file',
                    type=argparse.FileType('r'),
                    nargs='*',
                    default=sys.stdin,
                    help='file(s) to read from')
partp.add_argument ('--outfile1', '-o1', '-1',
                    type=argparse.FileType('w'),
                    nargs=1,
                    default=None,
                    help="output file for partition 1")
partp.add_argument ('--outfile2', '-o2', '-2',
                    type=argparse.FileType('w'),
                    nargs=1,
                    default=None,
                    help="output file for partition 2")
partp.add_argument ('--size1', '-s1',
                    type=int,
                    nargs='?',
                    default=None,
                    help="size of partition 1 [entries] (default = 70% of entries)")
partp.add_argument ('--size2', '-s2',
                    type=int,
                    nargs='?',
                    default=None,
                    help="size of partition 2 [entries] (default = 30% of entries)")


strp.set_defaults(func=wrap_strip)
svmp.set_defaults(func=wrap_svmout)
fannp.set_defaults(func=wrap_fannout)
countp.set_defaults(func=wrap_count)
cmppar.set_defaults(func=wrap_compare)
partp.set_defaults(func=wrap_part)

if __name__ == "__main__":

    verbosity = 0

    obj = parser.parse_args()

    if obj.verbose is not None:
        verbosity = obj.verbose
        
    obj.func(obj)

