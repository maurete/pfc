function out = webif_train (positives, negatives, classifier, featureset, method)
    out = webif (classifier, featureset, method, positives, negatives, '', '', '');
end
