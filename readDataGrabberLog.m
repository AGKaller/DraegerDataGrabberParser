function [S, rawVarNames] = readDataGrabberLog(infile)
% [S, rawVarNames] = readDataGrabberLog(infile)

REF_DATENUM = datenum('1970-01-01 00:00:00');
I_FIRST_VAR = 5; % Time [ms],Date,Time,Rel.Time [s]
MS2DAY = 1000*60*60*24;


% get number of rows
% [nrows] = getTxtFileLength(infile); % , nbyte

[fid, errMsg] = fopen(infile,'rt');
assert(fid>0,'Could not open file ''%s''\n because ''%s''.',infile,errMsg);

% get column names...
tline = fgetl(fid);
rawVarNames = strsplit(tline,',');
rawVarNames = rawVarNames(I_FIRST_VAR:end);
% and make valid variable names
varNames = matlab.lang.makeValidName(rawVarNames);
varNames = matlab.lang.makeUniqueStrings(varNames);
nVar = numel(varNames);

frmt = ['%f %s %s %f' repmat(' %f',1,nVar)];
data = textscan(fid,frmt,'Delimiter',',');
data{1} = data{1}/MS2DAY + REF_DATENUM;

% preallocate output
for k = 1:nVar
    cidx = I_FIRST_VAR+k-1;
    ridx = ~isnan(data{cidx});
    S.(varNames{k}) = [data{1}(ridx) data{cidx}(ridx)];
end

end

