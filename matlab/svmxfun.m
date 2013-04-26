function res=svmxfun(trndata,trnlabs,tstdata,rbf_sigma,boxconstraint)
svmStruct = svmtrain(trndata,trnlabs,'Kernel_Function','rbf','rbf_sigma',rbf_sigma,'boxconstraint',boxconstraint);
res=svmclassify(svmStruct,tstdata);