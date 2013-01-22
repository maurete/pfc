function z = genpat2d ( )
  z = [];
  while size(z)(1) < 1000
    p = rand(1,2)*2 - 1;
    r = 2*meansq(p);
    if r < 0.5
      z = [ z; p 1 ];
    elseif r > 0.7
	z = [ z; p 2 ];
    endif
  endwhile
endfunction
