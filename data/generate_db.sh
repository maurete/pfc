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

gen_dataset () {
    zcat -f $SRC | ./tests.py rnafold_clean $EXTRAOPTS > work/$NAME.clean
    $RNAFOLD < work/$NAME.clean > work/$NAME.rnafold
    mkdir -p work/$NAME
    ./feats.py by_species work/$NAME.rnafold -o work/$NAME -c $CLS $SPECIES
}

gen_nr_dataset () {
    zcat -f $SRC | ./tests.py rnafold_clean $EXTRAOPTS > work/$NAME.clean
    $CDHIT -i work/$NAME.clean -o work/$NAME.nr
    $RNAFOLD < work/$NAME.nr > work/$NAME.rnafold
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

echo "Dataset conserved-hairpin: mostly-pseudo miRNA tst set as in Triplet-SVM"
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

echo "Dataset mirbase12-nr: miRNAs from miRBase 12.0 as in (microPred,) MiRenSVM"
NAME="mirbase12-nr"
SRC="src/mirbase/12.0/hairpin.fa.gz"
CLS="1"
SPECIES=""
gen_nr_dataset

echo "Dataset 3utr: pseudo hairpins from 3'-UTRdb as in MiRenSVM"
EXTRAOPTS="-m 70 -M 150"
NAME="3utrdb"
SRC="src/3utrdb/3UTRef.Homo_sapiens.fasta.gz"
CLS="-1"
SPECIES="-s hsa"
gen_nr_dataset
NAME="3utrdb"
SRC="src/3utrdb/3UTRef.Anopheles_gambiae_str._PEST.fasta.gz"
CLS="-1"
SPECIES="-s aga"
gen_nr_dataset
EXTRAOPTS=""

echo "Dataset rfam91: pseudo hairpins for aga from Rfam9.1 as in MiRenSVM"
NAME="rfam91"
SRC="src/mirensvm/rfam91-aga.fa"
CLS="-1"
SPECIES="-s aga"
gen_dataset

EXTRAOPTS="-M 500"
echo "Dataset mirbag-real-train: real train pre-miRNAs as in MiR-BAG"
NAME="mirbag-real-train"
SRC="src/mirbag/*-train-real.fa"
CLS="1"
SPECIES=""
gen_dataset

echo "Dataset mirbag-real-test: real test pre-miRNAs as in MiR-BAG"
NAME="mirbag-real-test"
SRC="src/mirbag/*-test-real.fa"
CLS="1"
SPECIES=""
gen_dataset

echo "Dataset mirbag-pseudo-train: pseudo train hairpins as in MiR-BAG"
NAME="mirbag-pseudo-train"
CLS="-1"
for SP in hsa cfa rno mmu cel dme
do
    SRC="src/mirbag/${SP}-train-pseudo.fa"
    SPECIES="-s ${SP}"
    gen_dataset
done

echo "Dataset mirbag-pseudo-test: pseudo test hairpins as in MiR-BAG"
NAME="mirbag-pseudo-test"
CLS="-1"
for SP in hsa cfa rno mmu cel dme
do
    SRC="src/mirbag/${SP}-test-pseudo.fa"
    SPECIES="-s ${SP}"
    gen_dataset
done
EXTRAOPTS=""

echo "Dataset mirbase20: miRNAs from miRBase 20"
NAME="mirbase20"
SRC="src/mirbase/20/hairpin.fa.gz"
CLS="1"
SPECIES=""
gen_dataset

echo "Dataset mirbase20-nr: miRNAs from miRBase 20+CD-HIT"
NAME="mirbase20-nr"
SRC="src/mirbase/20/hairpin.fa.gz"
CLS="1"
SPECIES=""
gen_nr_dataset

echo "Cleaning aux files.."
rm -f work/*.*

echo "Moving directories to data/"
rm -rf mirbase50 coding updated conserved-hairpin
rm -rf mirbase82-nr functional-ncrna mirbase12 other-ncrna
rm -rf mirbase20 mirbase20-nr mirbase12-nr 3utrdb rfam91
rm -rf mirbag-real-test mirbag-real-train 
rm -rf mirbag-pseudo-test mirbag-pseudo-train

mv -f work/* .

echo "Done!"
