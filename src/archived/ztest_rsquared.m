function ztest_rsquared

    function y = normalize(x)
        y = x-min(x(:));
        y = y ./ max(y(:));
    end

    % sample "kernels"
    [X,Y] = meshgrid(-8:.5:8);
    R = sqrt(X.^2 + Y.^2) + eps;
    sinc = sin(R)./R;
    load('penny.mat','P');
    com = common;
    xuetrain = load_data('xue');
    xuedata = com.stshuffle(5667, [xuetrain.real; xuetrain.pseudo]);

    kernel_r = (normalize(R)+eye(size(R,1)))./2;
    kernel_sinc = normalize(sinc+eye(size(sinc,1)));
    kernel_penny = (normalize(P)+eye(size(P,1)))./2;
    kernel_xuerbf = kernel_rbf(xuedata(:,1:66),xuedata(:,1:66));
    kernel_xuelin = kernel_linear(xuedata(:,1:66),xuedata(:,1:66));

    fprintf('kernel_r\n')
    kcur = kernel_r;
    [rsq b] = Rsquared(kcur,Inf)
    [rsq2 b2] = Rsquared2(kcur)
    [rsqac bac] = Rsquared_AC(kcur,Inf)

    fprintf('kernel_sinc\n')
    kcur = kernel_sinc;
    [rsq b] = Rsquared(kcur,Inf)
    [rsq2 b2] = Rsquared2(kcur)
    [rsqac bac] = Rsquared_AC(kcur,Inf)

    fprintf('kernel_penny\n')
    kcur = kernel_penny;
    [rsq b] = Rsquared(kcur,Inf)
    [rsq2 b2] = Rsquared2(kcur)
    [rsqac bac] = Rsquared_AC(kcur,Inf)

    fprintf('kernel_xuerbf\n')
    kcur = kernel_xuerbf;
    [rsq b] = Rsquared(kcur,Inf)
    [rsq2 b2] = Rsquared2(kcur)
    [rsqac bac] = Rsquared_AC(kcur,Inf)

    fprintf('kernel_xuelin\n')
    kcur = kernel_xuelin;
    [rsq b] = Rsquared(kcur,Inf)
    [rsq2 b2] = Rsquared2(kcur)
    [rsqac bac] = Rsquared_AC(kcur,Inf)

    % figure;
    % mesh(kernel_r);
    % figure;
    % mesh(kernel_sinc);
    % figure;
    % mesh(kernel_penny);
    % figure;
    % mesh(kernel_xuerbf);
    % figure;
    % mesh(kernel_xuelin);


end