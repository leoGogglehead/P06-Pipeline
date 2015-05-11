function f_plot3DScatter(featurePts, cIdx, funcInds, keepThese)

%   dbstop in f_plot3DScatter at 6;

  % create 3D scatter plot to help visualize data
  colors = ['r' 'b' 'g' 'y' 'm' 'c' 'k'];
  figure(2);
%  tmp = cellfun(@regexp, cIdx, repmat(cellstr('not'),[length(cIdx) 1]), 'UniformOutput', false); % true = not an artifact
  idx = cIdx == keepThese;
  if size(funcInds,2) == 1
    plot(ones(size(featurePts(idx,1))), reshape(featurePts(idx,1),[],1), '.k'); hold on;
    plot(ones(size(featurePts(~idx,1))), reshape(featurePts(~idx,1),[],1), '.', 'Color', [0.7 0.7 0.7]);
  elseif size(funcInds,2) == 2
    scatter(reshape(featurePts(idx,1),[],1), reshape(featurePts(idx,2),[],1), 12, 'k', 'filled'); hold on;
    scatter(reshape(featurePts(~idx,1),[],1), reshape(featurePts(~idx,2),[],1), 12, [0.7 0.7 0.7], 'filled');
  elseif size(funcInds,2) >= 2
    scatter3(reshape(featurePts(idx,1),[],1), reshape(featurePts(idx,2),[],1), reshape(featurePts(idx,3),[],1), 12, 'k', 'filled'); hold on;
    scatter3(reshape(featurePts(~idx,1),[],1), reshape(featurePts(~idx,2),[],1), reshape(featurePts(~idx,3),[],1), 12, [0.7 0.7 0.7], 'filled');
  end
  xlabel('Feature 1'); ylabel('Feature 2'); zlabel('Feature 3');
%   for i = 1: 2 % nClusters
%     scatter3(featurePts(cIdx==i,1), featurePts(cIdx==i,2), featurePts(cIdx==i,3), 36, colors(i)); hold on;
%   end
%   xlabel('Feature 1'); ylabel('Feature 2'); zlabel('Feature 3');
end