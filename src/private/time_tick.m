function out = time_tick(in,count)
% tick timer
out.begintime = in.begintime;
out.count = in.count + count;
out.time  = round(etime(clock,in.begintime));
fprintf( '> time\t\t%02d:%02d\n', floor(out.time/60), mod(out.time,60))
