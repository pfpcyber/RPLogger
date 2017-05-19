function RPLoggerDataCollection(varargin)

gui_Singleton = 1;
gui_State = struct(...
    'gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @DataCollection_OpeningFcn, ...
    'gui_OutputFcn',  @DataCollection_OutputFcn, ...
    'gui_LayoutFcn',  @DataCollection_LayoutFcn, ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
% 
if (nargin && isstruct(varargin{1}))
    setappdata(0, 'S1', varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before GUI is made visible.
function DataCollection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Choose default command line output
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
CenterUI(handles.data_collection_figure);

handles.uicontrol_pMonProto.Enable = 'off';
handles.uicontrol_pMonPort.Enable = 'off';

imageArray=imread('PFPLogo.jpg');
axes(handles.bl_logo);
imshow(imageArray);





S1 = getappdata(0, 'S1');
axes(handles.waveform);
plot(zeros(1, S1.Capture.TraceLength));
ylabel('Volts');
ylim([-S1.Capture.VerticalRange*1000 S1.Capture.VerticalRange*1000]);

% Initialize controls to current field values.
fields = fieldnames(handles);
for i=1:length(fields)
    if (isa(handles.(fields{i}), 'matlab.ui.control.UIControl'))
        init_uicontrol(handles.(fields{i}));
    end
end

% Allocate pMon interface.
iface = pMonLogger();
iface.setCallbacks(...
    'ReceiveTraceFcn', @(x)onTraceData(x, handles), ...
    'TriggerFcn', @(x)onTrigger(x, handles));
setappdata(0, 'pMonLogger', iface);

% Select 'Analysis' controls sheet at startup.
set(handles.uicontrol_capture_btn, 'Value', 1);

% --- Outputs from this function are returned to the command line.
function varargout = DataCollection_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function h1 = DataCollection_LayoutFcn(policy)
% policy - create a new figure or use a singleton. 'new' or 'reuse'.

% Create a temporary config context.
S1 = getappdata(0, 'S1');
S2 = S1;
setappdata(0, 'S2', S2);
units = get(0, 'units');
set(0,'units','inches');
inches = get(0,'screensize');
set(0,'units',units);
h = min([0.8*12.25/inches(4), .85]);
w = 11/inches(3);

persistent hsingleton;
if strcmpi(policy, 'reuse') & ishandle(hsingleton)
    h1 = hsingleton;
    return;
end

h1 = figure(...
    'WindowStyle', 'normal',...
    'Units','normalized',...
    'Position',[(1-w)/2, (1-h/2), w, h],...
    'Visible',get(0,'defaultfigureVisible'),...
    'Color',[1 1 1],...
    'IntegerHandle','off',...
    'MenuBar','none',...
    'Name','Red Pitaya Data Collection',...
    'NumberTitle','off',...
    'Resize','on',...
    'PaperPosition',get(0,'defaultfigurePaperPosition'),...
    'ScreenPixelsPerInchMode','manual',...
    'ParentMode','manual',...
    'HandleVisibility','callback',...
    'CloseRequestFcn',@DataCollection_CloseFcn, ...
    'Tag','data_collection_figure');
if isdeployed
    set(h1, 'WindowStyle', 'modal');
end
set(h1, 'Units', 'Inches');
pos = get(h1, 'Position');

logo_height = 1; % inches
logo_pos = [ 0.5, pos(4) - logo_height - 0.1, 2.0, logo_height];
logo = axes(...
    'Parent',h1,...
    'FontUnits',get(0,'defaultaxesFontUnits'),...
    'Units','Inches',...
    'Position',logo_pos,...
    'XRulerMode',get(0,'defaultaxesXRulerMode'),...
    'Tag','bl_logo',...
    'ParentMode','manual');
set(logo, 'Units', 'Pixels');

oscilloscope_labels = { 'Red Pitaya' };

oscilloscope = { 'redpitaya' };

proto = { 'tcp', 'udp' };

proto_labels = { 'TCP/IP', 'UDP' };

% Control Panel
panel_cfg = make_panel(h1, 'Settings', [ logo_pos(1) 0 3.5/3 0 ], 'Inches');
panel_cfg = add_uicontrol(panel_cfg, '', 'radiobutton', { 'Capture' }, 'capture_btn');
panel_cfg = add_uicontrol(panel_cfg, '', 'radiobutton', { 'pMon' }, 'pmon_btn');
panel_cfg = add_uicontrol(panel_cfg, '', 'radiobutton', { 'Paths' }, 'paths_btn');
panel_cfg = finalize_layout(panel_cfg, 0.75, 1); % provide height in inches for the first panel

% pMon
pos = get_pos(panel_cfg, 'Inches');
panel_pmon = make_panel(h1, 'p-Mon', [ pos(1) 0 3.5 0 ], 'Inches');
add_uicontrol(panel_pmon, 'IP Address:', 'edit', { S1.pMon.IPAddress }, 'pMon.IPAddress');
add_uicontrol(panel_pmon, 'Port:', 'edit', { S1.pMon.Port }, 'pMon.Port');
add_uicontrol(panel_pmon, 'Proto:', 'popupmenu', proto_labels, 'pMon.Proto', 'Values', proto);
add_uicontrol(panel_pmon, '', 'pushbutton', {'Test Connection'}, 'test_connection');
[~, metrics] = finalize_layout(panel_pmon, 2.5*GetPlatformScaling());
set(panel_pmon, 'Visible', 'off');

% Capture
panel_cap = make_panel(h1, 'Capture', [ pos(1) 0 3.5 0 ], 'Inches');
add_uicontrol(panel_cap, 'Digitizer:', 'popupmenu', oscilloscope_labels, 'Red Pitaya', 'Values', oscilloscope);

layout_redpitaya(panel_cap, metrics, S1);

set(panel_cap, 'Visible', 'on');

% Paths
panel_paths = make_panel(h1, 'File Paths', [ logo_pos(1) 0 3.5 0], 'Inches');
add_uicontrol(panel_paths, 'Data Store:', 'edit', { S1.Paths.DataStore }, 'Paths.DataStore');
add_uicontrol(panel_paths, 'Initial SigMF :', 'edit', { S1.Paths.SigMF }, 'Paths.SigMF');
finalize_layout(panel_paths, metrics);

set(panel_paths, 'Visible', 'off');

% Resize config buttons panel to match Analysis panel width.
pos = get_pos(panel_pmon, 'Pixels');
set_size(panel_cfg, [pos(3), -1], 'Pixels');
set_anchor(panel_cfg, logo, 0, 'tlc');
set_anchor(panel_pmon, panel_cfg, metrics.sz(2)*0.75, 'below'); % pixels
set_anchor(panel_cap, panel_pmon, 0, 'top'); % pixels
set_anchor(panel_paths, panel_pmon, 0, 'top'); % pixels

% Waveform
pos = get_pos(panel_cap, 'Pixels');
pos0 = get_pos(h1, 'Pixels');
pos(3) = pos0(3) - pos(1)*2;
panel_waveform = make_panel(h1, 'Waveform', pos, 'Pixels');
set(panel_waveform, 'visible', 'on');

axes(...
    'Parent',panel_waveform,...
    'FontUnits',get(0,'defaultaxesFontUnits'),...
    'Units','normalized',...
    'Position',[ 0.075, 0.125, 0.8875, 0.8125 ],...
    'FontSize',10,...
    'FontSmoothing','off',...
    'Tag','waveform',...
    'ParentMode','manual');

set_anchor(panel_waveform, panel_cap, metrics.sz(2)*0.75, 'below');
set_anchor(logo, panel_waveform, 0, 'right_in');
set_anchor(logo, panel_cfg, 0, 'vmid');

% Progress bar (Top)
progress_bar = uiwaitbar(h1, 'Position', [logo_pos(1) 0 0 0], 'Units', 'Inches', ...
    'Text', 'Idle', ...
    'TextPosition', 'BottomCenter', ...
    'BackgroundColor', [1 1 1],... % panel
    'BarForegroundColor', [44 94 174]/255,...
    'BarBackgroundColor', get(h1, 'Color')*0.95);
set(progress_bar, 'Tag', 'waitbar');
set(progress_bar, 'Units', 'Pixels');
pos0 = get_pos(h1, 'Pixels');
pos = get_pos(progress_bar, 'Pixels');
set_size(progress_bar, [pos0(3) - pos(1)*2, metrics.sz(2)]);
set_anchor(progress_bar, panel_waveform, metrics.sz(2)*0.75, 'below');
set(progress_bar, 'Visible', 'on');

% Buttons
pos = get_pos(panel_pmon, 'Pixels');
panel_buttons = make_panel(h1, '', pos, 'Pixels', 'BorderType', 'none', 'Tag', 'uipanel_buttons');
add_button(panel_buttons, 'Acquire Trace', (1-(.025 * 3))/2);
add_button(panel_buttons, 'Start Capture', -1);
set(panel_buttons, 'Units', 'Pixels');
set_size(panel_buttons, [-1, metrics.sz(2)*1.5]);
set_anchor(panel_buttons, progress_bar, 0, 'below'); % pixels
set(panel_buttons, 'Visible', 'on');

FinalizeUI(h1);

hsingleton = h1;
setappdata(0, 'metrics', metrics);


function DataCollection_CloseFcn(hObject, eventdata)
% successful data collection, close any open background pings
KillPing();
ConfigOrg = getappdata(0,'ConfigOrg');
S1 = getappdata(0, 'S1');
S2 = getappdata(0, 'S2');
if (~isequal(S1, S2))
    choice = questdlg('Save changes to project file?', 'Confirm Exit', ...
        'Save', 'Discard', 'Cancel', 'Save');
    switch (choice)
        case 'Save'
            S1 = S2;
            Config = MapS1_JSONrp( S1, ConfigOrg)
            JsonFileWriter(S1.P2Scan.configFilePath,Config);
            setappdata(0, 'S1', S1);
        case 'Cancel'
            return
    end
end

if (isappdata(0, 'pMon'))
    delete(getappdata(0, 'pMon'));
    rmappdata(0, 'pMon');
end

if (isappdata(0, 'S2'))
    rmappdata(0, 'S2');
end

if (isappdata(0, 'metrics'))
    rmappdata(0, 'metrics');
end

data = guidata(hObject);
delete(data.data_collection_figure);

RPLogger();

% --- Handles default GUIDE GUI creation and callback dispatch
function varargout = gui_mainfcn(gui_State, varargin)

gui_StateFields =  {'gui_Name'
    'gui_Singleton'
    'gui_OpeningFcn'
    'gui_OutputFcn'
    'gui_LayoutFcn'
    'gui_Callback'};
gui_Mfile = '';
for i=1:length(gui_StateFields)
    if ~isfield(gui_State, gui_StateFields{i})
        error(message('MATLAB:guide:StateFieldNotFound', gui_StateFields{ i }, gui_Mfile));
    elseif isequal(gui_StateFields{i}, 'gui_Name')
        gui_Mfile = [gui_State.(gui_StateFields{i}), '.m'];
    end
end

numargin = length(varargin);

if numargin == 0
    % create the GUI only if we are not in the process of loading it
    % already
    gui_Create = true;
elseif local_isInvokeActiveXCallback(gui_State, varargin{:})
    vin{1} = gui_State.gui_Name;
    vin{2} = [get(varargin{1}.Peer, 'Tag'), '_', varargin{end}];
    vin{3} = varargin{1};
    vin{4} = varargin{end-1};
    vin{5} = guidata(varargin{1}.Peer);
    feval(vin{:});
    return;
elseif local_isInvokeHGCallback(gui_State, varargin{:})
    gui_Create = false;
else
    % create the GUI and hand varargin to the openingfcn
    gui_Create = true;
end

if ~gui_Create
    % In design time, we need to mark all components possibly created in
    % the coming callback evaluation as non-serializable. This way, they
    % will not be brought into GUIDE and not be saved in the figure file
    % when running/saving the GUI from GUIDE.
    designEval = false;
    if (numargin>1 && ishghandle(varargin{2}))
        fig = varargin{2};
        while ~isempty(fig) && ~ishghandle(fig,'figure')
            fig = get(fig,'parent');
        end
        
        designEval = isappdata(0,'CreatingGUIDEFigure') || (isscalar(fig)&&isprop(fig,'GUIDEFigure'));
    end
    
    if designEval
        beforeChildren = findall(fig);
    end
    
    % evaluate the callback now
    varargin{1} = gui_State.gui_Callback;
    if nargout
        [varargout{1:nargout}] = feval(varargin{:});
    else
        feval(varargin{:});
    end
    
    % Set serializable of objects created in the above callback to off in
    % design time. Need to check whether figure handle is still valid in
    % case the figure is deleted during the callback dispatching.
    if designEval && ishghandle(fig)
        set(setdiff(findall(fig),beforeChildren), 'Serializable','off');
    end
else
    if gui_State.gui_Singleton
        gui_SingletonOpt = 'reuse';
    else
        gui_SingletonOpt = 'new';
    end
    
    % Check user passing 'visible' P/V pair first so that its value can be
    % used by oepnfig to prevent flickering
    gui_Visible = 'auto';
    gui_VisibleInput = '';
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end
        
        % Recognize 'visible' P/V pair
        len1 = min(length('visible'),length(varargin{index}));
        len2 = min(length('off'),length(varargin{index+1}));
        if ischar(varargin{index+1}) && strncmpi(varargin{index},'visible',len1) && len2 > 1
            if strncmpi(varargin{index+1},'off',len2)
                gui_Visible = 'invisible';
                gui_VisibleInput = 'off';
            elseif strncmpi(varargin{index+1},'on',len2)
                gui_Visible = 'visible';
                gui_VisibleInput = 'on';
            end
        end
    end
    
    % Open fig file with stored settings.  Note: This executes all component
    % specific CreateFunctions with an empty HANDLES structure.
    
    
    % Do feval on layout code in m-file if it exists
    gui_Exported = ~isempty(gui_State.gui_LayoutFcn);
    % this application data is used to indicate the running mode of a GUIDE
    % GUI to distinguish it from the design mode of the GUI in GUIDE. it is
    % only used by actxproxy at this time.
    setappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]),1);
    if gui_Exported
        gui_hFigure = feval(gui_State.gui_LayoutFcn, gui_SingletonOpt);
        
        % make figure invisible here so that the visibility of figure is
        % consistent in OpeningFcn in the exported GUI case
        if isempty(gui_VisibleInput)
            gui_VisibleInput = get(gui_hFigure,'Visible');
        end
        set(gui_hFigure,'Visible','off')
        
        % openfig (called by local_openfig below) does this for guis without
        % the LayoutFcn. Be sure to do it here so guis show up on screen.
        movegui(gui_hFigure,'onscreen');
    else
        gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        % If the figure has InGUIInitialization it was not completely created
        % on the last pass.  Delete this handle and try again.
        if isappdata(gui_hFigure, 'InGUIInitialization')
            delete(gui_hFigure);
            gui_hFigure = local_openfig(gui_State.gui_Name, gui_SingletonOpt, gui_Visible);
        end
    end
    if isappdata(0, genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]))
        rmappdata(0,genvarname(['OpenGuiWhenRunning_', gui_State.gui_Name]));
    end
    
    % Set flag to indicate starting GUI initialization
    setappdata(gui_hFigure,'InGUIInitialization',1);
    
    appdata = [];
    appdata.GUIDEOptions = struct(...
        'active_h', [], ...
        'taginfo', struct(...
        'figure', 2, ...
        'text', 35, ...
        'uipanel', 37, ...f
        'edit', 37, ...
        'popupmenu', 6, ...
        'pushbutton', 3), ...
        'override', 0, ...
        'release', [], ...
        'resize', 'none', ...
        'accessibility', 'callback', ...
        'mfile', 1, ...
        'callbacks', 1, ...
        'singleton', 1, ...
        'syscolorfig', 1, ...
        'blocking', 0, ...
        'lastSavedFile', '', ...
        'lastFilename', '');
    appdata.lastValidTag = 'figure1';
    appdata.GUIDELayoutEditor = [];
    appdata.initTags = struct(...
        'handle', [], ...
        'tag', 'figure1');
    
    names = fieldnames(appdata);
    for i=1:length(names)
        name = char(names(i));
        setappdata(gui_hFigure, name, getfield(appdata,name));
    end
    
    % Fetch GUIDE Application options
    gui_Options = getappdata(gui_hFigure,'GUIDEOptions');
    % Singleton setting in the GUI M-file takes priority if different
    gui_Options.singleton = gui_State.gui_Singleton;
    
    if ~isappdata(gui_hFigure,'GUIOnScreen')
        % Adjust background color
        %         if gui_Options.syscolorfig
        %             set(gui_hFigure,'Color', get(0,'DefaultUicontrolBackgroundColor'));
        %         end
        
        % Generate HANDLES structure and store with GUIDATA. If there is
        % user set GUI data already, keep that also.
        data = guidata(gui_hFigure);
        handles = guihandles(gui_hFigure);
        if ~isempty(handles)
            if isempty(data)
                data = handles;
            else
                names = fieldnames(handles);
                for k=1:length(names)
                    data.(char(names(k)))=handles.(char(names(k)));
                end
            end
        end
        guidata(gui_hFigure, data);
    end
    
    % Apply input P/V pairs other than 'visible'
    for index=1:2:length(varargin)
        if length(varargin) == index || ~ischar(varargin{index})
            break;
        end
        
        len1 = min(length('visible'),length(varargin{index}));
        if ~strncmpi(varargin{index},'visible',len1)
            try set(gui_hFigure, varargin{index}, varargin{index+1}), catch break, end
        end
    end
    
    % If handle visibility is set to 'callback', turn it on until finished
    % with OpeningFcn
    gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
    if strcmp(gui_HandleVisibility, 'callback')
        set(gui_hFigure,'HandleVisibility', 'on');
    end
    
    feval(gui_State.gui_OpeningFcn, gui_hFigure, [], guidata(gui_hFigure), varargin{:});
    
    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        % Handle the default callbacks of predefined toolbar tools in this
        % GUI, if any
        guidemfile('restoreToolbarToolPredefinedCallback',gui_hFigure);
        
        % Update handle visibility
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
        
        % Call openfig again to pick up the saved visibility or apply the
        % one passed in from the P/V pairs
        if ~gui_Exported
            gui_hFigure = local_openfig(gui_State.gui_Name, 'reuse',gui_Visible);
        elseif ~isempty(gui_VisibleInput)
            set(gui_hFigure,'Visible',gui_VisibleInput);
        end
        if strcmpi(get(gui_hFigure, 'Visible'), 'on')
            figure(gui_hFigure);
            
            if gui_Options.singleton
                setappdata(gui_hFigure,'GUIOnScreen', 1);
            end
        end
        
        % Done with GUI initialization
        if isappdata(gui_hFigure,'InGUIInitialization')
            rmappdata(gui_hFigure,'InGUIInitialization');
        end
        
        % If handle visibility is set to 'callback', turn it on until
        % finished with OutputFcn
        gui_HandleVisibility = get(gui_hFigure,'HandleVisibility');
        if strcmp(gui_HandleVisibility, 'callback')
            set(gui_hFigure,'HandleVisibility', 'on');
        end
        gui_Handles = guidata(gui_hFigure);
    else
        gui_Handles = [];
    end
    
    if nargout
        [varargout{1:nargout}] = feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    else
        feval(gui_State.gui_OutputFcn, gui_hFigure, [], gui_Handles);
    end
    
    if isscalar(gui_hFigure) && ishghandle(gui_hFigure)
        set(gui_hFigure,'HandleVisibility', gui_HandleVisibility);
    end
end

function gui_hFigure = local_openfig(name, singleton, visible)

% openfig with three arguments was new from R13. Try to call that first, if
% failed, try the old openfig.
if nargin('openfig') == 2
    % OPENFIG did not accept 3rd input argument until R13,
    % toggle default figure visible to prevent the figure
    % from showing up too soon.
    gui_OldDefaultVisible = get(0,'defaultFigureVisible');
    set(0,'defaultFigureVisible','off');
    gui_hFigure = matlab.hg.internal.openfigLegacy(name, singleton);
    set(0,'defaultFigureVisible',gui_OldDefaultVisible);
else
    % Call version of openfig that accepts 'auto' option"
    gui_hFigure = matlab.hg.internal.openfigLegacy(name, singleton, visible);
    %     %workaround for CreateFcn not called to create ActiveX
    %     if feature('HGUsingMATLABClasses')
    %         peers=findobj(findall(allchild(gui_hFigure)),'type','uicontrol','style','text');
    %         for i=1:length(peers)
    %             if isappdata(peers(i),'Control')
    %                 actxproxy(peers(i));
    %             end
    %         end
    %     end
end

function result = local_isInvokeActiveXCallback(gui_State, varargin)

try
    result = ispc && iscom(varargin{1}) ...
        && isequal(varargin{1},gcbo);
catch
    result = false;
end

function result = local_isInvokeHGCallback(gui_State, varargin)

try
    fhandle = functions(gui_State.gui_Callback);
    result = ~isempty(findstr(gui_State.gui_Name,fhandle.file)) || ...
        (ischar(varargin{1}) ...
        && isequal(ishghandle(varargin{2}), 1) ...
        && (~isempty(strfind(varargin{1},[get(varargin{2}, 'Tag'), '_'])) || ...
        ~isempty(strfind(varargin{1}, '_CreateFcn'))) );
catch
    result = false;
end

function layout_redpitaya(panel, metrics, S1)
chan = [ 0, 1 ];

chan_labels = { 'Ch A', 'Ch B' };

freq = [125e6 62.5e6 31.25e6 15.625e6 7.8125e6 3.90625e6 1.953125e6 0.9765625e6 30518 15259 7629 3815 1907 954];

freq_labels = { '125 MHz', '62.5 MHz', '31.25 MHz', '15.625 MHz', ...
    '7.8125 MHz', '3.90625 MHz', '1.953125 MHz', '0.9765625 MHz', ...
    '30.518 kHz', '15.259 kHz', '7.629 kHz', '3.815 kHz', '1.907 kHz', ...
    '0.954 kHz'};

trig_src = [ 1, 2, 3, 4, 5, 6, 7, 9 ];

trig_src_labels = { 'Software', 'Ch A Rising', 'Ch A Falling', 'Ch B Rising', ...
    'Ch B Falling', 'Ext Rising', 'Ext Falling', 'Custom' };

gain = [ 0, 1 ];

gain_labels = { 'LV', 'HV' };

pre_trig = [ 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 ];

pre_trig_labels = { '0%', '5%', '10%', '15%', '20%', '25%', '30%', '35%', ...
    '40%', '45%', '50%' };

add_uicontrol(panel, 'Channel:', 'popupmenu', chan_labels, 'Capture.DataChannel', 'Values', chan);
add_uicontrol(panel, 'Sample Rate:', 'popupmenu', freq_labels, 'Capture.SampleFreq', 'Values', freq);
add_uicontrol(panel, 'Trigger Source:', 'popupmenu', trig_src_labels, 'Trigger.TriggerSource', 'Values', trig_src);
add_uicontrol(panel, 'Trigger Level (V):', 'edit', gain_labels, 'Trigger.TriggerLevel');
add_uicontrol(panel, 'Trace Length:', 'edit', { S1.Capture.TraceLength }, 'Capture.TraceLength');
add_uicontrol(panel, 'Num States:', 'edit', { S1.DataCollectionParams.NumStates }, 'DataCollectionParams.NumStates');
add_uicontrol(panel, 'Num Traces:', 'edit', { S1.DataCollectionParams.NumTraces }, 'DataCollectionParams.NumTraces');
add_uicontrol(panel, 'Pre-trigger:', 'popupmenu', pre_trig_labels, 'Trigger.TriggerPosition', 'Values', pre_trig);
add_uicontrol(panel, 'Gain:', 'popupmenu', gain_labels, 'Capture.Gain', 'Values', gain);
finalize_layout(panel, metrics, 5);

%% Callbacks
function pmon_btn_callback(hObject, eventdata, varargs)
data = guidata(hObject);
set(hObject, 'Value', 1);
set(data.uicontrol_capture_btn, 'Value', 0);
set(data.uicontrol_paths_btn, 'Value', 0);
set(data.uipanel_p_Mon, 'Visible', 'on');
set(data.uipanel_Capture, 'Visible', 'off');
set(data.uipanel_FilePaths, 'Visible', 'off');

function capture_btn_callback(hObject, eventdata, varargs)
data = guidata(hObject);
set(hObject, 'Value', 1);
set(data.uicontrol_pmon_btn, 'Value', 0);
set(data.uicontrol_paths_btn, 'Value', 0);
set(data.uipanel_p_Mon, 'Visible', 'off');
set(data.uipanel_Capture, 'Visible', 'on');
set(data.uipanel_FilePaths, 'Visible', 'off');

function paths_btn_callback(hObject, eventdata, varargs)
data = guidata(hObject);
set(hObject, 'Value', 1);
set(data.uicontrol_pmon_btn, 'Value', 0);
set(data.uicontrol_capture_btn, 'Value', 0);
set(data.uipanel_p_Mon, 'Visible', 'off');
set(data.uipanel_Capture, 'Visible', 'off');
set(data.uipanel_FilePaths, 'Visible', 'on');

function abortCapture(handles)
pmonLogger = getappdata(0, 'pMonLogger');
uiwaitbar(handles.waitbar, 'Label', 'Idle');
uiwaitbar(handles.waitbar, 0);
pmonLogger.disconnect();
enableAll(handles);

function AcquireTrace_callback(hObject, eventdata, handles, varargin)
pmonLogger = getappdata(0, 'pMonLogger');

if (strcmp(handles.uicontrol_AcquireTrace.String, 'Abort Capture'))
    set(handles.uicontrol_AcquireTrace, 'String', 'Acquire Trace');
    abortCapture(handles);
else
    disableAll(handles);
    uiwaitbar(handles.waitbar, 'Label', 'Waiting for Trigger');
    uiwaitbar(handles.waitbar, 0);
    set(handles.uicontrol_AcquireTrace, 'String', 'Abort Capture');
    set(handles.uicontrol_AcquireTrace, 'Enable', 'on');
    
    pmonLogger.Callbacks.ReceiveTraceFcn = @(x)onTraceData(x, handles);
    pmonLogger.Callbacks.CompletionFcn = @(code, msg)onAcquireComplete(code, msg, handles, true);
    % pmonLogger.initialize();
    pmonLogger.acquire();
end

%%
function StartCapture_callback(hObject, eventdata, handles)
%%
S2 = getappdata(0, 'S2');
pmonLogger = getappdata(0, 'pMonLogger');

if (strcmp(handles.uicontrol_StartCapture.String, 'Abort Capture'))
    % Capture aborted.
    set(handles.uicontrol_StartCapture, 'String', 'Start Capture');
    handles.uipanel_Waveform.Title = 'Waveform';
    KillPing();
    abortCapture(handles);
else
    % Start capture pressed.
    KillPing();
    PingPmon(pmonLogger);
    % Handle non-empty Traces folder.
    if exist(S2.Paths.DataStore, 'dir')% || exist(S2.Paths.SigMF, 'dir')
        disableAll(handles);
        d1 = dir(S2.Paths.DataStore);
        d1 = { d1.name };
        d1(logical(~cellfun(@isempty, regexp(d1, '^\.{1,2}$', 'start')))) = []; % filter out '.' and '..'
        if ~isempty(d1)
            msg = sprintf('Trace files found in %s.\n\nOK to delete?', S2.Paths.DataStore);
            button = questdlg(msg,  'Folder Not Empty', ...
                'Yes', 'Cancel', 'Cancel');
            switch (button)
                case 'Yes'
                    [status, message, messageid] = rmdir(S2.Paths.DataStore, 's');
                    mkdir(S2.Paths.DataStore);
                otherwise
                    enableAll(handles);
                    return
            end
        end
    end
    
    
    uiwait(warndlg({'Please set the device to the desired  run state.';'Press OK to continue.'}, ...
                            'Set Run State', 'modal'));
    disableAll(handles);
    handles.uipanel_Waveform.Title = 'Completed: 0%';
    uiwaitbar(handles.waitbar, 'Label', 'Waiting for Trigger');
    uiwaitbar(handles.waitbar, 0);
    set(handles.uicontrol_StartCapture, 'String', 'Abort Capture');
    set(handles.uicontrol_StartCapture, 'Enable', 'on');
    
    h = RPLoggerDataCollectionMain(S2, pmonLogger, handles, ...
        @(code, msg, acq_complete)onAcquireComplete(code, msg, handles, acq_complete));
    h.start();
end

function test_connection_callback(hObject, eventdata)
pmonLogger = getappdata(0, 'pMonLogger');
handles = guidata(hObject);
disableAll(handles);

pmonLogger.Callbacks.CompletionFcn = @(code, msg)onTestConnectionComplete(code, msg);
if pmonLogger.connect(true) == 0
    pmonLogger.disconnect();
    msgbox('Connection successful!', 'modal');
end
enableAll(handles);

function uicontrol_callback(hObject, eventdata)
data = get(hObject, 'UserData');
fieldname = data('FieldName');

if (isempty(strfind(fieldname, '.')))
    eval(sprintf('%s_callback(hObject, eventdata)', matlab.lang.makeValidName(fieldname)));
else
RPLoggerDefaultHandler(hObject, eventdata);
pmonLogger = getappdata(0, 'pMonLogger');
S1 = getappdata(0,'S1');
S2 = getappdata(0,'S2');

if (~isequal(S1, S2))
    pmonLogger.Initialized = false;
    setappdata(0,'pMonLogger',pmonLogger);
end
    
end

function enableAll(handles)
set(findall(handles.uipanel_Settings, '-property', 'enable'), 'enable', 'on');
set(findall(handles.uipanel_Capture, '-property', 'enable'), 'enable', 'on');
set(findall(handles.uipanel_p_Mon, '-property', 'enable'), 'enable', 'on');
set(findall(handles.uipanel_FilePaths, '-property', 'enable'), 'enable', 'on');
set(handles.uicontrol_AcquireTrace', 'enable', 'on');
set(handles.uicontrol_StartCapture', 'enable', 'on');
drawnow;

function disableAll(handles)
set(findall(handles.uipanel_Settings, '-property', 'enable'), 'enable', 'off');
set(findall(handles.uipanel_Capture, '-property', 'enable'), 'enable', 'off');
set(findall(handles.uipanel_p_Mon, '-property', 'enable'), 'enable', 'off');
set(findall(handles.uipanel_FilePaths, '-property', 'enable'), 'enable', 'off');
set(handles.uicontrol_AcquireTrace', 'enable', 'off');
set(handles.uicontrol_StartCapture', 'enable', 'off');
drawnow;

function onTraceData(traceBuffer, handles)
uiwaitbar(handles.waitbar, 'Label', 'Receiving Data');
uiwaitbar(handles.waitbar, traceBuffer.NumSamplesReceived/length(traceBuffer.Samples));
drawnow;

function onTrigger(chan, handles)
uiwaitbar(handles.waitbar, 'Label', 'Trigger Received');
drawnow;

function onError(code, msg, title)
if (~isempty(msg))
    errordlg(msg, title, 'modal');
elseif (rc ~= -1)
    msg = sprintf('Received error code: %d', code);
    errordlg(msg, title, 'modal');
else
    errordlg('An error occurred', title, 'modal');
end

function onTestConnectionComplete(code, msg)
if (code < 0 || ~isempty(msg))
    onError(code, msg, 'Connection Error');
end

function onAcquireComplete(code, msg, handles, single_capture)
S2 = getappdata(0, 'S2');
pmonLogger = getappdata(0, 'pMonLogger');
if (code < 0 || ~isempty(msg))
    onError(code, msg, 'Data Acquisition Error');
end
if (pmonLogger.Buffer.Size > 1e7)
    uiwaitbar(handles.waitbar, 'Label', 'Preparing Waveform');
    drawnow;
end
plot_waveform(handles.waveform, S2, pmonLogger.Buffer.Samples);
uiwaitbar(handles.waitbar, 'Label', 'Idle');
uiwaitbar(handles.waitbar, 0);
if (single_capture)
    set(handles.uicontrol_AcquireTrace, 'String', 'Acquire Trace');
    enableAll(handles);
end
drawnow

