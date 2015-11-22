function out = savestr(variable_to_be_saved)
    s = '0123456789abcdef';
    tmpname = s(ceil(rand(1,20)*16));
    save(tmpname,'variable_to_be_saved')
    [status] = system(['base64 < ',tmpname,'.mat > ',tmpname,'.base64']);
    out = fileread([tmpname,'.base64']);
    delete([tmpname,'.mat']);
    delete([tmpname,'.base64']);
end
