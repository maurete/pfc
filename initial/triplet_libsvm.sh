#!/usr/bin/env bash
./util/fautil.py svm --label 1 train_hsa_163.txt > __trainset.svm
./util/fautil.py svm --label -1 train_cds_168.txt >> __trainset.svm
svm-scale -s __trainset.scale __trainset.svm > __trainset_scaled.svm
svm-easy __trainset_scaled.svm
./util/fautil.py svm --label 1 test_hsa_30.txt > __testset.svm
svm-scale -r __trainset.scale __testset.svm > __testset_scaled.svm
svm-predict __testset_scaled.svm __trainset_scaled.svm.model __results_real.txt
./util/fautil.py svm --label -1 test_cds_1000.txt > __testset.svm
svm-scale -r __trainset.scale __testset.svm > __testset_scaled.svm
svm-predict __testset_scaled.svm __trainset_scaled.svm.model __results_pseudo.txt
./util/fautil.py svm --label 1 test_hsa_updated.txt > __testset.svm
svm-scale -r __trainset.scale __testset.svm > __testset_scaled.svm
svm-predict __testset_scaled.svm __trainset_scaled.svm.model __results_updated.txt
