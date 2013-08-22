#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Generate database with all features (triplet, sequence, folding) for all
# datasets. This script requires `zcat` to be found in PATH (required for
# miRBase 20 dataset). Also required is Python 2 v2.7+ and RNAfold from the
# Vienna RNA package.
#
# USAGE: ./generate_db.sh
# 
# -----------------------------------------------------------------------------
#

# RNAfold command, replace with the right value for your system
RNAFOLD="RNAfold -noPS"

gen_dataset () {
    zcat -f $SRC | ./tests.py rnafold_clean > work/$NAME.clean
    $RNAFOLD < work/$NAME.clean > work/$NAME.rnafold
    mkdir -p work/$NAME
    ./feats.py by_species work/$NAME.rnafold -o work/$NAME -c $CLS $SPECIES
}

echo "We will now generate the datasets with all features, please be patient.."
echo ""

echo "Dataset mirbase50: from mirBase v5.0 as in Triplet-SVM"
NAME="mirbase50"
SRC="src/triplet/1_download_pre-miRNAs_from_miRNA_registry/hairpin.fa"
CLS="1"
SPECIES=""
gen_dataset

echo "Dataset updated: UPDATED test set as in Triplet-SVM"
NAME="updated"
SRC="src/triplet/7_test_dataset/39_hsa_miRNAs_one_stemloop.txt"
CLS="1"
SPECIES=""
gen_dataset

echo "Dataset coding: CODING pseudo-miRNAs set as in Triplet-SVM"
NAME="coding"
SRC="src/triplet/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt"
CLS="-1"
SPECIES="-s pseudo"
gen_dataset

echo "Dataset conserved-hairpin: (pseudo?) miRNAs test set as in Triplet-SVM"
NAME="conserved-hairpin"
SRC="src/triplet/7_test_dataset/genome_chr19.txt"
CLS="0"
SPECIES="-s unknown"
gen_dataset

echo "Dataset mirbase82-nr: non-redundant miRNAs as in miPred"
NAME="mirbase82-nr"
SRC="src/mipred/miRNAs8.2h/rnafold/*"
CLS="1"
SPECIES=""
gen_dataset

echo "Dataset functional-ncrna: functional ncRNAs from Rfam 7.0 as in miPred"
NAME="functional-ncrna"
SRC="src/mipred/Rfam7.0/rnafold/*"
CLS="-1"
SPECIES="-s ncrna"
gen_dataset

echo "Dataset mirbase12: miRNAs from miRBase 12.0 as in microPred"
NAME="mirbase12"
SRC="src/micropred/691-pre-miRNAs.fasta"
CLS="1"
SPECIES=""
gen_dataset

echo "Dataset other-ncrna: other ncRNAs compiled by microPred authors"
NAME="other-ncrna"
SRC="src/micropred/754-other-ncRNAs-fix.fasta"
CLS="-1"
SPECIES="-s ncrna"
gen_dataset

echo "Dataset mirbase20: miRNAs from miRBase 20"
NAME="mirbase20"
SRC="src/mirbase/20/hairpin.fa.gz"
CLS="1"
SPECIES=""
gen_dataset

echo "Cleaning aux files.."
rm -f work/*.*

echo "Moving directories to data/"
rm -rf mirbase50 coding updated conserved-hairpin
rm -rf mirbase82-nr functional-ncrna mirbase12 other-ncrna
rm -rf mirbase20

mv -f work/* .

echo "Done!"
