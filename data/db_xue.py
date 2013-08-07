#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import re
import sys
import math

# formato de la linea de descripcion:
#   * comienza con un > (opcionalmente precedido de espacios
#   * (1) id: 3 letras + n { alfanum | _ | - }
#   * se ignoran otros caracteres hasta el fin de linea
#   >hsa-mir-123 Homo sapiens... etc
desc_fmt = r"^\s*>([a-zA-Z]{3}[\w_|+-]+)(\s.+)?\s*$"

# formato de la linea de descripcion con variables extra:
#   * comienza con un > (opcionalmente precedido de espacios
#   * (1) id: 3 letras + n { alfanum | _ | - }
#   * se ignoran otros caracteres hasta el fin de linea
#   >hsa-mir-123 Homo sapiens... etc
xtra_fmt = r"^>[a-zA-Z]{3}[\w\d_|+-]+(?:\s+[\w\d]+\s+\d+)*\s+SEQ_LENGTH\s+(\d+)\s+GC_CONTENT\s+([\d.]+)\s+BASEPAIR\s+(\d+)\s+FREE_ENERGY\s+(-[\d.]+)\s+LEN_BP_RATIO\s+([\d.]+)\s*$"

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

# error máximo tolerado al comparar floats
ERROR_THR = 1E-14



def load_file ( f, extra=False ):
    """
    Lee el archivo pasado como parámetro y lo guarda en una lista de entradas.
    @param f: el archivo a leer.
    @return: lista de tuplas leidas.
    @rtype: list
    """

    # en entries guardo cada entrada leida
    entries = list()

    # si f es una lista de archivos
    # hago recursion con cada elem
    if type(f) is list:
        for li in f:
            entries.extend(load_file(li,extra))
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

                    if extra and not re.match(xtra_fmt, cur_dsc):
                        print("extra features reuested but description does not match:")
                        print(cur_dsc)
                    if extra and re.match(xtra_fmt, cur_dsc):
                        ''' save entry with extra features
                        taken from the description line'''
                        xs = re.split(xtra_fmt, cur_dsc)
                        xv = [None, None, None, None, None]
                        # seq_length
                        xv[0] = int(xs[1])
                        # gc_content
                        xv[1] = float(xs[2])
                        # basepair
                        xv[2] = int(xs[3])
                        # free_energy
                        xv[3] = float(xs[4])
                        # len_bp_ratio
                        xv[4] = float(xs[5])

                        # guardo la entrada en el dict 
                        entries.append((id_, cur_dsc, cur_seq, cur_st2,
                                        fenergy, xv[0], xv[1], xv[2],
                                        xv[3], xv[4]))
                    else:
                        # guardo la entrada en el dict 
                        entries.append((id_, cur_dsc, cur_seq, cur_st2, fenergy))
                        
                # asigno el valor actual a la
                # linea de descripcion y reseteo las otras
                lll = line.replace( '''''', '')
                cur_dsc = lll[:]
                cur_seq = ""
                cur_st2 = ""
                fenergy = 0
            
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
                    #cur_dsc += " FREE_ENERGY {}".format(split[3])
                    fenergy = float(split[3])

            # si no entiendo la linea, escribo una advertencia
            else:
                sys.stderr.write("WARNING: {}: ignoring line {:d}\n".format(
                        f.name,lineno))

        # si lei algo del for anterior, me queda
        # la ultima entrada sin guardar:
        if cur_dsc:
            # obtengo el id
            id_ = re.split(desc_fmt, cur_dsc)[1]

            if extra and not re.match(xtra_fmt, cur_dsc):
                print("extra features reuested but description does not match:")
                print(cur_dsc)
            # if extra features requested
            if extra and re.match(xtra_fmt, cur_dsc):
                ''' save entry with extra features
                taken from the description line'''
                xs = re.split(xtra_fmt, cur_dsc)
                xv = [None, None, None, None, None]
                # seq_length
                xv[0] = int(xs[1])
                # gc_content
                xv[1] = float(xs[2])
                # basepair
                xv[2] = int(xs[3])
                # free_energy
                xv[3] = float(xs[4])
                # len_bp_ratio
                xv[4] = float(xs[5])

                # guardo la entrada en el dict 
                entries.append((id_, cur_dsc, cur_seq, cur_st2, fenergy,
                                xv[0], xv[1], xv[2], xv[3], xv[4]))
            else:
                # guardo la entrada en el dict 
                entries.append((id_, cur_dsc, cur_seq, cur_st2, fenergy))
        
            # asigno el valor actual a la
            # linea de descripcion y reseteo las otras
            lll = line.replace( '''''', '')
            cur_dsc = lll[:]
            cur_seq = ""
            cur_st2 = ""

    return entries




def xue_extra ( sequence, structure ):
    """
    Calcula las variables extra presentes en la base de datos de Xue
    @param sequence: string de secuencia (long. N)
    @param structure: string de estructura secundaria (long. N)
    @return: dict con las features extra
    @rtype: dict
    """

    # las longitudes deben coincidir
    if len(sequence) != len(structure):
        raise Exception( "sequence and structure differ in length!" )

    # busco limites de areas a considerar (ver paper)
    ll = structure.find('(')
    lr = structure.rfind('(')
    rl = structure.find(')')
    rr = structure.rfind(')')

    #ll = max(1,ll)
    #rr = min(len(structure)-2,rr)

    # si lr > rl probablemente haya mas de un loop
    if lr > rl:
        raise Exception("couldn't guess hairpin structure (more than one loop?)")

    gc_count = 0
    length = lr-ll + rr-rl + 2

    bp = structure.count('(')
    bp2 = structure.count(')')
    assert(bp == bp2)
    
    len_bp = length/float(bp)

    # recorro la secuencia: para cada triplet sumo 1 al bucket correspondiente
    for i in list(range(ll,lr+1)) + list(range(rl,rr+1)):
        if 'G' in sequence[i] or 'C' in sequence[i]:
            gc_count +=1

    gc = gc_count / float(length)
            
    return {"seq_length": length,
            "basepair": bp,
            "gc_content": gc,
            "len_bp_ratio": len_bp}




def strip_extra ( infile, outfile, d=0 ):
    """
    Lee el archivo de entrada y guarda sólo aquellas entradas
    que no contengan múltiples loops en el archivo de salida.
    Incluye las variables extra calculadas en el paper de xue
    @param infile: archivo(s) a leer
    @param outfile: archivo donde escribir la salida
    @param d: auxiliar para recursión, debe ser cero
    @rtype: None
    """

    # leo el archivo
    f = load_file(infile)

    # para cada entrada
    for l in f:
        # testeo multiples loops
        if re.match( mult_fmt, l[3]):
            pass
        # si solo hay un loop
        else:
            f = xue_extra(l[2],l[3])
            
            s = '\tSEQ_LENGTH\t{}\tGC_CONTENT\t{:.15g}\tBASEPAIR\t{}\tFREE_ENERGY\t{:.2f}\tLEN_BP_RATIO\t{:.15g}'.format(
                f['seq_length'],f['gc_content'],f['basepair'],l[4],f['len_bp_ratio'])
            
            # guardo la entrada en el archivo
            outfile.write('>' + l[0] + s + '\n' + 
                          l[2] + '\n' +
                          l[3] + '\n')







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
    for n in 'AGCU':
        for s in ['...', '..(', '.(.', '.((', '(..', '(.(', '((.', '(((']:
            occur[n + s] = 0

    # busco limites de areas a considerar (ver paper)
    ll = structure.find('(')
    lr = structure.rfind('(')
    rl = structure.find(')')
    rr = structure.rfind(')')

    #ll = max(1,ll)
    #rr = min(len(structure)-2,rr)

    if ll == 0:
        sequence = " " + sequence
        structure = "." + structure
        ll = ll+1
        lr = lr+1
        rl = rl+1
        rr = rr+1

    if rr == len(structure)-1:
        sequence = sequence + " "
        structure = structure + "."

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
    for n in 'AGCU':
        for s in ['...', '..(', '.(.', '.((', '(..', '(.(', '((.', '(((']:
            if normalize:
                vector.append(occur[n + s] / float(tot))
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
    f = load_file(infile)

    # para cada elemento leido
    for val in f:
        # si es multiloop, paso
        if re.match( mult_fmt, val[3]):
            pass
            
        else:
            # obtengo el vector de frecuencias de triplets
            v = triplet(val[2], val[3])
            # escribo la etiqueta al arch. de salida
            #outfile.write("{:d}".format(label))
            # para cada i de 1 a 32
            for i in range(len(v)):
                # escribo i:v[i]
                if v[i] > 0:
                    outfile.write( "{:d}:{:.15g} ".format(i+1,v[i]) )

            # escribo un retorno de linea
            outfile.write('\n')




def compare( set1files, set2files ):
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
    set1 = load_file(set1files, True)
    set2 = load_file(set2files, True)

    #set1 = set1
    #set2 = set2
    
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

        #tuple length
        if len(set1[j]) < 9 or len(set2[k]) < 9:
            print("tuple too short! length {}/{}".format(len(set1[j]),len(set2[k])))
            break

        #seq_length
        if set1[j][5] != set2[k][5]:
            print("{}: SEQ_LENGTH differ! ({},{})".format(set1[j][0],set1[j][5],set2[k][5]))

        #gc_content
        if abs(set1[j][6]-set2[k][6]) > ERROR_THR:
            print("{}: GC_CONTENT differ! ({:.15g},{:.15g})".format(set1[j][0],set1[j][6],set2[k][6]))

        #basepair
        if set1[j][7] != set2[k][7]:
            print("{}: BASEPAIR differ! ({},{})".format(set1[j][0],set1[j][7],set2[k][7]))

        #free_energy
        if abs(set1[j][8]-set2[k][8]) > ERROR_THR:
            print("{}: FREE_ENERGY differ! ({:.15g},{:.15g})".format(set1[j][0],set1[j][8],set2[k][8]))

        #len_bp_ratio
        if abs(set1[j][9]-set2[k][9]) > ERROR_THR:
            print("{}: LEN_BP_RATIO differ! ({:.15g},{:.15g})".format(set1[j][0],set1[j][9],set2[k][9]))
        
        j = j+1
        k = k+1

    print("compared {}/{} elements.".format(len(set1),len(set2)))




def validate( infile ):
    """
    Lee el archivos de entrada y compara las características extra
    presentes en el archivo con las que hubieran sido generadas
    por el método propio, informando en caso que hubiera discrepancias
    entre ambas. SE IGNORA LA FEAT FREE_ENERGY, al no estar disponibles
    los archivos generados por RNAfold.
    @param infiles: archivo a validar
    @rtype: None
    """

    set1 = list()

    # leo el contenido de los archivos
    set1 = load_file(infile, True)
    
    j = -1

    while j < len(set1)-1:
        j = j+1

        xf = xue_extra(set1[j][2],set1[j][3])

        if re.match( mult_fmt, set1[j][3]):
            print("{}: multi-loop but still present in database!!!".format(set1[j][0]))

        #tuple length
        if len(set1[j]) < 9:
            print("{}: could not read extra features!".format(set1[j][0]))
            continue

        #seq_length
        if set1[j][5] != xf["seq_length"]:
            print("{}: SEQ_LENGTH differ! ({},{})".format(set1[j][0],set1[j][5],xf["seq_length"]))

        #gc_content
        if abs(set1[j][6]-xf["gc_content"]) > ERROR_THR:
            print("{}: GC_CONTENT differ! ({:.15g},{:.15g})".format(set1[j][0],set1[j][6],xf["gc_content"]))

        #basepair
        if set1[j][7] != xf["basepair"]:
            print("{}: BASEPAIR differ! ({},{})".format(set1[j][0],set1[j][7],xf["basepair"]))

        #len_bp_ratio
        if abs(set1[j][9]-xf["len_bp_ratio"]) > ERROR_THR:
            print("{}: LEN_BP_RATIO differ! ({:.15g},{:.15g})".format(set1[j][0],set1[j][9],xf["len_bp_ratio"]))
        

    print("validated {} elements.".format(j+1))




def compare_triplets ( file1, file2 ):
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
            print("Vector at line {} differs! Skipping.".format(i))
            return
        
        for l,m in zip(j.split(),k.split()):
            n = re.split(libsvm_ent,l)
            o = re.split(libsvm_ent,m)

            if int(n[1]) != int(o[1]):
                print("line {}: differing position: {} vs {}".format(i,n[1],o[1]))
            if (float(n[2])-float(o[2])) > ERROR_THR:
                print("line {}: differing value for elem {}: {} vs {}".format(i,n[1],n[2],o[2]))
            
        i = i+1

    print("{} svm-format lines compared.".format(i))




# wrapper para las funciones
def wrap_strip (obj):
    strip_extra(obj.file, obj.outfile)

def wrap_svmout (obj):
    svmout(obj.file, obj.outfile, obj.label)

def wrap_compare(obj):
    compare(obj.set1, obj.set2)

def wrap_cmp3(obj):
    compare_triplets(obj.set1, obj.set2)

def wrap_val(obj):
    validate(obj.infile)


parser = argparse.ArgumentParser( description='Xue dataset utility.',
                                  prog='db_xue')

parser.add_argument( '--verbose', '-v',
                     action='count',
                     help='increase verbosity level')

subp   = parser.add_subparsers()
strp   = subp.add_parser('strip',
                         #aliases=['singloop'],
                         description="strip multiloop entries from input")
svmp   = subp.add_parser('svm',
                         #aliases=['svmout'],
                         description="convert to libsvm format")

cmpp   = subp.add_parser('compare',
                         #aliases=['cmp', 'comparar'],
                         description="compare two sets of files")

cmp3   = subp.add_parser('cmp3',
                         #aliases=['cmp', 'comparar'],
                         description="compare two sets of TRIPLETS in SVM format")
valp   = subp.add_parser('validate',
                         #aliases=['svmout'],
                         description="validate source file")

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
cmpp.add_argument('--set1', '-1',
                    type=argparse.FileType('r'),
                    nargs='+',
                    required=True,
                    help='file(s) to be considered as set 1')
cmpp.add_argument('--set2', '-2',
                    type=argparse.FileType('r'),
                    nargs='+',
                    required=True,
                    help='file(s) to be counted in the second set')
cmp3.add_argument('--set1', '-1',
                    type=argparse.FileType('r'),
                    nargs='+',
                    required=True,
                    help='file(s) to be considered as set 1')
cmp3.add_argument('--set2', '-2',
                    type=argparse.FileType('r'),
                    nargs='+',
                    required=True,
                    help='file(s) to be counted in the second set')
valp.add_argument  ('infile',
                    type=argparse.FileType('r'),
                    nargs='*',
                    default=sys.stdin,
                    help='file(s) to read from')

strp.set_defaults(func=wrap_strip)
svmp.set_defaults(func=wrap_svmout)
cmpp.set_defaults(func=wrap_compare)
cmp3.set_defaults(func=wrap_cmp3)
valp.set_defaults(func=wrap_val)


if __name__ == "__main__":

    verbosity = 0
    
    obj = parser.parse_args()
    
    if obj.verbose:
        verbosity = obj.verbose

    obj.func(obj)

