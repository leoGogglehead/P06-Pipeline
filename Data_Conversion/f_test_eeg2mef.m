function [] = f_test_eeg2mef(sessionData, animalDir, dataBlockLen)
%   This is a generic function that compares .mef data (from the portal)
%   to the original .eeg file (use f_eeg2mef to convert data).  This
%   function checks metadata as well as timeseries data.
%
%   INPUT:
%       sessionData  = portal IEEGDataset object, i.e. session.data()
%       animalDir = path to the .eeg files comprising the sessionData
%       dataBlockLen = hrs; amount of data to pull from eeg/portal at once
%
%   OUTPUT:
%       If the files differ at any point, this script will stop execution 
%       and enter keyboard mode (K>>) to allow analysis of the data
%
%   USAGE:
%       f_test_eeg2mef(session.data(d),Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000,0.1);
%
%  datestr(timeVec(1)/1e6/3600/24)
  dbstop in f_test_eeg2mef at 139;
%     

    dateFormat = 'mm/dd/yyyy HH:MM:SS';
    dateOffset = datenum('1/1/1970 0:00:00',dateFormat);  % portal time

    % get list of data files in the animal directory
    % remove files that do not match the r###_### naming convention
    % remove .bni, .mat, .txt, .rev files
    EEGList = dir(fullfile(animalDir,'*'));
    removeThese = false(length(EEGList),1);
    for f = 1:length(EEGList)
      if (isempty(regexpi(EEGList(f).name,'r\d{3}_\d{3}\.')) || ...
        ~isempty(regexpi(EEGList(f).name,'bni')) || ...
        ~isempty(regexpi(EEGList(f).name,'mat')) || ...
        ~isempty(regexpi(EEGList(f).name,'txt')) || ...
        ~isempty(regexpi(EEGList(f).name,'lay')) || ...
        ~isempty(regexpi(EEGList(f).name,'rev')))
        removeThese(f) = true;
      end
    end
    EEGList(removeThese) = [];

    % confirm there is data in the directory
    assert(length(EEGList) >= 1, 'No data found in directory.');

    % create output directory (if needed) for mef files
    outputDir = fullfile(animalDir, 'mef');
    if ~exist(outputDir, 'dir');
      mkdir(outputDir);
    end

    % compile list of BNI filenames and start times
    for f = 1:length(EEGList)  
      try % try using the .bni extension
        if (regexp(EEGList(f).name,'eeg'))
          bni_name = fullfile(animalDir,[EEGList(f).name(1:8) '.bni']);
        else
          bni_name = fullfile(animalDir,[EEGList(f).name '.bni']);
        end
        fid=fopen(bni_name);   % METADATA IN BNI FILE
        metadata=textscan(fid,'%s = %s %*[^\n]');
        fclose(fid);
      catch % if problem, try using the .bni_orig extension
        if (regexp(EEGList(f).name,'eeg'))
          bni_name = fullfile(animalDir,[EEGList(f).name(1:8) '.bni_orig']);
        else
          bni_name = fullfile(animalDir,[EEGList(f).name '.bni_orig']);
        end
        fid=fopen(bni_name);   % METADATA IN BNI FILE
        assert(fid > 0, 'Check BNI file exists: %s\n', EEGList(f).name);
        metadata=textscan(fid,'%s = %s %*[^\n]');
        fclose(fid);
      end
      BNIList(f).name = bni_name;
      recordDate = char(metadata{1,2}(strcmp(metadata{:,1}, 'Date')));
      recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Time')));
      BNIList(f).dateNumber = datenum(sprintf('%s %s', recordDate, recordTime), dateFormat);
      BNIList(f).startTime = (BNIList(f).dateNumber - dateOffset + 1) * 24 * 3600 * 1e6;
      
      if f == 1 % if first BNI file, store the metadata
        % get number of channels, sampling frequency, channel labels...
        animalName = sscanf(char(metadata{1,2}(strcmp(metadata{:,1},'eeg_number'))),'%c',4);
        animalVideo = metadata{1,2}(strcmp(metadata{:,1},'Comment'));
        animalSF = str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate')));
        animalNChan = str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile')));
        animalVFactor = str2double(metadata{1,2}{strcmp(metadata{:,1},'UvPerBit')});
        chanLabels = strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),',');
      else % check the metadata matches the metadata in the first file
        assert(strcmp(sscanf(char(metadata{1,2}(strcmp(metadata{:,1},'eeg_number'))),'%c',4),animalName),'Animal name mismatch: %s', EEGList(f).name);
        assert(str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate'))) == animalSF, 'Sampling rate mismatch: %s', EEGList(f).name);
        assert(str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile'))) == animalNChan, 'Number of channels mismatch: %s', EEGList(f).name);
        assert(str2double(metadata{1,2}{strcmp(metadata{:,1},'UvPerBit')}) == animalVFactor, 'Voltage calibration mismatch: %s', EEGList(f).name);
        assert(sum(cellfun(@strcmp,chanLabels,strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),','))) == length(chanLabels), 'Channel label mismatch: %s',EEGList(f).name);
%       if sum(cellfun(@strcmp,chanLabels,strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),','))) ~= length(chanLabels)
%         keyboard;
%       end
      end
    end
    [~,IX] = sort([BNIList.dateNumber]); % sort EEGList by start time in .BNI
    EEGList = EEGList(IX);
    BNIList = BNIList(IX);
          
    assert(length(EEGList) >= 1, 'No data found in directory.');
    fid=fopen(fullfile(animalDir,[EEGList(1).name(1:8) '.bni']));   % METADATA IN BNI FILE
    metadata=textscan(fid,'%s = %s %*[^\n]');
    fclose(fid);
    
    % get number of channels, sampling frequency, and channel labels
    animalName = sscanf(char(metadata{1,2}(strcmp(metadata{:,1},'eeg_number'))),'%c',4);
    animalVideo = metadata{1,2}(strcmp(metadata{:,1},'Comment'));
    animalSF = str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate')));
    animalNChan = str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile')));
    animalVFactor = str2double(metadata{1,2}{strcmp(metadata{:,1},'UvPerBit')});
    chanLabels = strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),',');
    recordDate = char(metadata{1,2}(strcmp(metadata{:,1}, 'Date')));
    recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Time')));
    dateNumber = datenum(sprintf('%s %s', recordDate, recordTime), dateFormat);
    startTime = (dateNumber - dateOffset + 1) * 24 * 3600 * 1e6;
    
    % test one channel at a time
    for c = 1: 1%animalNChan
      % get portal metadata
      portalSF = sessionData.channels(c).sampleRate;
      portalNChan = length(sessionData.channels());
      portalVFactor = sessionData.channels(c).get_tsdetails().getVoltageConversion();
      portalChanLabel = sessionData.channels(c).label();
      portalStart = sessionData.channels(c).get_tsdetails().getStartTime();
      portalEnd = sessionData.channels(c).get_tsdetails().getEndTime();

      % confirm metadata matches for each file
      assert(portalSF == animalSF, 'Sampling rate mismatch: %s', EEGList(1).name);
%       assert(portalNChan == animalNChan, 'Number of channels mismatch: %s', EEGList(1).name);
      assert(portalVFactor == animalVFactor, 'Voltage calibration mismatch: %s', EEGList(1).name);
%       assert(strcmp(portalChanLabel, sprintf('ch%02d_%s',c,chanLabels{c})), 'Channel label mismatch: %s',EEGList(1).name);
      assert(abs(portalStart-startTime) < 1, 'Start time mismatch: %s', EEGList(1).name);
      
      reverseStr = '';

      for f = 1:length(EEGList)
        try
          % confirm file name matches expected name format - to weed out unrelated files
%           assert(~isempty(regexp(EEGList(f).name,'r\d{3}_\d{3}.eeg')), 'File name mismatch: %s', EEGList(f).name);

          assert(exist(BNIList(f).name,'file')==2, 'BNI file not found: %s', BNIList(f).name);
          fid=fopen(BNIList(f).name);   % METADATA IN BNI FILE
          metadata=textscan(fid,'%s = %s %*[^\n]');
          fclose(fid);
          recordDate = char(metadata{1,2}(strcmp(metadata{:,1}, 'Date')));
          recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Time')));
          dateNumber = datenum(sprintf('%s %s', recordDate, recordTime), dateFormat);
          fileStart = (dateNumber - dateOffset + 1) * 24 * 3600 * 1e6;   % start time of data in this file
          offsetUsec = fileStart - startTime;
          portalOffset = floor(offsetUsec / 1e6 * 2000);
          
          fid2=fopen(fullfile(animalDir,EEGList(f).name));  % DATA IN .EEG FILE
          fseek(fid2,0, 1);
          numSamples=(ftell(fid2)/animalNChan)/2;         % /number of channels / 2 (==> int16)
          fclose(fid2);
          m=memmapfile(fullfile(animalDir,EEGList(f).name),'Format',{'int16',[animalNChan numSamples],'x'});

          fileEnd = fileStart + numSamples/2000*1e6;
          recordEnd = datestr(datenum(fileEnd/1e6/3600/24)+dateOffset-1);
          fprintf('file: %s   start: %s %s   end: %s \n',EEGList(f).name,recordDate,recordTime,recordEnd);

          blockSize = dataBlockLen * 3600 * animalSF;  % amount of data to pull from EEG file at one time, in samples
          numBlocks = ceil(numSamples/blockSize);
          for b = 1: numBlocks
            msg = sprintf(...
              'Testing %s channel %d. Percent finished: %3.1f.\\n',...
              EEGList(f).name, c, 100*b/numBlocks);
            fprintf([reverseStr, msg]);
            reverseStr = repmat(sprintf('\b'), 1, length(msg)-1);

            curPt = 1 + (b-1)*blockSize;
            endPt = min([b*blockSize numSamples]);
            
            eegData = m.data.x(c,curPt:endPt);
            portalData = sessionData.getvalues(curPt+portalOffset:endPt+portalOffset,c);
            
            diffInd = find(double(eegData)' - portalData,1);
            if ~isempty(diffInd)
              fprintf('recalculating offset: %s\n',EEGList(f).name);
              newportalOffset = round(offsetUsec / 1e6 * 2000);
              portalData = sessionData.getvalues(curPt+newportalOffset:endPt+newportalOffset,c);
              diffInd = find(double(eegData)' - portalData,1);
              if ~isempty(diffInd)
                keyboard;
              else
                portalOffset = newportalOffset;
              end
            end
          end
          reverseStr = '';
        catch err
          if (isempty(regexp(EEGList(f).name,'r\d{3}_\d{3}.eeg')))
            fprintf('Disregarding %s\n', EEGList(f).name);
            reverseStr = '';
          else
            rethrow(err);
          end
        end
      end
      toc
    end
end