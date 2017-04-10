function [ types ] = LoadDataTypes( fname )
%Load dataTypes from text file into a dictionary for validation

types = containers.Map;

fd = fopen(fname);
% make sure you include dataTypes.txt when building the exe.\n');
% mcc -mv -o P2ScanTestR2016b P2Scan.m -a C:\Users\PFP\AppData\Local\Temp\pfpStaging\P2Scan\branch\P2Scan_RC1_Coder\ui\dataTypes.txt

while feof(fd) == 0
    line = fgetl(fd);
    c = textscan(line, '%s %s');
    types(c{1}{1}) = c{2}{1};
end
fclose(fd);

