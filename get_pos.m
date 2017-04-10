function pos = get_pos(handle, units)
orig = get(handle, 'Units');
set(handle, 'Units', units);
pos = get(handle, 'Position');
set(handle, 'Units', orig);
