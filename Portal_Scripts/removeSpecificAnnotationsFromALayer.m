% This script will remove specific annotations from a given layer.  For
% instance, use this to remove annotations made before recording start or
% after recording end.

clearvars -except session; 
close all; 
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P06-Pipeline'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define constants for the analysis
study = 'jensen';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = [7:12,14:34]; % index of animals in data key

origLayerName = 'seizure-linelength'; % name of existing layer, move annots from here
newLayerName = 'seizure-linelength-start-stop'; % name of new layer, move annots to here

removeAnnotations = 0; % flag to prevent script from running accidentally

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
%   fprintf('Loaded %s\n', session.data(r).snapName);
end  


%% Note start/stop times are in the study specific data key.
if removeAnnotations
  a = input(sprintf('Do you really want to remove annotations from %s? (y/n): ', origLayerName), 's');
  if strcmpi(a, 'y')
    for r = 1:length(runThese)
      try
        [allEvents, timesUSec, channels] = f_getAllAnnots(session.data(r), origLayerName);
        startUsecs = round((datenum(dataKey.startEEG(runThese(r)), 'dd-mmm-yyyy HH:MM:SS') - datenum(dataKey.startSystem(runThese(r)), 'dd-mmm-yyyy HH:MM:SS'))*24*60*60*1e6);
        endUsecs = round((datenum(dataKey.endEEG(runThese(r)), 'dd-mmm-yyyy HH:MM:SS') - datenum(dataKey.startSystem(runThese(r)), 'dd-mmm-yyyy HH:MM:SS'))*24*60*60*1e6);
        keepThese = find(timesUSec(:,1) > startUsecs & timesUSec(:,2) < endUsecs);
      catch err
        rethrow(err);
      end
      if ~isempty(keepThese)
        f_uploadAnnotations(session.data(r), newLayerName, timesUSec(keepThese,:), channels(keepThese), 'seizure');
        fprintf('Removed %d/%d annotations: %s\n', length(allEvents) - length(keepThese), length(allEvents), session.data(r).snapName);
      else
        fprintf('%s: Removed all annotations.\n', session.data(r).snapName);
      end
    end
  else
     fprintf('%s: No annotations removed.\n', session.data(r).snapName);
  end
end

