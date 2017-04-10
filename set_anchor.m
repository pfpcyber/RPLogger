function set_anchor(handle, handle_ref, pad, anchor_point, isTopLevel)
if nargin == 4
    isTopLevel = false;
end 
pos0 = get_pos(handle_ref, 'Pixels');
if (isa(handle_ref, 'matlab.ui.Figure') | isTopLevel)
    % If the reference panel is a figure, then the figure is w.r.t to the
    % screen coordinates. But, we want the lower left corner to be (0,0) so
    % that we can arrange all interior UI elements w.r.t this anchor.
    pos0 = pos0 - [pos0(1) pos0(2) pos0(1) pos0(2)];
end
pos = get_pos(handle, 'Pixels');
switch (anchor_point)
    case 'tlc' % align top left corner
        pos(1) = pos0(1);
        pos(2) = pos0(2) + pos0(4) - pos(4);
    case 'top'
        pos(2) = pos0(2) + pos0(4) - pos(4) + pad;
    case 'above'
        pos(2) = pos0(2) + pos0(4) + pad;
    case 'below'
        pos(2) = pos0(2) - pos(4) - pad;
    case 'right'
        pos(1) = pos0(1) + pos0(3) + pad;
    case 'right_in'
        pos(1) = pos0(1) + (pos0(3) - pos(3));
    case 'left'
        pos(1) = pos0(1) - pos(3) - pad;
    case 'vmid'
        pos(2) = (pos0(4) - pos(4))/2 + pos0(2);
    otherwise
        error('invalid anchor_point: %s', anchor_point);
end
set(handle, 'Position', pos);
