function success = RPLoggerDefaultHandler(hObject, eventdata)
global errorStr;
errorStr = '';
data = get(hObject, 'UserData'); % get user data
fieldname = data('FieldName');
f = regexp(fieldname, '\.', 'split');
S2 = getappdata(0, 'S2');
S2_valid = S2;
assert(length(f)==2);
assert(isstruct(S2));
persistent dataTypes
if isempty(dataTypes)
    dataTypes = LoadDataTypes('dataTypes.txt');
end

% Get caller info
[st, ~] = dbstack;
S2.P2Scan.Caller = [];
if length(st) >= 2
    S2.P2Scan.Caller = regexprep(st(2).file, '\.m$', '');
end

% Insert fieldname.
S2.P2Scan.Fieldname = fieldname;
setappdata(0, 'S2', S2);

% UI -> INI
switch(get(hObject, 'Style'))
    case 'popupmenu'
        values = data('Values');
        if (~iscell(values))
            values = num2cell(values);
        end
        value = values{get(hObject, 'Value')};
    case 'checkbox'
        value = get(hObject, 'Value');
    otherwise
        str = cell2mat(get(hObject, 'String'));
        [value, valid] = str2num(str); %#ok<ST2NM>
        if (~valid)
            value = str;
        end
end

% Check type
try 
    S2.(f{1}).(f{2}) = value;
    isKey = dataTypes.isKey(strcat(f{1},'.',f{2}));
    if isKey
        type = dataTypes(strcat(f{1},'.',f{2}));
    else
        type = [];
    end
    S2 = CheckType(S2, f{1}, f{2});
    setappdata(0,'S2',S2);
catch  
    UpdateUI(hObject);
    showErr();
    return;
end   

% Validate fields and field dependencies.
if ~update_RPLoggerdependencies(hObject, f, value)
    setappdata(0,'S2',S2_valid);
    UpdateUI(hObject);
    showErr();
end

function showErr()
global errorStr

msg = sprintf('%s', regexprep(errorStr, '^[\r\n]+', ''));
errordlg(msg, 'Invalid Input Detected', 'modal');
