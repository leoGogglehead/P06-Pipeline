clear all; clc; close;
% SFR toolbox will not work on Windows!  Only Mac or Linux.
% Remember you need to edit SFR_ReposFile.xml with paths to data
%
% be sure there are no extra/blank lines in SFR_ReposFile.xml - gives a
%   "[Fatal Error] SFR_ReposFile.xml:2:6: The processing instruction target
%   matching "[xX][mM][lL]" is not allowed.] error
%
% <SFR_REPOSFILE user="jtmoyer">
%    <LOC id="orion">
%      <REPOS id="SFRroot" path="/Users/jtmoyer/desk/MATLAB/P04-Jensen-data"/>
%      <REPOS id="AnimalData" path="/Volumes/fourier.seas.upenn.edu/public/DATA/Animal_Data/Frances_Jensen/r206/Hz2000/r206_000_mef"/>
%    </LOC>
% </SFR_REPOSFILE>  

addpath('/Users/jtmoyer/desk/MATLAB/P05-Dichter-data');
addpath('/Users/jtmoyer/desk/MATLAB/');
addpath(genpath('/Users/jtmoyer/desk/MATLAB/SFR-Toolbox'));
addpath('/Users/jtmoyer/desk/MATLAB/SFR-Toolbox/lib');
addpath('/Users/jtmoyer/desk/MATLAB/SFR-Toolbox/tools');
addpath(genpath('/Users/jtmoyer/desk/MATLAB/ieeg-matlab-1.8.3'));

%% load data from portal
% portal_file = 'I023_A0001_D001';
% session = IEEGSession(portal_file,'jtmoyer','jtm_ieeglogin.bin');


%% load post-processed data using SFR toolbox
sfrsetlocation('orion','/Users/jtmoyer/desk/MATLAB/SFR_ReposFile.xml');
typeID = 'MefByChannel';
rootID = 'AnimalData';
subPath = '';
files = {'Dichter_r121_ch01_L_DG.mef'};  % 'good_chan001.mef'
repos = SFRepos(typeID, rootID, subPath, files);
post_data = repos.data;


blockSize = 10*60*2000;   % minutes * seconds * sampling frequency

for b = 1:100
  curPt = 1 + (b-1)*blockSize;
  endPt = b*blockSize;
  times = (curPt:endPt)/1e6;
  plot(times,post_data.data(curPt:endPt),'k');
  pause;
end

%% compare data 
% block_size = 6000;
% times = 1:block_size;
% 
% i = 1;
% while i < 10
%   pre_data = session.data.getvalues(times,1);
%   plot(times,pre_data,'b'); hold on;
%   plot(times,post_data.data(times,1),'r'); hold off; 
%   times = times+block_size;
%   i = i + 1;
% end