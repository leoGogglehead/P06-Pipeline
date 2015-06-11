%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

clearvars -except session;
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\libsvm-3.18'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [1:34]; % training data = 2,3,19,22,24,25,26
params.channels = 1:4;
params.label = 'seizure';
params.technique = 'linelength';
params.startTime = '1:00:00:00';  % day:hour:minute:second, in portal time
params.endTime = '0:00:00:00'; % day:hour:minute:second, in portal time
params.lookAtArtifacts = 1; % lookAtArtifacts = 1 means keep artifacts to see what's being removed

eventDetection = 0;
unsupervisedClustering = 1;
addAnnotations = 1;  
scoreDetections = 0;
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
featFn = fh();


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
% for r = 1: length(session.data)
%   fprintf('Loaded %s\n', session.data(r).snapName);
% end  


%% Feature detection 
fig_h = 1;
if eventDetection
  for r = 1:length(runThese)
    fprintf('Running %s_%s on: %s\n',params.label, params.technique, session.data(r).snapName);
    f_eventDetection(session.data(r), params, runDir);
    if addAnnotations (f_addAnnotations(session.data(r), params, runDir)); end;
    toc
  end
end

%% clustering
if unsupervisedClustering
  if ~exist('allData', 'var') 
    allData = struct('channels', cell(length(runThese),1), 'timesUsec', cell(length(runThese),1), 'features', cell(length(runThese),1), 'labels', cell(length(runThese),1));
    for r = 1:length(runThese)
      [allData(r).channels, clips, allData(r).timesUsec, allData(r).labels] = f_loadDataClips(session.data(r), params, runDir);
%       if r == 22
%         keyboard;
%       end
      allData(r).features = f_calculateFeatures(allData(r), clips, featFn);
      clips = [];
    end
  end
  
%   bins = 0:15:300;
%   for i = 1: size(allData,1)
%     for a = 1:length(allData(i).labels)
%       if ~isempty(strfind(allData(i).labels{a}, 'grooming'))
%         for c = 1: length(allData(i).channels{a})
%           figure(1); bar(bins, allData(i).features{a,3}{c}, 'histc');
%           ylim([0 300]);
%           title(allData(i).labels{a});
%           pause;
%         end
%       end
%     end
%   end
%     
%   for i = 1: size(allData,1)
%     for a = 1:length(allData(i).labels)
%       if ~isempty(strfind(allData(i).labels{a}, 'seizure'))
%         for c = 1: length(allData(i).channels{a})
%           figure(1); bar(bins, allData(i).features{a,3}{c}, 'histc');
%           ylim([0 300]);
%           title(allData(i).labels{a});
%           pause;
%         end
%       end
%     end
%   end
%     
  useData = allData; 
  useTheseFeatures = [3]; % which feature functions to use for clustering?
  useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params);
  useData = f_removeAnnotations(session, params, useData, featFn, useTheseFeatures);

%   useTheseFeatures = [2]; % which feature functions to use for clustering?
%   useData = f_removeAnnotations(session, params, useData, featFn, useTheseFeatures);
%   useTheseFeatures = [3] % which feature functions to use for clustering?
%   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params);
%   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params);
%   useTheseFeatures = [3] % which feature functions to use for clustering?
%   useData = f_unsupervisedClustering(session, useData, useTheseFeatures, runThese, params);

  layerName = sprintf('%s-%s-%s', params.label, params.technique, 'grooming-artifact');
  for r = 1:length(runThese)
    if addAnnotations f_uploadAnnotations(session.data(r), layerName, useData(r).timesUsec, useData(r).channels, 'Event'); end;
  end
end


%% Score detections
if scoreDetections
%   f_boxPlot(session, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');
  viewAnnots2(session); % 'SVMSeizure-2');  
  fprintf('Box plot: %s\n', params.label, params.technique, session.data(r).snapName);
  toc
end


%% Analyze results
if boxPlot
%   f_boxPlot(session, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');
  f_boxPlotPerDay(session, runDir, runThese, dataKey, sprintf('%s-%s',params.label, params.technique)); % 'SVMSeizure-2');  
  fprintf('Box plot: %s\n', params.label, params.technique, session.data(r).snapName);
  toc
end



