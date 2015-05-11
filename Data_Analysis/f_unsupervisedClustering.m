function allData = f_unsupervisedClustering(session, allData, funcInds, runThese)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_unsupervisedClustering at 53

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
  [cIdx, xyz] = kmeans(featurePts, 2, 'Distance', 'sqeuclidean');


  if xyz(1,1) > xyz(2,1)    % class1 = 'artifact';  class2 = 'not-artifact';
    keepThese = 2;
  else                      % class1 = 'not-artifact'; class2 = 'artifact';
    keepThese = 1;
  end
  
  %     f_plot1DFeatures(featuresMatrix{r});
%   f_plot3DScatter(featurePts, cIdx, funcInds, keepThese);
  
  % get rid of the data points in allData that are artifact
  for r = 1:length(runThese)
    featureClasses = zeros(size(allData(r).channels));
    c = 1;
    % cIdx is classes vector; collapse to dimensions of allData.channels
    % use mean as tiebreaker if same clip gets > 1 class
    for i = 1: size(allData(r).channels,1)
      featureClasses(i) = round(mean(cIdx(c:c+size(allData(r).channels{i},2)-1)));
      c = c + size(allData(r).channels{i},2);
    end
    
    fprintf('%s: Removing %d/%d annotations.\n', session.data(r).snapName, length(find((featureClasses ~= keepThese))), length(featureClasses));
    
    allData(r).channels = {allData(r).channels{featureClasses == keepThese}}';
    allData(r).timesUsec = (allData(r).timesUsec(featureClasses == keepThese,:));
    allData(r).features = reshape({allData(r).features{featureClasses == keepThese,:}},[],size(allData(r).features,2));
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

  
end

