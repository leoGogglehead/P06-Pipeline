function [] = f_rev2portal(dataset, animalDir, layerName)
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
  %  dbstop in f_rev2portal at 128

  %....... Load .rev annotations  
  revDir = fullfile(animalDir,'Hz250Rev');
  bniDir = fullfile(animalDir,'Hz2000');
  
  % open first BNI file in directory to get start time of recording
  try % try using the .bni extension
    bni_name = fullfile(bniDir, [animalDir(39:42) '_000.bni']);
    fid=fopen(bni_name);   % METADATA IN BNI FILE
    metadata=textscan(fid,'%s = %s %*[^\n]');
    fclose(fid);
  catch % if problem, try using the .bni_orig extension
    bni_name = fullfile(bniDir, [animalDir(39:42) '_000.bni_orig']);
    fid=fopen(bni_name);   % METADATA IN BNI FILE
    assert(fid > 0, 'Check BNI file exists: %s\n', rev250List(f).name);
    metadata=textscan(fid,'%s = %s %*[^\n]');
    fclose(fid);
  end
  recordDate = char(metadata{1,2}(strcmp(metadata{:,1}, 'Date')));
  recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Time')));
  dateFormat = 'mm/dd/yyyy HH:MM:SS';
  dateOffset = datenum(sprintf('%s %s', recordDate, recordTime), dateFormat); % in days

  % get list of .rev files in the Hz250Rev directory
  % remove files that start with '.'
  rev250List = dir(fullfile(revDir,'*.rev'));
  removeThese = false(length(rev250List),1);
  rev250List(removeThese) = [];
  for f = 1:length(rev250List)
    if (strncmp(rev250List(f).name,'.',1))
      removeThese(f) = true;
    end
  end
  rev250List(removeThese) = [];
  
  % there may be some .rev files in the Hz2000 directory
  rev2000List = dir(fullfile(bniDir,'*.rev'));
  removeThese = false(length(rev2000List),1);
  rev2000List(removeThese) = [];
  for f = 1:length(rev2000List)
    if (strncmp(rev2000List(f).name,'.',1))
      removeThese(f) = true;
    end
  end
  rev2000List(removeThese) = [];
  
  % confirm .rev files are present
  if length(rev250List)+length(rev2000List) == 0
    fprintf('\nNo .rev files found in directory: %s\n', animalDir(39:42));
    return;
  end

  % create revList, which holds paths/names of all .rev files in both dirs
  revList = cell((length(rev250List) + length(rev2000List)),2);
  for f = 1:size(revList,1)
    if f <= length(rev250List) && ~isempty(rev250List)
      revList{f,1} = fullfile(revDir, rev250List(f).name);
      revList{f,2} = fullfile(bniDir, rev250List(f).name(1:8));
    else
      revList{f,1} = fullfile(bniDir, rev2000List(f-length(rev250List)).name);
      revList{f,2} = fullfile(bniDir, rev2000List(f-length(rev250List)).name(1:8));
    end
  end

  allLabels = cell(1,3);
  for f = 1:size(revList,1) 
    % open and scan .rev file
    fid = fopen(revList{f,1});   
    revText = textscan(fid,'%f %*[^:]:%[^;];%*[^;];%*[^:]:%[^<]<%*[^>]>');
    fclose(fid);
    
    % open and scan associated .bni file
    try % try using the .bni extension
      bni_name = [revList{f,2} '.bni'];
      fid=fopen(bni_name);   % METADATA IN BNI FILE
      metadata=textscan(fid,'%s = %s %*[^\n]');
      fclose(fid);
    catch % if problem, try using the .bni_orig extension
      bni_name = [revList(f) '.bni_orig'];
      fid=fopen(bni_name);   % METADATA IN BNI FILE
      assert(fid > 0, 'Check BNI file exists: %s\n', rev250List(f).name);
      metadata=textscan(fid,'%s = %s %*[^\n]');
      fclose(fid);
    end
    recordDate = char(metadata{1,2}(strcmp(metadata{:,1}, 'Date')));
    recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Time')));
    dateNumber = datenum(sprintf('%s %s', recordDate, recordTime), dateFormat);
    startTime = (dateNumber - dateOffset) * 24 * 3600 * 1e6; % in microseconds
    
    revText{1} = revText{1}*1e6 + startTime;
    revText{2} = strtrim(revText{2});
    revText{3} = strtrim(revText{3});
    % datestr(datenum(revText{1}/1e6/3600/24)+dateOffset-1)
    for i = 1: 3
      allLabels{i} = [allLabels{i}; revText{i}];
    end
  end
  
  %....... Add annotations to portal
  eventTimes = allLabels{1};
  eventChannels = allLabels{2}; % 'L_DG', 'ch_01', 'ch_02',
  eventLabels = allLabels{3};
  
  % save unique channels and labels to a text file for reference
  uniqueLabels = unique(eventLabels);
  uniqueChannels = unique(eventChannels);
  fid = fopen(fullfile(revDir, [animalDir(39:42) '.txt']),'w');
  fprintf(fid, 'uniqueChannels\r\n');
  fprintf(fid, '%s\r\n', uniqueChannels{:});
  fprintf(fid, '\r\nuniqueLabels\r\n');
  fprintf(fid, '%s\r\n', uniqueLabels{:});
  fclose(fid);
  
  fprintf('\nAnimal: %s\n', animalDir(39:42));
  % upload annotations to dataset
  % remove old layer and add new one
  try 
    fprintf('Removing existing layer\n');
    dataset.removeAnnLayer(layerName);
  catch 
    fprintf('No existing layer\n');
  end
  annLayer = dataset.addAnnLayer(layerName);

  % create annotations
  fprintf('Creating annotations...');
%  ann = IEEGAnnotation.createAnnotations(eventTimes, eventTimes+5*1e6, 'Event', eventLabels, dataset.channels(1));
  ann = IEEGAnnotation.createAnnotations(eventTimes, eventTimes+1*1e6, 'Event', eventLabels, dataset.channels(1));
  fprintf('done!\n');

%   for i = 1:numel(uniqueAnnotChannels)
%     tmpChan = uniqueAnnotChannels(i);
%     ann = [ann IEEGAnnotation.createAnnotations(eventTimesUSec(eventChannels==tmpChan,1), ...
%       eventTimesUSec(eventChannels==tmpChan,2),'Event', ...
%       params.label,dataset.channels(tmpChan))];
%   end

  %add annotations 5000 at a time (freezes if adding too many)
  numAnnot = numel(ann);
  startIdx = 1;
  fprintf('Adding annotations...\n');
  for i = 1:ceil(numAnnot/5000)
    fprintf('Adding %d to %d\n',startIdx,min(startIdx+5000,numAnnot));
    annLayer.add(ann(startIdx:min(startIdx+5000,numAnnot)));
    startIdx = startIdx+5000;
  end
  fprintf('done!\n');
end