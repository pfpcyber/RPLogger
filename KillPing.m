function KillPing()
global USE_LIBPIQ_MEX;

% mex/prod mode, let dev in matlab not ping everything/mess with open terminals
if ispc && (isdeployed ) || all(USE_LIBPIQ_MEX)
    % dev doesn't start admin command prompts
    % prod starts admin command prompts
    % matlab '!start' makes batch script run from cmd.exe, but cant kill admin
    % matlab system() runs with conhost.exe, windowtitle is messed up
    % killing with "WINDOWTITLE eq P2SCAN*" does not find the conhost.exe...
    % prod "Administrator: P2SCAN*" does not find the cmd.exe...

    % force kill all, horrible solution...
    [rc, msg] = system('taskkill /IM cmd.exe /F');
    %fprintf_ext('\n\nrc cmd kill: %d\nmsg: %s\n', rc, msg);
    [rc, msg] = system('taskkill /IM conhost.exe /F');
    %fprintf_ext('\nrc conhost kill: %d\nmsg: %s\n', rc, msg);
    [rc, msg] = system('taskkill /IM ping.exe /F');
    %fprintf_ext('\nrc ping kill: %d\nmsg: %s\n', rc, msg);
end
