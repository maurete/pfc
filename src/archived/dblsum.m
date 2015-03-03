function z = dblsum(sig, set1, set2)

    K = @(sig,x,y) exp((-norm(x-y)^2)/(2*sig^2));
    
    z = 0;
    for i = 1:size(set1,1)
        for j = 1:size(set2,1)
            z = z + K(sig, set1(i,:), set2(j,:));
        end
    end
end
