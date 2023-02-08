%%%%%% main Matlab script for reading out free-running multi-echo cardiac raw data from Siemens SOLA 1.5T MRI scanner
%%%%%% with display of physiological data extaracted from Pilot Tone
%%%%%% with 3D radial phyllotaxis trajectory computation
%%%%%% "Motion Resolved Fat-Fraction Mapping with Whole-Heart Free-Running Multi-Echo GRE" by Mackowiak et al. 2023
%%%%%% 18.01.2023 - Adèle L.C. Mackowiak
%%%%%% contact: jbastiaansen.mri@gmail.com

%% Path generation
basedir = '\PublicRepository';
addpath(genpath(fullfile(basedir,'Code_Dependencies')));

%% Load and read raw data
% Location free-running imaging data
VOL = 'V1';
FRdata_file = 'meas_MID00642_FID64709_FRFF_MEGRE_8XC_BW893_FA12_DTE2P05_MONO_22x1000';
FRdata_path = fullfile(basedir, VOL, FRdata_file);

% Read raw data in format [Np x Nlines x 1 x 1 x Ncoil]
% Data is read in order of acquisition with echoes 1 to NTE in succession
[twix_obj, rawData] = fReadSiemensRawData_FreeRunning_MultiEcho_v2021(FRdata_path);

% Clear imaging data from PT data
rawData([1:2,end-1:end],:,:,:) = 0;

% Extract parameters
param.Np     = double(twix_obj.image.NCol);                                         % Number of readout point per spoke
param.Nshot  = double(twix_obj.image.NSeg);                                         % Number of spirals acquired
param.Nseg   = double(twix_obj.image.NLin/param.Nshot/twix_obj.image.NEco);         % Number of segments per spiral
param.Nlines = double(twix_obj.image.NLin);                                         % Number of acquired lines
param.Necho  = double(twix_obj.image.NEco);                                         % Number of echoes
param.Nx     = param.Np/2;                                                                                      
param.Ny     = param.Np/2;
param.Nz     = param.Np/2;

%% Load and display physiological signals
load(fullfile(basedir, VOL, 'PhysioInfo.mat'));

% Raw Pilot Tone signals
step = max(max(PTsignals-repmat(mean(PTsignals,1),size(PTsignals,1),1),[],1),[],2);
figure('Name','Raw PT signals','Position',[0 0 1500 900]);
plot(lines_TimeStamp_s, PTsignals-repmat(mean(PTsignals,1),size(PTsignals,1),1)+repmat(0:step:(size(PTsignals,2)-1)*step,size(PTsignals,1),1));
xlabel('time [s]');
ylabel('amplitude [a.u.]'); 
title(['Raw Pilot Tone Signals - ' num2str(size(PTsignals,2)) ' coils'])

% Extracted respiratory signal
figure('Name','Respiratory signal','Position',[200 200 1600 300])
plot(TimeStamp_ms, respSignal, '-k')
grid on
xlabel('time [ms]')
ylabel('amplitude [a.u.]')
yticks([])

% Extracted cardiac signal and triggers
figure('Name','Cardiac signal','Position',[200 200 1600 300])
plot(lines_TimeStamp_s.*1000, cardSignal , '-k')
hold on
plot(cardTriggers, zeros(length(cardTriggers),1), '*b', 'MarkerSize', 10, 'DisplayName', 'PT triggers')
grid on
xlabel('time [ms]')
ylabel('amplitude [a.u.]')
yticks([])

%% Compute trajectory coordinates
%%% Please cite this reference when using Phylloatxis trajectory:
%%% D. Piccini et al., 2011 https://doi.org/10.1002/mrm.22898 

[kx, ky, kz] = computePhyllotaxis(param.Np, param.Nseg, param.Nshot, true);



