function [] = f_eeg2mef(animalDir, dataBlockLen, gapThresh, mefBlockSize)
%   This is a generic function that converts data from the raw binary *.eeg 
%   format to MEF. Header information for this data is contained in the
%   *.bni files and the data is contained in the *.eeg files.  Files are
%   concatenated based on the time data in the .bni file, resulting in one
%   file per channel which includes all data sessions.
%
%   INPUT:
%       animalDir  = directory with one or more .eeg files for conversion
%       dataBlockLen = amount of data to pull from .eeg at one time, in hrs
%       gapThresh = duration of data gap for mef to call it a gap, in msec
%       mefBlockSize = size of block for mefwriter to wrte, in sec
%
%   OUTPUT:
%       MEF files are written to 'mef\' subdirectory in animalDir, ie:
%       ...animalDir\mef\
%
%   USAGE:
%       f_eeg2mef('Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000',0.1,10000,10);
%
%     
%     dbstop in f_eeg2mef at 25;

    % portal time starts at midnight on 1/1/1970
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
    
    % convert one channel at a time; first 4 channels are important for
    % dichter data set
    for c = 1: 4  % 1-4 are CA1 and DG, except r151 and r152
      % open mef file, write metadata to the mef file
      mefFile = fullfile(outputDir, ['Jensen_' animalName '_ch' num2str(c, '%0.2d') '_' chanLabels{c} '.mef']);
      h = edu.mayo.msel.mefwriter.MefWriter(mefFile, mefBlockSize, animalSF, gapThresh); 
      h.setSubjectID(animalName);
      h.setUnencryptedTextField(animalVideo);
      h.setSamplingFrequency(animalSF);
      h.setPhysicalChannelNumber(c);
      h.setVoltageConversionFactor(animalVFactor);
      h.setChannelName(chanLabels{c});
      fileEnd = 0;    % for catching overlapping files
      dropSamples = 0;

      % run through each file in the directory and append it to mef file
      for f = 1:length(EEGList)
        try
          % open BNI file to get metadata and recording start for this file
          fid=fopen(BNIList(f).name);   % METADATA IN BNI FILE
          metadata=textscan(fid,'%s = %s %*[^\n]');
          fclose(fid);

          % map timeseries data to memmap structure for fast read/write
          fid2=fopen(fullfile(animalDir,EEGList(f).name));                  % DATA IN .EEG FILE
          fseek(fid2,0, 1);
          numSamples=(ftell(fid2)/animalNChan)/2;         % /number of channels / 2 (==> int16)
          fclose(fid2);
          m=memmapfile(fullfile(animalDir,EEGList(f).name),'Format',{'int16',[animalNChan numSamples],'x'});

          % make sure the beginning of this file does not overlap the end
          % of the previous file
          if BNIList(f).startTime <= fileEnd
            dropSamples = min([ceil((fileEnd-BNIList(f).startTime)/1e6*animalSF) numSamples]);              
          end
          
          % calculate end time of recording for file, output to display
          BNIList(f).recordStart = datestr(datenum(BNIList(f).startTime/1e6/3600/24)+dateOffset-1);
          fileEnd = BNIList(f).startTime + numSamples/animalSF*1e6;
          recordEnd = datestr(datenum(fileEnd/1e6/3600/24)+dateOffset-1);
          fprintf('file: %s (%d/%d)   start: %s   end: %s   chan: %d/%d\n',...
            EEGList(f).name,f,length(EEGList),BNIList(f).recordStart,...
            recordEnd, c, animalNChan);

          % need to pull small blocks of data from memmap file
          blockSize = dataBlockLen * 3600 * animalSF;  % amount of data to pull from EEG file at one time, in samples
          numBlocks = ceil(numSamples/blockSize);
          reverseStr = '';

          % write data block by block to mef file
          for b = 1: numBlocks
            curPt = 1+(b-1)*blockSize;
            endPt = min([b*blockSize numSamples]);
            blockOffset = 1e6 * (b-1) * blockSize / animalSF;

            % create time, data vectors
            data = m.data.x(c,curPt:endPt);
            timeVec = 0:length(data)-1;
            timeVec = timeVec ./ animalSF * 1e6;
            timeVec = timeVec + BNIList(f).startTime + blockOffset;
            
            if dropSamples > 0
              data(1:dropSamples) = [];
              timeVec(1:dropSamples) = [];
              fprintf('Dropped %d seconds. File: %s\n', ...
                ceil(dropSamples/animalSF),EEGList(f).name);
              dropSamples = 0;
            end

            % send time, data vectors to mef file
            try
              if length(data > 0)
                h.writeData(data, timeVec, length(data));
              end
            catch err2
              h.close();
              disp(err2.message);
              rethrow(err2);
            end
          end
          
        % in case of trouble above, be sure to close file before exiting
        catch err
          if (isempty(regexp(EEGList(f).name,'r\d{3}_\d{3}.eeg')))
            fprintf('Disregarding %s\n', EEGList(f).name);
            reverseStr = '';
          else
            h.close();
            disp(err.message);
            rethrow(err);
          end
        end
      end
      h.close();
      toc
    end
end