function [groupStruct, h] = f_boxPlot(session, runThese, dataKey, layerName)
  % f_boxPlot will create a box and whisker plot for each data session in
  %    runThese. Plots are grouped by dataKey.treatmentGroup.
  %
  % Inputs
  % session: IEEG session including all sessions for which to plot events
  % runThese: vector of indexes to plot (cooresponding to dataKey.index)
  % dataKey: table of index, animalId, portalId, treatmentGroup
  % layerName: annotation layer for which to plot events
  %
%   dbstop in f_boxPlot at 76;
  
  groupName = cell(length(runThese),1);
  lengthInDays = nan(length(runThese),1);
  numEvents = nan(length(runThese),1);
  eventsPerDay = nan(length(runThese),1);
  
  % create box plot
  for r = 1: length(runThese)
    % find appropriate annLayer based on layerName
    assert(strcmp(session.data(r).snapName, dataKey.portalId(runThese(r))), 'SnapName does not match dataKey.portalID\n');
    a = 1;
    try
      while ~strcmp(session.data(r).annLayer(a).name, layerName) && a <= length(session.data(r).annLayer)
        a = a + 1;
      end
      assert(strcmp(session.data(r).annLayer(a).name,layerName), 'Layer not found: %s in %s\n', layerName, session.data(r).snapName);
    catch
      fprintf('Layer not found: %s in %s\n', layerName, session.data(r).snapName);
    end
    
    groupName{r} = dataKey.treatmentGroup{runThese(r)};
    try
      lengthInDays(r) = (session.data(r).channels(1).get_tsdetails.getDuration/1e6/60/60/24);
      numEvents(r) = session.data(r).annLayer(a).getNrEvents;
    catch
      fprintf('Setting numEvents to 0.\n');
      numEvents(r) = 0;
    end
    eventsPerDay(r) = numEvents(r)/lengthInDays(r);
  end
  
  % create box plot
  uniqueGroups = unique(groupName);
  figure(1); h = boxplot(eventsPerDay, groupName, 'groupOrder', uniqueGroups); hold on;
  xlabel('Treatment Group');
  ylabel('Postulated Epileptiform Events per Day');

  % overlay data points on top of box plot
  for r = 1: length(uniqueGroups)
    inds = cellfun(@strcmp, groupName, cellstr(repmat(uniqueGroups{r}, size(groupName))));
    plot(repmat(r, size(inds(inds==1))), eventsPerDay(inds), 'o', 'MarkerSize', 6);
  end
  
  % perform ranksum test, use sigstar to plot significance levels
  figure(1);
  sigcell = {};
  sigprob = [];
  for r = 1: length(uniqueGroups)
    inds = cellfun(@strcmp, groupName, cellstr(repmat(uniqueGroups{r}, size(groupName))));
    for j = r+1: length(uniqueGroups)
      inds2 = cellfun(@strcmp, groupName, cellstr(repmat(uniqueGroups{j}, size(groupName))));
      [p(r,j) h0(r,j)] = ranksum(eventsPerDay(inds), eventsPerDay(inds2));
      fprintf('\nTest %s vs %s, p = %0.3f, h = %d\n', uniqueGroups{r}, uniqueGroups{j}, p(r,j), h0(r,j));
      sigcell = [sigcell, [r j]];
      sigprob = [sigprob p(r,j)];
    end
  end
  sigstar(sigcell, sigprob);
  ylim([0 300]);
  title(layerName);

  % plot rats individually to get a sense where the data points are
  colors = ['k' 'b' 'r' 'g'];
  figure(3); hold on;
  for r = 1:size(eventsPerDay,1)
    animalNumber = str2num(session.data(r).snapName(9:10));
    c = strcmp(uniqueGroups, groupName{r});
    h2(c) = bar(animalNumber, eventsPerDay(r), colors(c));
  end
  legend(h2, uniqueGroups{1:4});  
  title(layerName);
end