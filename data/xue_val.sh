#!/usr/bin/env bash

DIFF=diff
if which colordiff > /dev/null
then DIFF=colordiff
fi


# echo "Triplet-SVM: Parsing secondary structure and removing multi-looped sequences"

# ./feats.py singleloop < triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt > updated.strip
# ./feats.py singleloop < triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt > coding.strip
# ./feats.py singleloop < triplet/7_test_dataset/test_cds_1000.txt > conserved-hairpin.strip

# for f in $(ls triplet/2_predict_secondary_structure_of_miRNAs/)
# do echo "file: $f"
# cat triplet/2_predict_secondary_structure_of_miRNAs/$f | ./feats.py singleloop > ${f%%.secondstructure}.strip
# done

# echo "Triplet-SVM: Validating secondary structures with RNAfold v1.8.5"
# for f in *.strip
# do echo " * $f"
# ./tests.py rnafold_clean < $f | ext_utils/ViennaRNA-1.8.5/Progs/RNAfold -noPS | ./tests.py rnafold -1 $f -2 -
# done

# # echo "Triplet-SVM: Validating secondary structures with RNAfold v2"
# # for f in *.strip
# # do echo " * $f"
# # ./tests.py rnafold_clean < $f | RNAfold --noPS | ./tests.py rnafold -1 $f -2 -
# # done

# echo "***  miPred  ***"
echo "miPred: Validating secondary structures with RNAfold v1.8.5"

# for d in miRNAs8.2h mRNAs Rfam7.0
# do echo "directory: $d"
# for f in $(ls miPred/$d/rnafold/)
# do echo "file: $f"
# ./tests.py rnafold_clean < miPred/$d/rnafold/$f | ext_utils/ViennaRNA-1.8.5/Progs/RNAfold -noPS | ./tests.py rnafold -1 miPred/$d/rnafold/$f -2 - 
# done
# # echo "miPred: Validating secondary structures with RNAfold v2"
# # for f in $(ls miPred/$d/rnafold/)
# # do 
# # echo "file: $f"
# # ./tests.py rnafold_clean < miPred/$d/rnafold/$f | RNAfold --noPS | ./tests.py rnafold -1 miPred/$d/rnafold/$f -2 - 
# # done
# done

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


# echo "microPred: Calculating secondary structures with RNAfold v1.8.5"
# ./tests.py rnafold_clean < microPred/691-pre-miRNAs.fasta | ext_utils/ViennaRNA-1.8.5/Progs/RNAfold -noPS > 691.strip
# ./tests.py rnafold_clean < microPred/754-other-ncRNAs-fix.fasta | ext_utils/ViennaRNA-1.8.5/Progs/RNAfold -noPS > 754.strip
# ./tests.py rnafold_clean < microPred/8494-pseudo-hairpins.fasta | ext_utils/ViennaRNA-1.8.5/Progs/RNAfold -noPS > 8494.strip

# echo "comparing CODING set from all sources"
# ./tests.py rnafold -1 8494.strip -2 coding.strip
# ./tests.py rnafold -1 8494.strip -2 miPred/pseudoMiRNAs/rnafold/pseudoMiRNAs.rnafold


echo "microPred: Calculating and validating features"
./feats.py micropred < 691.strip > 691.stats
./feats.py micropred < 754.strip > 754.stats
./feats.py micropred < 8494.strip > 8494.stats

./tests.py micropred -1 691.stats -2 microPred/pre-miRNAs-48-features.csv
./tests.py micropred -1 754.stats -2 microPred/other-ncRNAs-48-features.csv
./tests.py micropred -1 8494.stats -2 microPred/pseudo-hairpins-48-features.csv



# echo "REAL miRNAs: Validating generated files"

# # for f in *.strip
# # do echo " ********************      Comparing $f   *********************** "
# # $DIFF --strip-trailing-cr triplet/3_extract_miRNAs_without_multiple_loops/${f%%.strip}_one_stemloop.txt $f
# # if [[ $? -ne 0 ]]
# # then echo "^^^^^^^^^^^^ differences found in file $f, please check the output above ^^^^^^^^^^^^^^^^^^^^"
# # else echo ".............  files match!!  ...................."
# # fi
# # done
# for f in *.strip
# do echo " *** Comparing $f ..."
# ./db_xue.py compare -2 triplet/3_extract_miRNAs_without_multiple_loops/${f%%.strip}_one_stemloop.txt -1 $f
# done

# # for f in *.strip
# # do echo " *** inserting $f into database ..."
# # ./build_db.py xue0 1 $f
# # done

# for f in *.strip
# do echo " *** coding triplets for $f with original and own script ..."
# ./ext_utils/3_step_triplet_coding_for_queries.pl $f $f.aux
# ./ext_utils/4_libsvm_format.pl $f.aux $f.xuetriplet
# rm $f.aux
# ./db_xue.py svm $f > $f.triplet
# done

# for f in *.triplet
# do echo " *** comparing triplets in file $f ..."
# ./db_xue.py cmp3 -1 $f -2 ${f%%.triplet}.xuetriplet
# done

# # echo " *** cleaning aux files ..."
# rm *.strip
# rm *.triplet
# rm *.xuetriplet

# # echo " *** validating Xue's CODING set calculated features ..."
# # ./db_xue.py validate triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt

# # echo " *** inserting Xue's CODING set into database ..."
# # ./build_db.py xue1 -1 coding triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt

# # echo " *** validating Xue's CONSERVED-HAIRPIN set calculated features ..."
# # ./db_xue.py validate triplet/7_test_dataset/genome_chr19.txt

# # echo " *** inserting Xue's CONSERVED-HAIRPIN set into database ..."
# # ./build_db.py xue1 -1 conserved triplet/7_test_dataset/genome_chr19.txt

# # echo " *** validating Xue's UPDATED set calculated features ..."
# # ./db_xue.py validate triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt

# # echo " *** inserting Xue's UPDATED set into database ..."
# # ./build_db.py xue1 1 hsa triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt

echo "Cleaning files.."
rm *.mipred
