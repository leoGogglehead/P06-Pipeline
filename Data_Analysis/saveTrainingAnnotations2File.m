%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

clearvars -except session; 
% clear all; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [1:34]; % [3,4,7,8,6,10,15,17];  % jensen: hypoxia = 6,10,15,17; vehicle 3,4,7,8
params.channels = 1:4;
params.label = 'start';
params.technique = 'stop';
params.startTime = '0:00:00:00';  % day:hour:minute:second, in portal time
params.endTime = '0:00:00:00'; % day:hour:minute:second, in portal time

saveAnnotations = 1;
outputDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data\Output\TrainingData';

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
    runThese(r)
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


%% Backup annotations 
% clips = {};
timesUsec = [];
channels = {};
labels = {};
layerName = sprintf('%s-%s', params.label, params.technique);
if saveAnnotations
  for r = 1:length(runThese)
    fprintf('Getting %s on: %s\n', layerName, session.data(r).snapName);
    params.startUsecs = 0;
    params.endUsecs = session.data(r).channels(1).get_tsdetails().getDuration;
  
    % get annotations
    try
      [allEvents, timesUsec, channels] = f_getAllAnnots(session.data(r), layerName);
      labels = {allEvents.description}';

      % save to mat file
      clipsFile = fullfile(runDir, sprintf('/Output/%s-backupAnnot-%s-%s.mat',session.data(r).snapName,params.label,params.technique));
      save(clipsFile, 'timesUsec', 'channels', 'labels', '-v7.3');
    catch
    end
  end
end


%       [allEvents, tmptimesUsec, tmpchannels] = f_getAllAnnots(session.data(r), layerName);
%       tmplabels = {allEvents.description};
%       szridx = ~cellfun(@isempty, regexp(tmplabels, 'seizure')); % true = seizure/seizure-artifact
% 
%       szrTimes = tmptimesUsec(szridx,:);
%       szrChannels = tmpchannels(szridx);
% 
%       % add ability to save data clips to file for fast retrieval
%       tmpclips = cell(size(szrTimes,1),1);
%       numChans = length(session.data(r).channels);
%       for i = 1:size(szrTimes,1)
%         % get data - sometimes it takes a few tries for portal to respond
%         count = 0;
%         successful = 0;
%         while count < 10 && ~successful
%           try
%             tmpDat = dataset.getvalues(timesUsec(i,1), timesUsec(i,2)-timesUsec(i,1), 1:numChans);
%             successful = 1;
%           catch
%             count = count + 1;
%             fprintf('Try #: %d\n', count);
%           end
%         end
%         if ~successful
%           error('Unable to get data.');
%         end
% 
%         tmpDat(isnan(tmpDat)) = 0;
%         tmpclips{i} = tmpDat;
%       end
% 
% %       clips = [clips; tmpclips(~cellfun(@isempty,tmpclips))];  % true = not an artifact 
%       timesUsec = [timesUsec; szrTimes];
%       channels = [channels; szrChannels];
%       labels = [labels; tmplabels(szridx)'];


