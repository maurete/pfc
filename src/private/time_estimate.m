function time_estimate(in,count)
% estimate remaining time to achieving #count operations
    if in.count < 1; return; end
    esttime = round(in.time/in.count * (count-in.count));
    estendt = datevec(datenum(0,0,0,0,0,esttime)+now);
    fprintf('# estimated\t%dm %d\tendtime\t%02d:%02d\n', ...
            floor(esttime/60), mod(esttime,60), fix(estendt(4:5)))
end
