function print_test_info(test_info)
    fprintf('# test results\n')
    fprintf('> SE %8.6f\tSP %8.6f\tGm %8.6f\n',test_info.se, test_info.sp, test_info.gm)
end
