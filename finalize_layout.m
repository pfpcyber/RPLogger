function [panel, metrics] = finalize_layout(panel, metrics, m)
% pos0 must be normalized
children = get(panel, 'Children');
nchild = length(children);

vpad = 0.025; % normalized coords
hpad = 0.025; % normalized coords
vsep = 0.05;  % normalized coords
hsep = 0.025; % normalized coords
% is_dynamic = isstruct(metrics);

if (nargin < 3 || isempty(m) || m < 1)
    m = nchild;
    n = 1;
else
    n = ceil(nchild/m);
end

if isnumeric(metrics)
    % metrics defines the height of the panel (in inches). The layout of
    % the child controls is specified in normalized coordinates.
    h = (1 - vpad*2 - vsep*(m-1))/m; % normalized height of each child
    pos = [hpad vpad (1-hpad*2) h];  % position of bottom-most control
    set(children(1), 'Position', pos);
    pos = get(panel, 'Position');
    pos(4) = metrics;
    set(panel, 'Position', pos);
    
    % Now, generate pixel-based metrics from the normalized coords.
    clear metrics;
    set(children(1), 'Units', 'pixels')
    pos = get(children(1), 'Position');
    metrics.sz = pos(3:4);
    % set(children(1), 'Units', 'normalized');
    set(panel, 'Units', 'Pixels');
    pos = get(panel, 'Position');
    metrics.vsep = pos(4)*vsep; % pixels
    metrics.hsep = pos(3)*hsep; % pixels
    metrics.vpad = pos(4)*vpad; % pixels
    metrics.hpad = pos(3)*hpad; % pixels
end

sz = layout_uicontrols(children, m, n, metrics);

set(panel, 'Units', 'Pixels');
pos = get(panel, 'Position');
pos(3:4) = sz;
set(panel, 'Position', pos);
set(panel, 'Visible', 'on');

function sz = layout_uicontrols(children, m, n, metrics)
assert(m*n >= length(children));
npad = m*n - length(children);
tmp = uipanel('Visible', 'off', 'Parent', []);
children = flipud([repmat(tmp, npad, 1); children(:)]);
children = flipud(reshape(children, m, []));
children = children(:);

pos0 = [metrics.hpad metrics.vpad metrics.sz]; % position of bottom left control
h = 0;
k = 1;
for i=1:n
    pos = pos0;
    for j=1:m
        if (children(k) ~= tmp)
            % layout column-wise, bottom to top
            set(children(k), 'Units', 'Pixels');
            set(children(k), 'Position', pos);
        end
        pos = pos + [0 (metrics.sz(2) + metrics.vsep) 0 0];
        k = k + 1;
    end
    if (~h)
        h = pos(2) + metrics.vsep;
    end
    pos0 = pos0 + [(metrics.sz(1) + metrics.hsep) 0 0 0];
end

delete(tmp);
sz = [pos0(1) h];