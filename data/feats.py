#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import re
import sys
import math
import os

# formato de la linea de descripcion:
#   * comienza con un > (opcionalmente precedido de espacios
#   * (1) id: 3 letras + n { alfanum | _ | - }
#   * se ignoran otros caracteres hasta el fin de linea
#   >hsa-mir-123 Homo sapiens... etc
desc_fmt = r"^\s*>[(]?([a-zA-Z0-9]{2,3}[\w<.:/_+-]+)([|,\s].+)?\s*$"

# extra features en la descripcion, Xue
seq_length_fmt   = r'^>.*\sSEQ_LENGTH\s+(\d+)\s.*$'
gc_content_fmt   = r'^>.*\sGC_CONTENT\s+([\d.]+)\s.*$'
basepair_fmt     = r'^>.*\sBASEPAIR\s+(\d+)\s.*$'
free_energy_fmt  = r'^>.*\sFREE_ENERGY\s+([-\d.]+)\s.*$'
len_bp_ratio_fmt = r'^>.*\sLEN_BP_RATIO\s+([\d.]+).*$'

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

# following set obtained from miRbase v20 organisms.txt.gz
# doing the following on a Python shell:
# >>> import gzip
# >>> f = gzip.open( "src/mirbase/20/organisms.txt.gz", 'r')
# >>> valid_ids = {e.split()[0] for e in f.read().splitlines()}
# >>> valid_ids
valid_ids = set(['sci', 'pti', 'ptc', 'pta', 'aly', 'osa', 'lla',
                 'mne', 'nlo', 'tca', 'cln', 'xtr', 'han', 'hru',
                 'gma', 'zma', 'cla', 'bfl', 'nvi', 'bna', 'rgl',
                 'rno', 'kshv', 'dan', 'cel', 'ame', 'ssp', 'amg',
                 'ssl', 'nve', 'ttu', 'lca', 'lco', 'pgi', 'dya',
                 'ssc', 'dme', 'dpu', 'hci', 'dps', 'dpr', 'crt',
                 'lja', 'cme', 'tre', 'xla', 'hsv1', 'mcmv', 'dpe',
                 'hsv2', 'esi', 'cre', 'pbi', 'crm', 'tgu', 'ola',
                 'pvu', 'mdo', 'mdm', 'ipu', 'cfa', 'odi', 'ebv',
                 'hiv1', 'bta', 'pma', 'rrv', 'rmi', 'emu', 'lus',
                 'asu', 'sha', 'peu', 'mghv', 'blv', 'bdi', 'smr',
                 'ptr', 'smo', 'ddi', 'dsi', 'aja', 'sme', 'dse',
                 'hco', 'sma', 'hsa', 'eca', 'mmu', 'tur', 'meu',
                 'mml', 'gga', 'hma', 'nta', 'ggo', 'cgr', 'aca',
                 'ctr', 'lmi', 'vun', 'ath', 'cte', 'bol', 'isc',
                 'bgy', 'pde', 'sja', 'dre', 'hbr', 'ppc', 'ppa',
                 'har', 'mes', 'ppe', 'sof', 'hhv6b', 'ngi', 'pol',
                 'api', 'ppt', 'ppy', 'ahy', 'hvu', 'hvt', 'bra',
                 'sbi', 'bpcv2', 'bbe', 'hex', 'rco', 'gpy', 'fru',
                 'mse', 'cqu', 'aqu', 'lgi', 'hcmv', 'bmo', 'aqc',
                 'mcv', 'tcc', 'sko', 'sv40', 'aae', 'iltv', 'sly',
                 'mtr', 'htu', 'der', 'ata', 'cin', 'dev', 'dmo',
                 'aau', 'stu', 'prv', 'egr', 'egu', 'tni', 'sla',
                 'prd', 'cbn', 'spu', 'cbr', 'tae', 'bma', 'hvsa',
                 'hme', 'ssy', 'hhi', 'jcv', 'csi', 'mdv1', 'oan',
                 'mdv2', 'csa', 'far', 'pab', 'oar', 'gra', 'hpa',
                 'dwi', 'hpe', 'bpcv1', 'gar', 'dgr', 'bkv', 'rlcv',
                 'vvi', 'bhv1', 'hbv', 'dvi', 'mja', 'ghr', 'ama',
                 'cpa', 'age', 'aga', 'ccr', 'ccl', 'xbo', 'bcy',
                 'ghb', 'cca', 'gso'])




def load_fasta ( f ):
    """
    Lee el archivo pasado como parámetro y lo guarda en una lista de entradas.
    @param f: el archivo a leer.
    @return: lista de tuplas leidas:
    (id, desc, seq, str, mfe, len3, gc3, bp3, len_bp3).
    @rtype: list
    """

    # en entries guardo cada entrada leida
    entries = list()

    # si f es una lista de archivos
    # hago recursion con cada elem y los agrego al final
    if type(f) is list:
        for li in f:
            entries.extend(load_fasta(li))

    else:        
        # variables auxiliares
        lineno = 0
        cur_dsc = None
        cur_seq = ""
        cur_st2 = ""
        id_ = ""
        seq_length = None
        gc_content = None
        basepair = None
        free_energy = None
        len_bp_ratio = None

        # leo cada linea del archivo
        for line in f:
            lineno += 1
            # si leo una linea de descripcion
            if re.match(desc_fmt, line):
                # si no es la primera iteracion
                if cur_dsc:
                    # obtengo el id
                    id_ = re.split(desc_fmt, cur_dsc)[1]
                    
                    # extraigo feat SEQ_LENGTH de Xue
                    if re.match(seq_length_fmt,cur_dsc):
                        seq_length = int(re.split(seq_length_fmt,
                                                   cur_dsc)[1])

                    # extraigo feat GC_CONTENT de Xue
                    if re.match(gc_content_fmt,cur_dsc):
                        gc_content = float(re.split(gc_content_fmt,
                                                     cur_dsc)[1])

                    # extraigo feat BASEPAIR de Xue
                    if re.match(basepair_fmt,cur_dsc):
                        basepair = int(re.split(basepair_fmt,
                                                 cur_dsc)[1])

                    # extraigo feat FREE_ENERGY de Xue
                    if re.match(free_energy_fmt,cur_dsc):
                        free_energy = float(re.split(free_energy_fmt,
                                                      cur_dsc)[1])

                    # extraigo feat LEN_BP_RATIO de Xue
                    if re.match(len_bp_ratio_fmt,cur_dsc):
                        len_bp_ratio = float(re.split(len_bp_ratio_fmt,
                                                       cur_dsc)[1])

                    # guardo la entrada en el dict
                    if re.match(seqn_fmt,cur_seq):
                        entries.append((id_, cur_dsc, cur_seq.upper(), cur_st2,
                                        free_energy, seq_length, gc_content,
                                        basepair, len_bp_ratio))
                    else:
                        sys.stderr.write("ign {}, non-GCUA sequence\n".format(
                            id_))


    
                # asigno el valor actual a la
                # linea de descripcion y reseteo las otras
                cur_dsc = line.replace( '''''', '')
                cur_seq = ""
                cur_st2 = ""
                seq_length = None
                gc_content = None
                basepair = None
                free_energy = None
                len_bp_ratio = None
                
            # si leo una linea de secuencia
            elif re.match(r"^\s*([a-zA-Z]+)\s*$", line):
                # agrego el pedazo de secuencia
                # al final de la variable cur_seq
                cur_seq += re.split(r"^\s*([a-zA-Z]+)\s*$",line)[1]
            
            # si leo una linea de estructura secundaria
            elif re.match(snds_fmt, line):
                # separo la linea segun la regexp
                split = re.split(snds_fmt, line)
                # guardo al parte de estruct secund al
                # final de la var cur_st2
                cur_st2 += split[1]
                
                # si al final la linea contene la free energy
                if split[3]:
                    # extraigo la MFE de RNAfold
                    free_energy = float(split[3])

            # si no entiendo la linea, escribo una advertencia
            else:
                sys.stderr.write("{}: {} ignoring line {:d}\n{}".format(
                        f.name,id_,lineno,line))

        # si lei algo del for anterior, me queda
        # la ultima entrada sin guardar:
        if cur_dsc:
            # obtengo el id
            id_ = re.split(desc_fmt, cur_dsc)[1]

            if re.match(seq_length_fmt,cur_dsc):
                seq_length = int(re.split(seq_length_fmt,
                                          cur_dsc)[1])

            if re.match(gc_content_fmt,cur_dsc):
                gc_content = float(re.split(gc_content_fmt,
                                            cur_dsc)[1])

            if re.match(basepair_fmt,cur_dsc):
                basepair = int(re.split(basepair_fmt,
                                        cur_dsc)[1])

            if re.match(free_energy_fmt,cur_dsc):
                free_energy = float(re.split(free_energy_fmt,
                                             cur_dsc)[1])

            if re.match(len_bp_ratio_fmt,cur_dsc):
                len_bp_ratio = float(re.split(len_bp_ratio_fmt,
                                              cur_dsc)[1])

            # guardo la entrada en el dict 
            if re.match(seqn_fmt,cur_seq):
                entries.append((id_, cur_dsc, cur_seq.upper(), cur_st2,
                                free_energy, seq_length, gc_content,
                                basepair, len_bp_ratio))
            else:
                sys.stderr.write("ign {}, non-GCUA sequence\n".format(id_))


    return entries




def load_str ( f ):
    """
    Lee el archivo f EN FORMATO "STR" de miRBase.
    @param f: el archivo a leer.
    @return: lista de tuplas leidas:
    (id, desc, seq, str, mfe, len3, gc3, bp3, len_bp3).
    @rtype: list
    """

    # en entries guardo cada entrada leida
    entries = list()

    # si f es una lista de archivos
    # hago recursion con cada elem y los agrego al final
    if type(f) is list:
        for li in f:
            entries.extend(load_str(li))

    else:
        id_fmt = r"^>([a-zA-Z0-9_-]+)\s*.*$"
        mfe_fmt = r"^>[a-zA-Z0-9_-]+\s+\(([-0-9.]+)\)\s+.*$"

        lines = f.read().splitlines()

        for l in range(0,len(lines),8):

            identifier = None
            mfe        = None
            sequence   = ""
            structure  = ""

            if re.match(id_fmt,lines[l]):
                identifier = re.split(id_fmt,lines[l])[1]
            else:
                raise Exception("Unknown identifier! {}".format(lines[l]))

            if re.match(mfe_fmt,lines[l]):
                mfe = re.split(mfe_fmt,lines[l])[1]
        
            hpin_len = len(lines[l+4])-1

            seq_top = ""
            seq_btm = ""
            str_top = ""
            str_btm = ""

            for i in range(hpin_len):
                if lines[l+4][i] == "|":
                    seq_top += lines[l+3][i]
                    seq_btm += lines[l+5][i]
                    str_top += "("
                    str_btm += ")"
                else:
                    if lines[l+2][i] in "gcuaGCUA":
                        seq_top += lines[l+2][i]
                        str_top += "."
                    if lines[l+6][i] in "gcuaGCUA":
                        seq_btm += lines[l+6][i]
                        str_btm += "."
        
            for i in range(3,6):
                if lines[l+i][hpin_len] in "gcuaGCUA":
                    seq_top += lines[l+i][hpin_len]
                    str_top += "."

            sequence = seq_top.upper() + seq_btm[::-1].upper()
            structure = str_top + str_btm[::-1]

            entries.append((identifier,sequence,structure,mfe))

    return entries




def triplet_feats_extra ( sequence, structure ):
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
        raise Exception("couldn't guess hairpin structure "
                        "(has more than one loop?)")

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




def write_fasta ( strfilein, fastafileout ):
    """
    Lee al archivo en formato str de mipred y lo escribe en formato
    fasta idem a la salida de RNAfold.
    Incluye la mfe en la linea de descripción
    @param infile: archivo(s) a leer
    @param outfile: archivo donde escribir la salida
    @rtype: None
    """

    # leo el archivo
    f = load_str(strfilein)

    # para cada entrada
    for e in f:
        desc = ">{}".format(e[0])
        if e[3]:
            desc += "\tFREE_ENERGY\t{}".format(e[3])

        fastafileout.write( desc + '\n' + e[1] + '\n' + e[2] + '\n')




def triplet_filter_single_loop ( infile, outfile, d=0 ):
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
    f = load_fasta(infile)

    # para cada entrada
    for l in f:
        # testeo multiples loops
        if re.match( mult_fmt, l[3]):
            pass
        # si solo hay un loop
        else:
            try:
                x = triplet_feats_extra(l[2],l[3])

                if l[4]:
                    s = ('\tSEQ_LENGTH\t{}\tGC_CONTENT\t{:.15g}\t'+
                         'BASEPAIR\t{}\tFREE_ENERGY\t{:.2f}'+
                         '\tLEN_BP_RATIO\t{:.15g}').format(
                             x['seq_length'],x['gc_content'],
                             x['basepair'],l[4],x['len_bp_ratio'])
                else:
                    s = ('\tSEQ_LENGTH\t{}\tGC_CONTENT\t{:.15g}\tBASEPAIR\t{}'+
                         '\tLEN_BP_RATIO\t{:.15g}').format(
                             x['seq_length'],x['gc_content'],
                             x['basepair'],x['len_bp_ratio'])

                # guardo la entrada en el archivo solo si hay mas de 22 bp
                #if f['basepair'] > 22:
                outfile.write('>' + l[0] + s + '\n' + 
                              l[2] + '\n' +
                              l[3] + '\n')

            except Exception as e:
                sys.stderr.write("error found for entry {}:\n{}\n{}".format(
                    l[0],l[2],l[3]))




def triplet_filter_multi_loop ( infile, outfile ):
    """
    Lee el archivo de entrada y guarda sólo aquellas entradas
    que SI contengan múltiples loops en el archivo de salida.
    Incluye las variables extra calculadas en el paper de xue
    @param infile: archivo(s) a leer
    @param outfile: archivo donde escribir la salida
    @param d: auxiliar para recursión, debe ser cero
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)

    # para cada entrada
    for l in f:
        # testeo multiples loops
        if not re.match( mult_fmt, l[3]):
            pass
        # si solo hay un loop
        else:
            f = triplet_feats_extra(l[2],l[3])
            
            s = ('\tSEQ_LENGTH\t{}\tGC_CONTENT\t{:.15g}\tBASEPAIR\t{}\t'+
                 'FREE_ENERGY\t{:.2f}\tLEN_BP_RATIO\t{:.15g}').format(
                     f['seq_length'],f['gc_content'],
                     f['basepair'],l[4],f['len_bp_ratio'])
            
            # guardo la entrada en el archivo solo si hay mas de 22 bp
            #if f['basepair'] > 22:
            outfile.write('>' + l[0] + s + '\n' + 
                          l[2] + '\n' +
                          l[3] + '\n')




def triplet_feats ( sequence, structure, normalize = True ):
    """
    Calcula el 32-vector de frecuencia de triplets según el
    procedimiento explicado en Xue et al.
    @param sequence: string de secuencia (long. N)
    @param structure: string de estructura secundaria (long. N)
    @return: 32-vector, cada elem tiene el nro de ocurrencias para el triplet
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


    # si hay bp en los extremos agrego "."
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
        raise Exception("couldn't guess hairpin structure"+
                        " (has more than one loop?)")

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




def triplet_svmout ( infile, outfile ):
    """
    Genera el archivo de entrada para libsvm, etiquetando
    a todos los elementos con la etiqueta 'label' (int)
    @param infile: archivo(s) de entrada (formato FASTA)
    @param outfile: archivo de salida (formato libsvm)
    @param label: etiqueta para los elementos de salida (int)
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)

    # para cada elemento leido
    for val in f:
        # si es multiloop, paso
        if re.match( mult_fmt, val[3]):
            pass
            
        else:
            # obtengo el vector de frecuencias de triplets
            v = triplet_feats(val[2], val[3])
            # escribo la etiqueta al arch. de salida
            #outfile.write("{:d}".format(label))
            # para cada i de 1 a 32
            for i in range(len(v)):
                # escribo i:v[i]
                if v[i] > 0:
                    outfile.write( "{:d}:{:.15g} ".format(i+1,v[i]) )

            # escribo un retorno de linea
            outfile.write('\n')




def triplet_out ( infile, outfile ):
    """
    Guarda los 32-triplets en el archivo de salida.
    @param infile: archivo(s) de entrada (formato FASTA)
    @param outfile: archivo de salida (formato f f f f f... x32)
    @param label: etiqueta para los elementos de salida (int)
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)

    for val in f:
        if re.match( mult_fmt, val[3]):
            continue

        v = triplet_feats(val[2], val[3])
        outfile.write("\t".join("{:.15g}".format(i) for i in v)+"\n")




def mipred_feats ( sequence, structure ):
    """
    Calcula las sig. 23 caracteristicas segun miPred: A, C, G, U, G+C, A+U,
    AA, AC, AG, AU, CA, CC, CG, CU, GA, GC, GG, GU, UA, UC, UG, UU, pb
    @param sequence: string de secuencia (long. N)
    @param structure: string de estructura secundaria (long. N)
    @return: 23-vector con las features
    @rtype: list
    """

    # las longitudes deben coincidir
    if len(sequence) != len(structure):
        raise Exception( "sequence and structure differ in length!" )

    out = []

    # 4 nucleotidos
    for n in 'ACGU':
        out.append(sequence.count(n))

    out.append(out[2]+out[1]) # G+C
    out.append(out[0]+out[3]) # A+U

    # 16 dinucleotidos
    count = {}
    for n in 'ACGU':
        for m in 'ACGU':
            count[n+m] = 0

    # scan dinucleotidos
    for i in range(len(sequence)-1):
        count[sequence[i:i+2]] += 1

    # agrego al vector
    for n in 'ACGU':
        for m in 'ACGU':
            out.append(count[n+m])
    
    # base pairings
    bp = structure.count('(')
    bp2 = structure.count(')')
    assert(bp == bp2)
    out.append(bp) # pb
    
    return out




def mipred_out ( infile, outfile ):
    """
    Genera el archivo de entrada para libsvm, etiquetando
    a todos los elementos con la etiqueta 'label' (int)
    @param infile: archivo(s) de entrada (formato FASTA)
    @param outfile: archivo de salida (formato libsvm)
    @param label: etiqueta para los elementos de salida (int)
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)

    outfile.write("Len\tA\tC\tG\tU\tG+C\tA+U\tAA\tAC\tAG\tAU\t" +
                  "CA\tCC\tCG\tCU\tGA\tGC\tGG\tGU\tUA\tUC\tUG\tUU\tpb\tmfe\n")

    # para cada elemento leido
    for val in f:
        # obtengo el vector de frecuencias de triplets
        v = mipred_feats(val[2], val[3])
        # escribo la etiqueta al arch. de salida
        outfile.write("{:d}\t".format(len(val[2])))

        # escribo las features salvo mfe
        outfile.write("\t".join("{:d}".format(i) for i in v))
        
        # escribo mfe y salto de linea
        outfile.write("\t{:.2f}\n".format(val[4]))




def upred_feats ( sequence, structure, mfe, extra = False ):
    """
    Calcula las features relativas a los base pairs según microPred
    @param sequence: string de secuencia (long. N)
    @param structure: string de estructura secundaria (long. N)
    @param mfe: minimum free energy, tomada de RNAfold
    @return: 4-vector con las features [bp, #A-U, #G-C, #G-U]
    @rtype: list
    """

    # las longitudes deben coincidir
    if len(sequence) != len(structure):
        raise Exception( "sequence and structure differ in length!" )

    # base pairings
    bp = structure.count('(')
    bp2 = structure.count(')')
    assert(bp == bp2)

    s = []
    d = {"AU":0, "UA":0, "GC":0, "CG":0, "GU":0, "UG":0, "tot":0}
    for j,k in zip(structure,sequence):
        if j == ".":
            continue
        elif j == "(":
            s.append(k)
        elif j == ")":
            d[s.pop()+k] += 1
            d["tot"] += 1
        else:
            raise Exception("invalid char in structure!!")

    au = d["AU"] + d["UA"]
    gc = d["GC"] + d["CG"]
    gu = d["GU"] + d["UG"]

    assert(d["tot"] == bp)

    l = float(len(sequence))

    pgc = 100*(sequence.count('G')+sequence.count('C'))/l
    mfei1 = mfe/(l*pgc)
    mfei4 = mfe/float(bp)

    if extra:
        return [mfei1,mfei4,bp/l,au/l,gc/l,gu/l,bp,mfe,pgc,int(l)]

    return [mfei1,mfei4,bp/l,au/l,gc/l,gu/l]




def upred_out ( infile, outfile, extra = False ):
    """
    Genera el archivo de entrada para libsvm, etiquetando
    a todos los elementos con la etiqueta 'label' (int)
    @param infile: archivo(s) de entrada (formato FASTA)
    @param outfile: archivo de salida (formato libsvm)
    @param label: etiqueta para los elementos de salida (int)
    @rtype: None
    """

    # leo el archivo
    f = load_fasta(infile)


    outfile.write("MFEI1\tMFEI4\tdP\t|A-U|/L\t|G-C|/L\t|G-U|/L")
    if extra:
        outfile.write("\tbp\tmfe\t%(G+C)\tLen")
    outfile.write("\n")

    # para cada elemento leido
    for val in f:
        # calculo las feats de microPred
        v = upred_feats(val[2], val[3], val[4], extra)

        # escribo las features
        outfile.write("\t".join("{:.15g}".format(i) for i in v) + "\n")




def features_by_species ( infile, outdir, cls = 1, force_sp_name = None,
                          write_headers = False):

    f = load_fasta ( infile )
    species = []
    desc = []
    sequence = []
    structure = []
    triplet = []
    triplet_extra = []
    sequence_feats = []
    folding_feats = []

    for e in f:
        # step 0. validate reqs: structure, mfe and not multi-loop
        if len(e[3]) < 1 or re.match( mult_fmt, e[3]) or not e[4]:
            continue

        # step 1. get species name (will determine output filename)
        if force_sp_name:
            species.append(force_sp_name)
        else:
            idd = re.split( r"^>([\w\d]+)-.*$", e[1] )[1]
            if idd not in valid_ids:
                sys.stderr.write("WARNING: invalid id: {}\n".format(idd))
            species.append(idd)
    
        # step 2. copy sequence, structure, description
        desc.append(e[1])
        sequence.append(e[2])
        structure.append(e[3])

        # step 3. calculate features
        triplet.append( triplet_feats(e[2],e[3]) )
        triplet_extra.append( triplet_feats_extra(e[2],e[3]) )
        s = [len(e[2])] # sequence length
        f = [e[4]] # mfe
        s.extend(mipred_feats(e[2],e[3])[:-1]) # mipred feats
        f.extend(upred_feats(e[2],e[3],e[4])) # upred feats
        sequence_feats.append(s)
        folding_feats.append(f)
    
    # step 4. write files
    num = len(sequence)
    for sp in set(species):
        with open( os.path.join(outdir,sp+".fa"), 'w') as o:
            for i in range(num):
                if species[i] == sp:
                    o.write( "{}\n{}\n{}\n".format(
                        desc[i],sequence[i],structure[i]))
                
        with open( os.path.join(outdir,sp+".3"), 'w') as o:
            if write_headers:
                o.write("\t".join("{}".format(n+s) for n in 'AGCU' for
                                  s in ['...', '..(', '.(.', '.((', '(..',
                                        '(.(', '((.', '((('])+"\n")
            for i in range(num):
                if species[i] == sp:
                    o.write( "\t".join("{:.15g}".format(
                        j) for j in triplet[i])+"\n" )

        with open( os.path.join(outdir,sp+".3x"), 'w') as o:
            if write_headers:
                o.write("len3\tbasepair\tlen3/bp\tgc/len3\n")
            for i in range(num):
                if species[i] == sp:
                    o.write( "{}\t{}\t{:.15g}\t{:.15g}\n".format(
                        triplet_extra[i]["seq_length"],
                        triplet_extra[i]["basepair"],
                        triplet_extra[i]["len_bp_ratio"],
                        triplet_extra[i]["gc_content"]))

        with open( os.path.join(outdir,sp+".s"), 'w') as o:
            if write_headers:
                o.write("Len\tA\tC\tG\tU\tG+C\tA+U\tAA\tAC\tAG\tAU\t" +
                  "CA\tCC\tCG\tCU\tGA\tGC\tGG\tGU\tUA\tUC\tUG\tUU\n")
            for i in range(num):
                if species[i] == sp:
                    o.write( "\t".join("{:.15g}".format(
                        j) for j in sequence_feats[i])+"\n" )

        with open( os.path.join(outdir,sp+".f"), 'w') as o:
            if write_headers:
                o.write("mfe\tMFEI1\tMFEI4\tdP\t|A-U|/L\t|G-C|/L\t|G-U|/L\n")
            for i in range(num):
                if species[i] == sp:
                    o.write( "\t".join("{:.15g}".format(
                        j) for j in folding_feats[i])+"\n" )

        with open( os.path.join(outdir,sp+".c"), 'w') as o:
            if write_headers:
                o.write("Class\n")
            for i in range(num):
                if species[i] == sp:
                    o.write( "{}\n".format(cls) )

    print( "Wrote {} entries.".format(num))




# wrapper para las funciones
def wrap_single (obj):
    triplet_filter_single_loop(obj.file, obj.outfile)

def wrap_strtofasta (obj):
    write_fasta(obj.file, obj.outfile)

def wrap_multi (obj):
    triplet_filter_multi_loop(obj.file, obj.outfile)

def wrap_triplet_svm (obj):
    if obj.raw:
        triplet_out(obj.file, obj.outfile)
    else:
        triplet_svmout(obj.file, obj.outfile)

def wrap_mipred (obj):
    mipred_out(obj.file, obj.outfile)

def wrap_micropred (obj):
    upred_out(obj.file, obj.outfile, obj.extra)

def wrap_fbysp (obj):
    features_by_species(obj.file, obj.outdir, obj.cls, obj.species, obj.headers)



parser = argparse.ArgumentParser( description='Feature extraction utility.',
                                  prog='feats.py')

parser.add_argument( '--verbose', '-v',
                     action='count',
                     help='increase verbosity level')

subp = parser.add_subparsers()

singleloop = subp.add_parser('singleloop',
                             description="remove multiloop entries, FASTA fmt")

strtofasta = subp.add_parser('strtofasta',
                             description="convert miRBase .str to .fasta")

multiloop  = subp.add_parser('multiloop',
                             description="remove singlloop entries, FASTA fmt")

tripletsvm = subp.add_parser('triplet',
                             description="extract triplets, libsvm/raw format")

mipred     = subp.add_parser('mipred',
                             description="extract miPred feats, tab-separated")

micropred  = subp.add_parser('micropred',
                             description="extract microPred feats, tab-sep")

byspecies  = subp.add_parser('by_species',
                             description="all features, output by species")


singleloop.set_defaults(func=wrap_single)
strtofasta.set_defaults(func=wrap_strtofasta)
multiloop.set_defaults(func=wrap_multi)
tripletsvm.set_defaults(func=wrap_triplet_svm)
mipred.set_defaults    (func=wrap_mipred)
micropred.set_defaults (func=wrap_micropred)
byspecies.set_defaults (func=wrap_fbysp)


singleloop.add_argument('file',
                        type=argparse.FileType('r'),
                        nargs='*',
                        default=sys.stdin,
                        help='file(s) to read from')
singleloop.add_argument('--outfile', '-o',
                        type=argparse.FileType('w'),
                        nargs='?',
                        default=sys.stdout,
                        help="output file to write to")

strtofasta.add_argument('file',
                        type=argparse.FileType('r'),
                        nargs='*',
                        default=sys.stdin,
                        help='file(s) to read from')
strtofasta.add_argument('--outfile', '-o',
                        type=argparse.FileType('w'),
                        nargs='?',
                        default=sys.stdout,
                        help="output file to write to")

multiloop.add_argument ('file',
                        type=argparse.FileType('r'),
                        nargs='*',
                        default=sys.stdin,
                        help='file(s) to read from')
multiloop.add_argument ('--outfile', '-o',
                        type=argparse.FileType('w'),
                        nargs='?',
                        default=sys.stdout,
                        help="output file to write to")

tripletsvm.add_argument('file',
                        type=argparse.FileType('r'),
                        nargs='*',
                        default=sys.stdin,
                        help='file(s) to read from')
tripletsvm.add_argument('--outfile', '-o',
                        type=argparse.FileType('w'),
                        nargs='?',
                        default=sys.stdout,
                        help="output file to write to")
tripletsvm.add_argument('--raw', '-r',
                        action='count',
                        help='raw outpt instead of libsvm-formatted')

mipred.add_argument    ('file',
                        type=argparse.FileType('r'),
                        nargs='*',
                        default=sys.stdin,
                        help='file(s) to read from')
mipred.add_argument    ('--outfile', '-o',
                        type=argparse.FileType('w'),
                        nargs='?',
                        default=sys.stdout,
                        help="output file to write to")

micropred.add_argument ('file',
                        type=argparse.FileType('r'),
                        nargs='*',
                        default=sys.stdin,
                        help='file(s) to read from')
micropred.add_argument ('--outfile', '-o',
                        type=argparse.FileType('w'),
                        nargs='?',
                        default=sys.stdout,
                        help="output file to write to")
micropred.add_argument ('--extra', '-e',
                        action='count',
                        help='include extra features')

byspecies.add_argument ('file',
                        type=argparse.FileType('r'),
                        nargs='*',
                        default=sys.stdin,
                        help='file(s) to read from')
byspecies.add_argument ('--outdir', '-o',
                        type=str,
                        nargs='?',
                        default="./",
                        help="output dir where to write files")
byspecies.add_argument ('--cls', '-c',
                        type=int,
                        nargs='?',
                        default=1,
                        help="set class (1 or -1)")
byspecies.add_argument ('--species', '-s',
                        type=str,
                        nargs='?',
                        default=None,
                        help="force species name")
byspecies.add_argument ('--headers', '-j',
                        action='count',
                        help='write headers to generated files')


# main function
if __name__ == "__main__":
    verbosity = 0
    obj = parser.parse_args()
    if obj.verbose:
        verbosity = obj.verbose
    obj.func(obj)
