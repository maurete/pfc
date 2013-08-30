% binv2dec: convierte el vector binario binvector en un número decimal
function d = binv2dec( binvector )
  b = reshape( binvector|0, 1, [] );
  d = bin2dec( strvcat(b+48) );
endfunction
