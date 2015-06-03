function [features, rawValues] = f_calculateFeatures(channels, clips, featFn)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%    dbstop in f_calculateFeatures at 30

% download training data from portal and save to file or load from file
% download data from portal and save to file or load from file
% calculate features for each training clip - don't save these to file yet
% calculate features for each data clip - don't save these to file yet
% cluster 
% - maybe several times, w/ different features
% - how to keep track of which clips go to which animal?
% - ideally would be able to click on data points in scatter plots and view

  % data = clips{i}(:,channels{i}(:)) = x{i}(:,c{i}(:)) = x(:,c)
%   featFn{7} = f_find8HzPower(cell(),cell()); % 8 Hz bandpower/total bandpower
%   featFn{8} = f_findFModulation(1,2);

  % calculate features for each annotation and normalize (z-score)
  fprintf('Calculating features...\n');
  features = cell(length(clips),length(featFn));
  for f = 1: size(featFn,2)
    for i = 1: size(channels,1)
%       rawValues{i,f} = featFn{f}(clips{i}, channels{i});
%       features{i,f} = normpdf(rawValues{i,f});
      features{i,f} = featFn{f}(clips{i}, channels{i});
    end
    toc
  end
  rawValues = features;
  means = mean(reshape([features{:}], [], length(featFn)));
  stds = std(reshape([features{:}], [], length(featFn)));
  for f = 1: length(featFn)
    if stds ~= 0
      features(:,f) = cellfun(@(x) (x-means(f))/stds(f), features(:,f), 'UniformOutput', false);
    else
      features(:,f) = cellfun(@(x) (x-means(f)), features(:,f), 'UniformOutput', false);
    end
  end
end



% 
% function featureOut = f_findEnergy(x)
% %   dbstop in f_find8HzPower at 176
%   fs = 2000; % Hz
%   featureOut = cell(length(x),1);
%   for i = 1: length(x)
%     for j = 1: size(x{i},2)
%       y = f_low_pass_filter8(x{i}(:,j),fs);
% %       y = bandpower(x{i}(:,j), fs, [2 8]);
% %       y = x{i}(:,j);
%       featureOut{i}(:,j) = sum(y.^2);  
%     end
%   end
% end
% 
% function featureOut = f_findLinelength(x)
% %   dbstop in f_findCorrelations at 142
%   featureOut = cell(length(x),1);
%   for i = 1: length(x)
%     for j = 1: size(x{i},2)
%       featureOut{i}(:,j) = mean(abs(diff(x{i}(:,j))));  
%     end
%   end
% end
% 
% function featureOut = f_findMeancrossings(x)
% %   dbstop in f_findCorrelations at 142
%   featureOut = cell(length(x),1);
%   for i = 1: length(x)
%     for j = 1: size(x{i},2)
%       y = x{i}(:,j);
%       featureOut{i}(:,j) = sum((y(1:end-1,:)>repmat(mean(y),size(y,1)-1,1)) & y(2:end,:)<repmat(mean(y),size(y,1)-1,1) | (y(1:end-1,:)<repmat(mean(y),size(y,1)-1,1) & y(2:end,:)>repmat(mean(y),size(y,1)-1,1))); % mean crossings 
%     end
%   end
% end
% 
% function featureOut = f_findFModulation(data, chan)
% %   dbstop in f_findFmodulation at 210;
%   fs = 2000; % Hz
%   featureOut = cell(length(data),1);
%   for i = 1: size(data,1)
%     for j = 1: size(chan{i},2)
%       y = f_high_pass_filter(data{i}(:,j),fs);
%       y = f_low_pass_filter(y,fs);
%       zx = find( (y(1:end-1,:)>repmat(mean(y),size(y,1)-1,1)) & y(2:end,:)<repmat(mean(y),size(y,1)-1,1) | (y(1:end-1,:)<repmat(mean(y),size(y,1)-1,1) & y(2:end,:)>repmat(mean(y),size(y,1)-1,1))) ; % mean crossings 
%       featureOut{i}(:,j) = max(diff((zx))) / mean(diff((zx)));
%     end
%   end
% end
% 
% function featureOut = f_find8HzPower(data, chan)
% %   dbstop in f_find8HzPower at 176
%   fs = 2000; % Hz
%   featureOut = cell(length(data),1);
%   for i = 1: size(data,1)
%     for j = 1: size(chan{i},2)
% %       y = f_high_pass_filter(x{i}(:,j),fs);
% %       y = f_low_pass_filter12(y,fs);      
%       eightHz = bandpower(data{i}(:,j),fs,[6 10]);
%       allHz = bandpower(data{i}(:,j),fs,[0 30]);
%       featureOut{i}(:,j) = eightHz / allHz;  
%     end
%   end
% end
% 
% function featureOut = f_findNChannels(x)
% %   dbstop in f_findCorrelations at 142
%   featureOut = cell(length(x),1);
%   for i = 1: length(x)
%     for j = 1: size(x{i},2)
%       featureOut{i}(:,j) = size(x{i},2);  
%     end
%   end
% end
% 
% function featureOut = f_findCorrelations(x)
% %   dbstop in f_findCorrelations at 260
%   fs = 2000; % Hz
%   featureOut = cell(length(x),1);
%   for i = 1: length(x)
%     for j = 1: size(x{i},2)
%       y = f_high_pass_filter(x{i},fs);
% %       y = f_low_pass_filter(y,fs);
%       a = reshape(corr(y.^2),[],1);
% %       a = max(a(a~=1)); 
% %       a(isempty(a)) = 0;
%       a = mean(a(a~=1)); 
%       a(isnan(a)) = 0;
%       featureOut{i}(:,j) = a;
%     end
%   end  
% end
% 
% function featureOut = f_findDuration(x)
% %   dbstop in f_findCorrelations at 142
%   featureOut = cell(length(x),1);
%   for i = 1: length(x)
%     for j = 1: size(x{i},2)
%       featureOut{i}(:,j) = size(x{i},1);  
%     end
%   end
% end
% 
% function y = f_high_pass_filter(x, Fs)
%   % MATLAB Code
%   % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
%   % Generated on: 04-Mar-2015 10:14:48
% 
%   persistent Hd;
% 
%   if isempty(Hd)
% 
%     N     = 3;    % Order
%     F3dB  = 4;     % 3-dB Frequency
%     Apass = 1;     % Passband Ripple (dB)
% 
%     h = fdesign.highpass('n,f3db,ap', N, F3dB, Apass, Fs);
% 
%     Hd = design(h, 'cheby1', ...
%       'SOSScaleNorm', 'Linf');
% 
%     set(Hd,'PersistentMemory',true);
% 
%   end
%   
%   y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
% %   y = filtfilt(h,x);
% end
% 
% function y = f_low_pass_filter(x,Fs)
%   % MATLAB Code
%   % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
%   % Generated on: 09-Mar-2015 11:44:09
% 
%   persistent Hd;
% 
%   if isempty(Hd)
% 
%     N     = 4;     % Order
%     F3dB  = 30;    % 3-dB Frequency
%     Apass = 1;     % Passband Ripple (dB)
% 
%     h = fdesign.lowpass('n,f3db,ap', N, F3dB, Apass, Fs);
% 
%     Hd = design(h, 'cheby1', ...
%       'SOSScaleNorm', 'Linf');
% 
%     set(Hd,'PersistentMemory',true);
% 
%   end
% 
%   y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
% %  y = filter(Hd,x);
% end
% 
% 
% function y = f_low_pass_filter8(x,Fs)
%   % MATLAB Code
%   % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
%   % Generated on: 09-Mar-2015 11:44:09
% 
%   persistent Hd;
% 
%   if isempty(Hd)
% 
%     N     = 4;     % Order
%     F3dB  = 8;    % 3-dB Frequency
%     Apass = 1;     % Passband Ripple (dB)
% 
%     h = fdesign.lowpass('n,f3db,ap', N, F3dB, Apass, Fs);
% 
%     Hd = design(h, 'cheby1', ...
%       'SOSScaleNorm', 'Linf');
% 
%     set(Hd,'PersistentMemory',true);
% 
%   end
% 
%   y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
% %  y = filter(Hd,x);
% end
% 
