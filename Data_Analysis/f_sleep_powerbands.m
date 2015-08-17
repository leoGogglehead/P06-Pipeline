% function output = f_sleep_powerbands(data, params, fs, curTime)
function [timeOut, slowFastRatio, sleep_power] = f_sleep_powerbands(data, params, fs, curTime)

%%
% Usage: f_burst_linelength(dataset, params)
% Input:
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
%
% dbstop in f_sleep_powerbands at 242

%%-----------------------------------------
%%---  feature creation and data processing
% calculate number of sliding windows (overlap is ok)
%     NumWins = @(xLen, fs, winLen, winDisp) (xLen/fs)/winDisp-(winLen/winDisp-1);
NumWins = @(xLen, fs, winLen, winDisp)  round(xLen /((winLen-winDisp)*fs)) - 1;
nw = int64(NumWins(length(data), fs, params.windowLength, params.windowDisplacement));
timeOut = zeros(nw,1);
% featureOut = zeros(nw, length(params.channels));

%     filter then normalize each channel by std of entire data block
%     origData = data;
%     data = high_pass_filter(data, fs);
%     data = low_pass_filter(data, fs);
%     rmsdata = rms(data,1);
%     rmsdata(rmsdata > params.rmsArtifactThresh) = NaN;
%     Check back later for artifact removal threshold
%     filtOut = data ./ repmat(rmsdata,size(data,1),1);
filtOut = data;
% filtOut = data(1:params.NumData,:);

%   normalizer = max(std(data)) ./ std(data);
%   for c = 1: length(params.channels)
%     data(:,c) = data(:,c) .* normalizer(c);
%   end

%   % low-pass filter
%   filtOut = low_pass_filter(data, fs); % see below

% Relative power of each band in comparison to total band power. Relative
% power will be in a 1x6 cell array, each cell corresponds to 1 channel.
% Within each cell, there is a matrix size #frequency band x # windows
% (in order of frequency: delta, theta, alpha...)
%     RelativePow = cell(1,6);

% Slow: fast ratio will be in matrix form, size #win x #chan
%     slowFastR = zeros(nw, length(params.channels));
%
% For each channel, calculate the total power and then the relative
% power of each frequency band
for ch = 1 : length(params.channels)
    winLen = params.windowLength;
    winDisp = params.windowDisplacement;
    
    if params.smoothDur > 0
        smoothLength = 1/params.windowDisplacement * params.smoothDur; % in samples of data signal
        smoother =  1 / smoothLength * ones(1,smoothLength);
        
        %             [s,w,t,p] = spectrogram(filtOut(:,ch), winLen*fs, winDisp * fs,[],fs);
        %             TotalPow = sum(p(find(w >= 0.5 & w <=48),:));
        %             TotalPow = conv(TotalPow,smoother, 'same');
        %             timeOut = t + winDisp*fs + curTime;
        %
        %             % Delta band
        %             IdDelta = find(w>= 0.5 & w< 3.5);
        %             PowDelta = sum(p(IdDelta,:));
        %             RelPowDelta(ch,:) = PowDelta ./ TotalPow;
        %             RelPowDelta(ch,:) = conv(RelPowDelta(ch,:), smoother, 'same');
        %
        
        % Calculate relative power and slow:fast power ratio using
        % bandpower. Must use sliding windows
        
        tic
        for w = 1: nw
            winBeg = params.windowDisplacement * fs * (w-1) + 1;
            winEnd = min([winBeg+params.windowLength*fs-1 length(filtOut)]);
            winData = filtOut(winBeg : winEnd, ch);
            timeOut(w) = winEnd/fs*1e6 + curTime;         % right-aligned
            
            [pxx,f] = pwelch(winData,ones(length(winData),1),0,length(winData),fs);
            IdTot = find(f >= 0.5 & f <48);
            TotPowW(ch,w) = sum(pxx(IdTot,:));
            
            IdDelta = find(f >= 0.5 & f <3.5);
            PowDeltaW(ch,w) = sum(pxx(IdDelta,:));
            RelPowDeltaW(ch,w) = PowDeltaW(ch,w) ./ TotPowW(ch,w);
            
            IdTheta = find(f >= 3.5 & f <8);
            PowThetaW(ch,w) = sum(pxx(IdTheta,:));
            RelPowThetaW(ch,w) = PowThetaW(ch,w) ./ TotPowW(ch,w);
            
            IdAlpha = find(f >= 8 & f <12.5);
            PowAlphaW(ch,w) = sum(pxx(IdAlpha,:));
            RelPowAlphaW(ch,w) = PowAlphaW(ch,w) ./ TotPowW(ch,w);
            
            IdSigma = find(f >= 12.5 & f <16);
            PowSigmaW(ch,w) = sum(pxx(IdSigma,:));
            RelPowSigmaW(ch,w) = PowSigmaW(ch,w) ./ TotPowW(ch,w);
            
            IdBeta1 = find(f >= 16 & f <24);
            PowBeta1W(ch,w) = sum(pxx(IdBeta1,:));
            RelPowBeta1W(ch,w) = PowBeta1W(ch,w) ./ TotPowW(ch,w);
            
            IdBeta2 = find(f >= 24 & f <32);
            PowBeta2W(ch,w) = sum(pxx(IdBeta2,:));
            RelPowBeta2W(ch,w) = PowBeta2W(ch,w) ./ TotPowW(ch,w);
            
            IdGamma = find(f >= 32 & f <48);
            PowGammaW(ch,w) = sum(pxx(IdGamma,:));
            RelPowGammaW(ch,w) = PowGammaW(ch,w) ./ TotPowW(ch,w);
            
        end
        TotPowW(ch,:) = conv(TotPowW(ch,:),smoother, 'same');
        RelPowDeltaW(ch,:) = conv(RelPowDeltaW(ch,:),smoother, 'same');
        RelPowThetaW(ch,:) = conv(RelPowThetaW(ch,:),smoother, 'same');
        RelPowAlphaW(ch,:) = conv(RelPowAlphaW(ch,:),smoother, 'same');
        RelPowSigmaW(ch,:) = conv(RelPowSigmaW(ch,:),smoother, 'same');
        RelPowBeta1W(ch,:) = conv(RelPowBeta1W(ch,:),smoother, 'same');
        RelPowBeta2W(ch,:) = conv(RelPowBeta2W(ch,:),smoother, 'same');
        RelPowGammaW(ch,:) = conv(RelPowGammaW(ch,:),smoother, 'same');
        
        % Calculate slow:fast power ratio
        slowFastR(ch,:) = (RelPowDeltaW(ch,:) + RelPowThetaW(ch,:)) ./ (RelPowAlphaW(ch,:) + ...
            RelPowSigmaW(ch,:) +RelPowBeta1W(ch,:) +RelPowBeta2W(ch,:) +RelPowGammaW(ch,:));
        
        toc
    end
end
    
slowFastRatio = slowFastR';
sleep_power.RelPowDelta = RelPowDeltaW';
sleep_power.RelPowTheta = RelPowThetaW';
sleep_power.RelPowAlpha = RelPowAlphaW';
sleep_power.RelPowSigma = RelPowSigmaW';
sleep_power.RelPowBeta1 = RelPowBeta1W';
sleep_power.RelPowBeta2 = RelPowBeta2W';
sleep_power.RelPowGamma = RelPowGammaW';

%         RelPowDeltaW' RelPowThetaW' RelPowAlphaW' RelPowSigmaW' RelPowBeta1W' RelPowBeta2W' RelPowGammaW'];
% 
%     figure(1)
%     subplot(4,2,1)
%     plot(1:length(RelPowDeltaW),RelPowDeltaW(1,:))
%     title('Delta')
%     
%     subplot(4,2,2)
%     plot(1:length(RelPowThetaW),RelPowThetaW(1,:))
%     title('Theta')
%     
%     subplot(4,2,3)
%     plot(1:length(RelPowAlphaW),RelPowAlphaW(1,:))
%     title('Alpha')
%     
%     subplot(4,2,4)
%     plot(1:length(RelPowAlphaW),RelPowSigmaW(1,:))
%     title('Sigma')
%     
%     subplot(4,2,5)
%     plot(1:length(RelPowSigmaW),RelPowBeta1W(1,:))
%     title('Beta1')
%     
%     subplot(4,2,6)
%     plot(1:length(RelPowBeta2W),RelPowBeta2W(1,:))
%     title('Beta2')
%     
%     subplot(4,2,7)
%     plot(1:length(RelPowGammaW),RelPowGammaW(1,:))
%     title('Gamma')
%     
%     subplot(4,2,8)
%     plot(1:length(TotPowW),TotPowW(1,:))
%     title('Total Power')
% 


    % for each window, calculate feature as defined in params
%     for w = 1: nw
%         winBeg = params.windowDisplacement * fs * (w-1) + 1;
%         winEnd = min([winBeg+params.windowLength*fs-1 length(filtOut)]);
%         timeOut(w) = winEnd/fs*1e6 + curTime;         % right-aligned
%         featureOut(w,:) = params.function(filtOut(winBeg:winEnd,:));
%     end

    % smooth window using convolution
%     if params.smoothDur > 0
%         smoothLength = 1/params.windowDisplacement * params.smoothDur; % in samples of data signal
%         smoother =  1 / smoothLength * ones(1,smoothLength);
%         for c = 1: length(params.channels)
% %             featureOut(:,c) = conv(featureOut(:,c),smoother,'same');
%         end
%     end
%     output = [timeOut featureOut];
    %%---  feature creation and data processing
    %%-----------------------------------------
    

    end


% function y = low_pass_filter(x,Fs)
% % MATLAB Code
% % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
% % Generated on: 09-Mar-2015 11:44:09
% 
% persistent Hd;
% 
% if isempty(Hd)
%     
%     N     = 4;     % Order
%     F3dB  = 50;    % 3-dB Frequency
%     Apass = 1;     % Passband Ripple (dB)
%     
%     h = fdesign.lowpass('n,f3db,ap', N, F3dB, Apass, Fs);
%     
%     Hd = design(h, 'cheby1', ...
%         'SOSScaleNorm', 'Linf');
%     
%     set(Hd,'PersistentMemory',true);
%     
% end
% 
% y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
% %  y = filter(Hd,x);
% end
% 
% function y = high_pass_filter(x, Fs)
% % MATLAB Code
% % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
% % Generated on: 04-Mar-2015 10:14:48
% 
% persistent Hd;
% 
% if isempty(Hd)
%     
%     N     = 3;    % Order
%     F3dB  = 4;     % 3-dB Frequency
%     Apass = 1;     % Passband Ripple (dB)
%     
%     h = fdesign.highpass('n,f3db,ap', N, F3dB, Apass, Fs);
%     
%     Hd = design(h, 'cheby1', ...
%         'SOSScaleNorm', 'Linf');
%     
%     set(Hd,'PersistentMemory',true);
%     
% end
% 
% y = filtfilt(Hd.sosMatrix, Hd.ScaleValues, x);
% %   y = filtfilt(h,x);
% end
% 
