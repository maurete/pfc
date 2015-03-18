function print_test_info(test_info)
% print testing information to screen
fprintf('# \t\tdataset\t\tclass\tsize\tperformance\n');
fprintf('# \t\t-------\t\t-----\t----\t-----------\n');
for i=1:length(test_info)
    fprintf('+ %24s\t%d\t%d\t%8.6f\n',...
            test_info(i).name, test_info(i).class, ...
            test_info(i).size, test_info(i).rate);
end
if isfield(test_info(1),'sen_source')
    fprintf('# \n')
    fprintf('# \tSE for dataset used in training\t\t%f\n',test_info(1).sen_source);
    fprintf('# \tSP for dataset used in training\t\t%f\n',test_info(1).spe_source);
    fprintf('# \tSE for other datasets\t\t\t%f\n',test_info(1).sen_other);
    fprintf('# \tSP for other datasets\t\t\t%f\n',test_info(1).spe_other);
end
