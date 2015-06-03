function A = hum(X,varargin)
% A = hum(X,Fs[,bandLims,nu])  Amplitude of AC mains/powerline hum in signal.
%                       [jre 11/14]
% Amplitude A =[1*Nch] of sinusoid detected in each column of signal matrix X =[Ns*Nch] within bandLims = [loHz hiHz]
% (default [54 63]), estimated by eigenvector decomposition. Output can also be 0 if no hum detected, or NaN if noncomputable.
% The peak of the pseudospectrum tends to left-shift outside of bandLims when signal is hum+EEG instead of hum+white noise.
% This can be remedied by denoising lower-freq scalp EEG components, e.g., x-tvd(x,10^nu), though doing so could
% change the meaning of A for large values (hardly so for a pure sinudoid until detrending eats away its own sinusoid).
% Send nu (e.g., -1.3333) as a 4th argument to do this. W/nu=-1.3333, will track A linearly until 28, then eventually
% saturates to 38.8. Can use -ln(1-y/38.8)/0.04429 for y>=27.66 but strictly <38.8 to unwarp A to [28.1752, 290.5568]
% when those "big" values are returned by the algorithm.
% OR could switch to the non-detrended signature when output >=27.66 [now this is the default behavior].
% The eigen method here will eventually return NaNs when input is flat or weird.
%
% A = hum(X,b0,a0)
% A simpler but easily fooled alternative is to use a peaking filter.
% Send 2nd-order IIR filter coefficients b0,a0, e.g., from w0 = 60/(Fs/2); [b0,a0] = iirnotch(w0,w0/35)
% to estimate the amplitude of the residual signal X-notched(X). A big flaw of this method is that it
% will always report some value regardless of there being a peak around the hum, e.g., for white noise.
% Weakness here is that hum peak is in the filter and not necessarily in the signal.
%
% NOTE Hum is really the fundamental AND all its harmonics, but the focus here is on the fundamental only.

if isscalar(varargin{1})  % Requires potential b0 to be a vector, e.g., length 3 if from iirnotch
    Fs = varargin{1};
    if nargin==2
        bandLims = [54 63];
    else
        bandLims = varargin{2};
        if isempty(bandLims), bandLims = [54 63]; end
    end
    if nargin==4, nu = varargin{3}; end
else
    b0 = varargin{1};
    a0 = varargin{2};
end

if isrow(X), X = X(:); end
Nch = size(X,2);
A = NaN(1,Nch);
if exist('nu','var')  % Detrend by denoise 1st to enhance pseudospectrum peak around hum, if any
    Xorig = X;  % EXPERIMENTAL Keeping a copy to autoretry w/o tvd when output A>=27.66
    for j=1:Nch
        X(:,j) = X(:,j) - tvd(X(:,j),10^nu);
    end
else
    X = detrend(X,0);  % Not critical, but for consistency in values range. Same as subtracting smoothest possible tvd
end

if exist('bandLims','var')  % The eigen method
    X = double(X);  % Eig requires doubles
    warning('off','MATLAB:singularMatrix')  % When near-singular doesn't converge & would spit mssg for several iter
      % To also mute displayed mssg 'Exiting: Iteration count is exceeded, exiting LSQNONNEG...'
      % would need to mod rootmusic.m to pass a 3rd arg w/OPTIONS.Display='none' in call to lsqnonneg.m
      % [For now admin-forced the commenting out of lines 157-9 in R2013b installed dir. R2014b wouldn't allow so copied the identical R2013b file]
    for j=1:Nch
        try
            [f,pow] = rooteig(X(:,j),2,Fs);  % Hum is really the fundamental & all its harmonics, but the 2 here requests only 1 sinusoid
            ixHit = find(f>=bandLims(1)&f<=bandLims(2),1);
            if isempty(ixHit)
                pow = 0;
            else
                pow = pow(ixHit);
            end
            A(j) = sqrt(2*pow);
            if A(j)>=27.66 && exist('nu','var')  % EXPERIMENTAL When no longer in linear zone, retry w/simple mean removal instead of smooth TVD-detrended
                A(j) = hum(Xorig(:,j),Fs,bandLims);  % Signature w/o nu; no infinite loop w/above 2nd minterm
            end
        catch  % Weird & flat chans make it crash badly when roots receives [Inf,NaN,-Inf,...]' from rootmusic.m
            A(j) = NaN;
        end
    end
else  % The peaking filter method
    for j=1:Nch
        A(j) = sqrt(2)*rms(X(:,j)-filter(b0,a0,X(:,j)));
    end
end
