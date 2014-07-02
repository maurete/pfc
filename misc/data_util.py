#!/usr/bin/env python
'''
genera resultados promediados a partir del archivo results.tsv
para las 3 diferentes semillas (303456,456789,5829)
'''

import sys
import sqlite3

conn = sqlite3.connect(':memory:')
c = conn.cursor()
c.execute('CREATE TABLE data (date float, seed integer, tt text, data text, dataset text, fset integer, classifier text, param1 real, param2 real, se real, sp real, acc real)')

in_data = sys.stdin.read()
lines = []
for l in in_data.splitlines():
    s = l.split()
    if s[0][0] != '#':
        if len(s) == 9:
            row = (s[0],s[1],s[2],s[3],s[4],s[5],s[6],s[7],None,None,None,s[8])
        elif len(s) == 10:
            row = (s[0],s[1],s[2],s[3],s[4],s[5],s[6],s[7],s[8],None,None,s[9])
        elif len(s) == 11:
            row = (s[0],s[1],s[2],s[3],s[4],s[5],s[6],s[7],None,s[8],s[9],s[10])
        elif len(s) == 8:
            row = (s[0],s[1],s[2],s[3],s[4],s[5],s[6],None,None,None,None,s[7])
        else:        
            row = tuple(s)
        #        print(str(row))
        c.execute('insert into data values(?,?,?,?,?,?,?,?,?,?,?,?)', row)

errflag = 0

for d in ('all','hsa','all+human','all+coding','xue','batuwita','ng'):
    for f in range(1,16):
        for cl in ('svm-linear','svm-rbf','mlp'):
            s = set()
            for dset in c.execute('SELECT dataset FROM data WHERE data=? AND classifier=? AND fset=?', (d,cl,f)):
                s.add(dset[0])
            #print(s)
            for t in s:
                qq=set()
                for i in c.execute('SELECT seed FROM data WHERE data=? AND classifier=? AND fset=? AND dataset=?', (d,cl,f,t)).fetchall():
                    qq.add(i[0])
                for se in (303456,456789,5829):
                    if se not in qq:
                        errflag = 1
                        print("{} ( '{}', {}, {} )".format(cl.replace('-','_'),d,f,se))

if errflag:
    exit(1)

c.execute('CREATE TABLE avg ( tt text, data text, dataset text, fset integer, classifier text, se real, sp real, acc real)')

for d in ('all','hsa','all+human','all+coding','xue','batuwita','ng'):
    for f in range(1,16):
        for cl in ('svm-linear','svm-rbf','mlp'):
            s = set()
            for dset in c.execute('SELECT dataset FROM data WHERE data=? AND classifier=? AND fset=?', (d,cl,f)):
                s.add(dset[0])

            for t in s:
                q = c.execute('SELECT seed, tt, se, sp, acc FROM data WHERE data=? AND classifier=? AND fset=? AND dataset=?', (d,cl,f,t)).fetchall()
    
                #if len(q) != 3:
                #    print("error! {} elementos, se esperaban 3:".format(len(q)) + str(q))
    
                se = 0
                sp = 0
                acc = 0
                for w in range(0,3):
                    try:
                        se = se + q[w][2]
                        sp = sp + q[w][3]
                    except TypeError:
                        pass 
                    acc = acc + q[w][4]
                
                se = se/3.0
                sp = sp/3.0
                acc = acc/3.0
    
                c.execute("INSERT INTO avg VALUES (?,?,?,?,?,?,?,?)", (q[0][1], d, t, f, cl, se, sp, acc))

for res in c.execute("SELECT * FROM avg"):
    print("{0[0]}\t{0[1]}\t{0[2]}\t{0[3]}\t{0[4]}\t{0[5]}\t{0[6]}\t{0[7]}".format(res))
    
