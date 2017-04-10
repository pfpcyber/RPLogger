function [Result] = MetaFileWriter(FileNamePath,value)
% File writer for meta data 
opt.SingletCell = 1;
opt.FileName = FileNamePath;
j= savejson('',value,opt);

%j= savejson('',value,FileNamePath);

Result = 1;

