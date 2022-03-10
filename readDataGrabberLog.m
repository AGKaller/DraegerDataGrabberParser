function [S, rawVarNames] = readDataGrabberLog(infile)
% [S, rawVarNames] = readDataGrabberLog(infile)

% TODO: avoid dynamic structure indexing, its slooooow!

REF_DATENUM = datenum('1970-01-01 00:00:00');
I_FIRST_VAR = 5; % Time [ms],Date,Time,Rel.Time [s]
MS2DAY = 1000*60*60*24;

colWarnFlag = 0;

% get number of rows
[nrows] = getTxtFileLength(infile); % , nbyte

[fid, errMsg] = fopen(infile,'rt');
assert(fid>0,'Could not open file ''%s''\n because ''%s''.',infile,errMsg);

% get column names...
tline = fgetl(fid);
rawVarNames = strsplit(tline,',');
rawVarNames = rawVarNames(I_FIRST_VAR:end);
% and make valid variable names
varNames = matlab.lang.makeValidName(rawVarNames);
varNames = matlab.lang.makeUniqueStrings(varNames);

% preallocate output
nVar = numel(varNames);
for k = 1:nVar
    S.(varNames{k}) = nan(nrows,2);
end
cnter = zeros(size(varNames));

% loop lines
progBarSiz = 20;
lreadSiz = ceil(log10(nrows+1));
msgSiz = fprintf('%*d/%d lines read,   0%% [%s]',lreadSiz, 0, nrows, repmat(' ',1,progBarSiz));
for il = 2:nrows
    tline = fgetl(fid);
%     v = strsplit(tline,',','CollapseDelimiters',false);
    % strsplit is basically a wrapper for regexp and has much overhead.
    v = regexp(tline,',','split');
    % convert ms to days and add reference datetime:
    time = str2double(v{1})/MS2DAY + REF_DATENUM;
    v_ = v(I_FIRST_VAR:end);
    
    if numel(v_) > nVar
        if ~colWarnFlag
            warning('readDataGrabberLog:lineHasTooManyValues', ...
                    'Line %d has more values than there are headers. Ignoring additional values.\n File: %s', ...
                    il, infile);
            colWarnFlag = 1; % issue warning only once
            msgSiz = 0;
        end
        v_ = v_(1:nVar);
    end
    
    k = find(~cellfun(@isempty,v_));
    % str2double is time consuming, only apply to non-empty colums!
    v_n = str2double(v_(k));
    cnter(k) = cnter(k)+1;
    for ik = 1:numel(k)
        S.(varNames{k(ik)})(cnter(k(ik)),:) = [time v_n(ik)];
    end
    
    if rem(il,1000)==0
        perc  = il/nrows;
        nBar = round(perc*progBarSiz);
        fprintf(repmat('\b',1,msgSiz));
        msgSiz = fprintf('%*d/%d lines read, % 3.0f%% [%s%s]', ...
            lreadSiz, il, nrows, perc*100, repmat('|',1,nBar), repmat(' ',1,progBarSiz-nBar));
    end
end

fprintf(repmat('\b',1,msgSiz));
fprintf('%*d/%d lines read, 100%% [%s]\n', ...
            lreadSiz, il, nrows, repmat('|',1,progBarSiz));
fclose(fid);

for k = 1:nVar
    iMax = find(~isnan(S.(varNames{k})(:,1)),1,'last');
    S.(varNames{k}) = S.(varNames{k})(1:iMax,:);
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