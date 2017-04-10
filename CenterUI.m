function CenterUI(handle_figure)
units = get(0, 'units');
set(0,'units','pixels');
pos0 = get(0,'screensize');
set(0,'units',units);
pos = get_pos(handle_figure, 'pixels');
units = handle_figure.Units;
pos(1) = (pos0(3) - pos(3))/2;
pos(2) = (pos0(4) - pos(4))/2;
handle_figure.Units = 'pixels';
handle_figure.Position  = pos;
handle_figure.Units = units;