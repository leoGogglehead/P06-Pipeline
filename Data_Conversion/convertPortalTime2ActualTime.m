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
% 
% r099 = I032_A0002_D001, start time = '05/09/2008 13:19:06'
% r101 = I032_A0004_D001, start time = '06/05/2008 14:12:37'
% r121 = I032_A0007_D001, start time = '03/17/2009 12:47:37'
% r161 = I032_A0015_D001, start time = '07/21/2011 17:09:07'

portalTime = datenum('02:08:44:10', 'dd:HH:MM:SS');
dateOffset = datenum('05/09/2008 13:19:06', 'mm/dd/yyyy HH:MM:SS') - datenum('01:00:00:00', 'dd:HH:MM:SS');
actualTime = datestr(portalTime + dateOffset);
fprintf('portalTime %s = actualTime %s\n', datestr(portalTime), datestr(actualTime));
