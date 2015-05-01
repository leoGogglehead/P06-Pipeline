function output = f_spike_AR(data, params, fs, curPt)
  % (dataset,channels,mult)
  %   USAGE: [eventTimesUSEc eventChannels] = spike_AR(dataset, channels,mult)
  % 
  %   This function will detect spikes in channels of a given dataset, and upload to layerName annotation layer on the portal.
  %   Each spike occurrence will be returned in an array of times eventTimesUSec (in microsecs) and eventChannels (idx)
  %   The algorithm is based off of Acir 2004 and is as follows:
  %	1. Bandpass filter data 1-70 Hz
  %	2. Model with autoregressive model of order 5 with Burg's lattice-based method
  %	3. Square residuals and apply amplitude threshold (mult*stddev of squared residual) to detect spikes
  %
  %   INPUT:
  %   'dataset'   -   IEEGDataset object
  %   'channels'  -   [Nx1] array of channel indices
  %   'mult'      -   integer to multiply by standard deviation for threshold

  %   OUTPUT:
  %   'eventTimesUSec'    -   times of events in microsecds
  %   'eventChannels'     -   corresponding channels for each event
  %
  %   See also: uploadAnnotations.m
  %
  %   History:
  %   8/22/2014:  commented code more thoroughly: Hoameng Ung
  % 
%     dbstop in f_spike_AR at 49

  %%-----------------------------------------
  %%---  feature creation and data processing
  
  % normalize data so RMS of each channel = 1
%   origData = data;
  data = data ./ repmat(rms(data,1),size(data,1),1);
  filtOut = low_pass_filter(data, fs); % filter code is below

  e_n = data - filtOut; %residual
  sigma = repmat(std(e_n,1),size(e_n,1),1); % std(e_n); 
  d_n = (e_n./sigma).^2;
  featureOut = double(d_n > params.spikeThresh);
  
  % smooth to remove double spikes
  if params.smoothDur > 0
    smoothLength = fs * params.smoothDur; % in samples of data signal
    smoother =  1 / smoothLength * ones(1,smoothLength);
    for c = 1: length(params.channels)
      featureOut(:,c) = conv(featureOut(:,c),smoother,'same');
    end
  end
  output = [double(curPt:curPt+length(featureOut)-1)' featureOut];

  
%   figure(1);  ax1 = subplot(311); 
%   t=1:length(data);  t = t *1 / fs;
%   plot(t,data(:,3),'k');  hold on;
%   ax2 = subplot(312);  plot(t,d_n(:,3),'k');
%   line([t(1) t(end)],[params.minThresh params.minThresh]);
%   ax3 = subplot(313);
%   plot(t,featureOut(:,3));
%   linkaxes([ax1,ax2,ax3],'x');

%   % find derivative
%   deriv = [zeros(1,length(params.channels)); sign(diff(d_n))];
%    
%   % find where the sign changes from positive to negative: diff will be less
%   % than zero
%   diffOfSign = [zeros(1,length(params.channels)); diff(deriv) < 0];     % 1's indicate the peaks
% %   plot(timeVec(2:end-1),diffOfSign, 'g'); % we lose another value from diff
% 
%   % now need to narrow down which ones are above threshold
%   abovePeak = d_n > params.minThresh; % ones tell where data is above threshold
% %   plot(timeVec, abovePeak,'c');
% 
%   % find indices where signal is both above thresh and a maximum
%   multiplyBoth = abovePeak .* diffOfSign;
%   [idx chan] = find(multiplyBoth);
% %   plot(data(:,3),'k'); hold on;
% %   plot(idx(chan == 3),-16,'r.');

%   % find elements of output that are over threshold and convert to
%   % start/stop time pairs (in usec)
%   % end time is one window off because of the diff above - correct it below
%   annotChannels = [];
%   annotUSec = [];
%   i = 1;
%   while i <= length(idx)
%     if (chan(i+1) == chan(i))
%       if ( (idx(i+1) - idx(i))/fs >= params.minISI / 1000 )
%         annotChannels = [annotChannels; chan(i)];
%         annotUSec = [ annotUSec; ...
%         [output(idx(i),1)/fs*1e6 ((output(idx(i+1),1)/fs-params.windowDisplacement))*1e6] ];
%       end
%     else
%       % insert a NaN as a placeholder? Can weed them out in
%       % f_addAnnotationss
%       keyboard;
%     end
%     i = i + 2;
%   end
%   output = [annotChannels-1 annotUSec]';

    % plot things
    %   figure(1); 
    %   subplot(311); hold on;
    %   plot(data(1:15*2000,3),'k');
    %   plot(filtOut(1:15*2000,3),'b');
    %   subplot(312); 
    %   plot(e_n(1:15*2000,3),'k');
    %   subplot(313); plot(d_n(1:15*2000,3),'r');

    %   % --- autoregressive
    %   filtOut = band_pass_filter(data, fs); % Fc = 2 Hz, see below
    % 
    %   for c = 1: size(filtOut,2)
    %     d1 = filtOut(:,c);
    %
    %     %assume order 5, solve AR model with Burg's lattice method
    %     model =ar(d1,5,'burg');
    %     yhat = predict(model,d1,5);
    %     e_n = d1 - yhat; %residual
    %     sigma = std(e_n); 
    %     d_n = (e_n/sigma).^2;
    % 
    %     %remove nan values from calculation of threshold
    %     tmp = d_n;
    %     tmp(isnan(data)) = [];
    %     thres = mean(tmp) + params.mult*std(tmp); %threshold residual squared by multiple
    % 
    %     %find peaks
    %     d_n(isnan(data)) = 0;
    %     [~, idx] = findpeaks(d_n,'MINPEAKHEIGHT',thres);
    %     spikeIdx = idx(diff(idx)>.075*fs); %keep peaks >.075 s apart
    %     spikeIdx = double(curPt) + spikeIdx - 1; %set spikeIdx relative to block
    %
    %   eventTimesUSec = [eventTimesUSec; spikeIdx/fs*1e6];
    %   eventChannels = [eventChannels; ones(numel(spikeIdx),1)*i];
    % --- autoregressive
    % 
    %     output = [spikeIdx featureOut]';
    %   end
  %%---  feature creation and data processing
  %%-----------------------------------------
end

function y = low_pass_filter(x, Fs)
  % MATLAB Code
  % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
  % Generated on: 05-Mar-2015 15:21:21

  persistent Hd;

  if isempty(Hd)

    N     = 6;     % Order
    F3dB  = 5;    % 3-dB Frequency
    Astop = 80;    % Stopband Attenuation (dB)
    Fs    = 2000;  % Sampling Frequency

    h = fdesign.lowpass('n,f3db,ast', N, F3dB, Astop, Fs);

    Hd = design(h, 'cheby2', ...
      'SOSScaleNorm', 'Linf');

    set(Hd,'PersistentMemory',true);

  end
  
  y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
%   y = filter(Hd,x);
end

% function y = band_pass_filter(x, Fs)
%   % MATLAB Code
%   % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
%   % Generated on: 04-Mar-2015 12:46:24
% 
%   persistent Hd;
% 
%   if isempty(Hd)
% 
%     N     = 6;     % Order
%     F3dB1 = 1;     % First
%     F3dB2 = 70;    % Second
%     Apass = 1;     % Passband Ripple (dB)
% 
%     h = fdesign.bandpass('n,f3db1,f3db2,ap', N, F3dB1, F3dB2, Apass, Fs);
% 
%     Hd = design(h, 'cheby1', ...
%       'SOSScaleNorm', 'Linf');
% 
%     set(Hd,'PersistentMemory',true);
% 
%   end
% 
%   y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
% %   y = filter(Hd,x);
% end