#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Generate database with all features (triplet, sequence, folding) for all
# datasets. This script requires `zcat` to be found in PATH (required for
# miRBase 20 dataset). Also required is Python 2 v2.7+, RNAfold from the
# Vienna RNA package, and the CD-HIT program (http://cd-hit.org) for
# generating non-redundant data sets.
#
# USAGE: ./generate_db.sh
# 
# -----------------------------------------------------------------------------
#

# RNAfold command, replace with the right value for your system
RNAFOLD="RNAfold -noPS"
CDHIT="cdhit"
EXTRAOPTS=""
MULTILOOP=""

gen_dataset () {
    zcat -f $SRC | ./tests.py rnafold_clean $EXTRAOPTS > work/$NAME.clean
    $RNAFOLD < work/$NAME.clean > work/$NAME.rnafold
    mkdir -p work/$NAME
    ./feats.py by_species work/$NAME.rnafold $MULTILOOP -o work/$NAME -c $CLS $SPECIES
}

gen_nr_dataset () {
    zcat -f $SRC | ./tests.py rnafold_clean $EXTRAOPTS > work/$NAME.clean
    $CDHIT -i work/$NAME.clean -o work/$NAME.nr
    $RNAFOLD < work/$NAME.nr > work/$NAME.rnafold
    mkdir -p work/$NAME
    ./feats.py by_species work/$NAME.rnafold $MULTILOOP -o work/$NAME -c $CLS $SPECIES
}

echo "We will now generate the datasets with all features, please be patient.."
echo ""

echo "Dataset mirbase50: from mirBase v5.0 as in Triplet-SVM"
NAME="mirbase50"
SRC="src/triplet/1_download_pre-miRNAs_from_miRNA_registry/hairpin.fa"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset mirbase50-train: train hsa from mirBase v5.0 as in Triplet-SVM"
NAME="mirbase50/3svm-train"
SRC="src/triplet/5_training_dataset/train_hsa_163.txt"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset mirbase50-test: test hsa from mirBase v5.0 as in Triplet-SVM"
NAME="mirbase50/3svm-test"
SRC="src/triplet/7_test_dataset/test_hsa_30.txt"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset cross-species: from mirBase v5.0 as in Triplet-SVM for CROSS-SPECIES"
NAME="cross-species"
SRC="src/triplet/7_test_dataset/*.secondstructure"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset updated: UPDATED test set as in Triplet-SVM"
NAME="updated"
SRC="src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset coding: CODING pseudo-miRNAs set as in Triplet-SVM"
NAME="coding"
SRC="src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt"
CLS="-1"
SPECIES="-s hsa"
MULTILOOP=""
gen_dataset

echo "Dataset coding: train pseudo-miRNAs set as in Triplet-SVM"
NAME="coding/3svm-train"
SRC="src/triplet/5_training_dataset/train_cds_168.txt"
CLS="-1"
SPECIES="-s hsa"
MULTILOOP=""
gen_dataset

echo "Dataset coding: test pseudo-miRNAs set as in Triplet-SVM"
NAME="coding/3svm-test"
SRC="src/triplet/7_test_dataset/test_cds_1000.txt"
CLS="-1"
SPECIES="-s hsa"
MULTILOOP=""
gen_dataset

echo "Dataset conserved-hairpin: mostly-pseudo miRNA tst set as in Triplet-SVM"
NAME="conserved-hairpin"
SRC="src/triplet/7_test_dataset/genome_chr19.txt"
CLS="0"
SPECIES="-s hsa"
MULTILOOP=""
gen_dataset

echo "Dataset mirbase82-mipred: non-redundant miRNAs as in miPred"
NAME="mirbase82-mipred"
SRC="src/mipred/miRNAs8.2h/rnafold/*"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset mirbase82-mipred-multi: non-redundant miRNAs as in miPred"
NAME="mirbase82-mipred/multi"
SRC="src/mipred/miRNAs8.2h/rnafold/*"
CLS="1"
SPECIES=""
MULTILOOP="-m"
gen_dataset

echo "Dataset functional-ncrna: functional ncRNAs from Rfam 7.0 as in miPred"
NAME="functional-ncrna"
SRC="src/mipred/Rfam7.0/rnafold/*"
CLS="-1"
SPECIES="-s ncrna"
MULTILOOP=""
gen_dataset

echo "Dataset functional-ncrna-multi: functional ncRNAs from Rfam 7.0 as in miPred"
NAME="functional-ncrna/multi"
SRC="src/mipred/Rfam7.0/rnafold/*"
CLS="-1"
SPECIES="-s ncrna"
MULTILOOP="-m"
gen_dataset

echo "Dataset mirbase12-micropred: miRNAs from miRBase 12.0 as in microPred"
NAME="mirbase12-micropred"
SRC="src/micropred/691-pre-miRNAs.fasta"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset mirbase12-micropred-multi: miRNAs from miRBase 12.0 as in microPred"
NAME="mirbase12-micropred/multi"
SRC="src/micropred/691-pre-miRNAs.fasta"
CLS="1"
SPECIES=""
MULTILOOP="-m"
gen_dataset

echo "Dataset mirbase12: miRNAs from miRBase 12.0 for testing microPred"
NAME="mirbase12"
SRC="src/mirbase/12.0/hairpin.fa.gz"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset mirbase12-multi: miRNAs from miRBase 12.0 for testing microPred"
NAME="mirbase12/multi"
SRC="src/mirbase/12.0/hairpin.fa.gz"
CLS="1"
SPECIES=""
MULTILOOP="-m"
gen_dataset

echo "Dataset other-ncrna: other ncRNAs compiled by microPred authors"
NAME="other-ncrna"
SRC="src/micropred/754-other-ncRNAs-fix.fasta"
CLS="-1"
SPECIES="-s ncrna"
MULTILOOP=""
gen_dataset

echo "Dataset other-ncrna: other ncRNAs compiled by microPred authors"
NAME="other-ncrna/multi"
SRC="src/micropred/754-other-ncRNAs-fix.fasta"
CLS="-1"
SPECIES="-s ncrna"
MULTILOOP="-m"
gen_dataset

echo "Dataset mirbase20: miRNAs from miRBase 20"
NAME="mirbase20"
SRC="src/mirbase/20/hairpin.fa.gz"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_dataset

echo "Dataset mirbase20: miRNAs from miRBase 20"
NAME="mirbase20/multi"
SRC="src/mirbase/20/hairpin.fa.gz"
CLS="1"
SPECIES=""
MULTILOOP="-m"
gen_dataset

echo "Dataset mirbase20-nr: miRNAs from miRBase 20+CD-HIT"
NAME="mirbase20-nr"
SRC="src/mirbase/20/hairpin.fa.gz"
CLS="1"
SPECIES=""
MULTILOOP=""
gen_nr_dataset

echo "Dataset mirbase20-nr-multi: miRNAs from miRBase 20+CD-HIT"
NAME="mirbase20-nr/multi"
SRC="src/mirbase/20/hairpin.fa.gz"
CLS="1"
SPECIES=""
MULTILOOP="-m"
gen_nr_dataset

echo "Cleaning aux files.."
find work -type f -name "*.clean" -exec rm "{}" ";"
find work -type f -name "*.clstr" -exec rm "{}" ";"
find work -type f -name "*.nr" -exec rm "{}" ";"
find work -type f -name "*.rnafold" -exec rm "{}" ";"

echo "Moving directories to data/"
rm -rf mirbase50 coding updated conserved-hairpin cross-species
rm -rf mirbase82-mipred functional-ncrna
rm -rf mirbase12 mirbase12-micropred other-ncrna
rm -rf mirbase20 mirbase20-nr 

mv -f work/* .

echo "Done!"
