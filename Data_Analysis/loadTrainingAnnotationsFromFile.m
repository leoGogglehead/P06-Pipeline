%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

clear all; 
% clear all; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
dataPath = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data\Output\TrainingData';
layerName = 'start-stop';

% %% Load investigator data key
% switch study
%   case 'dichter'
%     rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD';
%     runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data';
%   case 'jensen'
%     addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data')); 
%     runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data';
%   case 'chahine'
%     rootDir = 'Z:\public\DATA\Human_Data\SleepStudies';   % directory with all the data
%     runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P03-Chahine-data';
%   case 'pitkanen'
%     addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P01-Pitkanen-data')); 
% end
% addpath(genpath(runDir));
% fh = str2func(['f_' study '_data_key']);
% dataKey = fh();


% %% Establish IEEG Sessions
% % Establish IEEG Portal sessions.
% % Load session if it doesn't exist.
% if ~exist('session','var')  % load session if it does not exist
%   session = IEEGSession(dataKey.portalId{runThese(1)},'jtmoyer','jtm_ieeglogin.bin');
%   for r = 2:length(runThese)
%     runThese(r)
%     session.openDataSet(dataKey.portalId{runThese(r)});
%   end
% else    % clear and throw exception if session doesn't have the right datasets
%   if (~strcmp(session.data(1).snapName, dataKey.portalId{runThese(1)})) || ...
%       (length(session.data) ~= length(runThese))
%     clear all;
%     error('Need to clear session data.  Re-run the script.');
%   end
% end
% for r = 1: length(session.data)
%   fprintf('Loaded %s\n', session.data(r).snapName);
% end  

%% upload annotations to portal
files = dir(dataPath);
for d = 1:length(files)
  if ~files(d).isdir
    if ~exist('session', 'var')
      session = IEEGSession(files(d).name(1:15),'jtmoyer','jtm_ieeglogin.bin');
    else
      session.openDataSet(files(d).name(1:15));
    end
    if ~isempty(strfind(files(d).name, layerName))
      load(fullfile(dataPath,files(d).name));
%       f_uploadAnnotations(session.data(length(session.data)), files(d).name(29:41), timeUsec, channels, labels);
    end
  end
end
