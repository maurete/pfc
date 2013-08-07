#!/usr/bin/env bash

DIFF=diff
if which colordiff > /dev/null
then DIFF=colordiff
fi

echo "REAL miRNAs: Parsing secondary structure and removing multi-looped sequences"
for f in $(ls triplet/2_predict_secondary_structure_of_miRNAs/)
do echo "file: $f"
cat triplet/2_predict_secondary_structure_of_miRNAs/$f | ./db_xue.py strip > ${f%%.secondstructure}.strip
done

echo "REAL miRNAs: Validating generated files"
# for f in *.strip
# do echo " ********************      Comparing $f   *********************** "
# $DIFF --strip-trailing-cr triplet/3_extract_miRNAs_without_multiple_loops/${f%%.strip}_one_stemloop.txt $f
# if [[ $? -ne 0 ]]
# then echo "^^^^^^^^^^^^ differences found in file $f, please check the output above ^^^^^^^^^^^^^^^^^^^^"
# else echo ".............  files match!!  ...................."
# fi
# done
for f in *.strip
do echo " *** Comparing $f ..."
./db_xue.py compare -2 triplet/3_extract_miRNAs_without_multiple_loops/${f%%.strip}_one_stemloop.txt -1 $f
done

for f in *.strip
do echo " *** inserting $f into database ..."
./build_db.py xue0 1 $f
done

for f in *.strip
do echo " *** coding triplets for $f with original and own script ..."
./aux/3_step_triplet_coding_for_queries.pl $f $f.aux
./aux/4_libsvm_format.pl $f.aux $f.xuetriplet
rm $f.aux
./db_xue.py svm $f > $f.triplet
done

for f in *.triplet
do echo " *** comparing triplets in file $f ..."
./db_xue.py cmp3 -1 $f -2 ${f%%.triplet}.xuetriplet
done

echo " *** cleaning aux files ..."
rm *.strip
rm *.triplet
rm *.xuetriplet

echo " *** validating Xue's CODING set calculated features ..."
./db_xue.py validate triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt

echo " *** inserting Xue's CODING set into database ..."
./build_db.py xue1 -1 coding triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt

echo " *** validating Xue's CONSERVED-HAIRPIN set calculated features ..."
./db_xue.py validate triplet/7_test_dataset/genome_chr19.txt

echo " *** inserting Xue's CONSERVED-HAIRPIN set into database ..."
./build_db.py xue1 -1 conserved triplet/7_test_dataset/genome_chr19.txt

echo " *** validating Xue's UPDATED set calculated features ..."
./db_xue.py validate triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt

echo " *** inserting Xue's UPDATED set into database ..."
./build_db.py xue1 1 hsa triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt
