This directory contains all materials mentioned in the paper.

1: The sequences of the miRNA precursors of 12 species are downloaded from the miRNA registry (release 5.0).
2: The secondary structures of all pre-miRNA are predicted using RNAfold.
3: The miRNA examples without multiple loops are used in the paper.
4: 8494 pseudo-miRNA hairpins are as negative examples.
5: The training dataset contains 163 human pre-miRNAs and 168 pseudo-miRNA hairpins and is used to train the SVM classifier.
6: The svm model is trained by the traning dataset and is used to predict unknown hairpins by SVM classifier.
7: Test dataset contains: 30 human pre-miRNAs, 1000 pseudo-miRNA hairpins, hairpins from human chromosome 19, pre-miRNAs from 11 species and 39 updated human-specific pre-miRNAs.
8: The test data are formatted according to the input format of libsvm.
9: Prediction results of the test data.
10: The 1000 hairpins of the TE-C test: 119 pseudo-miRNA hairpins are positively recognized and 881 pseudo-miRNA hairpins are negatively recognized.
11: The 14 human miRNAs with multiple loops.

Note: There is an example shown in "triplet-svm-predictor" directory.
