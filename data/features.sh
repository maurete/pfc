#!/usr/bin/env bash

DIFF=diff
if which colordiff > /dev/null
then DIFF=colordiff
fi

RNAFOLD="RNAfold -noPS"

echo "Step 1: Removing multi-looped sequences"
echo " ** Triplet-SVM"
./feats.py singleloop \
    < triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt \
    > updated.singleloop
./feats.py singleloop \
    < triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt \
    > coding.singleloop
./feats.py singleloop \
    < triplet/7_test_dataset/test_cds_1000.txt \
    > conserved-hairpin.singleloop
for f in $(ls triplet/2_predict_secondary_structure_of_miRNAs/)
do echo "file: $f"
./feats.py singleloop \
    < triplet/2_predict_secondary_structure_of_miRNAs/$f \
    > ${f%%.secondstructure}.singleloop
done
echo " ** miPred"
for d in miRNAs8.2h mRNAs Rfam7.0 # skip pseudoMiRNAs, same as CODING
do echo "directory: $d"
for f in $(ls miPred/$d/rnafold/)
do echo "file: $f"
./feats.py singleloop < miPred/$d/rnafold/$f > ${f%%.rnafold}.singleloop
done
done
echo " ** microPred"
$RNAFOLD < microPred/691-pre-miRNAs.fasta \
    | ./feats.py singleloop > 691.singleloop
$RNAFOLD < microPred/754-other-ncRNAs-fix.fasta \
    | ./feats.py singleloop > 754.singleloop
# $RNAFOLD < microPred/8494-pseudo-hairpins.fasta \
#     | ./feats.py singleloop > 8494.singleloop

# remove al single-loop files with zero size (original was all multiloop)
find *.singleloop -size 0 -exec rm "{}" ";"

echo "Step 2: Calculating features"
echo " ** Triplet-SVM"
for f in *.singleloop
do ./feats.py triplet -r < $f > ${f%%.singleloop}.triplet
done
echo " ** miPred"
for f in *.singleloop
do ./feats.py mipred < $f > ${f%%.singleloop}.mipred
done
echo " ** microPred"
for f in *.singleloop
do ./feats.py micropred < $f > ${f%%.singleloop}.micropred
done

