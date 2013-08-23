
Pre-miRNA and pseudo-pre-miRNA datasets
=======================================

In this folder you can find the following

* 9 datasets for *single-loop only* pre-miRNAs (positive examples) and
  non-pre-miRNAs (negative examples). See below for a description of
  each corresponding dataset.
* The original source datasets as obtained from the web in the `src/`
  directory.
* `feats.py`, a Python utility for feature extraction.
* `tests.py`, a Python utility mostly useful for comparing features
  files.
* `validate.sh`, a Bash script for validating feature extraction.
* `generate_db.sh`, a Bash script for re-generating the database for
  all 9 datasets.

Features
--------
In the directory for each dataset you'll find the following six files,
(explained below) for each species. The negative and unknown datasets
contain artificial species names, even though they are taken from the
human genome. This is in part because of the nonstandard naming for
this sequences, in part to remind that they are not real pre-miRNAs.
Name `pseudo` is used in the `coding` dataset, `ncrna` for ncRNA
datasets and `unknown` for the `conserved-hairpin` dataset.

The order of entries is consistent through all six files: line number
X in each file corresponds to the same entry, except for the .fa file
where lines `3*X` (description), `3*X+1` (sequence) and `3*X+2`
(secondary structure) belong to entry X.

### `<species>.c`
Single-column file indicating the class of the entry: `1` for
pre-miRNA, `-1` for non-pre-miRNA, and `0` for indeterminate.
`0` entries should not be used for training.

### `<species>.fa`
FASTA-like file containing, for each entry, a description line
beginning with `>`, a sequence line containing a string with
characters `AGCU` only, and a matching secondary structure line
consisting of characters `(.)`.

### `<species>.3`
Tab-separated file in which each column corresponds with the
ocurrence count of each "triplet" values as explained on (Xue et
al.). All values are divided by the total number of triplets. The
order of ocurrence for the triplets is the following:

	A..., A..(, A.(., A.((, A(.., A(.(, A((., A(((,
	G..., G..(, G.(., G.((, G(.., G(.(, G((., G(((,
	C..., C..(, C.(., C.((, C(.., C(.(, C((., C(((,
	U..., U..(, U.(., U.((, U(.., U(.(, U((., U(((

### `<species>.3x`
Tab-separated file with extra features as found on the (Xue et al.)'s
datasets. The columns represent the following values, in that order:

* `len3` is the length of the 'stem portion' for extracting triplet
  values. Represents the length of the sequence portion that is part
  of the stem, i.e. the total sequence length minus the length of the
  unpaired ends and the central (terminal) loop.
* `basepair` the number of base pairs.
* `len3/basepair` `len3` divided by `basepair`.
* `gc_count/len3` the number of `G`s plus the number of `C`s _in the
  stem only_ divided by `len3`.

### `<species>.s`
Tab-separated file containing sequence measures. These features are
obtained for the full sequence, not only the stem part. Note also that
the order of columns follow the pattern `A,C,G,U` (alphabetical), in
contrast with the `A,G,C,U` pattern for triplets. Contains the
following fields:

* `Len` full sequence length, contrast with `len3` feature above.
* `A,C,G,U` (4 columns) (A,G,C,U)-nucleotide count.
* `G+C` G count + C count, contrast with `gc_count/len3` above.
* `A+U` A count + U count.
* `AA,AC,AG,AU,CA,CC,CG,CU,GA,GC,GG,GU,UA,UC,UG,UU` (16 columns)
  dinucleotide count, where the XY-dinucleotide is defined as an
  X-nucleotide inmediately followed by an Y-nucleotide, from left to
  right. Dinucleotides overlap each other: the sequence `ACU` has an
  AC-count of 1 and a CU-count of 1.
  
### `<species>.f`
Tab-separated file containing folding measures. Features computed
as explained in (Batuwita & Palade Supplementary), please refer to
that work for a detailed description. For each entry, the
following columns are present:

* `mfe` Minimum Free Energy as obtained with the `RNAfold` utility
  from the (Hofacker et al.).
* `MFEI1` MFE Index 1: `dG/%(G+C)`.
* `MFEI4` MFE Index 4: `mfe` divided by the number of base pairs
  (`basepair` feature in the .3x file).
* `dP` sequence length-normalized base pair count.
* `|A-U|/L` normalized A-U base pair count.
* `|G-C|/L` normalized G-C base pair count.
* `|G-U|/L` normalized G-U base pair count.

Datasets
--------

The following datasets are available as directories with the structure
as explained above. Please refer to the original work for a detailed
explanation of each.

### mirbase50
Published in (Xue et al.), from miRBase release 5.0 (miRBase).
Contains 1210 validated pre-miRNAs for various species:

* 76  ath (A.thaliana)
* 73  cbr (C.briggsae)
* 110 cel (C.elegans)
* 71  dme (fruit fly D.melanogaster)
* 71  dps (fruit fly D.pseudoobscura)
* 24  dre (zebrafish)
* 5   ebv (E-Barr virus)
* 112 gga (chicken) 
* 193 hsa (human)
* 207 mmu (mouse)
* 96  osa (rice)
* 172 rno (rat)
	
### updated
Published in (Xue et al.) as the "Latest human miRNA updated" test
set. Contains 39 validated human pre-miRNAs (hsa).
 
### coding
Published in (Xue et al.) as the "CODING" set.  Contains 8494 pseudo
pre-miRNAs collected from the protein-coding regions of human RefSeq
genes. To be used as negative training set.
	 
### conserved-hairpin
Published in (Xue et al.) as the "CONSERVED-HAIRPIN" set.  Contains
2444 pseudo pre-miRNAs from the human chromosome 19.  Some entries are
in fact real pre-miRNAs. The class is set in purpose as `0` and the
species name as `unknown` to highlight the not-completely-certain
"negativity" of this set.

### mirbase82-nr
Taken from (Ng & Mishra), this dataset contains 1985 (out of 2241 in
the original dataset) single-loop pre-miRNAs from miRBase release 8.2
(miRBase) filtered to 90% identity using a greedy incremental
clustering algorithm (Li & Godzik) for 40 different species including
vertebrate, plant, virus and other pre-miRNAs.

### functional-ncrna
Contains 2657 (out of 12387) single-loop functional prokaryotic and
eukaryotic ncRNAs from Rfam 7.0 (Griffith-Jones et al.) after
stripping 46 types of pre-miRNAs. Dataset obtained from (Ng & Mishra).

### mirbase12
Obtained from (Batuwita & Palade), this dataset contains 660 out of
691 non-redundant single-loop human pre-miRNAs from miRBase release
12.0 (miRBase).

### other-ncrna
Consists of 129 out of 754 single-loop human non-miRNA ncRNA
sequences. Details for this dataset can be found on (Batuwita &
Palade).

### mirbase20
Taken from miRBase 20 (miRBase), contains 21433 pre-miRNAs out of
24521 spanning 204 species, notably 1801 human, 1121 mouse, 423 rat
and 392 rice. Sequences with non-GCUA nucleotides have been stripped
as well as those multi-looped.

Comments
--------

* As stated above, only single loop entries are incorporated into this
  database.
* Entries having a sequence with characters other than A, C, G, U are
  discarded when building the database.

References
----------

(Xue et al.)            doi:10.1186/1471-2105-6-310
(Batuwita & Palade)     doi:10.1093/bioinformatics/btp107
(miRBase)               doi:10.1093/nar/gkh023
(Ng & Mishra)           doi:10.1093/bioinformatics/bti283
(Hofacker et al.)       doi:10.1007/BF00818163
(Griffith-Jones et al.) doi:10.1093/nar/gki081
(Li & Godzik)           doi:10.1093/bioinformatics/btl158
