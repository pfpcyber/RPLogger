classdef pMonLogger < handle
    properties
        Callbacks   = [];
    end
    
    properties (SetAccess = private)
        S1          = [];
        State       = 0;     % receive state
        Fd          = [];    % hardware interface descriptor (tcpip/udp/usb/etc.)
        Buffer      = [];
        Timer       = [];
        NumSampPacket = 0;     % number of samples in the current packet
    end
    properties 
        Initialized = false; % whether pMon is initialized for capture
    end    
    
    methods
        % Constructor.
        function obj = pMonLogger()
            obj.Buffer = TraceBuffer(obj.S1.Capture.TraceLength, 'int16');
        end
        
        % Destructor.
        function delete(obj)
            if ~isempty(obj.Fd)
                disconnect(obj);
            end
        end
        
        % Custom getter to return a handle to the application context.
        % S2 is the 'working' context; S1 is the original context.
        function val = get.S1(obj)
            if (isappdata(0, 'S2'))
                val = getappdata(0, 'S2');
            else
                val = getappdata(0, 'S1');
            end
        end
        
        function setCallbacks(obj, varargin)
            if (mod(length(varargin), 2) ~= 0)
                error('varargs must be provided as key/value pairs.');
            end
            
            obj.Callbacks = [];
            keys = varargin(1:2:end);
            vals = varargin(2:2:end);
            
            k = find(cellfun(@(x) strcmpi('ReceiveTraceFcn', x), keys));
            if (~isempty(k) && isa(vals{k}, 'function_handle'))
                obj.Callbacks.ReceiveTraceFcn = vals{k};
            end
            
            k = find(cellfun(@(x) strcmpi('TriggerFcn', x), keys));
            if (~isempty(k) && isa(vals{k}, 'function_handle'))
                obj.Callbacks.TriggerFcn = vals{k};
            end
            
            k = find(cellfun(@(x) strcmpi('CompletionFcn', x), keys));
            if (~isempty(k) && isa(vals{k}, 'function_handle'))
                obj.Callbacks.CompletionFcn = vals{k};
            end
        end
        
        %%% Connect to the pMon unit.
        function rc = connect(obj, do_completion, varargin)
            %disp('connecting');
            rc = -1;
            if (mod(length(varargin), 2) ~= 0)
                error('Must provide key/value pairs to connect()');
            end
            
            keys = varargin(1:2:end);
            vals = varargin(2:2:end);
            %disp('connecting 1');
            % Set default value for InputBufferSize if not provided in varargin.
            k = find(cellfun(@(x) strcmpi('InputBufferSize', x), keys), 1);
            if (isempty(k))
                keys = [keys {'InputBufferSize'}];
                vals = [vals {obj.S1.Capture.TraceLength*4}];
            end
            %disp('connecting 2');
            % Close any open connections.
            a = instrfind('Status','open','Type','tcpip','RemoteHost',obj.S1.pMon.IPAddress);
            if ~isempty(a)
                %disp('closing open connections');
                fclose(a);
            end
            %disp('connecting 3');
            try
                obj.Fd = tcpip(obj.S1.pMon.IPAddress, obj.S1.pMon.Port);
                set(obj.Fd, 'ByteOrder', 'littleEndian');
                set(obj.Fd, 'UserData', obj); % store a reference to us!
                if (strcmpi(obj.S1.pMon.Proto, 'udp'))
                    set(obj.Fd, 'DatagramTerminateMode', 'off'); % udp only
                end
                %disp('connecting 4');
                for i=1:length(keys)
                    set(obj.Fd, keys{i}, vals{i});
                end
                %disp('connecting 4.1');
                %   set(S1.P2Scan.fd,'Timeout',S1.Trigger.AutoTriggerTimeoutms+5000);
                fopen(obj.Fd);
                %disp('connecting 4.2');
                if (do_completion)
                    completion(obj);
                end
                %disp('connecting 4.3');
                rc = 0; % success
                %disp('connecting 5');
            catch e
                %disp('caught error');
                if (strcmpi(e.identifier, 'instrument:fopen:opfailed'))
                    msg = sprintf('Failed to connect to pMon at: %s:%d\nThe pMon application may not be running.', ...
                        obj.S1.pMon.IPAddress, obj.S1.pMon.Port);
                    completion(obj, -1, msg);
                else
                    completion(obj, -1, e.message);
                end
            end
            %disp('finished connecting');
        end
        
        function rc = disconnect(obj, close_all)
            %disp('disconnecting');
            if (nargin < 2 || isempty(close_all))
                close_all = false;
            end
            rc = -1;
            if (close_all)
                fclose(fds);
            else
                if ~isempty(obj.Timer)
                    stop(obj.Timer);
                    delete(obj.Timer);
                end
                obj.Timer = [];
                fclose(obj.Fd);
            end
            obj.Fd = [];
            obj.Initialized = false;
            obj.State = 0;
            %disp('finished disconnecting');
        end
        
        function rc = initialize(obj)
            %disp('initializing');
            inbuf_size = 1024*1024;
            rc = connect(obj, false, ...
                'InputBufferSize', inbuf_size, ...
                'OutputBufferSize', 8192, ...
                'ReadAsyncMode', 'continuous', ...
                'BytesAvailableFcn', @obj.handleReceive, ...
                'BytesAvailableFcnMode', 'byte', ...
                'BytesAvailableFcnCount', inbuf_size);
            obj.Timer = timer('Period', 0.01, 'BusyMode', 'drop', ...
                'ExecutionMode', 'fixedspacing', ...
                'Name', 'Timer_pMon', ...
                'TimerFcn', @obj.onTimer, 'UserData', obj);
            start(obj.Timer);
            
            if rc
                return
            end
            rc = -1;
            
            % Select the Red Pitaya digitizer.
            if (send(obj, uint32([87 2]), 'Register Digitizer') < 0)
                return
            end
            
            if (send(obj, uint32(0), 'Initialization') < 0)
                return
            end
            
            % Handle variable trace length.
            trace_length = obj.S1.Capture.TraceLength;
            if (trace_length < 0) %
                trace_length = intmax('uint32');
            end
            config = '';
            
            % Handle custom trigger and trigger configuration file.
            if (obj.S1.Trigger.TriggerSource == 9)
                fn = obj.S1.Trigger.TriggerConfig;
                fid = fopen(fn, 'r');
                if (fid < 0)
                    completion(obj, -1, sprintf('Trigger configuration file:\n%s\nnot found.', fn));
                    return
                end
                config = fread(fid, 'uint8=>char').';
                if (length(config) >= 4096)
                    completion(obj, -1, sprintf('Trigger configuration too long in file:\n%s\n(Must be less than 4096 characters.)', fn));
                    return
                end
            end
            
            cmd = [...
                typecast(uint32([26 ...
                bitshift(uint32(1), obj.S1.Capture.DataChannel) ...
                trace_length ...
                0 ... % Mode (single trigger)
                obj.S1.Trigger.TriggerSource]), 'uint8') ...
                typecast(single(obj.S1.Trigger.TriggerLevel), 'uint8') ...
                typecast(single(obj.S1.Trigger.TriggerHysteresis), 'uint8') ...
                typecast(uint32([obj.S1.Trigger.TriggerPosition ...
                obj.S1.Capture.Gain]), 'uint8'), ...
                unicode2native(config)];
            
            if (send(obj, uint8(cmd), 'Configure Trigger') < 0)
                return
            end
            if (send(obj, uint32([11 obj.S1.Capture.SampleFreq]), 'Set Sample Rate') < 0)
                return
            end
            obj.Initialized = true;
            rc = 0; % success
            %disp('finished initializing');
        end
        
        function rc = acquire(obj)
            rc = 0;
            if (~obj.Initialized)
                rc = initialize(obj);
            end
            
            % Acquire raw scan.
            if (rc == 0)
                rc = send(obj, uint32([3 bitshift(uint32(1), obj.S1.Capture.DataChannel)]), 'Acquire');
            end
            
            % ZRK - I don't think this is needed, since errors will be
            % delivered to the completion function.
            %             if (rc < 0)
            %                 completion(obj, rc, 'Data acquisition failed.');
            %             end
        end
        
        function rc = teardown(obj)
            try
                rc = send(obj, uint32(1), 'Teardown Scope');
            catch e
                completion(obj, -1, e.message);
            end
            if ~isempty(obj.Timer)
                stop(obj.Timer);
                delete(obj.Timer);
            end
            obj.Timer = [];
            obj.Initialized = false;
            obj.State = 0; % abort any transfer
        end
    end
    
    methods (Access = protected)
        function completion(obj, code, msg)
            if (nargin < 3)
                msg = '';
            end
            if (nargin < 2)
                code = 0;
            end
            if isfield(obj.Callbacks, 'CompletionFcn') && ~isempty(obj.Callbacks.CompletionFcn)
                obj.Callbacks.CompletionFcn(code, msg);
            end
        end
        
        function rc = send(obj, data, msg)
            rc = -1;
            try
                data = typecast(data, 'uint8');
                % Add command length as second uint32; +4 for length itself
                data = [data(1:4) typecast(uint32(length(data) + 4), 'uint8') data(5:end)];
                fwrite(obj.Fd, data, 'uint8');
                flushoutput(obj.Fd);
                rc = 0;
            catch e
                completion(obj, -1, e.message);
            end
        end
        
        function onTimer(obj, t, event)
            data = t.UserData;
            fd = data.Fd;
            if (~isempty(fd) && fd.BytesAvailable > 0)
                handleReceive(obj, fd, event);
            end
        end
        
        function handleReceive(obj, fd, event)
            if (fd.BytesAvailable == 0)
                return;
            end
            
            kStateIdle = 0;
            kStateReceivingTrace = 1;
            CMD_POS = 5;
            
            try
                switch(obj.State)
                    case kStateIdle
                        if (fd.BytesAvailable < 64) % Ensure we have at least the header
                            return
                        end
                        sig = fread(fd, 4, 'char');
                        ret = fread(fd, 15, 'int32');
                        cmd = ret(CMD_POS);
                        if ret(2) ~= 0
                            msg = sprintf('Received error code: %d', ret(2));
                            throw(MException('handleReceive:error_code', msg));
                        end
                        switch (cmd)
                            case 3 % PFP_ADC_GET_RAW in protocol.h
                                nsamp_total = ret(7);
                                obj.NumSampPacket = ret(1)/2; % each sample is 2 bytes (int16_t)
                                if (obj.S1.Capture.TraceLength >= 0 && nsamp_total ~= obj.S1.Capture.TraceLength)
                                    msg = sprintf('Requested number of samples in not equal to capture size. %d != %d', ...
                                        nsamp_total, obj.S1.Capture.TraceLength);
                                    throw(MException('handleReceive:error_code', msg));
                                end
                                if (obj.Buffer.Size ~= nsamp_total)
                                    obj.Buffer = TraceBuffer(nsamp_total, obj.Buffer.Type);
                                elseif (obj.Buffer.NumSamplesRemaining == 0) % trace can be delivered in multiple PFP_ADC_GET_RAW packets
                                    obj.Buffer.clear();
                                end
                                setScaleFactor(obj);
                                obj.State = kStateReceivingTrace;
                            case 88 % PFP_TRIG_RECEIVED
                                if (isfield(obj.Callbacks, 'TriggerFcn') && ~isempty(obj.Callbacks.TriggerFcn))
                                    obj.Callbacks.TriggerFcn(ret(CMD_POS + 1));
                                end
                        end
                    case kStateReceivingTrace
                        buf = fread(fd, min(obj.NumSampPacket, fd.BytesAvailable/2), 'int16');
                        if ~isempty(find(buf > 32763,1)) || ~isempty(find(buf < -32767,1))
                            msg = sprintf('At least one of the Input Samples exceeds the maximum value (clipping).');
                            error(msg);
                            
                            debug =1;
                        end
                        obj.NumSampPacket = obj.NumSampPacket - length(buf);
                        obj.Buffer.addSamples(buf);
                        if (isfield(obj.Callbacks, 'ReceiveTraceFcn') && ~isempty(obj.Callbacks.ReceiveTraceFcn))
                            obj.Callbacks.ReceiveTraceFcn(obj.Buffer);
                        end
                        if (obj.Buffer.NumSamplesRemaining == 0)
                            obj.State = kStateIdle;
                            completion(obj);
                        elseif (obj.NumSampPacket == 0)
                            obj.State = kStateIdle;
                        else
                        end
                    otherwise
                        error('invalid state: %d', state);
                end
            catch e
                if (~isempty(obj.Fd))
                    disconnect(obj);
                    completion(obj, -1, e.message);
                end
            end
        end
        
        function setScaleFactor(obj)
            % Converts raw counts to physical voltage units.
            %            switch (obj.S1.Hardware.OscilloscopeType)
            %                case 'redpitaya'
            % Red Pitaya ADC is 1V p-p; in LV mode, signal is scaled by
            % 499k/(499k * 2); in HV mode, signal is scaled by
            % 200k/(200k + 10M). The 0.5 is for the 1V p-p range.
            if (obj.S1.Capture.Gain == 0)
                % LV
                obj.Buffer.Scaling = 0.5 * 2;
            else
                % HV
                obj.Buffer.Scaling = 0.5 * (200e3 + 10e6)/(200e3);
            end                %               otherwise
        end
    end % methods
end % class
