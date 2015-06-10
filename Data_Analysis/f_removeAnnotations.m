function allData = f_removeAnnotations(session, params, allData, featFn, useTheseFeatures)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_removeAnnotations at 32
  
  featFn(useTheseFeatures)
  useData = allData;
  for u = 1: length(useTheseFeatures)
    f = useTheseFeatures(u);
    for r = 1: size(allData,1)
      for a = size(allData(r).features,1): -1: 1
        if params.lookAtArtifacts
          removeIdx = find(allData(r).features{a,f} == 0);
        else
          removeIdx = find(allData(r).features{a,f} == 1);
        end
        if length(removeIdx) == length(allData(r).features{a,f})
          allData(r).channels(a) = [];
          allData(r).timesUsec(a,:) = [];
          allData(r).features(a,:) = [];
          allData(r).labels(a,:) = [];
        else
          for i = 1: size(allData(r).features,2)
            allData(r).features{a,i}(removeIdx) = [];
          end
          allData(r).channels{a}(removeIdx) = [];
        end
      end
    end
  end
  for r = 1: length(session.data)
    fprintf('%s: Removed %d/%d annotations.\n', session.data(r).snapName, (size(useData(r).timesUsec,1)-size(allData(r).timesUsec,1)), size(useData(r).timesUsec,1));
  end
end

