function FinalizeUI(parent_fig)

s = GetPlatformScaling();

% Set fig and all child UI controls to normalized coordinates.
set(findall( parent_fig, '-property', 'Units' ), 'Units', 'Normalized');
set(findall( parent_fig, '-property', 'FontUnits' ), 'FontUnits', 'Normalized');
