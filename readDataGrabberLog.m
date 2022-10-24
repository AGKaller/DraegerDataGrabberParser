function [S, rawVarNames] = readDataGrabberLog(infile)
% [S, rawVarNames] = readDataGrabberLog(infile)

% TODO: support zipped input files -> zipToolsPy


REF_DATENUM = datenum('1970-01-01 00:00:00');
I_FIRST_VAR = 5; % Time [ms],Date,Time,Rel.Time [s]
MS2DAY = 1000*60*60*24;
PROGBARSIZ = 10; % progress bar size


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

[~,fnam] =  fileparts(infile);
finfo = dir(infile);
fprintf('Loading ''%s'':\n\t%.1fMB, %d variables: ', ...
    fnam, finfo.bytes/2^20, nVar);

if nVar<1
    S=struct();
    fprintf('\n');
    fclose(fid);
    return;
end

scanFrmt = ['%f %*10c %*12c %*f' repmat(' %f',1,nVar)];
mtchFrmt = ['^' repmat('([^,\n]*),?',1,I_FIRST_VAR+nVar-2) '([^,\n]*)[^\n]*$'];
CHNKSZ = 1e7;
DELIM = ',';
data = [];

msgSiz = fprintf('%3.0f%% [%s]', 0, repmat(' ',1,PROGBARSIZ));
try
    while ~feof(fid)
        dataChnk = fread(fid,[1,CHNKSZ], 'uint8=>char');
        if ~feof(fid)
            dataChnk = [dataChnk fgets(fid)];
        end
    
        dataChnk = regexp(dataChnk,mtchFrmt,'tokens','lineanchors');
        dataChnk = vertcat(dataChnk{:});
        if isempty(dataChnk{end}), dataChnk{end} = ' '; end
        dataChnk = strjoin(dataChnk',DELIM);
        dataChnk = textscan(dataChnk,scanFrmt,'Delimiter',DELIM);
        data = [data; horzcat(dataChnk{:})];
    
        perc  = ftell(fid)/finfo.bytes;
        nBar = round(perc*PROGBARSIZ);
        fprintf(repmat('\b',1,msgSiz));
        msgSiz = fprintf('%3.0f%% [%s%s]', ...
            perc*100, repmat('|',1,nBar), repmat(' ',1,PROGBARSIZ-nBar));
    end

catch ME
    fprintf('\n');
    flcose(fid);
    rethrow(ME);
end

fclose(fid);

nrows = size(data,1);
lreadSiz = ceil(log10(nrows+1));
fprintf('. %*d lines read\n', ...
            lreadSiz, nrows);

% convert time stamp
data(:,1) = data(:,1)/MS2DAY + REF_DATENUM;

% make output
for k = 1:nVar
    cidx = k+1;
    ridx = ~isnan(data(:,cidx));
    S.(varNames{k}) = [data(ridx,1) data(ridx,cidx)];
end

end

