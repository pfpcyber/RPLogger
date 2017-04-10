function success = update_RPLoggerdependencies(hObject, f, value)
persistent map;

if (isempty(map))
    map = containers.Map('KeyType', 'char', 'ValueType', 'Any');
    map('Paths.UserDefinedRootPath') = @make_paths;
    map('Trigger.TriggerSource') = @on_trigger_src;
    map('Trigger.TriggerConfig') = @on_trigger_src;
    map('Capture.TraceLength') = @on_trace_length;
    map('Capture.*') = @on_capture;
    map('Trigger.*') = @on_trigger;
    setappdata(0, 'callbacks_map', map);
end

data = get(hObject, 'UserData');
fieldname = data('FieldName');
wildcard = [strtok(fieldname, '.') '.*'];

S2 = getappdata(0, 'S2');
S2_copy = S2; % store copy in case of error
S2.(f{1}).(f{2}) = value;
setappdata(0, 'S2', S2);

if (map.isKey(fieldname))
    % Handle single field changes.
    feval(map(fieldname));
end

if(map.isKey(wildcard))
    % Handle section (wildcard) changes.
    feval(map(wildcard));
end

% Verify changes.
[S2, success] = RPLoggerVerifyConfig(getappdata(0, 'S2'), 1);
if (~success)
    setappdata(0, 'S2', S2_copy); % restore copy, from above
else
    setappdata(0, 'S2', S2);
end

UpdateUI(hObject);

function make_paths
S2 = getappdata(0, 'S2');

% If root project path changed, update all child paths.
cellfun(@(x) make_one_path(x, S2.Paths.UserDefinedRootPath), { ...
    'Analytics', 'Traces', 'STFTs', 'Signatures', 'DetectorsFile', ...
    'PDsFile', 'ThresholdsFile'});

function make_one_path(field, base)
S2 = getappdata(0, 'S2');
[~, stem, ext] = fileparts(S2.Paths.(field));
S2.Paths.(field) = fullfile(base, [stem ext]);
setappdata(0, 'S2', S2);

function on_trigger_src
S2 = getappdata(0, 'S2');

if strcmp(S2.P2Scan.Caller, 'ConfigureProject') && ...
        ~strcmp(S2.P2Scan.Fieldname, 'Trigger.TriggerConfig')
    % ConfigureProject UI has a dedicated pushbutton to select
    % the trigger config file; no need to prompt the user here.
    return;
end

if S2.Trigger.TriggerSource == 9
    file = [];
    if (exist(S2.Trigger.TriggerConfig, 'file'))
        file = S2.Trigger.TriggerConfig;
    end
    [filename, pathname] = uigetfile('*.txt', 'Select Trigger Config File', file);
    if ~isequal(filename, 0) && exist(fullfile(pathname, filename), 'file')
        S2.Trigger.TriggerConfig = fullfile(pathname, filename);
        setappdata(0, 'S2', S2);
    end
end

function on_trace_length
S2 = getappdata(0, 'S2');
trace_len = round(S2.Capture.TraceLength);
msg = [];
setappdata(0, 'S2', S2);


function on_pmon
% When any pMon setting changes...
callbacks = [];
if isappdata(0, 'pMon')
    pmon = getappdata(0, 'pMon');
    callbacks = pmon.Callbacks;
    delete(pmon);
end
pmon = pMonLogger();
pmon.Callbacks = callbacks;
setappdata(0, 'pMon', pmon);

function on_capture
on_pmon();

function on_trigger
on_pmon();


