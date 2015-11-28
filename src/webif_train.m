function out = webif_train (positives,negatives,classifier,featureset,method)
%WEBIF_TRAIN Train-only method for use with Webdemo-Builder
%
%  This function is a wrapper to WEBIF where only POSITIVES, NEGATIVES,
%  CLASSIFIER, FEATURESET and METHOD input parameters are accepted.
%
%  See also WEBIF.
%

    out = webif(classifier,featureset,method,positives,negatives,'','','');

end
