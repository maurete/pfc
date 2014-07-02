#!/usr/bin/env python

import os
import glob
import gzip
import subprocess

class organism(object):
    def __init__(self, s):
        arr = s.split('\t')
        self.org  = arr[0]
        self.name = arr[2]
        self.tree = arr[3].split(';')
        self.idx  = 0

    def __eq__(self, s):
        try:
            return self.org == s.org
        except AttributeError:
            return self.org == s

    def __lt__(self, s):
        try:
            return self.tree < s.tree
        except AttributeError:
            return False

    def __iter__(self):
        self.i = 0
        return self

    def next(self):
        if self.i == len(self.tree)-1:
            raise StopIteration
        self.i = self.i + 1
        return self.tree[self.i-1]
        
    @property
    def kingdom(self):
        return self.tree[0]

    # @property
    # def tree(self):
    #     return self.tree

    # @property
    # def name(self):
    #     return self.name


def kingdom ( path = '../data/mirbase20-nr',
              organisms = '../data/src/mirbase/20/organisms.txt.gz' ):

    filecont = gzip.open(organisms,'r').read()

    orglist = { }
    species = { }
    kingdom = { 'Metazoa':0, 'Mycetozoa':0, 'Viruses':0,
                'Chromalveolata':0, 'Viridiplantae':0 }
    mtztype = { 'Hexapoda':0, 'Mammalia':0, 'Aves':0, 
                'Pisces':0, 'Nematoda':0 }
    virtype = { }



    for l in filecont.splitlines():
        if '#' not in l:
            o = organism(l)
            orglist[o.org] = o

            if o.tree[0] == 'Viridiplantae':
                if o.tree[1] not in virtype:
                    #print(str(o.tree))
                    virtype[o.tree[1]] = 0
            
    for f in glob.glob(path+"/*.3"):
        with open(f,'r') as fi:
            l = len(fi.read().splitlines())
            s = os.path.basename(f).split('.')[0]
            species[s] = l

    out = ''

    for s in species.keys():
        k = orglist[s].kingdom
        
        out = "{}\n{}{},{}".format(out,'-'.join(orglist[s].tree),orglist[s].name.replace(' ','_'),species[s])

    print(out)
    return

        # kingdom[k] = kingdom[k] + species[s] 

        # if k == 'Metazoa':
        #     for w in mtztype.keys():
        #         if w in orglist[s].tree:
        #             mtztype[w] = mtztype[w] + species[s] 
        # elif k == 'Viridiplantae':
        #     for w in virtype.keys():
        #         if w in orglist[s].tree:
        #             virtype[w] = virtype[w] + species[s] 

    # for k in kingdom.keys():
    #     print("{}\t{}".format(k, kingdom[k]))
    # for k in mtztype.keys():
    #     print("{}\t{}".format(k, mtztype[k]))
    # for k in virtype.keys():
    #     print("{}\t{}".format(k, virtype[k]))

    # gnuplot_out = '''set xrange [-20:20]
    # set yrange [-20:20]
    # set style fill transparent solid 0.9 noborder
    # plot '-' using 1:2:3:4:5:6 with circles lc var'''

    # fac = 360.0/sum(kingdom[k] for k in kingdom.keys())

    # tree_depth = max(len(orglist[k].tree) for k in orglist.keys())
    
    # order = [sorted(orglist.values())[i].org for i in range(len(orglist))]

    # columns = []
    # p = 0
    # for o in order:
    #     if o in species.keys():
    #         columns.append((o,p,p+species[o]*fac,tree_depth))
    #         p = p+species[o]*fac

    # for i in range(tree_depth-1,-1,-1):
    #     p = 0
    #     for o in order:
    #         if o in species.keys():
    #             if len(orglist[o].tree)>i and orglist[o].tree[i] != '':
    #                 if orglist[o].tree[i] == columns[-1][0]:
    #                     columns[-1] = (columns[-1][0],columns[-1][1],p+species[o]*fac,i+1)
    #                 else:
    #                     columns.append((orglist[o].tree[i],p,p+species[o]*fac,i+1))
    #             p = p+species[o]*fac

    # i = 0
    # for l in columns:
    #     i = i+1 #% 256
    #     gnuplot_out = '{}\n0\t0\t{}\t{}\t{}\t{}\t{}'.format(gnuplot_out, l[3],l[1],l[2],i,l[0])

    # gnuplot_out = gnuplot_out + '\ne'

    # print(gnuplot_out)

    # p = subprocess.Popen('gnuplot',stdin=subprocess.PIPE)
    # p.communicate(gnuplot_out)

    # try:
    #     input()
    # except e:
    #     pass

    # p.terminate()

if __name__ == "__main__":

    kingdom()

