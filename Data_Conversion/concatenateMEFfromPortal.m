%% this script is designed to concatenate the jensen data from several
% sessions for each animal into one session for each animal, with the
% appropriate starting timestamp for the experiment
% for the Jensen files, the data is already on the portal

clear; clc; close all;
break this % bc sometimes i run this by accident
check dates - is the double<->int64 getting rounded? should i add one day?
tic
% addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.7'));
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data'));
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
javaaddpath('C:\Users\jtmoyer\Documents\MATLAB\java_MEF_writer\MEF_writer.jar');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% load data_key - animal_id, portal_id, start_data, start_time,
load data_key;

%% define constants for simulation
run_these = (50:74);  % indexes of rows in data_key
blockLen_hr = 0.1; % amount of data to convert at one time, in hours
mefGapThresh = 10000; % msec; time threshold for mef to call it a gap
mefBlockSize = 10; % seconds per block; size of block that mef writes
formatin = 'mm/dd/yyyy HH:MM:SS';
DateOffset = datenum('1/1/1970 0:00:00',formatin);  


%% calculate start time of session, in usec since Jan 1, 1970
for i = 1: length(run_these)
  date_string = sprintf('%s %s',data_key.start_date{run_these(i)},...
    data_key.start_time{run_these(i)});
  DateNumber = datenum(date_string,formatin) - DateOffset;
  % remove the int64 command below???  does the time getting rounded off?
  data_key.start_date_usec(run_these(i)) = int64(...
    DateNumber * 24 * 3600 * 1e6);
end
% datestr(double(data_key.start_date_usec(74)/1e6/3600/24))


%% open all data sets on portal
reverseStr = '';
session = IEEGSession(data_key.portal_id{run_these(1)},...
  'jtmoyer','jtm_ieeglogin.bin');
for i = 2: length(run_these)
  msg = sprintf('Loading IEEG session: %s\n',...
    data_key.animal_id{run_these(i)});
  session.openDataSet(data_key.portal_id{run_these(i)});
  fprintf([reverseStr,msg]);
  reverseStr = repmat(sprintf('\b'), 1, length(msg));
end

% dbstop in jensen_concatenate at 116;

%% iterate through rat sessions and convert to mef, one channel at a time
% must do a single channel (multiple sessions) all at once
finished = zeros(length(run_these),1);
problems = [];
for i = 1:length(run_these)
  if ~finished(i)
    current_rat = data_key.animal_id{run_these(i)}(1:11);
    same_rat = zeros(length(run_these),1);
    for r = i: length(run_these) % can be optimized
      same_rat(r) = strcmp(current_rat, data_key.animal_id{run_these(r)}(1:11));
    end
    numChan = length(session.data(i).channels);   
    for c = 1: numChan
      reverseStr = '';
      curSF = session.data(i).channels(c).sampleRate;
      mefFiles{i,c} = sprintf(...   % 'C:\\Users\\jtmoyer\\Documents\\MATLAB\\P04-Jensen-data\\mef\\%s_%02d.mef'
        'Z:\\public\\DATA\\Animal_Data\\Frances_Jensen\\mef\\%s_%02d.mef',...
        current_rat,c);
      h = edu.mayo.msel.mefwriter.MefWriter(...
        mefFiles{i,c}, mefBlockSize, curSF, mefGapThresh); 
      h.setVoltageConversionFactor(1);
      for r = i: length(run_these)
        if same_rat(r) && ~finished(r)
          assert(curSF == session.data(r).channels(c).sampleRate,...
            'Error: sampling rate mismatch between sessions');
          assert(numChan == length(session.data(r).channels),...
            'Error: channel count mismatch between sessions');
          dataLength = session.data(r).channels(c).getNrSamples;
          blockSize = blockLen_hr * 3600 * curSF;  % convert to samples
          numBlocks = ceil(dataLength/blockSize);
          for j = 1: numBlocks
            curPt = 1 + (j-1)*blockSize;
            endPt = min([j*blockSize dataLength]);  % block length
            curBlockSize = endPt - curPt + 1;
            if (j == 1) || (j == numBlocks)% || (~exist('timeVec')) 
              timeVec = 0:curBlockSize-1;
              timeVec = timeVec ./ curSF * 1e6;
              blockOffset = 1e6 * (j-1) * blockSize / curSF;
              timeVec = timeVec + blockOffset + ...
                double(data_key.start_date_usec(run_these(r)));
            else
              timeVec = timeVec + blockSize * 1e6 / curSF;
            end
            data = session.data(r).getvalues(curPt:endPt,c);
            msg = sprintf(...
              'Writing %s channel %d. Percent finished: %3.1f. %s \\n',...
              data_key.animal_id{run_these(r)}, c, 100*j/numBlocks, ...
              datestr(timeVec(1)/1e6/3600/24));
            fprintf([reverseStr, msg]);
            reverseStr = repmat(sprintf('\b'), 1, length(msg)-1);
            % plot(double(data),double(timeVec));
%             findnans = find(isnan(data));
%             if ~isempty(findnans)
%               keyboard;
%               session.data(r).getvalues(curPt:endPt,1);
%               for n = 1: length(findnans)
%                 problems = [problems findnans(n)+curPt-1]; % should findnans(n)+curPt
%               end
%               timeVec(findnans) = [];
%               data(findnans) = []; %session.data(r).getvalues(findnans(n)+curPt-1,1);
%             end            
            try
              h.writeData(double(data), double(timeVec), length(data));
%               if length(timeVec) ~= curBlockSize % if it had a NaN
%                 clear timeVec; % then regenerate timeVec from scratch
%               end
            catch err
              throw(err);
            end
          end
          r = r + 1;
        end
      end
      fprintf('\n');
      try
        h.close();
      catch
        disp('Error closing file');
        throw();
      end
      toc
    end
    for r = i: length(run_these)
      if same_rat(r)
        finished(r) = 1;
      end
    end
  end
end

% session.data(1).channels(1).get_tsdetails()



