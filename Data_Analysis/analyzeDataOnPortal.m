%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

clearvars -except session; 
% clear all;  
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\libsvm-3.18'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [1:2]; % not 13! [22-29? 3,4,7,8,6,10,15,17];  % jensen: hypoxia = 6,10,15,17; vehicle 3,4,7,8
params.channels = 1:4;
params.label = 'seizure';
params.technique = 'linelength';
params.startTime = '1:00:00:00';  % day:hour:minute:second, in portal time
params.endTime = '0:00:00:00'; % day:hour:minute:second, in portal time

% check can i enter stop time = 0 and run the whole animal
% can i run on 1 or 2 channels (ie 1 and 3?)

eventDetection = 0;
unsupervisedClustering = 0;
supervisedClustering = 0;

params.plot3DScatter = 0;
params.plot1DFeatures = 0;

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
    f_addAnnotations(session.data(r), params, runDir);
    toc
  end
end


%% clustering
if unsupervisedClustering
  for r = 1:length(runThese)
    params = f_load_params(params)
    fprintf('Unsupervised clustering %s_%s on: %s\n',params.label, params.technique, session.data(r).snapName);
    f_unsupervisedClustering(session.data(r), params, runDir);
    toc
  end
end


%% Analyze results
if boxPlot
%   f_boxPlot(session, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');
  f_boxPlotPerDay(session, runDir, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');  
  fprintf('Box plot: %s\n', params.label, params.technique, session.data(r).snapName);
  toc
end


