function [] = f_txt2portal(dataset, animalDir)
  %   This is a generic function that uploads annotations from a text file
  %   (output from Sandman) to the portal.  Text files should be named like
  %   "102396_04172014_event list.txt" and a folder of the same name
  %   (ie "102396_04172014\").
  %
  %   INPUT:
  %       dataset = portal dataset, ie session.data (I0XX_P0XX_D01)
  %       animalDir  = directory with the .txt file
  %
  %   OUTPUT:
  %       annotations are assigned to appropriate layers and uploaded to
  %       the portal.
  %
  %   USAGE:
  %       f_txt2portal(session.data(1), 'Z:\public\DATA\Human_Data\SleepStudies\102396_04172014');
  %
  %    dbstop in f_txt2portal at 70

  %....... Directory to .txt file  
  txtDir = fullfile(animalDir,'');
    
  % scan in text data
  try 
    txt_name = fullfile(txtDir, [animalDir(40:end) '_event list.txt']);
    fid = fopen(txt_name);   
    metadata = textscan(fid,'%[^:]: %[^\n]', 12);
    textscan(fid,'%*[^\n]',1);
    textdata = textscan(fid, '%*[^\t] %[^\t] %[^\t] %[^\n]\n');
    fclose(fid);
  catch err 
    fprintf('Check text file exists: %s\n', txt_name);
    rethrow(err);
  end
  
  % get patient name, confirm it matches the directory name
  % get start time of recorded file
  patientID = char(metadata{1,2}(strcmp(metadata{:,1}, 'Patient Name')));
  assert(strcmp(patientID(1:15), animalDir(40:end)),'Patient name does not match: %s\n',txt_name);
  recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Study Date')));
  recordTime = recordTime(10:end);
  dateFormat = 'HH:MM:SS AM';
  dateOffset = datenum(recordTime, dateFormat); % in days
  
  % extract label, time, and duration values for each annotation
  % only use labels with a duration value - others are redundant
  keepInds = ~cellfun(@isempty,strtrim(textdata{3}));
  
  % get annotation text
  annotations = strtrim(textdata{1}(keepInds));
  
  % get annotation times, convert to microseconds (portal starts at midnight)
  times = textdata{2}(keepInds);
  times = datenum(times, 'HH:MM:SS AM') - dateOffset;
  % convert to Usec; times recorded after 0:00 need to be set to the next day
  times(times<0) = times(times<0) + 1;
  timesUsec = (times) * 24 * 60 * 60 * 1e6; %   check = datestr(timesUsec/1e6/60/60/24);

  % get duration of each annotation from text file
  % duration is the first cell, ignore other values & convert to usec
  numStrings = cellfun(@strsplit,textdata{3}(keepInds),'UniformOutput',false);
  duration = zeros(length(numStrings),1);
  for d = 1:length(numStrings)
    duration(d) = str2double(char(numStrings{d}(1))) * 1e6;
  end
  
  % assign annotations to different layers 
  layers = cell(length(annotations),1);
  for d = 1: length(annotations)
    if strcmp(annotations{d}, 'Wake')
      layers{d} = 'Wake';
    elseif strcmp(annotations{d}, 'NREM 1')
      layers{d} = 'NREM1';
    elseif strcmp(annotations{d}, 'NREM 2')
      layers{d} = 'NREM2';
    elseif strcmp(annotations{d}, 'NREM 3')
      layers{d} = 'NREM3';
    elseif strcmp(annotations{d}, 'REM')
      layers{d} = 'REM';
    elseif (strcmp(annotations{d},'Lights On') || strcmp(annotations{d},'Lights Off'))
      layers{d} = 'Lights';
    elseif (strcmp(annotations{d},'CPAP 0') || strcmp(annotations{d},'Diagnostic'))
      layers{d} = 'CPAP';
    else
      layers{d} = 'Notes';
    end
  end
    
  %....... Add annotations to portal
  eventTimes = timesUsec;
  eventLabels = annotations;
    
  fprintf('\Subject: %s\n', animalDir(40:end));

  % upload annotations to dataset
  % remove old layer and add new one
  uniqueLayers = unique(layers);
  
  for d = 1: length(uniqueLayers)
    layerName = uniqueLayers{d};
    for i = 1: length(layers)
      addThese(i) = strcmp(layers(i), layerName);
    end
    
    try
      fprintf('Removing existing layer: %s\n', layerName);
      dataset.removeAnnLayer(layerName);
    catch 
      fprintf('No existing layer\n');
    end
    annLayer = dataset.addAnnLayer(layerName);

    % create annotations
    fprintf('Creating annotations...');
    ann = IEEGAnnotation.createAnnotations(eventTimes(addThese), ...
      eventTimes(addThese)+duration(addThese), ...
      'Event', eventLabels(addThese), dataset.channels(1));
    fprintf('done!\n');

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
end