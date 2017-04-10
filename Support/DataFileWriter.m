function [Result] = DataFileWriter(FileName,Data,frmt)
% File writer use to write binary data to file



DataLength = length(Data);

SplitFrmt = char(split(frmt,'_'));
ReqType = SplitFrmt(1,1); % R or C
ReqPrecision = SplitFrmt(1,2:end); % f,i, u
ReqEndianess = SplitFrmt(2,1:2);

switch ReqType
    case 'r'
        Type = 'R';
    case 'c'
        Type = 'C';
end

switch ReqPrecision
    case 'f8'
        Precision  = 'float';
    case 'f16'
        Precision  = 'float';
    case 'f32'
        Precision  = 'float';
    case 'i8'
        Precision = 'int8';
    case 'i16'
        Precision = 'int16';
    case 'i32'
        Precision = 'int32';
    case 'u8'
        Precision = 'uint8';
    case 'u16'
        Precision = 'uint16';
    case 'u32'
        Precision = 'uint32';
end

switch ReqEndianess
    case 'le'
        Endianess = 'l';
    case 'be'
        Endianess = 'b';
end




[FileID, errmsg] = fopen(FileName,'w');



fwrite(FileID,Data,Precision, Endianess); 

fclose(FileID);
Result = 1;
debug = 1;

