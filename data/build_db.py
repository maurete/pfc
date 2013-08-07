#!/usr/bin/env python
import re
import db_xue
import os
import sqlite3
import sys


def main():
    cx = sqlite3.connect("db.sqlite");
    cu = cx.cursor();

    act = sys.argv[1]

    if act == "xue0":
        cls = int(sys.argv[2])
        fin = sys.argv[3]
        xue0(cu,cls,fin)

    elif act == "xue1":
        cls = int(sys.argv[2])
        label = sys.argv[3]
        fin = sys.argv[4]
        xue1(cu,cls,label,fin)

    cx.commit()
    cx.close()




def insert ( cur, tblname, col_spec, values ):
    d = tuple(values)

    spec = col_spec
    if type(col_spec) is tuple:
        spec = str(col_spec)
    elif type(col_spec) is list:
        spec = str(tuple(col_spec))

    l = len(values)
    try:
        cur.execute('INSERT OR REPLACE INTO {} {} VALUES (?{})'.format(
            tblname,col_spec,',?'*(l-1)), d)

    except Exception as e:
        print("Exception caught while doing insert: {}".format(str(e)))




# columns should be a tuple!! (or otherwise iterable)
def update ( cur, tblname, columns, values, condition ):
    v = tuple(values)
    d = tuple(columns)

    try:
        cur.execute('UPDATE {} SET {} WHERE {}'.format(
            tblname,
            ', '.join('"{}"="{}"'.format(k,v) for k,v in zip(columns,values)),
            condition))

    except Exception as e:
        print("Exception caught while doing update: {}".format(str(e)))



def xue0(cu, cls, infile):
    '''Xue step 0: creo la tabla y cargo datos de archivos fasta'''

    cu.execute('''
    CREATE TABLE IF NOT EXISTS triplet (
    id TEXT PRIMARY KEY, /* identificador de la secuencia */
    class boolean,       /* clase: true => premir, false => pseudo */
    species text,        /* especie: e.g hsa, rno, pseudo */
    number int,          /* num de linea en el archivo de la especie */
    seq text,            /* secuencia */
    struct text,         /* estructura secundaria */
    seq_length int,      /* longitud segun xue */
    gc_content float,    /* cantidad de g + cantidad de c */
    basepair int,        /* numero de base pairs */
    free_energy float,   /* minima energia libre */
    len_bp_ratio float,  /* longitud / base pairings */
    triplet1 float,      /* elemento triplet 1 */
    triplet2 float,      /* elemento triplet 1 */
    triplet3 float,      /* elemento triplet 1 */
    triplet4 float,      /* elemento triplet 1 */
    triplet5 float,      /* elemento triplet 1 */
    triplet6 float,      /* elemento triplet 1 */
    triplet7 float,      /* elemento triplet */
    triplet8 float,      /* elemento triplet */
    triplet9 float,      /* elemento triplet */
    triplet10 float,     /* elemento triplet */
    triplet11 float,     /* elemento triplet 1 */
    triplet12 float,     /* elemento triplet 1 */
    triplet13 float,     /* elemento triplet 1 */
    triplet14 float,     /* elemento triplet 1 */
    triplet15 float,     /* elemento triplet 1 */
    triplet16 float,     /* elemento triplet 1 */
    triplet17 float,     /* elemento triplet */
    triplet18 float,     /* elemento triplet */
    triplet19 float,     /* elemento triplet */
    triplet20 float,     /* elemento triplet */
    triplet21 float,     /* elemento triplet 1 */
    triplet22 float,     /* elemento triplet 1 */
    triplet23 float,     /* elemento triplet 1 */
    triplet24 float,     /* elemento triplet 1 */
    triplet25 float,     /* elemento triplet 1 */
    triplet26 float,     /* elemento triplet 1 */
    triplet27 float,     /* elemento triplet */
    triplet28 float,     /* elemento triplet */
    triplet29 float,     /* elemento triplet */
    triplet30 float,     /* elemento triplet */
    triplet31 float,     /* elemento triplet */
    triplet32 float      /* elemento triplet */
    );''' )

    entries = []
    with open(infile,'r') as f:
        entries = db_xue.load_file(f,True)

    species = re.split(r"^(\w+).*$", infile)[1]
    lineno = 0

    for e in entries:
        lineno = lineno + 1
        values = (e[0],cls,species,lineno,e[2],e[3],e[5],e[6],e[7],e[8],e[9])
        insert(cu, "triplet", '''(id, class, species, number, seq, struct, seq_length,
        gc_content, basepair, free_energy, len_bp_ratio)''', values)

        columns = tuple('triplet{}'.format(i) for i in range(1,33))
        values = db_xue.triplet(e[2],e[3])
        update(cu, "triplet", columns, values, '"id"="{}"'.format(e[0]))



def xue1(cu, cls, label, infile):
    '''Xue step 1: cargo datos de otros datasets Xue'''

    entries = []
    with open(infile,'r') as f:
        entries = db_xue.load_file(f,True)

    species = label
    lineno = 0

    for e in entries:
        lineno = lineno + 1
        values = (e[0],cls,species,lineno,e[2],e[3],e[5],e[6],e[7],e[8],e[9])
        insert(cu, "triplet", '''(id, class, species, number, seq, struct, seq_length,
        gc_content, basepair, free_energy, len_bp_ratio)''', values)

        columns = tuple('triplet{}'.format(i) for i in range(1,33))
        values = db_xue.triplet(e[2],e[3])
        update(cu, "triplet", columns, values, '"id"="{}"'.format(e[0]))







if __name__ == "__main__":
    main()

# cols = '''(id, seq, struct, class, trip01, trip02, trip03, trip04,
# trip05, trip06, trip07, trip08, trip09, trip10, trip11, trip12, 
# trip13, trip14, trip15, trip16, trip17, trip18, trip19, trip20, 
# trip21, trip22, trip23, trip24, trip25, trip26, trip27, trip28, 
# trip29, trip30, trip31, trip32, g,  c,  u,  a,
# gg, gc, gu, ga, cg, cc, cu, ca, ug, uc, uu, ua,
# ag, ac, au, aa, a_u_l, g_c_l, g_u_l)
# '''

# # Xue
# for fff in ('ath','cbr','cel','dme','dps','dre','ebv','gga','hsa','mmu','osa','rno'):
#     basepath = 'src/triplet/3_extract_miRNAs_without_multiple_loops/'
#     fullpath = basepath + fff + '_one_stemloop.txt'
#     with open(fullpath) as f:
#         contents = fautil.load_file(f)
#         for k in contents.keys():
#             q = [];
#             q.append(k)
#             q.append(contents[k][1])
#             q.append(contents[k][2])
#             q.append(True)
#             q = q + fautil.triplet(contents[k][1],contents[k][2], sid=k)
#             q = q + fautil.sequence_feats(contents[k][1])
#             insert_col(cu, cols, q)

# with open('src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt') as f:
#     contents = fautil.load_file(f)
#     for k in contents.keys():
#         q = [];
#         q.append(k)
#         q.append(contents[k][1])
#         q.append(contents[k][2])
#         q.append(False)
#         q = q + fautil.triplet(contents[k][1],contents[k][2], sid=k)
#         q = q + fautil.sequence_feats(contents[k][1])
#         insert_col(cu, cols, q)

# with open('src/triplet/5_training_dataset/train_cds_168.txt') as f:
#     contents = fautil.load_file(f)
#     for k in contents.keys():
#         q = [];
#         q.append(k)
#         q.append(contents[k][1])
#         q.append(contents[k][2])
#         q.append(False)
#         q = q + fautil.triplet(contents[k][1],contents[k][2], sid=k)
#         q = q + fautil.sequence_feats(contents[k][1])
#         insert_col(cu, cols, q)

# with open('src/triplet/5_training_dataset/train_hsa_163.txt') as f:
#     contents = fautil.load_file(f)
#     for k in contents.keys():
#         q = [];
#         q.append(k)
#         q.append(contents[k][1])
#         q.append(contents[k][2])
#         q.append(True)
#         q = q + fautil.triplet(contents[k][1],contents[k][2], sid=k)
#         q = q + fautil.sequence_feats(contents[k][1])
#         insert_col(cu, cols, q)

# for root, dirs, files in os.walk("src/triplet/7_test_dataset/"):
#     for name in files:
#         cls = True
#         if name in ['genome_chr19.txt',' test_cds_1000.txt']:
#             cls = False
#         with open(os.path.join(root,name)) as f:
#             contents = fautil.load_file(f)
#             for k in contents.keys():
#                 q = [];
#                 q.append(k)
#                 q.append(contents[k][1])
#                 q.append(contents[k][2])
#                 q.append(cls)
#                 q = q + fautil.triplet(contents[k][1],contents[k][2], sid=k)
#                 q = q + fautil.sequence_feats(contents[k][1])
#                 insert_col(cu, cols, q)


# ### miPred

# for root, dirs, files in os.walk("src/miPred/miRNAs8.2h/rnafold/"):
#     for name in files:
#         cls = True
#         #if name in ['genome_chr19.txt',' test_cds_1000.txt']:
#         #    cls = False
#         with open(os.path.join(root,name)) as f:
#             contents = fautil.load_file(f)
#             for k in contents.keys():
#                 q = [];
#                 q.append(k)
#                 q.append(contents[k][1])
#                 q.append(contents[k][2])
#                 q.append(cls)
#                 try:
#                     q = q + fautil.triplet(contents[k][1],contents[k][2], sid=k)
#                     q = q + fautil.sequence_feats(contents[k][1])
#                     insert_col(cu, cols, q)
#                 except Exception as e:
#                     print("Ignoring id %s from %s: sequence is multi-looped" % (q[0],name) )

# for root, dirs, files in os.walk("src/miPred/miRNAs8.2h/rnafold/"):
#     for name in files:
#         cls = True
#         #if name in ['genome_chr19.txt',' test_cds_1000.txt']:
#         #    cls = False
#         with open(os.path.join(root,name)) as f:
#             contents = fautil.load_file(f)
#             for k in contents.keys():
#                 q = [];
#                 q.append(k)
#                 q.append(contents[k][1])
#                 q.append(contents[k][2])
#                 q.append(cls)
#                 try:
#                     q = q + fautil.triplet(contents[k][1],contents[k][2], sid=k)
#                     q = q + fautil.sequence_feats(contents[k][1])
#                     insert_col(cu, cols, q)
#                 except Exception as e:
#                     print("Ignoring id %s from %s: sequence is multi-looped" % (q[0],name) )



