%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

clearvars -except session;% allData; 
% clear all;  
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\libsvm-3.18'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [26]; % not 6, 13! [22-29? 3,4,7,8,6,10,15,17];  % jensen: hypoxia = 6,10,15,17; vehicle 3,4,7,8
trainers = [1:2];
params.channels = 1:4;
params.label = 'training';
params.technique = 'data';
params.startTime = '1:00:00:00';  % day:hour:minute:second, in portal time
params.endTime = '0:00:00:00'; % day:hour:minute:second, in portal time

params.lookAtArtifacts = 0;

eventDetection = 0;
unsupervisedClustering = 1;
supervisedClustering = 0;
addAnnotations = 1;  % need to add this
boxPlot = 0;

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
fh = str2func(['f_' study '_params']);
params = fh(params)
fh = str2func(['f_' study '_define_features']);
featFn = fh()


%% Establish IEEG Sessions
% Establish IEEG Portal sessions.
% Load session if it doesn't exist.
if ~exist('session','var')  % load session if it does not exist
  session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin');
%   session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin','qa');
  for r = 2:length(runThese)
%     runThese(r)
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


%% Feature detection and annotation upload 
fig_h = 1;
if eventDetection
  for r = 1:length(runThese)
    fprintf('Running %s_%s on: %s\n',params.label, params.technique, session.data(r).snapName);
    f_eventDetection(session.data(r), params, runDir);
    if addAnnotations (f_addAnnotations(session.data(r), params, runDir)); end;
    toc
  end
end

% clear allData;
% dbstop in analyzeDataOnPortal at 105;

%% clustering
if unsupervisedClustering
  if ~exist('allData', 'var') 
    allData = struct('channels', cell(length(runThese),1), 'timesUsec', cell(length(runThese),1), 'features', cell(length(runThese),1));
    for r = 1:length(runThese)
      [allData(r).channels, clips, allData(r).timesUsec] = f_loadDataClips(session.data(r), params, runDir);
%       if r == 22
%         keyboard;
%       end
      [allData(r).features, allData(r).rawValues] = f_calculateFeatures(allData(r).channels, clips, featFn);
      clips = [];
    end
  end
  
  useData = allData;
  % remove 60 Hz
  useTheseFeatures = [1] % which feature functions to use for clustering?
  useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params);
%   useTheseFeatures = [5] % which feature functions to use for clustering?
%   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params);
%   useTheseFeatures = [3] % which feature functions to use for clustering?
%   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params);

  layerName = sprintf('%s-%s-%s', params.label, params.technique, 'minus-60Hz');
  for r = 1:length(runThese)
    if addAnnotations f_uploadAnnotations(session.data(r), layerName, useData(r).timesUsec, useData(r).channels, 'Event'); end;
  end
end

if supervisedClustering
  for r = 1:length(runThese)
%     f_loadTraingData();
%     f_loadDataClips();
%     f_calculateFeatures();
%     f_addAnnotations();
  end
%   f_supervisedClustering(session.data(r), params, runDir);
end


%% Analyze results
if boxPlot
  f_boxPlot(session, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');
%   f_boxPlotPerDay(session, runDir, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');  
  fprintf('Box plot: %s\n', params.label, params.technique, session.data(r).snapName);
  toc
end

