S1 = getP2ScanConfig_CL('Router_config_2000.ini','C:\P2Scan\Configurations\');

tcpipServer = tcpip('0.0.0.0',50007,'NetworkRole','Server');
set(tcpipServer,'InputBufferSize',64);
set(tcpipServer,'Timeout',120);
set(tcpipServer,'Terminator',['';'']);
fopen(tcpipServer);
rawData = '';
S1.P2Scan.scope=tcpipServer;
%(eMonWrite(S1, [4 0 0 0 S1.Data.DataChannel S1.Trigger.eMonGain], 'int32', 'Set Gain'))
exitcode=P3_write(S1, [15], 'int32', 'penis')



exitMatrix(1:64) = 126;
exitMatrix(1) = 69;
exitMatrix(2) = 79;
exitMatrix(3) = 70;
%exitMatrix = exitMatrix';
result = '';
while(~isequaln(rawData, exitMatrix))
    rawData = fread(tcpipServer,64);
    disp(rawData);
    %fwrite(tcpipServer, rawData)
end
disp(result)
%fprintf('End\n');
fclose(tcpipServer);

