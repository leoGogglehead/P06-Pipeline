% Use these commands to convert from portal time to actual time.
% Portal time starts at day 1, 0:00:00.  Actual time start depends 
% on the animal.
% 
% On the portal, navigate to the event you want to look up.  Note the time
% of the event, ie, Day 2 08:44:10.  Enter this below, ie, portalTime =
% datenum('02:08:44:10', 'dd:HH:MM:SS');
% 
% Then update the dateOffset with the start time of the rat recording
% (provided below), ie, for animal r099, enter dateOffset = 
% datenum('05/09/2008 13:19:06', 'mm/dd/yyyy HH:MM:SS') ...
%
% actualTime will be displayed in the matlab command window:
% 'portalTime 02-Jan-2015 08:44:10 = actualTime 10-May-2008 22:03:16'

study = 'sleepPSA';  % 'dichter'; 'jensen'; 'pitkanen'
portalId = 'RB09601';
convertFromPortalToActual = '01:05:38:00';  % 'dd:HH:MM:SS'; 01:00:00:00 = start time of portal
convertFromActualToPortal = '04/26/2012 02:01:13 AM';  % mm/dd/yyyy HH:MM:SS PM

%%.......

switch study
    case 'dichter'
        rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD';
        runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data';
    case 'jensen'
        rootDir = 'Z:\public\DATA\Animal_Data\Frances_Jensen';
        runDir = 'C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data';
    case 'sleepPSA'
        addpath(genpath('F:\Grad School\Github\P06-Pipeline'));
        runDir = 'F:\Grad School\Github\PSG export'
end
addpath(genpath(runDir));
fh = str2func(['f_' study '_data_key']);
dataKey = fh();

idx = find(strcmp(dataKey.portalId, portalId));

dateOffset = datenum(dataKey.startSystem(idx), 'dd-mmm-yyyy HH:MM:SS') - datenum('01:00:00:00', 'dd:HH:MM:SS');

portalTime = datenum(convertFromPortalToActual, 'dd:HH:MM:SS');
actualTime = datestr(portalTime + dateOffset);
fprintf('Portal %s = Subject %s\n', dataKey.portalId{idx}, dataKey.animalId{idx});
fprintf('portalTime %s = actualTime %s\n', convertFromPortalToActual, datestr(actualTime, 'mm/dd/yyyy HH:MM:SS'));

actualTime = datenum(convertFromActualToPortal, 'mm/dd/yyyy HH:MM:SS');
portalTime = datestr(actualTime - dateOffset + 1, 'dd:HH:MM:SS');
fprintf('actualTime %s = portalTime %s\n', datestr(actualTime, 'dd-mmm-yyyy HH:MM:SS'), portalTime);

