function plot_waveform(handle, S1, trace)

if (~isa(trace, 'double'))
    trace = double(trace);
end

xlim = 1:length(trace);
% Reduce plot time for long capture lengths.
if (length(trace) >= 1e6)
    n = ceil(length(trace) / 1e6);
    b = ones(10,1)/10; % low pass filter to prevent aliasing when drawing
    a = 1;
    trace = filter(b, a, trace);
    trace = trace(1:n:end);
    xlim = xlim(1:n:end);
end
plot(handle, xlim, trace);
% ylim(handle, [-S1.Capture.VerticalRange*1000 S1.Capture.VerticalRange*1000]);
minval = min(trace);
maxval = max(trace);
range = maxval - minval;
headroom = range*0.0125;
ylim(handle, [minval - headroom, maxval + headroom]);
ylabel(handle, 'Volts');
drawnow;