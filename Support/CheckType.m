function S1 = CheckType( S1, fieldname, subfieldname )
val = S1.(fieldname).(subfieldname);
if isempty(val)
    appendErr('Matrix must have more than zero elements')
    throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
end

isKey = S1.P2Scan.dataTypes.isKey((strcat(fieldname,'.',subfieldname)));
if isKey
    type = S1.P2Scan.dataTypes(strcat(fieldname,'.',subfieldname));
else
    type = 'numeric';
end

type = lower(type);
isVector = strfind(type,'[');
isInteger = strfind(type,'int');
isString = strfind(type,'string');

if (~isempty(isString))
    return;
end

if (ischar(val))
    msg = sprintf('Invalid entry for [%s]:%s Value must be a number',fieldname, subfieldname);
    appendErr(sprintf('%s', msg));
    throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
end
if (~isempty(isInteger))
    val = round(val);
    S1.(fieldname).(subfieldname) = val;
end
if (isempty(isVector) && (length(val) > 1))
    msg = sprintf('Invalid entry for [%s]:%s Value must be scalar',fieldname, subfieldname);
    appendErr(sprintf('%s', msg));
    throw(MException('VerifyConfig:BadValue','VerifyConfig:BadValue'));
end


function appendErr(msg)
global errorStr;
errorStr = sprintf('%s\n\n%s', errorStr, msg);


