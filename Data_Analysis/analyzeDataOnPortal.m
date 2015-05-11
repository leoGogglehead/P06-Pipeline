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
runThese = [24]; % not 13! [22-29? 3,4,7,8,6,10,15,17];  % jensen: hypoxia = 6,10,15,17; vehicle 3,4,7,8
trainers = [1:2];
params.channels = 1:4;
params.label = 'seizure';
params.technique = 'linelength';
params.startTime = '1:00:00:00';  % day:hour:minute:second, in portal time
params.endTime = '0:00:00:00'; % day:hour:minute:second, in portal time

featFn{1} = @(x,c) ones(size(c));% @(x,c) max(abs(x(:,c))) ./ rms(x(:,c));   % max over RMS value
featFn{2} = @(x,c) ones(size(c));% @(x,c) repmat((1+(cond(x(:,c))-1) ./ size(x(:,c),2)),size(c));  % DCN
featFn{3} = @(x,c) max(abs(x(:,c)));  % max values
featFn{4} = @(x,c) ones(size(c));% @(x,c) repmat(mean(mean(corr(x))), size(c));  % mean corr value over 4 channels
featFn{5} = @(x,c) rms(x(:,c)); % rms
featFn{6} = @(x,c) max(x(:,c).^2); % max of energy
% featFn{7} = @(x,c) sum((x(1:end-1,c)>repmat(mean(x(:,c)),size(x,1)-1,1)) & x(2:end,c)<repmat(mean(x(:,c)),size(x(:,c),1)-1,1)  | (x(1:end-1,c)<repmat(mean(x(:,c)),size(x(:,c),1)-1,1) & x(2:end,c)>repmat(mean(x(:,c)),size(x(:,c),1)-1,1))); % mean crossings 

eventDetection = 1;
unsupervisedClustering = 0;
supervisedClustering = 0;

params.plot3DScatter = 0;
params.plot1DFeatures = 0;

boxPlot = 1;

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
  allData = struct('channels', cell(length(runThese),1), 'timesUsec', cell(length(runThese),1), 'features', cell(length(runThese),1));
  for r = 1:length(runThese)
    [allData(r).channels, clips, allData(r).timesUsec] = f_loadDataClips(session.data(r), params, runDir);
    allData(r).features = f_calculateFeatures(allData(r).channels, clips, featFn);
  end
  clips = [];
  
  useTheseFeatures = [6] % which feature functions to use for clustering?
  allData = f_unsupervisedClustering(session, allData, useTheseFeatures, runThese);
  useTheseFeatures = [5] % which feature functions to use for clustering?
  allData = f_unsupervisedClustering(session, allData, useTheseFeatures, runThese);
  useTheseFeatures = [3] % which feature functions to use for clustering?
  allData = f_unsupervisedClustering(session, allData, useTheseFeatures, runThese);
%   useTheseFeatures = [7]; % which feature functions to use for clustering?
%   allData = f_unsupervisedClustering(session, allData, useTheseFeatures, runThese);
%   useTheseFeatures = [1]; % which feature functions to use for clustering?
%   allData = f_unsupervisedClustering(allData, useTheseFeatures, runThese);

  layerName = sprintf('%s-%s-%s', params.label, params.technique, 'kmeans');
  for r = 1:length(runThese)
    f_uploadAnnotations(session.data(r), layerName, allData(r).timesUsec, allData(r).channels, 'Event');
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
%   f_boxPlot(session, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');
  f_boxPlotPerDay(session, runDir, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');  
  fprintf('Box plot: %s\n', params.label, params.technique, session.data(r).snapName);
  toc
end


