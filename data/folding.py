#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import re
import sys
from feats import load_fasta, seqn_fmt, mult_fmt




def find_loops ( structure ):
    """
    encuentra el loop principal para la estructura secundaria.
    @param structure: estructura secundaria a examinar.
    @rtype: tupla con valores (inicio,fin,bp) del loop central.
    """

    # formato de tallo actual hacia izquierda y derecha
    left_fmt = r"(?<=^)[(.]+\(|(?<=\))[(.]+\("
    right_fmt = r"\)[.)]+(?=$)|\)[.)]+(?=\()"

    # divido la estructura en loops, devuelve en vactor con elementos:
    # < tallo lazo [[tallo-tallo lazo] ...] tallo >
    split = re.split(r"(?<=\()(\.*)(?=\))",structure)

    loops = []
    # para cada elemento del split
    for i in range(len(split)):
        if "(" in split[i] or ")" in split[i]:
            pass
        else:
            # inicio y fin del loop
            beg = sum(len(split[k]) for k in range(0,i))
            end = beg+len(split[i])

            # basepairs a derecha e izquierda del loop
            bpl = re.findall(left_fmt, structure[:beg])[-1].count('(')
            bpr = re.findall(right_fmt, structure[end:])[0].count(')')

            loops.append((beg,end,bpl,bpr))
    
    return loops




def find_main_loop_old ( structure ):
    """
    encuentra el loop principal para la estructura secundaria.
    @param structure: estructura secundaria a examinar.
    @rtype: tupla con valores (inicio,fin) del loop central.
    """

    # divido la estructura en loops, devuelve en vactor con elementos:
    # < tallo lazo [[tallo-tallo lazo] ...] tallo >
    split = re.split(r"(?<=\()(\.*)(?=\))",structure)

    centrality = []
    # calculo la centralidad de los lazos
    # para cada elemento del split
    for i in range(len(split)):
        if "(" in split[i] or ")" in split[i]:
            # si es tallo, seteo valor maximo
            centrality.append(len(structure))
        else:
            # si es lazo, seteo |nts a izq - nts a der| como centralidad 
            centrality.append(abs(sum(len(split[k]) for k in range(0,i)) -
                                  sum(len(split[l]) for l in range(i+1,len(split)))))

    # el valor minimo será el bucle central
    idx = centrality.index(min(centrality))
    # encuentro inicio, fin del bucle central
    pos = sum(len(split[k]) for k in range(0,idx))
    return (pos,pos+len(split[idx]))




def find_outer_loops_old ( structure ):
    """
    encuentra el loop principal para la estructura secundaria.
    @param structure: estructura secundaria a examinar.
    @rtype: tupla con valores (inicio,fin) del loop central.
    """

    # divido la estructura en loops, devuelve en vactor con elementos:
    # < tallo lazo [[tallo-tallo lazo] ...] tallo >
    split = re.split(r"(?<=\()(\.*)(?=\))",structure)

    centrality = []
    # calculo la centralidad de los lazos
    # para cada elemento del split
    for i in range(len(split)):
        if "(" in split[i] or ")" in split[i]:
            # si es tallo, seteo valor maximo
            centrality.append(len(structure))
        else:
            # si es lazo, seteo |nts a izq - nts a der| como centralidad 
            centrality.append(abs(sum(len(split[k]) for k in range(0,i)) -
                                  sum(len(split[l]) for l in range(i+1,len(split)))))

    # devolveré un vector de tuplas (inicio,fin)
    out = []
    count = 0
    for i in centrality:
        # si no es min(central) ni max(tallo)
        if min(centrality) < i < len(structure):
            # calculo y guardo posicion en vector out
            pos = sum(len(split[k]) for k in range(0,count))
            out.append((pos,pos+len(split[count])))
        count = count + 1
    
    return out




def untangle_old ( structure ):
    """
    desenreda el hairpin dejando solo el bucle central.
    @param structure: estructura secundaria a examinar.
    @rtype: str, estructura secundaria desenredada.
    """

    # formato de tallo actual hacia izquierda y derecha
    left_fmt = r"(?<=^)[(.]+\(|(?<=\))[(.]+\("
    right_fmt = r"\)[.)]+(?=$)|\)[.)]+(?=\()"

    # busco loops secundarios, a eliminar
    loops = find_outer_loops( structure )
    
    # convierto a bytearray para poder modificar in-place
    str2 = bytearray(structure)

    # para cada loop secundario
    for loop in loops:
        # cantidad de bp a izq,der que pueden ser tallo del bucle actual
        lpairs = re.findall(left_fmt, structure[:loop[0]])[-1].count('(')
        rpairs = re.findall(right_fmt, structure[loop[1]:])[0].count(')')

        # separo el minimo de bp
        for i in range(min(lpairs,rpairs)):
            str2[str2.rfind("(",0,loop[0])] = "."
            str2[str2.find(")",loop[1],-1)] = "."

    # devuelvo la estructura desenredada
    return str(str2)




def untangle ( structure ):
    """
    desenreda el hairpin dejando solo el bucle central.
    @param structure: estructura secundaria a examinar.
    @rtype: str, estructura secundaria desenredada.
    """

    # formato de tallo actual hacia izquierda y derecha
    left_fmt = r"(?<=^)[(.]+\(|(?<=\))[(.]+\("
    right_fmt = r"\)[.)]+(?=$)|\)[.)]+(?=\()"

    # busco todos los loops
    loops = find_loops( structure )
    
    maxstem = 0
    mainidx = -1
    # busco el loop principal
    for i in range(len(loops)):
        if (loops[i][2]+loops[i][3]) > maxstem:
            maxstem = loops[i][2]+loops[i][3]
            mainidx = i

    # elimino el loop principal de la lista
    del loops[mainidx]

    # convierto a bytearray para poder modificar in-place
    str2 = bytearray(structure)

    # para cada loop secundario
    for loop in loops:
        # separo el minimo de bp
        for i in range(min(loop[2],loop[3])):
            str2[str2.rfind("(",0,loop[0])] = "."
            str2[str2.find(")",loop[1],-1)] = "."

    # devuelvo la estructura desenredada
    return str(str2)




def rnafold_clean ( infile, outfile, minlen=0, maxlen=500 ):
    """
    Lee el archivo de entrada y guarda un archivo FASTA eliminando
    la información de estructura secundaria calculada por RNAfold.
    Opcionalmente
    @param infile: archivo(s) a leer
    @param outfile: archivo donde escribir la salida
    @param minlen: longitud mínima de las secuencias a guardar
    @param maxlen: longitud máxima de las secuencias a guardar
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)

    # para cada entrada
    for l in f:
        if minlen <= len(l[2]) <= maxlen:
            # si la secuencia es valida
            if re.match(seqn_fmt,l[2]):
                # guardo la entrada en el archivo
                outfile.write( l[1] + '\n' + l[2] + '\n' )
            else:
                sys.stderr.write("discarding entry {}: invalid sequence\n".format(l[0]))
        else:
            sys.stderr.write("discarding entry {}: invalid length\n".format(l[0]))




def untangle_file ( infile, outfile ):
    """
    Lee el archivo de entrada y guarda sólo aquellas entradas
    que no contengan múltiples loops en el archivo de salida.
    Incluye las variables extra calculadas en el paper de xue
    @param infile: archivo(s) a leer
    @param outfile: archivo donde escribir la salida
    @param sample: no. máx de elems, sel. aleatoria. si <=0 => todos
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)

    # para cada entrada
    for l in f:

        str2 = l[3]
        # testeo multiples loops
        c = 0
        while re.match( mult_fmt, str2):
            str2 = untangle(str2)
            c = c+1

            if c > 20:
                sys.stderr.write("Infinite loop. Entry follows:\n{}\n{}\n{}\n".format(
                    l[0],l[2],str2))
                return
        
        try:
            if l[4]:
                str2 = "{} ({:.2f})".format(str2,l[4])

            outfile.write('>{}\n{}\n{}\n'.format(l[0],l[2],str2))

        except Exception as e:
            sys.stderr.write("error untangling entry {}:\n{}\n{}".format(
                l[0],l[2],l[3]))




# wrappers para las funciones
def wrap_untangle (obj):
    untangle_file(obj.file, obj.outfile)

def wrap_rnafold_clean (obj):
    rnafold_clean(obj.file, obj.outfile, obj.minlength, obj.maxlength)




parser = argparse.ArgumentParser( description='Folding manipulation utility.',
                                  prog='folding.py')
parser.add_argument( '--verbose', '-v',
                     action='count',
                     help='increase verbosity level')

subp = parser.add_subparsers()
rnafclean = subp.add_parser('clean',
                            description="strip RNAfold info, FASTA output")
funtangle = subp.add_parser('untangle',
                            description="remove multiloop entries, FASTA fmt")

rnafclean.set_defaults(func=wrap_rnafold_clean)
funtangle.set_defaults(func=wrap_untangle)

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
rnafclean.add_argument ( '--minlength', '-m',
                         type=int,
                         nargs='?',
                         default=0,
                         help="minimum sequence length" )
rnafclean.add_argument ( '--maxlength', '-M',
                         type=int,
                         nargs='?',
                         default=sys.maxint,
                         help="maximum sequence length" )

funtangle.add_argument ( 'file',
                         type=argparse.FileType('r'),
                         nargs='*',
                         default=sys.stdin,
                         help='file(s) to read from')
funtangle.add_argument ( '--outfile', '-o',
                         type=argparse.FileType('w'),
                         nargs='?',
                         default=sys.stdout,
                         help="output file to write to")




# main function
if __name__ == "__main__":
    verbosity = 0
    obj = parser.parse_args()
    if obj.verbose:
        verbosity = obj.verbose
    obj.func(obj)
