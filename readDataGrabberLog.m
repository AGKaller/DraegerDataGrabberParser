function [S, rawVarNames] = readDataGrabberLog(infile)
% [S, rawVarNames] = readDataGrabberLog(infile)

% TODO: support zipped input files -> zipToolsPy


REF_DATENUM = datenum('1970-01-01 00:00:00');
I_FIRST_VAR = 5; % Time [ms],Date,Time,Rel.Time [s]
MS2DAY = 1000*60*60*24;
PROGBARSIZ = 20; % progress bar size


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
fprintf('Loading ''%s'': %.1fMB, %d variables. ', ...
    fnam, finfo.bytes/2^20, nVar);

if nVar<1
    S=struct();
    fprintf('\n');
    return;
end

frmt = ['%f %*10c %*12c %*f' repmat(' %f',1,nVar)];
data = textscan(fid,'%s','Delimiter','\n');
% TODO: better use fread() to read chunk (take care of memory!) into single
% vector, replace empty values ',,' by ',*,' to be handled by textscan
% ('TreatAsEmpty' parameter) and remove additional colums (see 22-10-14...)
% using regexprep(). Is this still faster? It is some code to write....

fclose(fid);
data = data{1};

% preallocate output
nrows = numel(data);
nVar = numel(varNames);
vals = cell(nrows,nVar+1);

lreadSiz = ceil(log10(nrows+1));
msgSiz = fprintf('%*d/%d lines read,   0%% [%s]',lreadSiz, 0, nrows, repmat(' ',1,PROGBARSIZ));
for il = 1:nrows
    vals(il,:) = textscan(data{il},frmt,'Delimiter',',');
    if rem(il,1000)==0
        perc  = il/nrows;
        nBar = round(perc*PROGBARSIZ);
        fprintf(repmat('\b',1,msgSiz));
        msgSiz = fprintf('%*d/%d lines read, % 3.0f%% [%s%s]', ...
            lreadSiz, il, nrows, perc*100, repmat('|',1,nBar), repmat(' ',1,PROGBARSIZ-nBar));
    end
end
fprintf(repmat('\b',1,msgSiz));
fprintf('%*d/%d lines read, 100%% [%s]\n', ...
            lreadSiz, il, nrows, repmat('|',1,progBarSiz));

... TODO: process values
data{1} = data{1}/MS2DAY + REF_DATENUM;

% make output
for k = 1:nVar
    cidx = I_FIRST_VAR+k-1;
    ridx = ~isnan(data{cidx});
    S.(varNames{k}) = [data{1}(ridx) data{cidx}(ridx)];
end

fprintf(' %d lines.\n',numel(data{1}));

end

