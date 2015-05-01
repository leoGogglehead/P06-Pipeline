%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

clearvars -except session; 
% clear all; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'dichter';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [2,4,7,15]; % [3,4,7,8,6,10,15,17];  % jensen: hypoxia = 6,10,15,17; vehicle 3,4,7,8
params.channels = 1:4;
params.label = 'training';
params.technique = 'data';
params.startTime = '0:00:00:00';  % day:hour:minute:second, in portal time
params.endTime = '0:00:00:00'; % day:hour:minute:second, in portal time

% check can i enter stop time = 0 and run the whole animal
% can i run on 1 or 2 channels (ie 1 and 3?)

backupAnnotations = 1;


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
if backupAnnotations
  for r = 1:length(runThese)
    fprintf('Backing up %s_%s on: %s\n',params.label, params.technique, session.data(r).snapName);
    layerName = sprintf('%s-%s', params.label, params.technique);

    params.startUsecs = 0;
    params.endUsecs = session.data(r).channels(1).get_tsdetails().getDuration;
  
    % get annotations
    layerName = sprintf('%s-%s', params.label, params.technique);
    [allEvents, timeUsec, channels, labels] = f_getAllAnnots(session.data(r), layerName, params);
    
    % save to mat file
    annotFile = fullfile(runDir, sprintf('/Output/%s-backupAnnot-%s-%s.mat',session.data(r).snapName,params.label,params.technique));
%     load(annotFile, '-mat');
    save(annotFile,'timeUsec','channels','labels','-v7.3');
    whos(annotFile)
  end
end

