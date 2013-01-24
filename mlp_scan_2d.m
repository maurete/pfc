function mlp_scan_2d ( mlp, x = [-2 2] , y = [-2 2], res=0.2 )

  noutputs = mlp{1,1}(end);

  classes = eye(noutputs);

  curx = x(1);
  cury = y(1);

  p = [];

  while curx <= x(2)
    cury = y(1);
    while cury <= y(2)

      output = mlp_eval( mlp, [curx; cury]);
      p = [p; curx cury binv2dec(output>0.5) ];

      cury=cury+res;
    endwhile
    curx = curx+res;
  endwhile

  figure;
  markers = ".+*ox^.+*ox";
  color = max( rainbow(max(p(:,3)+1))-0.3, 0);
  scatter(p(:,1), p(:,2), res*120, color(p(:,3).+1,:))

endfunction
