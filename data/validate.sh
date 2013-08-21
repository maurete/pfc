#!/usr/bin/env bash

# Script for validating RNAfold folding and specific features for
# each dataset.


# RNAfold command, replace with the right value for your system
RNAFOLD="RNAfold -noPS"

echo "Triplet-SVM: Validating RNAfold folding"

echo "folding 39_hsa_miRNAs_one_stemloop.txt..."
./tests.py rnafold_clean \
    < src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt \
    > work/updated.fa
$RNAFOLD < work/updated.fa > work/updated.rnafold
./tests.py rnafold \
    -1 src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt \
    -2 work/updated.rnafold

echo "folding 8494_hairpins_over_fe_15_bp_18_from_cds.txt..."
./tests.py rnafold_clean \
    < src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt \
    > work/coding.fa
$RNAFOLD < work/coding.fa > work/coding.rnafold
./tests.py rnafold \
    -1 src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt \
    -2 work/coding.rnafold

echo "folding test_cds_1000.txt..."
./tests.py rnafold_clean \
    < src/triplet/7_test_dataset/test_cds_1000.txt \
    > work/conserved-hairpin.fa
$RNAFOLD < work/conserved-hairpin.fa > work/conserved-hairpin.rnafold
./tests.py rnafold \
    -1 src/triplet/7_test_dataset/test_cds_1000.txt \
    -2 work/conserved-hairpin.rnafold

for f in $(ls src/triplet/2_predict_secondary_structure_of_miRNAs/)
do echo "folding $f..."
./tests.py rnafold_clean \
    < src/triplet/2_predict_secondary_structure_of_miRNAs/$f \
    > work/${f%%.secondstructure}.fa
$RNAFOLD < work/${f%%.secondstructure}.fa > work/${f%%.secondstructure}.rnafold
./tests.py rnafold \
    -1 src/triplet/2_predict_secondary_structure_of_miRNAs/$f \
    -2 work/${f%%.secondstructure}.rnafold
done

echo "Triplet-SVM: Removing multi-looped sequences"
for f in $(ls work/ | grep ".rnafold")
do echo "file: $f"
./feats.py singleloop \
    < work/$f \
    > work/${f%%.rnafold}.singleloop
done

echo "Triplet-SVM: Comparing single-loop files with originals"
echo "file: 39_hsa_miRNAs_one_stemloop.txt"
./tests.py rnafold \
    -1 src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt \
    -2 work/updated.singleloop
echo "file: 8494_hairpins_over_fe_15_bp_18_from_cds.txt"
./tests.py rnafold \
    -1 src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt \
    -2 work/coding.singleloop
echo "file: test_cds_1000.txt"
./tests.py rnafold \
    -1 src/triplet/7_test_dataset/test_cds_1000.txt \
    -2 work/conserved-hairpin.singleloop
for f in $(ls src/triplet/3_extract_miRNAs_without_multiple_loops/)
do echo "file: $f"
./tests.py rnafold \
    -1 src/triplet/3_extract_miRNAs_without_multiple_loops/$f \
    -2 work/${f%%_one_stemloop.txt}.singleloop
done

echo "Triplet-SVM: Computing and validating features"

for f in work/*.singleloop
do echo " *** coding triplets for $f with original and own script ..."
./ext_utils/3_step_triplet_coding_for_queries.pl $f $f.triplet_aux
./ext_utils/4_libsvm_format.pl $f.triplet_aux ${f%%.singleloop}.triplet_orig
rm $f.triplet_aux
./feats.py triplet < $f > ${f%%.singleloop}.triplet
done

for f in work/*.triplet
do echo " *** comparing triplets in file $f ..."
./tests.py triplet -1 $f -2 ${f}_orig
done

echo "Triplet-SVM: Validating TripletSVM extra features..."
./tests.py triplet_fasta \
    -1 src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt \
    -2 work/updated.singleloop
./tests.py triplet_fasta \
    -1 src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt \
    -2 work/coding.singleloop
./tests.py triplet_fasta \
    -1 src/triplet/7_test_dataset/test_cds_1000.txt \
    -2 work/conserved-hairpin.singleloop
for f in $(ls src/triplet/3_extract_miRNAs_without_multiple_loops/)
do echo "file: $f"
./tests.py triplet_fasta \
    -1 src/triplet/3_extract_miRNAs_without_multiple_loops/$f \
    -2 work/${f%%_one_stemloop.txt}.singleloop
done

echo "miPred: Validating secondary structure with RNAfold (ign mRNAs)..."
for d in miRNAs8.2h Rfam7.0
do
for f in $(ls src/mipred/$d/rnafold/)
do echo "file: $f"
./tests.py rnafold_clean < src/mipred/$d/rnafold/$f \
    | RNAfold -noPS | ./tests.py rnafold -1 src/mipred/$d/rnafold/$f -2 - 
done
done

echo "miPred: Calculating features (ignoring mRNAs)..."
for d in miRNAs8.2h Rfam7.0
do
for f in $(ls src/mipred/$d/rnafold/)
do echo "file: $f"
./feats.py mipred < src/mipred/$d/rnafold/$f > work/${f%%.rnafold}.mipred
done
echo "miPred: Validating features (ignoring mRNAs)..."
for f in $(ls src/mipred/$d/ | egrep "\.stats")
do 
echo "file: $f"
./tests.py mipred -1 src/mipred/$d/$f -2 work/${f%%.stats}.mipred
done
done

echo "microPred: Obtaining secondary structure with RNAfold"
./tests.py rnafold_clean < src/micropred/691-pre-miRNAs.fasta \
    | RNAfold -noPS > work/691.rnafold
./tests.py rnafold_clean < src/micropred/754-other-ncRNAs-fix.fasta \
    | RNAfold -noPS > work/754.rnafold
./tests.py rnafold_clean < src/micropred/8494-pseudo-hairpins.fasta \
    | RNAfold -noPS > work/8494.rnafold

echo "microPred: Calculating and validating features"
./feats.py micropred < work/691.rnafold > work/691.upred
./feats.py micropred < work/754.rnafold > work/754.upred
./feats.py micropred < work/8494.rnafold > work/8494.upred

./tests.py micropred -1 work/691.upred -2 src/micropred/pre-miRNAs-48-features.csv
./tests.py micropred -1 work/754.upred -2 src/micropred/other-ncRNAs-48-features.csv
./tests.py micropred -1 work/8494.upred -2 src/micropred/pseudo-hairpins-48-features.csv

echo "Verifying CODING dataset from all sources"
./tests.py rnafold -1 work/8494.rnafold -2 work/coding.singleloop
./tests.py rnafold -1 work/8494.rnafold \
    -2 src/mipred/pseudoMiRNAs/rnafold/pseudoMiRNAs.rnafold

echo "Cleaning files.."
rm -rf work/*

echo "Done. Please verify above output for errors!"
