classdef TraceBuffer < handle
    properties (SetAccess = public)
        Scaling = 1;
    end
    
    properties (SetAccess = private)
        Samples = [];
        Size = 0;
        Type = '';
        NumSamplesReceived = 0;
        NumSamplesRemaining = 0;
    end
    methods
        function obj = TraceBuffer(sz, type)
            obj.Samples =  zeros(sz, 1, type);
            obj.Size = sz;
            obj.Type = type;
            obj.NumSamplesRemaining = sz;
        end
        
        function addSamples(obj, samples)
            if (length(samples) > length(obj.Samples) - obj.NumSamplesReceived)
                n = length(obj.Samples) - obj.NumSamplesReceived;
                warning('Limiting number of samples to %d', n);
                samples = samples(1:n);
            end
            obj.Samples(obj.NumSamplesReceived + 1:obj.NumSamplesReceived + length(samples)) = samples;
            obj.NumSamplesReceived = obj.NumSamplesReceived + length(samples);
            obj.NumSamplesRemaining = obj.NumSamplesRemaining - length(samples);
            % On completion, scale to physical units.
            if (obj.NumSamplesRemaining == 0)
                obj.Samples = double(obj.Samples)/32768*obj.Scaling;
            end
        end
        
        function clear(obj)
           obj.Samples = zeros(size(obj.Samples), obj.Type);
           obj.NumSamplesReceived = 0;
           obj.NumSamplesRemaining = obj.Size;
        end
    end
end