function [Result] = JsonFileWriter(FileNamePath,value)
% File writer for meta data 
opt.SingletCell = 1;
opt.FileName = FileNamePath;
j= savejson('',value,opt);

Result = 1;

