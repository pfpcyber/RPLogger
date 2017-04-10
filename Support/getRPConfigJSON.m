function [S1,Config] = getRPConfigJSON()
% Returns P2Scan struct S1 and the Orginial JSON Config file contents
%
% Derek Liu
% 10/28/2104

%Default to .ini files
[FileName,PathName] = uigetfile('*.json*','Select the RP Logger Configuration File');

errorStr = '';
try
    Config = jsondecode(fileread([PathName FileName]));
    errorFlag = errorCheckRP(Config);
    if errorFlag == 1
        errorStr = sprintf('%s\n','Configuration Errors in Config file');
        msgbox(errorStr,'modal');
    end
    
   
    if strcmpi(Config.daq_global.EnableDAQDevice,'RP')
        S1 = MapJSONrp_S1(Config,[PathName FileName]);
    else
        errorStr = sprintf('%s\n','RP not selected');
        msgbox(errorStr,'modal');
    end
    
    
    if ~isempty(errorStr)
        errorStr = sprintf('%s\n%s\n\n%s','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
    end
    
catch err
    uiwait(msgbox(err.message));
end



