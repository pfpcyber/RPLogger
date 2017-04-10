function varargout = RPLogger(varargin)
% GUI for RPLogger Main Window
%

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @P2Scan_OpeningFcn, ...
    'gui_OutputFcn',  @P2Scan_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if (nargin && isstruct(varargin{1}))
    setappdata(0, 'S1', varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function P2Scan_OpeningFcn(hObject, eventdata, handles, varargin)
addpath('img')
% Add json support
addpath('jsonlab-1.5')
addpath('Support')
imageArray=imread('MainLogo.jpg');
axes(handles.axes1);
imshow(imageArray);

handles.output = hObject;
guidata(hObject, handles);
CenterUI(handles.RPLogger);
 
% S1 = getappdata(0, 'S1');

function varargout = P2Scan_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;


function DataCollection_Callback(hObject, eventdata, handles)
[S1, ConfigOrg] = getRPConfigJSON;
setappdata(0,'ConfigOrg',ConfigOrg);
setappdata(0,'S1',S1);
    RPLoggerDataCollection();



% --- Executes when user attempts to close RPLogger.
function RPLogger_CloseRequestFcn(hObject, eventdata, handles)
delete(handles.RPLogger);
