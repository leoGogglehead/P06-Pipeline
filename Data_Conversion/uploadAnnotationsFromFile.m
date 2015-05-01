%% Dichter_uploadRevAnnotations.m
% this script will read data from .rev files (Nicolet annotations) and 
% upload them to the portal.  The script uses the _eeg2mef function, which 
% assumes data is stored in rev files in a directory with this kind of path:
% Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000\r097_000.eeg

clearvars -except session; 
% clear all; 
close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));


%% Define constants for the analysis
study = 'chahine';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = 1;  % jensen 3,4,15,17; dichter 2-3; pitkanen 1-3
readRev = 1;  % convert data y/n?


%% Load investigator data key
switch study
  case 'dichter'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data'));
    rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD'; % directory with all the data
  case 'jensen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data')); 
  case 'chahine'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P03-Chahine-data'));
    rootDir = 'Z:\public\DATA\Human_Data\SleepStudies';   % directory with all the data
  case 'pitkanen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P01-Pitkanen-data')); 
end
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
    throw('Need to clear session data.  Re-run the script.');
  end
end
for r = 1: length(session.data)
  fprintf('Loaded %s\n', session.data(r).snapName);
end  


%% open and read in .txt files
if readRev
  for r = 1: length(runThese)
    animalDir = fullfile(rootDir,char(dataKey.animalId(runThese(r))));
    f_txt2portal(session.data(r), animalDir);
  end
end

