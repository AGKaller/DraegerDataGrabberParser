function [S, rawVarNames] = readDataGrabberLog(infile)
% [S, rawVarNames] = readDataGrabberLog(infile)

% TODO:
% speedup with textscan:
%   test = textscan(fid,'%d64 %{yyyy-MM-dd}D %{HH:mm:ss.SSS}D %f %f %f %f...
%                        %f %f <USE AS MANY %f AS NEEDED!>','HeaderLines',1,'Delimiter',','); 

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



function [nrows, nbyte] = getTxtFileLength(infile)
%

[fid, errMsg] = fopen(infile,'rt');
assert(fid>0,'getTxtFileLength:CouldNotOpenFile','Could not open file ''%s''\n because ''%s''.',infile,errMsg);

% get number of rows
chunksize = 1e9; % read chuncks of 10MB at a time
nrows = 0;
while ~feof(fid)
   ch = fread(fid, chunksize, '*uint8');
   if isempty(ch)
       break
   end
   nrows = nrows + sum(ch == 10);
end
% s = fread(fid,Inf,'*uint8');
% nrows = sum(s==10);
fseek(fid,-1,1);
if fread(fid,1,'*uint8')~=10
    nrows = nrows + 1;
end

% get size (bytes)
if nargout>1
    nbyte = ftell(fid);
end

fclose(fid);

end