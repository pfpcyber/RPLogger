function [ rc  ] = errorCheckRP( config )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


rc = 0;
ConfigFields = {'daq_global','rp_capture','Pico3406D_capture'};
daq_globalFields = {'DataPath','InitialSigMF','NumTraces','NumStates','EnableDAQDevice'};
rp_captureFields = {'ipaddress','port', 'proto','TraceLength','SampleFreq',...
    'DataChannel','VerticalRange','Gain','TriggerEnable',...
    'TriggerSource','TriggerLevel','TriggerPosition',...
    'TriggerConfig','TriggerHysteresis'};


errorStr = '';
errorStr1 = '';
warnStr = '';
%% daq_globals
NotFields = ~isfield(config, ConfigFields);
try
    if sum(NotFields) ~= 0
        BadFieldsIdx = find(NotFields);
        errorStr = sprintf('%s\n\n%s',errorStr,'One or more missing/incorrect objects in:');
        errorStr1 = '';
        for idx = 1:length(BadFieldsIdx)
            errorStr1 = sprintf('%s\n%s',errorStr1,ConfigFields{BadFieldsIdx(idx)});
        end
    end
    if ~isempty(errorStr)
        errorStr = sprintf('%s\n%s\n%s','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr,errorStr1);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
        errorStr1 = '';
    end
catch err
    rc = 1;
    uiwait(msgbox(err.message));
end



%% daq_global fields
NotFields = ~isfield(config.daq_global, daq_globalFields);
try
    if sum(NotFields) ~= 0
        BadFieldsIdx = find(NotFields);
        errorStr = sprintf('%s\n\n%s',errorStr,'One or more missing/incorrect fields in daq_global:');
        errorStr1 = '';
        for idx = 1:length(BadFieldsIdx)
            errorStr1 = sprintf('%s\n%s',errorStr1,daq_globalFields{BadFieldsIdx(idx)});
        end
    end
    if ~isempty(errorStr)
        errorStr = sprintf('\n%s\n%s\n%s','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr,errorStr1);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
        errorStr1 = '';
    end
catch err
    rc = 1;
    uiwait(msgbox(err.message));
end

%% rp_capture Fields
NotFields = ~isfield(config.rp_capture, rp_captureFields);
try
    if sum(NotFields) ~= 0
        BadFieldsIdx = find(NotFields);
        errorStr = sprintf('%s\n\n%s',errorStr,'One or more missing/incorrect fields in RPD_capture:');
        errorStr1 = '';
        for idx = 1:length(BadFieldsIdx)
            errorStr1 = sprintf('%s\n%s',errorStr1,rp_captureFields{BadFieldsIdx(idx)});
        end
    end
    if ~isempty(errorStr)
        errorStr = sprintf('%s\n%s\n%s','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr,errorStr1);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
        errorStr1 = '';
    end
catch err
    rc = 1;
    uiwait(msgbox(err.message));
end

% ********** Checking of Fields is complete ************

% ********** Check the values of Fields in daq_global *********
try
    %% daq_globals Field Values
    FieldValue = config.daq_global.DataPath;
    if strcmp(FieldValue,'/') || strcmp(FieldValue(1),'\')
        errorStr = sprintf('%s\n\n%s\n',errorStr,'Invalid entry daq_global.Datapath','Invalid Path format. Must begin with [Drive]:/');
    else
        [status,mess,messid] = mkdir(FieldValue);
        if status  == 0
            errorStr = sprintf('%s\n\n%s\n',errorStr,'Invalid entry daq_global.Datapath','Cannot create directory. Check path.');
        end
    end
    
    FieldValue = config.daq_global.InitialSigMF;
    if strcmp(FieldValue,'/') || strcmp(FieldValue(1),'\')
        errorStr = sprintf('%s\n\n%s\n',errorStr,'Invalid entry daq_global.InitialSigMF','Invalid Path format. Must begin with [Drive]:/');
    elseif exist(config.daq_global.InitialSigMF, 'file') ~= 2
        errorStr = sprintf('%s\n\n%s\n',errorStr,'No file found in daq_global.InitialSigMF','. Check path and file.');
    end
    
    FieldValue = config.daq_global.NumTraces;
    if (FieldValue <= 0) || (FieldValue < 50) 
        warnStr = sprintf('%s\n\n%s\n',errorStr,'Number of Traces should be large for Training');
    end
    
    FieldValue = config.daq_global.NumStates;
    if (FieldValue <= 0)
        errorStr = sprintf('%s\n\n%s\n',errorStr,'Number of Traces has to be larger than 0');
    end
       
    if ~isempty(errorStr)
        errorStr = sprintf('%s\n%s\n','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
    end
    if ~isempty(warnStr)
        warnStr = sprintf('%s\n%s\n','**** Warning ****',warnStr);
        uiwait(msgbox(warnStr,'modal'));
        warnStr = '';
    end

catch err
    rc = 1;
    uiwait(msgbox(err.message));
    errorStr = '';
end
% ********** End of checking the values of Fields in daq_global *********


%% *************** Check Values in rp_capture

try
    %% RP Field Values
    
    % Check ipaddress value
    FieldValue = config.rp_capture.ipaddress;
    if ~ischar(config.rp_capture.ipaddress) || isempty(regexp(config.rp_capture.ipaddress, '^(?:\d{1,3}\.){3}\d{1,3}$', 'match'))
        errorStr = sprintf('%s%s%s\n',errorStr,'Invalid entry for ipaddress: ', config.rp_capture.ipaddress);
    end
%     if max(cellfun(@(x)str2num(x), strsplit(S1.pMon.IPAddress, '.'))) > 255
%         errorStr = sprintf('%s%s',errorStr,'Invalid entry for [eMon]:IPAddress: %s. Value can not exceed 255.', S1.pMon.IPAddress));
%         throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
%     end
    
   
    % Port
    FieldValue = config.rp_capture.port;
    if ~(FieldValue >= 7001) || ~(FieldValue <= 65535)
        errorStr = sprintf('%s\n%s',errorStr,'Invalid rp_capture.port');
    end 
    
    % Check protocol
    FieldValue = config.rp_capture.proto;
    if FieldValue ~= 'tcp'
        errorStr = sprintf('%s\n%s',errorStr,'Invalid rp_capture.proto');
    end 
    

   % Check Trace Length
    FieldValue = config.rp_capture.TraceLength;
    if rem(FieldValue,1) ~= 0
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TraceLength must be an integer');
    end
    if (FieldValue <= 0) || (FieldValue > 50e6)
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TraceLength must be between 1-50e6.');
    end
    
    % Check Sample rate 
    FieldValue = config.rp_capture.SampleFreq;
    valid_freq = [125e6 62.5e6 31.25e6 15.625e6 7.8125e6 3.90625e6 1.953125e6 0.9765625e6 30518 15259 7629 3815 1907 954];
    [idx, valid] = get_closest(valid_freq, config.rp_capture.SampleFreq);
    
    if (~valid)
        errorStr = sprintf(['%s\n%s\n%.4g, %.4g, %.4g, %.4g,\n',...
            '%.4g, %.4g, %.4g, %.4g,\n%.4g %.4g, %.4g %.4g,\n%.4g ,%.4g\n'],...
            errorStr,'rp_capture.SampleFreq must be:', valid_freq)
    end 
  
    if ~isempty(errorStr)
        errorStr = sprintf('%s\n%s\n\n%s','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
    end
catch err
    rc = 1;
    uiwait(msgbox(err.message));
end


%% Check Data Channel, Vertical Range, Vertical coupling, gain
try
    % Check Trace Length
    FieldValue = config.rp_capture.DataChannel;
    if  FieldValue ~= 0
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.DataChannel must be 0');
    end
    
    % Check gain
    FieldValue = config.rp_capture.Gain;
    if ~isequal(FieldValue,0) && ~isequal(FieldValue,1)
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.Gain must be 0 or 1');
    end
    
    % Vertical Range value check for Channel 0 based on gain setting
    FieldValue = config.rp_capture.VerticalRange;
    if isequal(config.rp_capture.Gain,0)
        if ~isequal(FieldValue,1)
            errorStr = sprintf('%s%s\n',errorStr,'rp_capture.VerticalRange must be 1 for gain setting 0');
        end
    elseif isequal(config.rp_capture.Gain,1)
        if ~isequal(FieldValue,20)
            errorStr = sprintf('%s%s\n',errorStr,'rp_capture.VerticalRange must be 20 for gain setting 1');
        end
    end
    
   
    if ~isempty(errorStr)
        errorStr = sprintf('%s\n%s\n\n%s','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
    end
    
catch err
    rc = 1;
    uiwait(msgbox(err.message));
end


%% Check Trigger Settings
try
    % Check
    FieldValue = config.rp_capture.TriggerEnable;
    if ~isequal(FieldValue,true) && ~isequal(FieldValue,false)
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TriggerEnable must be True or False');
    end
    
    FieldValue = config.rp_capture.TriggerSource;
    if ~ismember(FieldValue,[1 2])
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TriggerSource must be between 1-2');
    end
    

    FieldValue = config.rp_capture.TriggerSlope;
    if ~ismember(FieldValue,[0 1 2 3 4])
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TriggerSlope must be between 0-4');
    end
    
    FieldValue = config.rp_capture.TriggerLevel;
    if ~(FieldValue >= -config.rp_capture.VerticalRange) && ~(FieldValue <= config.rp_capture.VerticalRange)
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TriggerLevel out of range ');
    end
        
    FieldValue = config.rp_capture.TriggerPosition;
    if ~(FieldValue >= 0) && (FieldValue <= 50)
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TriggerPosition must be between 0-50');
    end
    
    FieldValue = config.rp_capture.TriggerHysteresis;
    if ~(FieldValue >= 0) && (FieldValue <= config.rp_capture.VerticalRange)
        errorStr = sprintf('%s%s\n',errorStr,'rp_capture.TriggerPosition must be between 0-Vertical Range');
    end

    if ~isempty(errorStr)
        errorStr = sprintf('%s\n%s\n\n%s','The following errors were found in the configuration file.','After correcting, please relaunch.',errorStr);
        uiwait(msgbox(errorStr,'modal'));
        errorStr = '';
    end

catch err
    rc = 1;
    uiwait(msgbox(err.message));
    errorStr = '';
end






