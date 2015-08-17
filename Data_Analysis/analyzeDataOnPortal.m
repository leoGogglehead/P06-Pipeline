% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

clearvars -except session allData;
close all force; clc; tic;
% addpath('C:\Users\jtmoyer\Documents\MATLAB\');
% addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\libsvm-3.18'));
addpath(genpath('F:\Grad School\Github\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'chahine';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [1:3]; % training data = 2,3,19,22,24,25,26; 1:5,7:12,14:34
params.channels = 2:7;
params.label = 'sleep';
params.technique = 'powerbands';
params.startTime = '1:01:30:00';  % day:hour:minute:second, in portal time
params.endTime = '1:05:00:00'; % day:hour:minute:second, in portal time
params.lookAtArtifacts = 0; % lookAtArtifacts = 1 means keep artifacts to see what's being removed

eventDetection = 1;
unsupervisedClustering = 0;
addAnnotations = 0;  
scoreDetections = 0;
boxPlot = 0;

%% Load investigator data key
switch study
  case 'dichter'
    rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD';  % where original data is sotred
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data';  % investigator specific directory, for .xls, .doc files etc.
  case 'jensen'
    rootDir = 'Z:\public\DATA\Animal_Data\Frances_Jensen';  % where original data is sotred
    runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data';
  case 'chahine'
%     rootDir = 'Z:\public\DATA\Human_Data\SleepStudies';   
    runDir = 'F:\Grad School\Github\P03-Chahine-data';
  case 'pitkanen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P01-Pitkanen-data')); 
end
addpath(genpath(runDir));
fh = str2func(['f_' study '_data_key']);
dataKey = fh();
fh = str2func(['f_' study '_params']);
params = fh(params)
fh = str2func(['f_' study '_define_features']);
featFn = fh();


%% Establish IEEG Sessions
% Establish IEEG Portal sessions.
% Load session if it doesn't exist.
if ~exist('session','var')  % load session if it does not exist
  addpath(genpath('F:\Grad School\Github'));
  session = IEEGSession(dataKey.portalId{runThese(1)},'gogglehead','gog_ieeglogin.bin');
%   session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin','qa');
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


%% Feature detection 
fig_h = 1;
if eventDetection
  for r = 1:length(runThese)
    fprintf('Running %s_%s on: %s\n',params.label, params.technique, session.data(r).snapName);
    f_eventDetection(session.data(r), params, runDir, dataKey(runThese(r),:));
    if addAnnotations
      f_addAnnotations(session.data(r), params, runDir); 
    end;
    toc
  end
end


%% LEO - ignore everything below this
%.....................................
%.....................................

% %% clustering
% if unsupervisedClustering
%   if ~exist('allData', 'var') 
%     allData = struct('channels', cell(length(runThese),1), 'timesUsec', cell(length(runThese),1), 'features', cell(length(runThese),1), 'labels', cell(length(runThese),1));
%     for r = 1:length(runThese)
%       [allData(r).channels, clips, allData(r).timesUsec, allData(r).labels] = f_loadDataClips(session.data(r), params, runDir);
%       allData(r).features = f_calculateFeatures(allData(r), clips, featFn);
%       clips = [];
%     end
%   end
%   
%   useData = allData; 
%   useTheseFeatures = [3]; % which feature functions to use for clustering?
%   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params, runDir);
%   useData = f_removeAnnotations(session, params, useData, featFn, useTheseFeatures);
% 
%   layerName = sprintf('%s-%s-%s', params.label, params.technique, 'minus-grooming-thr1atatime');
%   for r = 1:length(runThese)
%     if addAnnotations f_uploadAnnotations(session.data(r), layerName, useData(r).timesUsec, useData(r).channels, 'Event'); end;
%   end
% end
% 
% 
% %% Score detections
% if scoreDetections
% %   f_boxPlot(session, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');
%   if ~exist('allData', 'var') 
%     load('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data\Output\allData.mat');
% %     allData = struct('channels', cell(length(runThese),1), 'timesUsec', cell(length(runThese),1), 'features', cell(length(runThese),1), 'labels', cell(length(runThese),1));
% %     for r = 1:length(runThese)
% %       [allData(r).channels, clips, allData(r).timesUsec, allData(r).labels] = f_loadDataClips(session.data(r), params, runDir);
% %     end
%   end
%   
%   
%   % make vector indicating number of detections in each dataset
%   % based on probability, randomly divide the desired number of detections between datasets
%   % then run through each dataset and present the detections to be scored
%   layerName = sprintf('%s-%s', params.label, params.technique);
%   numDetections = 20;
% %   rando = RandStream('mt19937ar', 'Seed', 1);
%   rng(1)
%   for i = 1: size(allData,1)
%     allLengths(i,1) = length(allData(i).channels);
%   end
%   sampleThese = sort(randsample(length(allLengths), numDetections, true, allLengths));
%   numSamples = hist(sampleThese, 1:length(allLengths))';
% 
%   for r = 1: size(allData,1)
%     these = randi(allLengths(r), [numSamples(r), 1]);
%     if these > 0
%       close all force;
%       f_scoreDetections(session.data(r), layerName, allData(r).timesUsec(these,:), 1:4, 'testing');
%       keyboard;
%     end
%   end
%   
% %   f_scoreDetections();
% %   f_calculatePerformance();
% end
% 
% 
% %% Analyze results
% if boxPlot
% %   f_boxPlot(session, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');
%   f_boxPlotPerDay(session, runDir, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');  
%   fprintf('Box plot: %s-%s\n', params.label, params.technique);
%   toc
% end
% 
% 
% 
