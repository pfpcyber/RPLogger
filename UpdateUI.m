function UpdateUI( hObject )
% Update all GUI elements.
data = guidata(hObject);
fields = fieldnames(data);
for i=1:length(fields)
    if (isa(data.(fields{i}), 'matlab.ui.control.UIControl'))
        init_uicontrol(data.(fields{i}));
    end
end


