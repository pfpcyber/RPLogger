function p = uiwaitbar(handle, varargin)
%uiwaitbar: A waitbar that can be embedded in a GUI figure.
% UIWAITBAR(parent, property, value, ...) creates a waitbar embedded in the
% parent figure.
% UIWAITBAR(handle, fraction) updates the waitbar to fraction

if (mod(length(varargin), 2) == 0)
    keys = varargin(1:2:end);
    vals = varargin(2:2:end);
    
    % Check if we're changing the label.
    k = find(cellfun(@(x) strcmpi('Label', x), keys), 1);
    if (~isempty(k))
        h = get(handle,'Child');
        set(h(1), 'String', vals{k});
        return
    end
    
    k = find(cellfun(@(x) strcmpi('BarBackgroundColor', x), keys));
    if (~isempty(k))
        bg_color = vals{k};
        keys(k) = [];
        vals(k) = [];
    else
        bg_color = [0.3 0.35 0.4];
    end
    
    k = find(cellfun(@(x) strcmpi('BarForegroundColor', x), keys));
    if (~isempty(k))
        color = vals{k};
        keys(k) = [];
        vals(k) = [];
    else
        color = [0 0.5 0];
    end
    
    k = find(cellfun(@(x) strcmpi('Units', x), keys));
    if (~isempty(k))
        units = vals{k};
        keys(k) = [];
        vals(k) = [];
    else
        units = 'normalized';
    end
    
    k = find(cellfun(@(x) strcmpi('Text', x), keys));
    if (~isempty(k))
        message = vals{k};
        tag = ['uiwaitbar_' matlab.lang.makeValidName(message)];
        keys(k) = [];
        vals(k) = [];
    else
        message = '';
        tag = '';
    end
    
    % Assume bottom placement.
    txt_pos = [0  0 1 .5];
    bar_pos = [0 .5 1 .5];
    align = 'Left';
    k = find(cellfun(@(x) strcmpi('TextPosition', x), keys));
    if (~isempty(k))
        if (~isempty(strfind(vals{k}, 'Top')))
            txt_pos = [0 .5 1 .5];
            bar_pos = [0  0 1 .5];
        end
        if (~isempty(regexpi(vals{k}, 'Right', 'match')))
            align = 'Right';
        elseif (~isempty(regexpi(vals{k}, 'Center', 'match')))
            align = 'Center';
        end
        keys(k) = [];
        vals(k) = [];
    end
    
    args = [keys(:) vals(:)].';
    
    p = uipanel('Parent', handle, 'Units', units, 'BorderType', 'none', 'Tag', tag, args{:});
    
    uicontrol( ...
        'Parent', p,...
        'FontUnits',get(0,'defaultuicontrolFontUnits'),...
        'FontSize',12,...
        'BackgroundColor',get(p, 'BackgroundColor'),...
        'Units','normalized',...
        'HorizontalAlignment',align,...
        'FontWeight','bold',...
        'String',message,...
        'Style','text',...
        'Position', txt_pos);
    
    h = axes( ...
        'Parent', p,...
        'Units', 'normalized',...
        'XLim',[0 1],'YLim',[0 1],...
        'XTick',[],'YTick',[],...
        'Color', bg_color,...
        'XColor', bg_color, 'YColor', bg_color,...
        'Position', bar_pos);
    
    patch([0 0 0 0], [0 1 1 0], color,...
        'Parent', h,...
        'EdgeColor', 'none');
else
    h = get(handle,'Child');
    p = get(h(2),'Child');
    x = get(p,'XData');
    x(3:4) = varargin{1};
    set(p,'XData',x);
end

