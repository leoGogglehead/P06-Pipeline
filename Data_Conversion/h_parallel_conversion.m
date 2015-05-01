function convertArcToMef_par(channels)
subjOrder = {'NVC1001_23_002','NVC1001_23_003','NVC1001_23_004','NVC1001_23,005', ...
    'NVC1001_23_006','NVC1001_23_007','NVC1001_24_001','NVC1001_24_002','NVC1001_24_004', ...
    'NVC1001_24_005','NVC1001_25_001','NVC1001_25_002','NVC1001_25_003','NVC1001_25_004','NVC1001_25_005'};
startUTC = {'1276155634000','','','','','','','','','','1276155634000','','','','',''};
% add paths
addpath(genpath('ARCdataviewer'));
javaaddpath('java_MEF_writer\MEF_writer.jar')

% set mef params
mefGapThresh = 10000; % msec; min size of gap in data to be called a gap
mefBlockSize = 15; % sec; size of block for mefwriter to write
getMefWriter= @(a,b,c,d) edu.mayo.msel.mefwriter.MefWriter(a,b,c,d);
k = 16;
%% load patient
try
    delete(gcp)
catch
end
parpool(16)
parfor c = 1:numel(channels)
    ch = channels(c)
    %Declare and setup AES object
    javaaddpath('java_MEF_writer\MEF_writer.jar')
    newAES = AES();
    newAES.ecogDir = sprintf('NVC1001_24_004\\%s',num2str(ch));

    newECoGSource = ARCDataReader(ECoGFile(), newAES.ecogDir, false, false, '');

    %% load meta data
    subjectID = newECoGSource.GetSubjectID();
    newAES.subjectID = subjectID;

    fs = newECoGSource.fileType.sampleRate;


    %% open mef
    mw = getMefWriter([subjectID '_' sprintf('%02d',ch) '.mef'], mefBlockSize, fs,mefGapThresh); %10000 samples

    %% write meta data to mef
    mw.setVoltageConversionFactor(1) % data * CF = uV
    mw.setSamplingFrequency(fs)
    mw.setInstitution('PENN')
    mw.setSubjectID(subjectID)
    mw.setChannelName(num2str(ch))

    startuUTC = 1276155634000000;
    % for each week
    for i = 1:newECoGSource.blockCount

        disp([num2str(ch) ':' num2str(i/newECoGSource.blockCount)]);
        % load the ARC data
        %block is 241920000 samples (7 days)
        %one day is equal to  34560000 samples

        beginSamp = newECoGSource.blockInfo(i).ixBegin;
        endSamp = newECoGSource.blockInfo(i).ixEnd;
        totalSamp = endSamp-beginSamp;
        sampBlock = floor(totalSamp/k); %write ~1 day at a time
        for j = 1:k
            sampRange = [(beginSamp + (j-1)*sampBlock) beginSamp + (j*sampBlock)-1];
            if j==k
                sampRange(end) = endSamp;
            end
                data = newECoGSource.ReadSamples(sampRange(1),sampRange(2),1); 

                startTimeUTC = startuUTC + sampRange(1)/400*1e6;
                endTimeUTC = startuUTC + sampRange(2)/400*1e6;
                
                removeIdx = data(:,2)==1;
                data(removeIdx,:) = [];
                % get timestamp, convert to uUTC
                ts = startTimeUTC:(1/fs)*1e6:endTimeUTC;

                % change no data to blanks, remove from timestamp
                ts(removeIdx) = [];

                % if block is not empty
                try
                    if numel(data) ~= 0 
                        % write mef
                        mw.writeData(data(:,1), ts, length(data(:,1)));
                    end
                catch
                    disp('Unable to write, retrying...');
                    mw.writeData(data(:,1), ts, length(data(:,1)));
                end
                
        end
    end
    % close mef
    try
      mw.close
    catch
        disp('Unable to close...');
        mw.close
    end
    mw
end

%




