#!/usr/bin/env bash

DIFF=diff
if which colordiff > /dev/null
then DIFF=colordiff
fi

echo "Triplet-SVM: Removing multi-looped sequences"

./feats.py singleloop \
    < src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt \
    > work/updated.singleloop
./feats.py singleloop \
    < src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt \
    > work/coding.singleloop
./feats.py singleloop \
    < src/triplet/7_test_dataset/test_cds_1000.txt \
    > work/conserved-hairpin.singleloop
for f in $(ls src/triplet/2_predict_secondary_structure_of_miRNAs/)
do echo "file: $f"
./feats.py singleloop \
    < src/triplet/2_predict_secondary_structure_of_miRNAs/$f \
    > work/${f%%.secondstructure}.singleloop
done

echo "Triplet-SVM: Validating secondary structures with RNAfold"
for f in work/*.singleloop
do echo " * $f"
./tests.py rnafold_clean < $f | RNAfold -noPS | ./tests.py rnafold -1 $f -2 -
done

echo "Triplet-SVM: Validating generated files"

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
for f in $(ls triplet/3_extract_miRNAs_without_multiple_loops/)
do echo "file: $f"
./tests.py triplet_fasta \
    -1 src/triplet/3_extract_miRNAs_without_multiple_loops/$f \
    -2 work/${f%%_one_stemloop.txt}.singleloop
done

echo "miPred: Validating secondary structure with RNAfold (ign mRNAs)..."
for d in miRNAs8.2h #Rfam7.0
do echo "directory: $d"
for f in $(ls src/mipred/$d/rnafold/)
do echo "file: $f"
./tests.py rnafold_clean < src/mipred/$d/rnafold/$f \
    | RNAfold -noPS | ./tests.py rnafold -1 src/mipred/$d/rnafold/$f -2 - 
done
done

echo "miPred: Calculating features (ignoring mRNAs)..."
for d in miRNAs8.2h #Rfam7.0
do echo "directory: $d"
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

echo "microPred: Validating secondary structures with RNAfold"
./tests.py rnafold_clean < src/micropred/691-pre-miRNAs.fasta \
    | RNAfold -noPS > work/691.rnafold
./tests.py rnafold_clean < src/micropred/754-other-ncRNAs-fix.fasta \
    | RNAfold -noPS > work/754.rnafold
./tests.py rnafold_clean < src/micropred/8494-pseudo-hairpins.fasta \
    | RNAfold -noPS > work/8494.rnafold

echo "microPred: Calculating and validating features"
./feats.py micropred < work/691.rnafold > work/691.stats
./feats.py micropred < work/754.rnafold > work/754.stats
./feats.py micropred < work/8494.rnafold > work/8494.stats

./tests.py micropred -1 work/691.stats -2 src/micropred/pre-miRNAs-48-features.csv
./tests.py micropred -1 work/754.stats -2 src/micropred/other-ncRNAs-48-features.csv
./tests.py micropred -1 work/8494.stats -2 src/micropred/pseudo-hairpins-48-features.csv

echo "Verifying CODING dataset from all sources"
./tests.py rnafold -1 work/8494.rnafold -2 work/coding.singleloop
./tests.py rnafold -1 work/8494.rnafold \
    -2 src/mipred/pseudoMiRNAs/rnafold/pseudoMiRNAs.rnafold

echo "Cleaning files.."
rm -f work/*
# rm -f *.mipred
# rm -f *.rnafold
# rm -f *.triplet
# rm -f *.triplet_orig
# rm -f *.stats
# rm -f *.singleloop

echo "Done. Please verify above output for errors!"
