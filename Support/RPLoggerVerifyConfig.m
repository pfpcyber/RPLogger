function [S1, success] = RPLoggerVerifyConfig(S1, suppress_error)
%VERIFYCONFIG Verifies configuration and optionally displays an error message.
%   [S1, success] = VERIFYCONFIG(S1, suppress_error) checks all parameters
%   and displays an error message if there are any issues. Set 'suppress_error'
%   to 0 (or omit) to suppress the error message from being displayed.
%
%   If there are any errors, an error message is stored in the global
%   variable 'errorStr'.
%
%   Note, VERIFYCONFIG may optionally modify the provided configuration, so
%   the caller should store the returned configuration. The result of the
%   check is stored in 'success'.


global errorStr

success = true;
errorStr = blanks(0);
persistent dataTypes
if isempty(dataTypes)
    dataTypes = LoadDataTypes('dataTypes.txt');
end
S1.P2Scan.dataTypes = dataTypes;

if (nargin < 2 || isempty(suppress_error))
    suppress_error = 0;
end

try
    
    % [pMon]
    if ~ischar(S1.pMon.IPAddress) || isempty(regexp(S1.pMon.IPAddress, '^(?:\d{1,3}\.){3}\d{1,3}$', 'match'))
        appendErr(sprintf('Invalid entry for [eMon]:IPAddress: %s', S1.pMon.IPAddress));
        throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
    end
    if max(cellfun(@(x)str2num(x), strsplit(S1.pMon.IPAddress, '.'))) > 255
        appendErr(sprintf('Invalid entry for [eMon]:IPAddress: %s. Value can not exceed 255.', S1.pMon.IPAddress));
        throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
    end
    if isdeployed
        S1 = checkRange(S1, 'pMon', 'Port', 7001, 7001);
        checkValid(S1, 'pMon', 'Proto', { 'tcp'}, { 'tcp = TCP/IP' });
    else
        S1 = checkRange(S1, 'pMon', 'Port', 1000, 65535);
        checkValid(S1, 'pMon', 'Proto', { 'tcp', 'udp' }, { 'tcp = TCP/IP', 'udp = UDP' });
    end
    S1.pMon.Proto = 'tcp'; % we don't support UDP yet.

    S1 = verifyRedPitaya(S1);
    % [Capture]
    S1 = checkRange(S1, 'Capture', 'TraceLength', 0, realmax);
    % Other scope-specific parameters checked separately.
    
    % [Trigger]
    checkBool(S1, 'Trigger', 'TriggerEnable');
    checkValid(S1, 'Trigger', 'TriggerSlope', 0:4, ...
        {'0: Above','1: Below','2: Rising','3: Falling', '4: Rising or Falling'});
    % TriggerSource checked by scope-specific function
    % TriggerCoupling checked by scope-specific function
    S1 = checkRange(S1, 'Trigger', 'TriggerLevel', -S1.Capture.VerticalRange, S1.Capture.VerticalRange);
    if ~isfield(S1.Trigger, 'TriggerHysteresis')
        S1.Trigger.TriggerHysteresis = abs(0.05*S1.Trigger.TriggerLevel);
    end
    S1 = checkRange(S1, 'Trigger', 'TriggerHysteresis', 0, S1.Capture.VerticalRange);
    S1 = checkRange(S1, 'Trigger', 'TriggerPosition', 0, 50);
    % TriggerTimeoutms checked by scope-specific function
    % TriggerConfig checked by scope-specific function
    % AutoTriggerTimeoutms checked by scope-specific function
    
    % [Paths]
    names = fieldnames(S1.DataPaths);
    for i=1:length(names)
        S1.Paths.(names{i}) = checkPath(S1, 'DataPaths', names{i});
    end
    
    
catch err
    success = false;
    if (~strcmp(err.identifier, 'VerifyConfig:BadValue'))
        uiwait(msgbox(err.message));
    elseif (~suppress_error)
        showErr();
    end
end





%% RedPitaya specific settings
function S1 = verifyRedPitaya(S1)
msg = 'for Red Pitaya';
valid_freq = [125e6 62.5e6 31.25e6 15.625e6 7.8125e6 3.90625e6 1.953125e6 0.9765625e6 30518 15259 7629 3815 1907 954];
[idx, valid] = get_closest(valid_freq, S1.Capture.SampleFreq);
if (~valid)
    labels = cellfun(@(x) freq2Str(x), num2cell(valid_freq), 'UniformOutput', false);
    checkValid(S1, 'Capture', 'SampleFreq' , valid_freq, labels, msg); % check not needed, just error printing...
else
    S1.Capture.SampleFreq = valid_freq(idx);
end

checkValid(S1, 'Capture', 'DataChannel'  , [0 1],   {'0: Channel A','1: Channel B'}, msg);
checkValid(S1, 'Capture', 'Gain'         , [0 1],   {'0: LV','1: HV'}, msg);
checkValid(S1, 'Trigger', 'TriggerSource', [1:7,9], {'1: Software', '2: Ch A Rising', '3: Ch A Falling', ...
    '4: Ch B Rising', '5: Ch B Falling', '6: Ext Rising', '7: Ext Falling', ...
    '9: Custom'}, msg);

if (S1.Capture.Gain == 0)
    S1.Capture.VerticalRange = 1;  % �1V; 2V p-p
else
    S1.Capture.VerticalRange = 20; % �20V, 40V p-p
end

% Custom trigger
if (S1.Trigger.TriggerSource == 9)
    if (checkReq(S1, 'Trigger', 'TriggerConfig') && ~exist(S1.Trigger.TriggerConfig, 'file'))
        appendErr(sprintf('Invalid entry [Trigger]:TriggerConfig\nThe custom trigger config file ''%s'' doesn''t exist.', ...
            S1.Trigger.TriggerConfig));
    end
end


function appendErr(msg)
global errorStr;
errorStr = sprintf('%s\n\n%s', errorStr, msg);


function success = checkReq(S1, fieldname, subfieldname)
success = true;
if ~isfield(S1, fieldname) || ~isfield(S1.(fieldname), subfieldname)
    appendErr(sprintf('Missing field [%s]:%s', fieldname, subfieldname));
    success = false;
end


function checkValid(S1, fieldname, subfieldname, values, values_str, msg)
if (nargin < 5 || isempty(values_str))
    values_str = cellstr(num2str(values(:)));
    values_str = regexprep(values_str, '^\s+|\s+$', '');
elseif ~iscell(values_str)
    error('values_str must be a cell array of strings.')
end

if (nargin < 6 || isempty(msg))
    msg = '';
else
    msg = [msg ' '];
end

if ((isreal(values) && ~any(S1.(fieldname).(subfieldname) == values)) || ...
        (iscell(values) && ~any(cellfun(@(x) strcmpi(x, S1.(fieldname).(subfieldname)), values))))
    txt = sprintf('Invalid entry for [%s]:%s\n\nValid Entries %sare:\n', ...
        fieldname, subfieldname, msg);
    for i=1:min(length(values_str), length(values))
        txt = sprintf('%s%s\n', txt, values_str{i});
    end
    appendErr(txt);
    throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
end

function path = checkPath(S1, fieldname, subfieldname)
path = S1.(fieldname).(subfieldname);
path = strrep(path, '\', '/');
folder = path;
if (~isempty(regexp(folder, '\.\w+$', 'match')))
    folder = fileparts(folder);
end

if isempty(folder)
    appendErr(sprintf('[DataPaths]:%s is empty.', subfieldname));
    throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
elseif ~exist(folder, 'dir') && ~mkdir(folder)
    appendErr(sprintf(['Invalid entry for [Datapaths]:%s.' ...
        '\nFailed to create path %s'], subfieldname, path));
    throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
end


function checkBool(S1, fieldname, subfieldname)
checkValid(S1, fieldname, subfieldname, 0:1, {'0: false', '1: true'});


function S1 = checkRange(S1, fieldname, subfieldname, low, high)
S1 = CheckType(S1, fieldname, subfieldname);
val = S1.(fieldname).(subfieldname);
if ~isnumeric(val) || ~all(val >= low & val <= high)
    if (isscalar(val))
        pre = 'The value';
    else
        pre = 'All values';
    end
    msg = sprintf('Invalid entry for [%s]:%s\n%s must be', ...
        fieldname, subfieldname, pre);
    if (high == realmax)
        appendErr(sprintf('%s must be >= %.0f.', msg, low));
    elseif (low == -realmax)
        appendErr(sprintf('%s must be <= %.0f.', msg, high));
    else
        appendErr(sprintf('%s must be between %.0f and %.0f.', msg, low, high));
    end
    throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
end

function str = freq2Str(freq)
mhz = freq/1e6;
if (mhz > 0.95)
    str = sprintf('%g MHz', mhz);
    return;
end

khz = freq/1e3;
if (khz > 0.95)
    str = sprintf('%g KHz', khz);
else
    str = sprintg('%g Hz', freq);
end

function showErr()
global errorStr
errorStr = regexprep(errorStr, '^[\s\n]+', '');

uiwait(errordlg(errorStr, 'Errors in Configuration.', 'modal'));
errorStr = blanks(0);
