classdef RPLoggerDataCollectionMain < handle
    properties (SetAccess = protected)
        TotalTraces  = 0;
        CurrentTrace = 0;
        S1           = [];
        SigMF = '';
        pMonLogger         = [];
        Header       = [];
        StateIdx      = 0;
        %IterIdx      = 0;
        TraceIdx     = 0;
    end
    
    methods
        % Constructor.
        function obj = RPLoggerDataCollectionMain(S1, pMonLogger, handles, callback)
            obj.S1 = S1;
            obj.pMonLogger = pMonLogger;

            obj.TotalTraces = S1.DataCollectionParams.NumTraces * ...
                S1.DataCollectionParams.NumStates;
            pMonLogger.Callbacks.CompletionFcn = @(code, msg)obj.onAcquireComplete(code, msg, handles, callback);
            if (S1.Capture.TraceLength < 1e6)
                pMonLogger.Callbacks.ReceiveTraceFcn = [];
            end
        end
        
        function rc = start(obj)
            rc = 0;
            obj.StateIdx = 0;
            obj.TraceIdx = 0;
            
            try
                if exist(obj.S1.DataPaths.SigMF, 'file') == 2
                    obj.SigMF = loadjson(obj.S1.DataPaths.SigMF);
%                     SigMF_Text = fileread(obj.S1.DataPaths.SigMF);
%                     obj.SigMF = jsondecode(SigMF_Text);

                end
            catch err
                uiwait(msgbox(sprintf('%s\n\n%s',err.message,['File not found: %s.', obj.S1.DataPaths.SigMF])));
            end
            tmp = regexp(obj.S1.DataPaths.SigMF, '/|\','split');
            obj.S1.DataPaths.SigMF = strrep(obj.S1.DataPaths.SigMF,tmp{end},'');


            if obj.pMonLogger.acquire() < 0
                rc = -1;
                return
            end
        end
    end
    
    methods (Access = protected)
        % Do the next operation.
        % Return 0: not done; 1: done; -1: error
        function rc = next(obj)
            rc = 0;
            obj.TraceIdx = obj.TraceIdx + 1;
            if obj.TraceIdx == obj.S1.DataCollectionParams.NumTraces
                obj.TraceIdx = 0;
                    obj.StateIdx = obj.StateIdx + 1;
                    if obj.StateIdx < obj.S1.DataCollectionParams.NumStates
                        uiwait(warndlg({'Please set the device to the next run state.';'Press OK to continue.'}, ...
                            'Set Run State', 'modal'));
                    else
                        rc = 1; % Done!
                        return
                    end
            end
            
            if obj.pMonLogger.acquire() < 0
                rc = -1;
                return
            end
        end
        
        function onAcquireComplete(obj, code, msg, handles, callback)
            % Call top-level completion handler.
            callback(code, msg, false);
            % SigMF meta data
            obj.SigMF.core_0x3A_global.core_0x3A_date = date;
            obj.SigMF.core_0x3A_capture{1,1}.core_0x3A_sample_start = 0;
            obj.SigMF.core_0x3A_capture{1,1}.core_0x3A_sample_rate = obj.S1.Capture.SampleFreq;
            obj.SigMF.core_0x3A_capture{1,1}.PFP_0x3A_channel = 0;
            obj.SigMF.core_0x3A_capture{1,1}.PFP_0x3A_length = obj.S1.Capture.TraceLength;
            obj.SigMF.core_0x3A_global.PFP_0x3A_label = obj.StateIdx;

            Opt = struct('Method', 'SHA-512', 'Input', 'bin');
            
            obj.SigMF.core_0x3A_global.core_0x3A_sha512 = DataHash(obj.pMonLogger.Buffer.Samples,Opt);
            % SigMF meta data
            DateTime = datetime('now','Timezone','local','Format','yyyy-MM-dd''T''HH:mm:ss,SSSSXXX');
            obj.SigMF.core_0x3A_capture{1,1}.core_0x3A_time = char(DateTime);
            obj.SigMF.core_0x3A_global.PFP_0x3A_sequence = obj.TraceIdx;
            
            % Base file name
            FileName = [num2str(DateTime.Year,'%04d'),...
                num2str(DateTime.Month,'%02d'),...
                num2str(DateTime.Day,'%02d'),...
                '_',...
                num2str(DateTime.Hour,'%02d'),...
                num2str(DateTime.Minute,'%02d'),...
                strrep(num2str(DateTime.Second,'%5.2f'), '.', '_')];
            
            
            DataFileName = [FileName '.data']; % Add .data extension
            DataFullPath = [obj.S1.DataPaths.DataStorage DataFileName];
            MetaFileName = [FileName '.meta'];%  Add .meta extension
            
            MetaFullPath = [obj.S1.DataPaths.DataStorage MetaFileName];
            
            obj.SigMF.core_0x3A_global.core_0x3A_datapath = DataFileName;
            
            DataFileWriter(DataFullPath,obj.pMonLogger.Buffer.Samples, obj.SigMF.core_0x3A_global.core_0x3A_datatype);
            MetaFileWriter(MetaFullPath,obj.SigMF);
            
            obj.CurrentTrace = obj.CurrentTrace + 1;
            percentComplete = (obj.CurrentTrace/obj.TotalTraces)*100;
            handles.uipanel_Waveform.Title = sprintf('Completed: %.2f%%', percentComplete);
            if (obj.CurrentTrace < obj.TotalTraces && ~isempty(obj.pMonLogger.Fd))
                obj.next();
            else
                callback(code, msg, true);
                set(handles.uicontrol_StartCapture, 'String', 'Start Capture');
                handles.uipanel_Waveform.Title = 'Waveform';
            end
        end
    end
end
