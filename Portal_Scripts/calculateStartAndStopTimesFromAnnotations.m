%% calculateStartAndStopTimesFromAnnotations.m
% This script will get annotations documenting the start and
% stop recording times of datasets from the portal and output them to the
% command window in '20-Sep-2013 09:20:27' format.  
% Annotations were made by hand on the portal.  Output variables are
% startTimes and endTimes.

clearvars -except session; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P06-Pipeline'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [27]; % use index value in data key
layerName = 'start-stop';  % name of the layer to save to disk


%% Load investigator data key
switch study
  case 'dichter'
    rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD';
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data';
  case 'jensen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data')); 
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data';
  case 'chahine'
    rootDir = 'Z:\public\DATA\Human_Data\SleepStudies';   % directory with all the data
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P03-Chahine-data';
  case 'pitkanen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P01-Pitkanen-data')); 
end
addpath(genpath(runDir));
fh = str2func(['f_' study '_data_key']);
dataKey = fh();


%% Establish IEEG Sessions
% Establish IEEG Portal sessions.
% Load session if it doesn't exist.
if ~exist('session','var')  % load session if it does not exist
  session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin');
  for r = 2:length(runThese)
    session.openDataSet(dataKey.portalId{runThese(r)});
  end
else    % clear and throw exception if session doesn't have the right datasets
  if (~strcmp(session.data(1).snapName, dataKey.portalId{runThese(1)})) || ...
      (length(session.data) ~= length(runThese))
    clear all;
    error('Need to clear session data.  Re-run the script.');
  end
end
for r = 1: length(session.data)
  fprintf('Loaded %s\n', session.data(r).snapName);
end  


%% Pull annotation times.  Assign 'EEGstart' and 'EEGend' times 
% appropriately.  Take portal time, which is in microseconds from start of
% file, and add to the system start time.
% Some files had intermittent pauses.  In these cases I used only the
% longest continuous recording epoch.
startTimes = cell(length(runThese),1);
endTimes = cell(length(runThese),1);
for r = 1:length(runThese)
  try
    [allEvents, timesUsec, channels] = f_getAllAnnots(session.data(r), layerName);
    dateOffset = datenum(dataKey.startSystem(runThese(r)), 'dd-mmm-yyyy HH:MM:SS');  % in days
  catch
    allEvents = [];
    dateOffset = [];
  end
  fprintf('%s: %d annotations found.\n', session.data(r).snapName, length(allEvents));
  
  if runThese(r) == 5 || runThese(r) == 7 || runThese(r) == 8 ...
      || runThese(r) == 9 || runThese(r) == 10
    annotTime = timesUsec(3,2) / 1e6 / 60 / 60 / 24;
    startTimes{r} = datestr(annotTime + dateOffset, 'dd-mmm-yyyy HH:MM:SS');
    annotTime = timesUsec(4,1) / 1e6 / 60 / 60 / 24;  % in days
    endTimes{r} = datestr(annotTime + dateOffset, 'dd-mmm-yyyy HH:MM:SS');
  elseif runThese(r) == 31 || runThese(r) == 32
    annotTime = timesUsec(1,2) / 1e6 / 60 / 60 / 24;
    startTimes{r} = datestr(annotTime + dateOffset, 'dd-mmm-yyyy HH:MM:SS');
    annotTime = timesUsec(2,1) / 1e6 / 60 / 60 / 24;  % in days
    endTimes{r} = datestr(annotTime + dateOffset, 'dd-mmm-yyyy HH:MM:SS');
  else
    for i = 1: length(allEvents)
      if ~isempty(regexpi(allEvents(i).description, 'start'))
        annotTime = timesUsec(i,2) / 1e6 / 60 / 60 / 24;  % in days
        startTimes{r} = datestr(annotTime + dateOffset, 'dd-mmm-yyyy HH:MM:SS');
      elseif ~isempty(regexpi(allEvents(i).description, 'end'))
        annotTime = timesUsec(i,1) / 1e6 / 60 / 60 / 24;  % in days
        endTimes{r} = datestr(annotTime + dateOffset, 'dd-mmm-yyyy HH:MM:SS');
      else
        labels = {allEvents.description}';
        keyboard;  
      end
    end
  end
end

  