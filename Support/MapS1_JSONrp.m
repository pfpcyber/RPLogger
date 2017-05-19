function [ Config] = MapS1_JSONrp( S1, Config)
% Maps S1 structure back to JSON format.




% S1.P2Scan.configFilePath = [ConfigFilePath];
% S1.P2Scan.configChanged = 0;
% S1.P2Scan.workingDirectory = pwd;
% %S1.P2Scan.sampleRates = [1000, 500, 250, 125, 62.5 10 5 1 .5 .1 .001];
% S1.P2Scan.VerticalRangeDefaults = [.01 .02 .05, .100, .200, .500, 1, 2, 5, 10, 20]; 


%% pMon

Config.rp_capture.ipaddress = S1.pMon.IPAddress;
Config.rp_capture.port = S1.pMon.Port;
Config.rp_capture.proto = S1.pMon.Proto;



%% Capture

Config.rp_capture.TraceLength = S1.Capture.TraceLength;
Config.rp_capture.SampleFreq = S1.Capture.SampleFreq;
Config.rp_capture.DataChannel = S1.Capture.DataChannel;
Config.rp_capture.VerticalRange = S1.Capture.VerticalRange;
Config.rp_capture.Gain = S1.Capture.Gain;


%% Trigger
Config.rp_capture.TriggerEnable = S1.Trigger.TriggerEnable;
Config.rp_capture.TriggerSource = S1.Trigger.TriggerSource;
Config.rp_capture.TriggerSlope = S1.Trigger.TriggerSlope;
Config.rp_capture.TriggerLevel = S1.Trigger.TriggerLevel;
Config.rp_capture.TriggerPosition = S1.Trigger.TriggerPosition;
Config.rp_capture.TriggerConfig = S1.Trigger.Config;
 Config.rp_capture.TriggerHysteresis = S1.Trigger.TriggerHysteresis;



%% DataCollectionParams
Config.daq_global.NumTraces = S1.DataCollectionParams.NumTraces;
Config.daq_global.NumStates = S1.DataCollectionParams.NumStates;

%% DataPaths
S1.Paths.DataStore = Config.daq_global.DataPath;
S1.Paths.SigMF = Config.daq_global.InitialSigMF;
        
end

