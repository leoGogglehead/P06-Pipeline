function allData = f_unsupervisedClustering(session, allData, funcInds, runThese, params)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%    dbstop in f_unsupervisedClustering at 91

% download training data from portal and save to file or load from file
% download data from portal and save to file or load from file
% calculate features for each training clip - don't save these to file yet
% calculate features for each data clip - don't save these to file yet
% cluster 
% - maybe several times, w/ different features
% - how to keep track of which clips go to which animal?
% - ideally would be able to click on data points in scatter plots and view

  featurePts = [];
  for r = 1: length(runThese)
    featurePts = [featurePts; reshape([allData(r).features{:,funcInds}], {}, length(funcInds))];
  end
  
%   featurePts = zscore(featurePts);
%   [cIdx, xyz] = kmeans(featurePts, 2, 'Distance', 'sqeuclidean');
%   if xyz(1,1) > xyz(2,1)    % class1 = 'artifact';  class2 = 'not-artifact';
%     keepThese = 2;
%   else                      % class1 = 'not-artifact'; class2 = 'artifact';
%     keepThese = 1;
%   end
  
  try
    binWidth = 1;
    bins = floor(min(featurePts)):binWidth:ceil(max(featurePts));
    h1 = hist(featurePts, bins);
  %   bar(bins, h1);
    localMinima = [false diff(sign(diff(h1))) > 0 true];
  %   topTwoThirds = (1:nbins) > nbins/3;
    aboveMedian = bins >= hist(median(featurePts),bins);
    thresh = bins(logical(localMinima .* aboveMedian));
    thresh = thresh(1) - binWidth/2;  % set thresh to left edge
    
  % remove values greater than threshold
  % too look at what's being removed on portal, switch to a <=
    if params.lookAtArtifacts 
      cIdx = (featurePts < repmat(thresh, length(featurePts), 1));
    else
      cIdx = (featurePts >= repmat(thresh, length(featurePts), 1));
    end

    if params.plot3DScatter 
      f_plot3DScatter(featurePts, cIdx, funcInds);
    end
  catch 
  end
  
  
  % get rid of the data points in allData that are artifact
  % cIdx is classes vector; collapse to dimensions of allData.channels
  % if any channel has artifact, call them all artifact to avoid crosstalk
  c = 1;
  for r = 1:length(runThese)
    try
      featureClasses = NaN(size(allData(r).channels));
      for i = 1: size(allData(r).channels,1)
        if params.lookAtArtifacts 
          featureClasses(i) = all(cIdx(c:c+size(allData(r).channels{i},2)-1) == ones(length(allData(r).channels{i}),1));
        else
          featureClasses(i) = any(cIdx(c:c+size(allData(r).channels{i},2)-1) == ones(length(allData(r).channels{i}),1));
        end
          
        % featureClasses(i) = round(mean(cIdx(c:c+size(allData(r).channels{i},2)-1)));
        c = c + size(allData(r).channels{i},2);
      end
      if params.plot1DFeatures
        f_plot1DFeatures(session.data(r), allData(r), funcInds, featureClasses);
      end

      fprintf('%s: Removing %d/%d annotations.\n', session.data(r).snapName, length(find((featureClasses))), length(featureClasses));

      allData(r).channels = {allData(r).channels{logical(~featureClasses)}}';
      allData(r).timesUsec = (allData(r).timesUsec(logical(~featureClasses),:));
      allData(r).features = reshape({allData(r).features{logical(~featureClasses),:}},[],size(allData(r).features,2));
    catch
    end
  end
end

%   %....
%   % 2 - remove pinging artifact - classify using kmeans (unsupervised) or SVM (supervised)
%   funcInds = [1];
%   features = features(annotClasses == keepThese,:);
%   channels = channels(annotClasses == keepThese,:);
%   featurePts = reshape([features{:,funcInds}], [], length(funcInds));
%   [cIdx, xyz] = kmeans(featurePts, 2, 'Distance', 'sqeuclidean');
%   
%   if xyz(1,1) > xyz(2,1)
%     class1 = 'artifact';
%     class2 = 'not-artifact';
%     keepThese = 2;
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
%     fstring = sprintf('featureLabels{i} = repmat(cellstr(class%d),[1 size(channels{i})])', featureClasses{i}(1));
%     eval(fstring);
%     for j = 1: size(channels{i},2)
%       featurePtsLabels{c+j-1} = cellstr(featureLabels{i}(j));
%     end
%     c = c + size(channels{i},2);
%   end
%   
%   % upload annotations to portal
%   annotClasses = round(cellfun(@mean, featureClasses));
%   annotUsec = timesUsec(annotClasses == keepThese,:);
%   annotChannels = channels(annotClasses == keepThese,:);
%   f_uploadAnnotations_v2(dataset,'2-minus-pinging',annotUsec,annotChannels,'Seizure');

  
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


