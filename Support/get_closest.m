function [idx, valid] = get_closest(values, value)
%  GET_CLOSEST returns the index of the item in the values array that's
%  closest to the provided value. The valid flag indicates whether the
%  selected value is close enough to the provided value (10%).
if (isreal(values))
    err = abs(values - value);
    v = values(err == min(err));
    valid = all(isreal(err) & isfinite(err)) && isscalar(v) && abs((v - value)/value) <= .1;
    idx = find(err == min(err), 1, 'first');
elseif (iscell(values))
    idx = find(cellfun(@(x) strcmpi(x, value), values), 1, 'first');
    valid = ~isempty(idx);
else
    error('get_closest() must take a numeric array or a cell array of strings');
end

