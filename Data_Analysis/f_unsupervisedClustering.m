function f_unsupervisedClustering(dataset, params, runDir)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_unsupervisedClustering at 91
    
  % download data from portal or load from file
  fs = dataset.sampleRate;
  clipsFile =  fullfile(runDir, sprintf('/Output/%s-clips-%s-%s.mat',dataset.snapName,params.label,params.technique));
%   clipsFile = fullfile(runDir, sprintf('/Output/seizures-%s-%s.mat',params.label,params.technique));
  if ~exist(clipsFile, 'file')
    fprintf('Downloading data clips from portal...\n');
    layerName = sprintf('%s-%s', params.label, params.technique);
    [allEvents, timesUsec, channels] = f_getAllAnnots(dataset, layerName, params);
    labels = {allEvents.description}';
    
    % save data clips to file for fast retrieval
    clips = cell(size(timesUsec,1),1);
    numChans = length(dataset.channels);
    for i = 1:size(allEvents,2)
      count = 0;    % get data - sometimes it takes a few tries for portal to respond
      successful = 0;
      while count < 10 && ~successful
        try
          tmpDat = dataset.getvalues(timesUsec(i,1), timesUsec(i,2)-timesUsec(i,1), 1:numChans);
          successful = 1;
        catch
          count = count + 1;
          fprintf('Try #: %d\n', count);
        end
      end
      if ~successful
        error('Unable to get data.');
      end
      tmpDat(isnan(tmpDat)) = 0;   % tmpDat = dataset.getvalues(timesUsec(i,1), timesUsec(i,2)-timesUsec(i,1), channels);
      clips{i} = tmpDat;
    end
    clips = clips(~cellfun('isempty',clips)); 
    save(clipsFile, 'clips', 'timesUsec', 'channels', 'labels', '-v7.3');
  else
    fprintf('Loading data clips from file...\n');
    load(clipsFile);
  end
  toc
  
  % define features to calculate for each data clip
  % store feature functions in featFn - no limit on # of functions
  %   featFn{1} = @(x) f_find8HzPower(x);  % look at 8 Hz rhythms
  %   featFn{2} = @(x) f_findCorrelations(x);
  %   featFn{3} = @(x) f_findDuration(x);
  %   featFn{1} = @(x) f_findEnergy(x);  % look at 8 Hz rhythms
  %   featFn{2} = @(x) f_findLinelength(x);
  %   featFn{3} = @(x) f_findMeancrossings(x);
  %   featFn{1} = @(x) f_findNChannels(x);  % look at 8 Hz rhythms

  % data = clips{i}(:,channels{i}(:)) = x{i}(:,c{i}(:)) = x(:,c)
  featFn{1} = @(x,c) max(abs(x(:,c))) ./ rms(x(:,c));   % max over RMS value
  featFn{2} = @(x,c) repmat((1+(cond(x(:,c))-1) ./ size(x(:,c),2)),[size(c)]);  % DCN
  featFn{3} = @(x,c) max(abs(x(:,c)));  % max values
  featFn{4} = @(x,c) repmat(mean(mean(corr(x))), [size(c)]);  % mean corr value over 4 channels
  featFn{5} = @(x,c) rms(x(:,c)); % rms
  featFn{6} = @(x,c) max(x(:,c).^2); % max of energy
%   featFn{7} = f_find8HzPower(cell(),cell()); % 8 Hz bandpower/total bandpower
%   featFn{8} = f_findFModulation(1,2);

  % calculate features for each annotation and normalize (z-score)
  features = cell(length(clips),length(featFn));
  for f = 1: size(featFn,2)
    fprintf('Calculating feature %d...\n', f);
    for i = 1: size(channels,1)
      features{i,f} = featFn{f}(clips{i}, channels{i});
    end
    toc
  end
  means = mean(reshape([features{:}], [], length(featFn)));
  stds = std(reshape([features{:}], [], length(featFn)));
  for f = 1: length(featFn)
    features(:,f) = cellfun(@(x) (x-means(f))/stds(f), features(:,f), 'UniformOutput', false);
  end

  %....
  % 1 - remove railing artifact - classify using kmeans (unsupervised) or SVM (supervised)
  funcInds = [5 6];
  featurePts = reshape([features{:,funcInds}], [], length(funcInds));
  [cIdx, xyz] = kmeans(featurePts, 2, 'Distance', 'sqeuclidean');
  
  if xyz(1,1) > xyz(2,1)
    class1 = 'artifact';
    class2 = 'not-artifact';
    keepThese = 2;
  else
    class1 = 'not-artifact';
    class2 = 'artifact';
    keepThese = 1;
  end
  
  featureClasses = cell(size(channels,1),1);
  featureLabels = cell(size(channels,1),1);
  featurePtsLabels = cell(size(featurePts,1),1);
  c = 1;
  for i = 1: size(channels,1)
    featureClasses{i} = cIdx(c:c+size(channels{i},2)-1);
    featureClasses{i} = repmat(round(mean(featureClasses{i})),size(channels{i}));
    fstring = sprintf('featureLabels{i} = repmat(cellstr(class%d),[1 size(channels{i})]);', featureClasses{i}(1));
    eval(fstring);
    for j = 1: size(channels{i},2)
      featurePtsLabels{c+j-1} = cellstr(featureLabels{i}(j));
    end
    c = c + size(channels{i},2);
  end
  
  % upload annotations to portal
  annotClasses = round(cellfun(@mean, featureClasses));
  annotUsec = timesUsec(annotClasses == keepThese,:);
  annotChannels = channels(annotClasses == keepThese,:);
  f_uploadAnnotations_v2(dataset,'1-minus-railing',annotUsec,annotChannels,'Seizure');

  
  %....
  % 2 - remove pinging artifact - classify using kmeans (unsupervised) or SVM (supervised)
  funcInds = [1];
  features = features(annotClasses == keepThese,:);
  channels = channels(annotClasses == keepThese,:);
  featurePts = reshape([features{:,funcInds}], [], length(funcInds));
  [cIdx, xyz] = kmeans(featurePts, 2, 'Distance', 'sqeuclidean');
  
  if xyz(1,1) > xyz(2,1)
    class1 = 'artifact';
    class2 = 'not-artifact';
    keepThese = 2;
  else
    class1 = 'not-artifact';
    class2 = 'artifact';
    keepThese = 1;
  end
  
  featureClasses = cell(size(channels,1),1);
  featureLabels = cell(size(channels,1),1);
  featurePtsLabels = cell(size(featurePts,1),1);
  c = 1;
  for i = 1: size(channels,1)
    featureClasses{i} = cIdx(c:c+size(channels{i},2)-1);
    featureClasses{i} = repmat(round(mean(featureClasses{i})),size(channels{i}));
    fstring = sprintf('featureLabels{i} = repmat(cellstr(class%d),[1 size(channels{i})])', featureClasses{i}(1));
    eval(fstring);
    for j = 1: size(channels{i},2)
      featurePtsLabels{c+j-1} = cellstr(featureLabels{i}(j));
    end
    c = c + size(channels{i},2);
  end
  
  % upload annotations to portal
  annotClasses = round(cellfun(@mean, featureClasses));
  annotUsec = timesUsec(annotClasses == keepThese,:);
  annotChannels = channels(annotClasses == keepThese,:);
  f_uploadAnnotations_v2(dataset,'2-minus-pinging',annotUsec,annotChannels,'Seizure');

  
%   %....
%   % 3- remove buzzing artifact - classify using kmeans (unsupervised) or SVM (supervised)
%   funcInds = [4];
%   features = features(annotClasses == keepThese,:);
%   channels = channels(annotClasses == keepThese,:);
%   featurePts = reshape([features{:,funcInds}], [], length(funcInds));
%   [cIdx, xyz] = kmeans(featurePts, 2, 'Distance', 'sqeuclidean');
%   
%   if xyz(1,1) > xyz(2,1)
%     class1 = 'artifact';
%     class2 = 'not-artifact';
%     keep = 2;
%   else
%     class1 = 'not-artifact';
%     class2 = 'artifact';
%     keepThese = 1;
%   end
%   
%   featureClasses = cell(size(channels,1),1);
%   featureLabels = cell(size(channels,1),1);
%   featurePtsLabels = cell(size(featurePts,1),1);
%   c = 1;
%   for i = 1: size(channels,1)
%     featureClasses{i} = cIdx(c:c+size(channels{i},2)-1);
%     featureClasses{i} = repmat(round(mean(featureClasses{i})),size(channels{i}));
%     fstring = sprintf('featureLabels{i} = repmat(cellstr(class%d),[1 size(channels{i})]);', featureClasses{i}(1));
%     eval(fstring);
%     for j = 1: size(channels{i},2)
%       featurePtsLabels{c+j-1} = cellstr(featureLabels{i}(j));
%     end
%     c = c + size(channels{i},2);
%   end
%   
%   if params.plot3DScatter
%     f_plot3DScatter(featurePts, featurePtsLabels, funcInds);
%   end
%   if params.plot1DFeatures
%     f_plot1DFeatures(dataset, funcInds, clips, features, channels, featurePts, featurePtsLabels, timesUsec, xyz);
%   end
%   
%   % upload annotations to portal
%   annotClasses = round(cellfun(@mean, featureClasses));
%   annotUsec = timesUsec(annotClasses == keepThese,:);
%   annotChannels = channels(annotClasses == keepThese,:);
%   f_uploadAnnotations_v2(dataset,'3-minus-buzzing',annotUsec,annotChannels,'Seizure');
% 


%   % classify using kmeans (unsupervised) or SVM (supervised)
%   %   cIdx = kmeans(featurePts, nClusters);
%   modelFile = fullfile(fullfile(runDir, sprintf('/Output/model-seizure-training-data.mat')));
%   if (exist(modelFile, 'file')==2)
%     fprintf('Loading SVM model.');
%     load(modelFile);
%   else
%     fprintf('Training new SVM model.');
%     model = f_trainSVMmodel(clipsFile,modelFile);
%   end
%   fprintf('Classifying data clips using SVM...\n');
%   featurePts = reshape([features{:}], [], length(featFn));  % calculated feature values, in columns
%   tlabels = zeros(length(featurePts),1);
%   [cIdx] = svmpredict(tlabels,featurePts,model);
%   featureClasses = cell(size(channels,1),1);
%   c = 1;
%   for i = 1: size(channels,1)
%     featureClasses{i} = cIdx(c:c+size(channels{i},2)-1);
%     c = c + size(channels{i},2);
%   end
%   toc

  
end


function featureOut = f_findEnergy(x)
%   dbstop in f_find8HzPower at 176
  fs = 2000; % Hz
  featureOut = cell(length(x),1);
  for i = 1: length(x)
    for j = 1: size(x{i},2)
      y = f_low_pass_filter8(x{i}(:,j),fs);
%       y = bandpower(x{i}(:,j), fs, [2 8]);
%       y = x{i}(:,j);
      featureOut{i}(:,j) = sum(y.^2);  
    end
  end
end

function featureOut = f_findLinelength(x)
%   dbstop in f_findCorrelations at 142
  featureOut = cell(length(x),1);
  for i = 1: length(x)
    for j = 1: size(x{i},2)
      featureOut{i}(:,j) = mean(abs(diff(x{i}(:,j))));  
    end
  end
end

function featureOut = f_findMeancrossings(x)
%   dbstop in f_findCorrelations at 142
  featureOut = cell(length(x),1);
  for i = 1: length(x)
    for j = 1: size(x{i},2)
      y = x{i}(:,j);
      featureOut{i}(:,j) = sum((y(1:end-1,:)>repmat(mean(y),size(y,1)-1,1)) & y(2:end,:)<repmat(mean(y),size(y,1)-1,1) | (y(1:end-1,:)<repmat(mean(y),size(y,1)-1,1) & y(2:end,:)>repmat(mean(y),size(y,1)-1,1))); % mean crossings 
    end
  end
end

function featureOut = f_findFModulation(data, chan)
%   dbstop in f_findFmodulation at 210;
  fs = 2000; % Hz
  featureOut = cell(length(data),1);
  for i = 1: size(data,1)
    for j = 1: size(chan{i},2)
      y = f_high_pass_filter(data{i}(:,j),fs);
      y = f_low_pass_filter(y,fs);
      zx = find( (y(1:end-1,:)>repmat(mean(y),size(y,1)-1,1)) & y(2:end,:)<repmat(mean(y),size(y,1)-1,1) | (y(1:end-1,:)<repmat(mean(y),size(y,1)-1,1) & y(2:end,:)>repmat(mean(y),size(y,1)-1,1))) ; % mean crossings 
      featureOut{i}(:,j) = max(diff((zx))) / mean(diff((zx)));
    end
  end
end

function featureOut = f_find8HzPower(data, chan)
%   dbstop in f_find8HzPower at 176
  fs = 2000; % Hz
  featureOut = cell(length(data),1);
  for i = 1: size(data,1)
    for j = 1: size(chan{i},2)
%       y = f_high_pass_filter(x{i}(:,j),fs);
%       y = f_low_pass_filter12(y,fs);      
      eightHz = bandpower(data{i}(:,j),fs,[6 10]);
      allHz = bandpower(data{i}(:,j),fs,[0 30]);
      featureOut{i}(:,j) = eightHz / allHz;  
    end
  end
end

function featureOut = f_findNChannels(x)
%   dbstop in f_findCorrelations at 142
  featureOut = cell(length(x),1);
  for i = 1: length(x)
    for j = 1: size(x{i},2)
      featureOut{i}(:,j) = size(x{i},2);  
    end
  end
end

function featureOut = f_findCorrelations(x)
%   dbstop in f_findCorrelations at 260
  fs = 2000; % Hz
  featureOut = cell(length(x),1);
  for i = 1: length(x)
    for j = 1: size(x{i},2)
      y = f_high_pass_filter(x{i},fs);
%       y = f_low_pass_filter(y,fs);
      a = reshape(corr(y.^2),[],1);
%       a = max(a(a~=1)); 
%       a(isempty(a)) = 0;
      a = mean(a(a~=1)); 
      a(isnan(a)) = 0;
      featureOut{i}(:,j) = a;
    end
  end  
end

function featureOut = f_findDuration(x)
%   dbstop in f_findCorrelations at 142
  featureOut = cell(length(x),1);
  for i = 1: length(x)
    for j = 1: size(x{i},2)
      featureOut{i}(:,j) = size(x{i},1);  
    end
  end
end

function y = f_high_pass_filter(x, Fs)
  % MATLAB Code
  % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
  % Generated on: 04-Mar-2015 10:14:48

  persistent Hd;

  if isempty(Hd)

    N     = 3;    % Order
    F3dB  = 4;     % 3-dB Frequency
    Apass = 1;     % Passband Ripple (dB)

    h = fdesign.highpass('n,f3db,ap', N, F3dB, Apass, Fs);

    Hd = design(h, 'cheby1', ...
      'SOSScaleNorm', 'Linf');

    set(Hd,'PersistentMemory',true);

  end
  
  y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
%   y = filtfilt(h,x);
end

function y = f_low_pass_filter(x,Fs)
  % MATLAB Code
  % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
  % Generated on: 09-Mar-2015 11:44:09

  persistent Hd;

  if isempty(Hd)

    N     = 4;     % Order
    F3dB  = 30;    % 3-dB Frequency
    Apass = 1;     % Passband Ripple (dB)

    h = fdesign.lowpass('n,f3db,ap', N, F3dB, Apass, Fs);

    Hd = design(h, 'cheby1', ...
      'SOSScaleNorm', 'Linf');

    set(Hd,'PersistentMemory',true);

  end

  y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
%  y = filter(Hd,x);
end


function y = f_low_pass_filter8(x,Fs)
  % MATLAB Code
  % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
  % Generated on: 09-Mar-2015 11:44:09

  persistent Hd;

  if isempty(Hd)

    N     = 4;     % Order
    F3dB  = 8;    % 3-dB Frequency
    Apass = 1;     % Passband Ripple (dB)

    h = fdesign.lowpass('n,f3db,ap', N, F3dB, Apass, Fs);

    Hd = design(h, 'cheby1', ...
      'SOSScaleNorm', 'Linf');

    set(Hd,'PersistentMemory',true);

  end

  y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
%  y = filter(Hd,x);
end

