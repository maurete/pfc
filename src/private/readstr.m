function out = readstr(str)
    s = '0123456789abcdef';
    tmpname = s(ceil(rand(1,20)*16));
    fh = fopen([tmpname,'.base64'],'w');
    fprintf(fh,'%s',str);
    fclose(fh);
    [status] = system(['base64 -d < ',tmpname,'.base64 > ',tmpname,'.mat']);
    load(tmpname);
    out=variable_to_be_saved;
    delete([tmpname,'.mat']);
    delete([tmpname,'.base64']);
end
