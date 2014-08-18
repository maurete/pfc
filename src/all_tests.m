function all_tests

    ds = { 'ng-multi', 'batuwita-multi', 'xue', 'ng', 'batuwita'};
    rn = [303456; 456789; 5829]; 

    fprintf('\n >>>>> Running all single-loop tests ...\n')
    for j=3:5
        for i=1:15
            fprintf('\n >>>>>>>> dataset %s, featset %d ....\n', ds{j}, i)
            for k=1:3
                svm_lin(ds{j},i,rn(k))
                svm_rbf(ds{j},i,rn(k))
                mlp(ds{j},i,rn(k))
                mlp(ds{j},i,rn(k),1)
            end        
        end
    end

    fprintf('\n >>>>> Running all multi-loop tests ...\n')
    for j=1:2
        for i=[4 5 8]
            fprintf('\n >>>>>>>> dataset %s, featset %d ....\n', ds{j}, i)
            for k=1:3
                svm_lin(ds{j},i,rn(k))
                svm_rbf(ds{j},i,rn(k))
                mlp(ds{j},i,rn(k))
                mlp(ds{j},i,rn(k),1)
            end        
        end
    end

end