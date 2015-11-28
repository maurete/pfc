function out = webif_test (traindata, testset, testset_class)
%WEBIF_TEST Test-only method for the web interface for use with Webdemo-Builder
%
%  This function is a wrapper to WEBIF where only PRE_TRAINED_MODEL, TEST_SET
%  and TEST_SET_CLASS input parameters are accepted.
%
%  See also WEBIF.
%

    out = webif ('', '', '', '', '', traindata, testset, testset_class);

end
