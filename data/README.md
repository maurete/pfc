
Datasets
========

This folder contains the following datasets:

 * mirbase50

   Published in (Xue et al.), from miRBase release 5.0.
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

 * updated
 
   Published in (Xue et al.) as the "UPDATED" test set.
   Contains 39 validated human pre-miRNAs (hsa).
 
 * coding
 
   Published in (Xue et al.) as the "CODING" set.
   Contains 8494 pseudo pre-miRNAs to be used as negative training set.
	 
 * conserved-hairpin

   Published in (Xue et al.) as the "CONSERVED-HAIRPIN" set.
   Contains 1000 pseudo pre-miRNAs, thou some are to be used as negative training set.
 
 * mirbase82-nr
 * functional-ncrna
 * mirbase12
 * other-ncrna
 * mirbase20








Directory structure
-------------------

You will find the following folders here:

 * src/
   
   The source datasets as obtained from respective authors
   
 * ext_utils/

   Other author's utilities (for validation purposes only)

 * <dataset>/

   Respective dataset 


[1] Xue et al.
