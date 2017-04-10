function set_size(handle, sz, units)
if (nargin < 3)
    units = 'pixels';
end

pos = get_pos(handle, units);
if (sz(1) > 0)
    pos(3) = sz(1);
end
if (sz(2) > 0)
    pos(4) = sz(2);
end
orig = get(handle, 'Units');
set(handle, 'Units', units);
set(handle, 'Position', pos);
set(handle, 'Units', orig);
