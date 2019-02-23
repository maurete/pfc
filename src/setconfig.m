function setconfig(key, value, quote, change)
%SETCONFIG set configuration option
%
%  SETCONFIG(KEY,VALUE,QUOTE,CHANGE) edits the config.m file and sets
%  the configuration option KEY to VALUE.
%  KEY is the name of the variable to set in the config.m file.
%  VALUE is the value to assign to the variable given by KEY.
%  QUOTE determines wether VALUE should be quoted in the config.m
%  file: if set to true, VALUE will be quoted; if unset or empty,
%  the function will try its best to guess wether the value should be
%  quoted or not.
%  CHANGE indicates wether a pre-existing value should be changed:
%  if set to false, value won't be set when key already exists.
%

    % set default (true) value for change
    if nargin < 4 || isempty(change),change=true;end

    % try to guess wether value should be quoted
    if nargin < 3 || isempty(quote),quote=false;
        try,if ischar(value),quote=true;end,end
    end

    lines = {};

    % Read config.m
    fid = fopen('config.m','r');
    if fid >= 0
        i = 1;
        fline = fgetl(fid);
        lines{i} = fline;
        while ischar(fline)
            i = i+1;
            fline = fgetl(fid);
            lines{i} = fline;
        end
        fclose(fid);
    end

    match=max([1,numel(lines)]);
    % match relevant line
    for i=1:numel(lines)-1
        if regexp(lines{i},sprintf('^\\s*%s\\s*=.*$',key))
            match = i;
            if ~change,return,end
            break
        end
    end

    % modify line
    if quote, lines{match} = sprintf('%s = ''%s'';',key,value);
    else, lines{match} = sprintf('%s = %g;',key,value);
    end

    % save file
    fid = fopen('config.m', 'w');
    for i = 1:numel(lines)
        if lines{i} == -1,break,end
        fprintf(fid,'%s\n', char(lines{i}));
    end
    fclose(fid);

    % validate by calling config.m file
    config;
end
