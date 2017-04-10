function p = GetPlatform
p.Scaling = 1.0;
if ispc
    p.Platform = 'windows';
    p.Scaling = 0.75; % all dimensions and point sizes must be scaled by 75% vs. mac/unix
elseif ismac
    p.Platform = 'mac';
else
    p.Platform = 'unix';
end
