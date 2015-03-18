function out = get_kernel(kernel, str, exact, varargin)
% get normalized kernel name or test for specific type in str
    if nargin < 3 || isempty(exact), exact = true; end
    kstr = lower(kernel);
    % find kernel type and variant
    if strfind(kstr,'lin')
        out = 'linear';
        if strfind(kstr,'uni'), out = 'linear_uni'; end
        if strfind(kstr,'unc'), out = 'linear_unc'; end
    elseif strfind(kstr,'rbf')
        out = 'rbf';
        if strfind(kstr,'uni'), out = 'rbf_uni'; end
        if strfind(kstr,'unc'), out = 'rbf_unc'; end
    elseif strfind(kstr,'mlp')
        out = 'mlp';
    elseif strfind(kstr,'ign')
        out = '';
    else
        error('Unknown kernel selected: %s', kernel)
    end
    if nargin > 2 && ~isempty(str)
        if exact, out = strcmp(out, str);
        else out = any(strfind(str,out));
        end
    end
end
