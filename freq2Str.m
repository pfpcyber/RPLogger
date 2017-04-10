function str = freq2Str(freq)
mhz = freq/1e6;
if (mhz > 0.95)
    str = sprintf('%g MHz', mhz);
    return;
end

khz = freq/1e3;
if (khz > 0.95)
    str = sprintf('%g KHz', khz);
else
    str = sprintg('%g Hz', freq);
end