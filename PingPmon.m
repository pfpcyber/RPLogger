function PingPmon(pmon)
global USE_LIBPIQ_MEX;

% mex/prod mode, let dev in matlab not ping everything/mess with open terminals
if ispc && (isdeployed )|| all(USE_LIBPIQ_MEX)
    % take the ip and ping whatever is passed in
    % invalid IPs will be pinged until KillPing() is called
    ip = pmon.S1.pMon.IPAddress;
    %fprintf('%s\n',ip);
    setenv('P2PINGADDR', ip);
    system('start /MIN /B "P2SCAN ping" ping %P2PINGADDR% -t');
end
