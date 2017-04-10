
function init_uicontrol(handle)
data = get(handle, 'UserData');
if (~isa(data, 'containers.Map'))
    return; % this is not one of our uicontrols...
end
f = regexp(data('FieldName'), '\.', 'split');
% for INI struct entries, the fieldname must have the format:
% field.subfield. If it's not an INI entry, then just return.
if (length(f) ~= 2)
    return;
end
S2 = getappdata(0, 'S2');
assert(isstruct(S2));
value = S2.(f{1}).(f{2});

switch (get(handle, 'Style'))
    case 'popupmenu'
        data = get(handle, 'UserData');
        assert(data.isKey('Values'));
        [idx, valid] = get_closest(data('Values'), value);
        if (~valid)
            idx = 1;
        end
        set(handle, 'Value', idx);
    case 'checkbox'
        set(handle, 'Value', value);
    case 'edit'
        % must be cell array of strings.
        if isnumeric(value)
            set(handle, 'String', { mat2str(value) });
        else
            set(handle, 'String', { value });
        end
end