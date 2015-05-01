function f_boxPlotPerDay(session, runDir, runThese, dataKey, layerName)
  % f_boxPlot will create a box and whisker plot for each data session in
  %    runThese. Plots are grouped by dataKey.treatmentGroup.
  %
  % Inputs
  % session: IEEG session including all sessions for which to plot events
  % runThese: vector of indexes to plot (cooresponding to dataKey.index)
  % dataKey: table of index, animalId, portalId, treatmentGroup
  % layerName: annotation layer for which to plot events
  %
%   dbstop in f_boxPlotPerDay at 170;
  
  groupName = cell(length(runThese),1);
  lengthInDays = nan(length(runThese),1);
  numEvents = nan(length(runThese),1);
  eventsPerDay = cell(length(runThese),1);
  
  % create box plot
  for r = 1: length(runThese)
    % find appropriate annLayer based on layerName
    assert(strcmp(session.data(r).snapName, dataKey.portalId(runThese(r))), 'SnapName does not match dataKey.portalID\n');
    fname = fullfile(runDir, sprintf('./Output/%s-annot-%s.txt',session.data(r).snapName,layerName));
    try
      fileExist = dir(fname);
      if fileExist.bytes > 0
        m = memmapfile(fname,'Format','single');
        eventData = reshape(m.data,3,[]);
        eventChannels = eventData(1,:)';
        eventTimesUsec = eventData(2:3,:)';
      else
        fprintf('No data found in: %s\n',fname);
        eventChannels = 0;
        eventTimesUsec = [-1 -1];
      end
    catch
      fprintf('File not found: %s\n',fname);
      eventChannels = 0;
      eventTimesUsec = [-1 -1];
    end
    

    % want to combine overlapping annotations for feature analysis.
    % if end time of first row is later than start time of second row,
    % there is an overlap - change end time of both to max end time of both
    % keep running through data until no more changes are found.
    [~,idx] = sort(eventTimesUsec(:,1));
    times = eventTimesUsec(idx,:);
    chans = eventChannels(idx);

    somethingChanged = 1;
    while somethingChanged
      somethingChanged = 0;
      i = 2;
      while i <= length(chans)
        if (times(i-1,2) > times(i,1)) && (times(i-1,2) ~= times(i,2))
          times(i-1,2) = max([times(i-1,2) times(i,2)]);
          times(i,2) = max([times(i-1,2) times(i,2)]);
          somethingChanged = 1;
        end
        i = i + 1;
      end
    end

    % if the end times match between rows, change the start times to the
    % earliest start time.  keep running until no more changes found.
    somethingChanged = 1;
    while somethingChanged
      somethingChanged = 0;
      i = 2;
      while i <= length(chans)
        if (times(i,1) > times(i-1,1)) && (times(i-1,2) == times(i,2))
          times(i,1) = times(i-1,1);
          somethingChanged = 1;
        end
        i = i + 1;
      end
    end

    % there might be multiple annotations with same start/stop time on the
    % same channel (from having several annots in same region)
    [~,idx] = sort(chans);
    times = times(idx,:);
    chans = chans(idx);
    i = length(chans);
    while i > 1
      if chans(i) == chans(i-1)
        if int64(times(i,1)) == int64(times(i-1,1)) && int64(times(i,2)) == int64(times(i-1,2))
          chans(i) = [];
          times(i,:) = [];
         end
      end
      i = i - 1;
    end

    % run from end to beginning of annotations - if start and end times
    % match, compress into one annotation across multiple channels
    [~,idx] = sort(times(:,1));
    times = times(idx,:);
    chans = num2cell(chans(idx));
    i = length(chans);
    while i > 1
      if int64(times(i,1)) == int64(times(i-1,1)) && int64(times(i,2)) == int64(times(i-1,2))
        chans{i-1} = [chans{i-1} chans{i}];
        chans(i) = [];
        times(i,:) = [];
      end
      i = i - 1;
    end
    eventChannels = chans;
    eventTimesUsec = times;

    % use histcounts to calculate number of events per day
    dayUsec = 24*60*60*1e6;
    groupName{r} = dataKey.treatmentGroup{runThese(r)};
    try
      lengthInDays(r) = (session.data(r).channels(1).get_tsdetails.getDuration/1e6/60/60/24);
      dayBins = dayUsec * (0:ceil(lengthInDays(r)));
    catch
      fprintf('Setting numEvents to 0.\n');
      numEvents(r) = 0;
    end
    eventsPerDay{r} = histc(eventTimesUsec(:,1), dayBins);
    % drop the last bin (zero) and second to last (fraction of a day)
    eventsPerDay{r}(end-1:end) = [];

%     % or extrapolate if > 0.5 day at the end?
%     if lengthInDays(r)-floor(lengthInDays(r) > 0.5
%       eventsPerDay{r}(end) = round(eventsPerDay{r}(end) * 1/(lengthInDays(r)-floor(lengthInDays(r))));
%     else
%       eventsPerDay{r}(end) = [];
%     end      
  end
    
  % create box plot
  eventsPerDayCol = [];
  groupsPerDayCol = [];
  for r = 1:size(eventsPerDay,1)
    eventsPerDayCol = [eventsPerDayCol; eventsPerDay{r}(:)];
    groupsPerDayCol = [groupsPerDayCol; repmat(groupName(r), size(eventsPerDay{r}(:)))];
  end
  uniqueGroups = unique(groupsPerDayCol);
  figure(1); h = boxplot(eventsPerDayCol, groupsPerDayCol, 'groupOrder', uniqueGroups); hold on;
  xlabel('Treatment Group');
  ylabel('Postulated Epileptiform Events per Day');
  title(layerName);

  % overlay data points on top of box plot
  for r = 1: length(uniqueGroups)
    inds = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{r}, size(groupsPerDayCol))));
    plot(repmat(r, size(inds(inds==1))), eventsPerDayCol(inds), 'o', 'MarkerSize', 6);
  end
  
%   % look at distribution - is it gaussian?
%   figure(2); 
%   for r = 1: length(uniqueGroups)
%     subplot(length(uniqueGroups),1,r);
%     inds = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{r}, size(groupsPerDayCol))));
%     y = hist(eventsPerDayCol(inds),20);
%     bar(y);
%     title(uniqueGroups{r});
%   end
  
  % perform ranksum test, use sigstar to plot significance levels
  figure(1);
  sigcell = {};
  sigprob = [];
  for r = 1: length(uniqueGroups)
    inds = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{r}, size(groupsPerDayCol))));
    for j = r+1: length(uniqueGroups)
      inds2 = cellfun(@strcmp, groupsPerDayCol, cellstr(repmat(uniqueGroups{j}, size(groupsPerDayCol))));
      [p(r,j) h0(r,j)] = ranksum(eventsPerDayCol(inds), eventsPerDayCol(inds2));
      fprintf('\nTest %s vs %s, p = %0.3f, h = %d\n', uniqueGroups{r}, uniqueGroups{j}, p(r,j), h0(r,j));
      sigcell = [sigcell, [r j]];
      sigprob = [sigprob p(r,j)];
    end
  end
  sigstar(sigcell, sigprob);
  ylim([0 350]);

  
  % plot rats individually to get a sense where the data points are
  colors = ['k' 'b' 'r' 'g'];
  figure(3); hold on;
  for r = 1:size(eventsPerDay,1)
    animalNumber = str2num(session.data(r).snapName(9:10));
    c = strcmp(uniqueGroups, groupName{r});
    h2(c) = plot(repmat(animalNumber, size(eventsPerDay{r})), eventsPerDay{r}, 'Marker', '.', 'Color', colors(c));
  end
  legend(h2, uniqueGroups{1:4});  
  title(layerName);
end