#!/usr/bin/env bash

DIFF=diff
if which colordiff > /dev/null
then DIFF=colordiff
fi

echo "Triplet-SVM: Removing multi-looped sequences"

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

echo "Triplet-SVM: Validating secondary structures with RNAfold"
for f in *.singleloop
do echo " * $f"
./tests.py rnafold_clean < $f | RNAfold -noPS | ./tests.py rnafold -1 $f -2 -
done

echo "Triplet-SVM: Validating generated files"

for f in *.singleloop
do echo " *** coding triplets for $f with original and own script ..."
./ext_utils/3_step_triplet_coding_for_queries.pl $f $f.triplet_aux
./ext_utils/4_libsvm_format.pl $f.triplet_aux ${f%%.singleloop}.triplet_orig
rm $f.triplet_aux
./feats.py triplet < $f > ${f%%.singleloop}.triplet
done

for f in *.triplet
do echo " *** comparing triplets in file $f ..."
./tests.py triplet -1 $f -2 ${f}_orig
done

echo "Triplet-SVM: Validating TripletSVM extra features..."
./tests.py triplet_fasta \
    -1 triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt \
    -2 updated.singleloop
./tests.py triplet_fasta \
    -1 triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt \
    -2 coding.singleloop
./tests.py triplet_fasta \
    -1 triplet/7_test_dataset/test_cds_1000.txt \
    -2 conserved-hairpin.singleloop
for f in $(ls triplet/3_extract_miRNAs_without_multiple_loops/)
do echo "file: $f"
./tests.py triplet_fasta \
    -1 triplet/3_extract_miRNAs_without_multiple_loops/$f \
    -2 ${f%%_one_stemloop.txt}.singleloop
done

echo "miPred: Validating secondary structure with RNAfold..."
for d in miRNAs8.2h mRNAs Rfam7.0
do echo "directory: $d"
for f in $(ls miPred/$d/rnafold/)
do echo "file: $f"
./tests.py rnafold_clean < miPred/$d/rnafold/$f \
    | RNAfold -noPS | ./tests.py rnafold -1 miPred/$d/rnafold/$f -2 - 
done
done

echo "miPred: Calculating features..."
for d in miRNAs8.2h mRNAs Rfam7.0
do echo "directory: $d"
for f in $(ls miPred/$d/rnafold/)
do echo "file: $f"
./feats.py mipred < miPred/$d/rnafold/$f > ${f%%.rnafold}.mipred
done
echo "miPred: Validating features..."
for f in $(ls miPred/$d/ | egrep "\.stats")
do 
echo "file: $f"
./tests.py mipred -1 miPred/$d/$f -2 ${f%%.stats}.mipred
done
done

echo "microPred: Validating secondary structures with RNAfold"
./tests.py rnafold_clean < microPred/691-pre-miRNAs.fasta \
    | RNAfold -noPS > 691.rnafold
./tests.py rnafold_clean < microPred/754-other-ncRNAs-fix.fasta \
    | RNAfold -noPS > 754.rnafold
./tests.py rnafold_clean < microPred/8494-pseudo-hairpins.fasta \
    | RNAfold -noPS > 8494.rnafold

echo "microPred: Calculating and validating features"
./feats.py micropred < 691.rnafold > 691.stats
./feats.py micropred < 754.rnafold > 754.stats
./feats.py micropred < 8494.rnafold > 8494.stats

./tests.py micropred -1 691.stats -2 microPred/pre-miRNAs-48-features.csv
./tests.py micropred -1 754.stats -2 microPred/other-ncRNAs-48-features.csv
./tests.py micropred -1 8494.stats -2 microPred/pseudo-hairpins-48-features.csv

echo "Verifying CODING dataset from all sources"
./tests.py rnafold -1 8494.rnafold -2 coding.singleloop
./tests.py rnafold -1 8494.rnafold \
    -2 miPred/pseudoMiRNAs/rnafold/pseudoMiRNAs.rnafold

echo "Cleaning files.."
rm -f *.mipred
rm -f *.rnafold
rm -f *.triplet
rm -f *.triplet_orig
rm -f *.stats
rm -f *.singleloop

echo "Done. Please verify above output for errors!"
