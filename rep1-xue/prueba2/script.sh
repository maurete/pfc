#!/usr/bin/env bash
#
echo -e "script para replicar procedimiento de Xue et al. Plego con RNAfold\n\n"
#
ln -fs ../fautil .
#
echo -e "0. copio datos de miRNAS a hairpin.fa"
cat ../original/1_download_pre-miRNAs_from_miRNA_registry/hairpin.fa > 1-hairpin.fa
#
echo -e "1. calculo plegados de hairpin, filtro los que no son humanos a 2-hsa-folded.fa"
cat 1-hairpin.fa | RNAfold --noPS | egrep -i -A2 "^>hsa-" > 2-hsa-folded.fa
#
echo -e "2. guardo entradas sigle-looped en 3-hsa-single-loop.fa"
./fautil strip < 2-hsa-folded.fa > 3-hsa-single-loop.fa
#
echo -e "3. copio datos random, elimino multiloop, guardo en 3-random-single-loop.fa"
cat ../original/4_pseudo_miRNAs/8494_hairpins_over_fe_15_bp_18_from_cds.txt | ./fautil strip > 3-random-single-loop.fa
#
echo -e "4. particiono hsa-single-loop en hsa-train (long. 163) y hsa-test (long. 30)"
./fautil part 3-hsa-single-loop.fa -s1 163 -s2 30 -1 4-hsa-train.fa -2 4-hsa-test.fa
#
echo -e "5. particiono random-single-loop en random-train (long. 168) y random-test (long. 1000)"
./fautil part 3-random-single-loop.fa -s1 168 -s2 1000 -1 4-random-train.fa -2 4-random-test.fa
#
#
echo -e "6. convierto hsa-train, hsa-test, random-train, random-test a formato svm"
./fautil svm 4-hsa-train.fa -l 1 > 5-hsa-train.svm
./fautil svm 4-random-train.fa -l -1 > 5-random-train.svm
./fautil svm 4-random-test.fa -l -1 > 5-random-test.svm
./fautil svm 4-hsa-test.fa -l 1 > 5-hsa-test.svm
#
echo -e "7. concateno conjunto de train"
cat 5*train.svm >  6-train.svm
#
echo -e "8. escalo train a train-scaled. guardo parametros de escalado"
svm-scale -s 7-svm-scale 6-train.svm > 7-train-scaled.svm
#
#echo -e "9. concateno conjunto de test"
#cat 5*test.svm >  6-test.svm
#
echo -e "9. escalo hsa-test a hsa-test-scaled usando params del punto 7"
svm-scale -r 7-svm-scale 5-hsa-test.svm > 7-hsa-test-scaled.svm
#
echo -e "10.escalo random-test a random-test-scaled usando params del punto 7"
svm-scale -r 7-svm-scale 5-random-test.svm > 7-random-test-scaled.svm
#
echo -e "11.entreno con svm-easy"
svm-easy 7-train-scaled.svm
# Scaling training data...
# Cross validation...
# Best c=512.0, g=0.0001220703125 CV rate=91.2387
# Training...
# Output model: 7-train-scaled.svm.model
#
echo -e "12.valido con svm-predict (miRNAs REALES):"
svm-predict 7-hsa-test-scaled.svm 7-train-scaled.svm.model 8-hsa-test-results.svm
# Accuracy = 92.7184% (955/1030) (classification)
echo -e "13.valido con svm-predict (PSEUDO miRNAs):"
svm-predict 7-random-test-scaled.svm 7-train-scaled.svm.model 8-random-test-results.svm
















