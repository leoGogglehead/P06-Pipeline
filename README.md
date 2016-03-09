# P06-Pipeline
# Power Spectral Analysis for Parkinson's Disease Patient Polysomnograms

This repository contains programs to perform Power Spectral Analysis on 65 Parkinson's Disease Patients' polysomnograms provided by Dr. Lama Chahine.

# Methods
1/ channelReference - references frontal, central and occipital recording electrodes to reference channels A1 and A2
2/ UploadAnnot - upload sleep stage annotations (NREM1-3, REM, Wake, Arousal, Bad data, etc...) on to the portal at IEEG
3/ getsortEndTime - This script gets the end time for all NREM, wake and REM annotations for each patient
4/ analyzeDataOnPortal - main calling function
5/ f_eventDetection - user-specified start-stop time function to analyze specified events on specified datasets, also creates line plots
6/ f_sleepPowerBands - create power spectral density estimate for different frequency bands from delta to gamma and also calculates the slow-fast ratio
7/ f_progressPlot - create plots for progression of the slow:fast ratio ( defined as (delta+theta)/(alpha+beta1+beta2+sigma+gamma)) for a user-specified type of annotation(NREM/REM/Wake) over the whole recording.
8/ f_epochPlot - create plots to compare 2 different epochs of the same type of annotation for one patient
