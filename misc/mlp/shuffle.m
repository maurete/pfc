% shuffle: randomiza filas en la matriz x
function z = shuffle( x )
  z = x(randperm(size(x)(1)),:);
endfunction
