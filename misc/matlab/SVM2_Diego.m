function res=SVM2_Diego(traindata,testdata,rbfs,boxc)
% SVM1: optimized SVM
%-------------------------------------------------

trndata=traindata.data;
trnlabs = str2num(cell2mat(traindata.labels));
tstdata=testdata.data;
tstlabs = str2num(cell2mat(testdata.labels));

%% SVM optimization

%HAY QUE CORRERLA DE NUEVO con cada dataset...
if nargin<3,
    N = size(traindata.data,1);
    c = cvpartition(N,'kfold',5);
    minfn = @(z)crossval('mcr',trndata,trnlabs,'Predfun',...
                         @(trndata,trnlabs,tstdata)svmxfun(trndata,trnlabs,tstdata,...
                                                      exp(z(1)),exp(z(2))),'partition',c);

    % OJO: se usan los patrones de test para optimizar los parametros???
    opts = optimset('TolX',5e-4,'TolFun',5e-4);
 
    %for 1:10... habria que correr varios y quedarse con el mejor porque es sensible a minimos locales
    [searchmin fval] = fminsearch(minfn,randn(2,1),opts)% do not requiere Global Optimization Toolbox
    %[searchmin fval] = patternsearch(minfn,?????? randn(2,1),opts) %requiere Global Optimization Toolbox
    rbfs=searchmin(1);
    boxc=searchmin(2);
end;

%% SVM optimized
% fixex values of previous trials (see main)

%% SVM training & testing
svmStruct = svmtrain(trndata,trnlabs,'Kernel_Function','rbf',...
                     'rbf_sigma',exp(rbfs),'boxconstraint',exp(boxc));

res = svmclassify(svmStruct,testdata.data);
