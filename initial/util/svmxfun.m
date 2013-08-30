function res=svmxfun(trndata,trnlabs,tstdata,rbf_sigma,boxconstraint)
svmStruct = svmtrain(trndata,trnlabs,'Kernel_Function','rbf', ...
                     'rbf_sigma',rbf_sigma,'boxconstraint',boxconstraint);
save('__svm__struct__.mat','-struct','svmStruct');
res=svmclassify(svmStruct,tstdata);
