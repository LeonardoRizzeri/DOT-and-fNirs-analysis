%% Diffuse Optical Tomography and fNIRS analysis
close all; clear; clc;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
codeDir = fullfile(projectRoot, 'code');
dataDir = fullfile(projectRoot, 'data');
modelDir = fullfile(projectRoot, 'models', 'MNI152_headModel');
externalDir = fullfile(projectRoot, 'external');

addpath(codeDir);
if exist(externalDir, 'dir')
    addpath(genpath(externalDir));
end

%% EXERCISE 1
% Compare DOT reconstructed images obtained with and without short-separation (SS) channel regression
load(fullfile(modelDir,'HeadVolumeMesh.mat'))
load(fullfile(modelDir,'GMSurfaceMesh.mat'))
load(fullfile(modelDir,'ScalpSurfaceMesh.mat'))

% Load 10-5 coordinates and landmark positions for anatomical reference
fid = fopen(fullfile(modelDir,'10-5_Points.txt'),'r');
tmp = textscan(fid,'%s %f %f %f','CollectOutput',1);
fclose(fid);
tenFive = tmp{2};
tenFiveLabel = tmp{1};

fid = fopen(fullfile(modelDir,'LandmarkPoints.txt'),'r');
tmp = textscan(fid,'%s %f %f %f','CollectOutput',1);
fclose(fid);
cranialL = tmp{2};
cranialLLabel = tmp{1};

%% Load NIRS data
load(fullfile(dataDir,'CCW1.nirs'),'-mat'); % load nirs data
load(fullfile(dataDir,'CCW.jac'),'-mat');   % load Jacobian
load(fullfile(dataDir,'vol2gm.mat'))
% SD.MeasList contains 2*nCh rows: the first half corresponds to Wavelength 1 
% and the second half corresponds to Wavelength 2
measList1 = SD.MeasList(SD.MeasList(:,4) == 1, :);
nCh = length(measList1(:,1));

%% 1) Plot the 3D array configuration (sources, detectors and channels).
figure;
plotmesh(ScalpSurfaceMesh.node, ScalpSurfaceMesh.face, 'FaceColor', [0.85 0.75 0.65], 'FaceAlpha', 0.4);
h = findobj(gca,'Type','patch');
set(h,'EdgeColor','k')
hold on;
plot3(SD.SrcPos(:,1), SD.SrcPos(:,2), SD.SrcPos(:,3), ...
'.r', 'MarkerSize', 20, 'DisplayName', 'Sources');
plot3(SD.DetPos(:,1), SD.DetPos(:,2), SD.DetPos(:,3), ...
'.b', 'MarkerSize', 20, 'DisplayName', 'Detectors');

for iCh = 1:nCh
    src = SD.SrcPos(measList1(iCh, 1), :);
    det = SD.DetPos(measList1(iCh, 2), :);
    plot3([src(1) det(1)], [src(2) det(2)], [src(3) det(3)], 'g', ...
    'HandleVisibility', 'off');
end

% Add one green line for the legend
plot3(nan, nan, nan, 'g', 'DisplayName', 'Channels');
legend('Location', 'best');
xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]');
title('3D Array Configuration - All Channels');
grid on; 

%% 2) Compute the source-detector distance for each channel and plot all distances with a histogram.
% SD.MeasList defines the channels:
% Column 1 = source index
% Column 2 = detector index
% Column 3 = measurement type
% Column 4 = wavelength index
distCh = zeros(nCh, 1);
for iCh = 1:nCh
    src = SD.SrcPos(measList1(iCh, 1), :);
    det = SD.DetPos(measList1(iCh, 2), :);
    distCh(iCh) = sqrt(sum((src - det).^2));
end

figure('Name', 'Step 2: Source-Detector Distance Histogram');
histogram(distCh, 30, 'FaceColor', [0.3 0.6 0.9]);
xlabel('Source-Detector Distance [mm]');
ylabel('Number of Channels');
title('Distribution of Source-Detector Distances');
grid on;

%% 3) Identify bad channels as those channels with signal-to-noise ratio lower than 20

SNRrange = 20;
remCh = removeNoisyChannels(d,  SNRrange);
remCh = remCh(:);
% Make remCh coherent with SD.MeasListAct.
% If removeNoisyChannels returns one value per physical channel, replicate it for both wavelengths.
if length(remCh) == nCh
    SD.MeasListAct = [remCh; remCh];
elseif length(remCh) == size(SD.MeasList,1)
    SD.MeasListAct = remCh;
else
    error('Unexpected length of remCh. Check removeNoisyChannels output.');
end
fprintf('Total channels in SD.MeasListAct: %d\n', length(SD.MeasListAct));
fprintf('Good channels (SNR >= 20): %d\n', sum(SD.MeasListAct == 1));
fprintf('Bad channels (SNR < 20): %d\n', sum(SD.MeasListAct == 0));

% A physical channel is considered valid only if it passes the SNR threshold for both wavelengths
actWL1 = SD.MeasListAct(SD.MeasList(:,4) == 1);
actWL2 = SD.MeasListAct(SD.MeasList(:,4) == 2);
if length(actWL2) == nCh
    actCh = actWL1 & actWL2;
else
    actCh = actWL1;
end
fprintf('Physical channels valid for both wavelengths: %d\n', sum(actCh == 1));
fprintf('Physical channels rejected: %d\n', sum(actCh == 0));

% Update the global SD structure before passing it to subsequent functions
SD.MeasListAct = [actCh; actCh];

%% --- Figure 3a: all channels, bad ones highlighted in red ---
figure('Name', 'Step 3a: Bad Channels Highlighted');
plotmesh(ScalpSurfaceMesh.node, ScalpSurfaceMesh.face, ...
'FaceColor', [0.85 0.75 0.65], 'FaceAlpha', 0.25, 'EdgeColor', 'none','HandleVisibility', 'off');
hold on;

plot3(SD.SrcPos(:,1), SD.SrcPos(:,2), SD.SrcPos(:,3), ...
'.r', 'MarkerSize', 20, 'DisplayName', 'Sources');
plot3(SD.DetPos(:,1), SD.DetPos(:,2), SD.DetPos(:,3), ...
'.b', 'MarkerSize', 20, 'DisplayName', 'Detectors');
plot3(nan, nan, nan, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Good channels');
plot3(nan, nan, nan, 'r-', 'LineWidth', 0.5, 'DisplayName', 'Bad channels (SNR < 20)');

for ch = 1:nCh
    src = measList1(ch,1);
    det = measList1(ch,2);
    srcPos = SD.SrcPos(src,:);
    detPos = SD.DetPos(det,:);
    if actCh(ch) == 1
        % Good channel
        plot3([srcPos(1) detPos(1)], ...
          [srcPos(2) detPos(2)], ...
          [srcPos(3) detPos(3)], ...
          'g-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
    else
        % Bad channel
        plot3([srcPos(1) detPos(1)], ...
          [srcPos(2) detPos(2)], ...
          [srcPos(3) detPos(3)], ...
          'r-', 'LineWidth', 0.5, 'HandleVisibility', 'off');
    end
end
lighting gouraud; camlight;
legend('Location', 'best');
xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]');
title('3D Array — Bad Channels Highlighted (SNR < 20)');

%% --- Figure 3b: good channels only ---
figure('Name', 'Step 3b: Good Channels Only');
plotmesh(ScalpSurfaceMesh.node, ScalpSurfaceMesh.face, ...
'FaceColor', [0.85 0.75 0.65], 'FaceAlpha', 0.25, 'EdgeColor', 'none', 'HandleVisibility', 'off');
hold on;
plot3(SD.SrcPos(:,1), SD.SrcPos(:,2), SD.SrcPos(:,3), ...
 '.r', 'MarkerSize', 22, 'DisplayName', 'Sources');
plot3(SD.DetPos(:,1), SD.DetPos(:,2), SD.DetPos(:,3), ...
 '.b', 'MarkerSize', 22, 'DisplayName', 'Detectors');
plot3(nan, nan, nan, 'g-', 'LineWidth', 1.5, 'DisplayName', 'Good channels');

for ch = 1:nCh
 if actCh(ch) == 1
     src = measList1(ch,1);
     det = measList1(ch,2);
     srcPos = SD.SrcPos(src,:);
     detPos = SD.DetPos(det,:);
     plot3([srcPos(1) detPos(1)], ...
           [srcPos(2) detPos(2)], ...
           [srcPos(3) detPos(3)], ...
           'g-', 'LineWidth', 1.5, 'HandleVisibility', 'off');
 end
end
lighting gouraud; camlight;
legend('Location', 'best', 'FontSize', 16);
xlabel('x [mm]'); ylabel('y [mm]'); zlabel('z [mm]');
title('3D Array — Good Channels Only');

%% 4) Pre-Processing
% 4a. Conversion to Optical Density
meanValue = mean(d);
dodConv = -log(abs(d)./meanValue);

% 4b. Wavelet motion correction
iqr = 0.5;
dodWavelet = hmrMotionCorrectWavelet(dodConv, SD, iqr);

% 4c. Band-pass filter: 0.01 - 2.5 Hz
lowerCutOff  = 0.01;
higherCutOff = 2.5;
fs = 1 / (t(2) - t(1));
dodfilt = hmrBandpassFilt(dodWavelet, fs, lowerCutOff, higherCutOff);

% 4d. Conversion to concentration changes
% DPF: 6.24 for lambda1, 5.18 for lambda2
DPF = [6.24, 5.18];
dc = hmrOD2Conc(dodfilt, SD, DPF);
% dc dimensions: nTime x 2 chromophores x nChannels

%% 5) Hemodynamic Response Function (HRF) Estimation via General Linear Model (GLM)
tRange = [-2 36];
sRange = fix(tRange*fs);
idxBasis = 1;             % Gaussian basis functions
paramsBasis = [2 2];      % step = 2 s, width = 2 s
driftOrder = 0;
glmSolveMethod = 2;       % correcting for serial correlation
flagMotionCorrect = 0;    % no additional motion correction inside GLM

rhoSD_ssThresh = 15;      % threshold for SS channels in mm
rhoSD_ssThresh_noSS = 0;  % no SS regression
flagSSmethod = 1;         % choose SS channel with highest correlation

[yavg_SS, ystd_SS, tHRF_SS, nTrials_SS, ynew_SS, yresid_SS, ysum2_SS, beta_SS, yR_SS] = ...
 hmrDeconvHRF_DriftSS(dc, s, t, SD, [], [], tRange, glmSolveMethod, ...
 idxBasis, paramsBasis, rhoSD_ssThresh, flagSSmethod, driftOrder, flagMotionCorrect);

[yavg_noSS, ystd_noSS, tHRF_noSS, nTrials_noSS, ynew_noSS, yresid_noSS, ysum2_noSS, beta_noSS, yR_noSS] = ...
 hmrDeconvHRF_DriftSS(dc, s, t, SD, [], [], tRange, glmSolveMethod, ...
 idxBasis, paramsBasis, rhoSD_ssThresh_noSS, flagSSmethod, driftOrder, flagMotionCorrect);
% yavg: average hemodynamic response in concentration changes

%--- Inverse Conversion: Concentration HRFs back to Optical Density ---
% The inverse problem mathematically requires input parameters expressed as 
% average OD variations rather than concentration changes. [cite: 341]
% The conversion is executed independently for each experimental condition
nCond = size(s,2);
nFrames = size(yavg_SS,1);
nMeas = size(SD.MeasList,1);
dodAvg_SS = zeros(nFrames, nMeas, nCond);
dodAvg_noSS = zeros(nFrames, nMeas, nCond);

for iCond = 1:nCond
    dodAvg_SS(:,:,iCond) = hmrConc2OD(squeeze(yavg_SS(:,:,:,iCond)), SD, DPF);
    dodAvg_noSS(:,:,iCond) = hmrConc2OD(squeeze(yavg_noSS(:,:,:,iCond)), SD, DPF);
end

%% 6) Display the whole array sensitivity for the first wavelength on the volumetric GM mesh 
% -------------------------------------------------------------------------
% GRAPH 1: SENSITIVITY MAP USING ALL CHANNELS
% -------------------------------------------------------------------------
figure('Name', 'Sensitivity Map - All Channels');

% Compute the cumulative volumetric sensitivity correctly (from attached file)
sens_vol_all = sum(abs(J{1}.vol), 1)';

% Assign to volumetric nodes and plot using the GM tissue elements (from pasted code)
HeadVolumeMesh.node(:,4) = sens_vol_all;
plotmesh(HeadVolumeMesh.node, HeadVolumeMesh.elem(HeadVolumeMesh.elem(:,5)==4,1:4))

colormap(turbo) 
h = findobj(gca, 'Type', 'patch');
set(h, 'EdgeColor', 'k', 'LineWidth', 0.01) 
colorbar 
axis equal; lighting gouraud; camlight;        
title('Sensitivity Map on Volumetric GM - All Channels (\lambda_1)');

% =========================================================================
% GRAPH 2: SENSITIVITY MAP USING GOOD CHANNELS ONLY
% =========================================================================
figure('Name', 'Sensitivity Map - Good Channels Only');

idxWL1 = SD.MeasList(:,4) == 1;
goodWL1 = SD.MeasListAct(idxWL1) == 1;

% Compute sensitivity restricted only to the valid channels
sens_vol_good = sum(abs(J{1}.vol(goodWL1,:)), 1)';

% Update volumetric nodes
HeadVolumeMesh.node(:,4) = sens_vol_good;
plotmesh(HeadVolumeMesh.node, HeadVolumeMesh.elem(HeadVolumeMesh.elem(:,5)==4,1:4))

colormap(turbo)
h = findobj(gca, 'Type', 'patch');
set(h, 'EdgeColor', 'k', 'LineWidth', 0.01)
colorbar
axis equal; lighting gouraud; camlight;
title('Sensitivity Map on Volumetric GM - Good Channels Only (\lambda_1)');

%% 7) Reconstruct HbO and HbR images for condition 2 mapped to the surface GM mesh
% Remove bad channels from Jacobian
for i = 1:length(SD.Lambda)
    tmp = J{i}.vol;
    JCropped{i} = tmp(SD.MeasListAct(SD.MeasList(:,4)==i)==1,:);
end

% Compute inverse of Jacobian
lambda1 = 0.1;
invJ = cell(length(SD.Lambda),1);
for i = 1:length(SD.Lambda)
    Jtmp = JCropped{i};
    JJT = Jtmp*Jtmp';
    S = svd(JJT);
    invJ{i} = Jtmp'/(JJT + eye(length(JJT))*(lambda1*max(S)));
end

% Data to reconstruct are optical density changes compared to baseline.
% Since the baseline is 0 post-GLM estimation, we define datarecon = -dodAvg.
datarecon_SS = -dodAvg_SS;
datarecon_noSS = -dodAvg_noSS;
nNodeVol = size(HeadVolumeMesh.node,1);
nNodeGM = size(GMSurfaceMesh.node,1);
nFrames = size(datarecon_SS,1);
wavelengths = SD.Lambda;
nWavs = length(SD.Lambda);

% Initialize final results matrices
hbo.vol_SS = zeros(nFrames,nNodeVol);
hbr.vol_SS = zeros(nFrames,nNodeVol);
hbo.gm_SS = zeros(nFrames,nNodeGM);
hbr.gm_SS = zeros(nFrames,nNodeGM);
hbo.vol_noSS = zeros(nFrames,nNodeVol);
hbr.vol_noSS = zeros(nFrames,nNodeVol);
hbo.gm_noSS = zeros(nFrames,nNodeGM);
hbr.gm_noSS = zeros(nFrames,nNodeGM);

% Obtain specific absorption coefficients
Eall = [];
for i = 1:nWavs
    Etmp = GetExtinctions(wavelengths(i));
    Etmp = Etmp(1:2);       % HbO and HbR only
    Eall = [Eall; Etmp./1e7];
end
Eallinv = pinv(Eall);

%% Image Reconstruction WITH Short-Separation (SS) Regression
cond = 2; % condition 2 = checkerboard rotating counterclockwise
for frame = 1:nFrames
    muaImageAll_SS = zeros(nWavs,nNodeVol);
    for wav = 1:nWavs
        dataTmp_SS = squeeze(datarecon_SS(frame, SD.MeasList(:,4)==wav & SD.MeasListAct==1, cond));
        dataTmp_SS = dataTmp_SS(:);
        invJtmp = invJ{wav};
        tmp_SS = invJtmp * dataTmp_SS;
        muaImageAll_SS(wav,:) = tmp_SS';
    end

    % Convert absorption changes to concentration changes
    tmp_SS = Eallinv * muaImageAll_SS;
    hbo_tmpVol_SS = tmp_SS(1,:);
    hbr_tmpVol_SS = tmp_SS(2,:);

    % Map to GM surface mesh
    hbo_tmpGM_SS = vol2gm*hbo_tmpVol_SS';
    hbr_tmpGM_SS = vol2gm*hbr_tmpVol_SS';

    % Book-keeping and saving
    hbo.vol_SS(frame,:) = hbo_tmpVol_SS;
    hbr.vol_SS(frame,:) = hbr_tmpVol_SS;
    hbo.gm_SS(frame,:) = hbo_tmpGM_SS;
    hbr.gm_SS(frame,:) = hbr_tmpGM_SS;
end

%% Image Reconstruction WITHOUT Short-Separation (SS) Regression
for frame = 1:nFrames
    muaImageAll_noSS = zeros(nWavs,nNodeVol);
    for wav = 1:nWavs
        dataTmp_noSS = squeeze(datarecon_noSS(frame, SD.MeasList(:,4)==wav & SD.MeasListAct==1, cond));
        dataTmp_noSS = dataTmp_noSS(:);
        invJtmp = invJ{wav};
        tmp_noSS = invJtmp * dataTmp_noSS;
        muaImageAll_noSS(wav,:) = tmp_noSS';
    end

    % Convert absorption changes to concentration changes
    tmp_noSS = Eallinv * muaImageAll_noSS;
    hbo_tmpVol_noSS = tmp_noSS(1,:);
    hbr_tmpVol_noSS = tmp_noSS(2,:);

    % Map to GM surface mesh
    hbo_tmpGM_noSS = vol2gm*hbo_tmpVol_noSS';
    hbr_tmpGM_noSS = vol2gm*hbr_tmpVol_noSS';

    % Book-keeping and saving
    hbo.vol_noSS(frame,:) = hbo_tmpVol_noSS;
    hbr.vol_noSS(frame,:) = hbr_tmpVol_noSS;
    hbo.gm_noSS(frame,:) = hbo_tmpGM_noSS;
    hbr.gm_noSS(frame,:) = hbr_tmpGM_noSS;
end

%% Plot Reconstructed Images at Target Time Points t = [0, 10, 15, 20]
greyJetPath = fullfile(projectRoot, 'assets', 'greyJet.mat');
if exist(greyJetPath, 'file')
    load(greyJetPath, 'greyJet')
else
    greyJet = jet(256);
end
tRecon = [0, 10, 15, 20];

for ist = 1:length(tRecon)
    [~, sRecon_SS] = min(abs(tHRF_SS - tRecon(ist)));
    [~, sRecon_noSS] = min(abs(tHRF_noSS - tRecon(ist)));
    
    GMSurfaceMesh_HbO_SS = GMSurfaceMesh;
    GMSurfaceMesh_HbR_SS = GMSurfaceMesh;
    GMSurfaceMesh_HbO_noSS = GMSurfaceMesh;
    GMSurfaceMesh_HbR_noSS = GMSurfaceMesh;
    
    GMSurfaceMesh_HbO_SS.node(:,4) = hbo.gm_SS(sRecon_SS,:);
    GMSurfaceMesh_HbR_SS.node(:,4) = hbr.gm_SS(sRecon_SS,:);
    GMSurfaceMesh_HbO_noSS.node(:,4) = hbo.gm_noSS(sRecon_noSS,:);
    GMSurfaceMesh_HbR_noSS.node(:,4) = hbr.gm_noSS(sRecon_noSS,:);
    
    figure('Position', [100, 100, 1400, 500], 'Color', 'w'); 
    
    % --- 1) HbO WITH Short-Separation regression ---
    subplot(1,4,1) 
    plotmesh(GMSurfaceMesh_HbO_SS.node, GMSurfaceMesh.face(:,1:3))
    h = findobj(gca,'Type','patch');
    set(h,'EdgeColor','none'); % Mantiene la tua impostazione originale della mesh
    clim([-0.05 0.05]); colormap(greyJet);
    axis equal; axis off; view([30 15]); lighting gouraud; camlight;
    title('HbO with SS regression', 'FontSize', 11)
    
    % --- 2) HbR WITH Short-Separation regression ---
    subplot(1,4,2) 
    plotmesh(GMSurfaceMesh_HbR_SS.node, GMSurfaceMesh.face(:,1:3))
    h = findobj(gca,'Type','patch');
    set(h,'EdgeColor','none');
    clim([-0.05 0.05]); colormap(greyJet);
    axis equal; axis off; view([30 15]); lighting gouraud; camlight;
    title('HbR with SS regression', 'FontSize', 11)
    
    % --- 3) HbO WITHOUT Short-Separation regression ---
    subplot(1,4,3) 
    plotmesh(GMSurfaceMesh_HbO_noSS.node, GMSurfaceMesh.face(:,1:3)) 
    h = findobj(gca,'Type','patch');
    set(h,'EdgeColor','none');
    clim([-0.05 0.05]); colormap(greyJet);
    axis equal; axis off; view([30 15]); lighting gouraud; camlight;
    title('HbO without SS regression', 'FontSize', 11)
    
    % --- 4) HbR WITHOUT Short-Separation regression ---
    subplot(1,4,4) 
    plotmesh(GMSurfaceMesh_HbR_noSS.node, GMSurfaceMesh.face(:,1:3))
    h = findobj(gca,'Type','patch');
    set(h,'EdgeColor','none');
    clim([-0.05 0.05]); colormap(greyJet);
    axis equal; axis off; view([30 15]); lighting gouraud; camlight;
    title('HbR without SS regression', 'FontSize', 11)
    
    cb = colorbar('Position', [0.38, 0.12, 0.26, 0.03], 'Orientation', 'horizontal');
    ylabel(cb, '\Delta Conc. [M\cdot mm]', 'FontSize', 9, 'VerticalAlignment', 'top'); 
    
    sgtitle(sprintf('DOT reconstruction - Condition 2 - t = %d s', tRecon(ist)), 'FontSize', 14, 'FontWeight', 'bold')
end

%%
fprintf('\n--- Spatial correlation between SS and noSS maps ---\n')
for i = 1:length(tRecon)
   [~, idx] = min(abs(tHRF_SS - tRecon(i)));
   r_HbO = corr(hbo.gm_SS(idx,:)', hbo.gm_noSS(idx,:)', 'Rows', 'complete');
   r_HbR = corr(hbr.gm_SS(idx,:)', hbr.gm_noSS(idx,:)', 'Rows', 'complete');
   fprintf('\nt = %d s\n', tRecon(i));
   fprintf('Spatial corr HbO SS vs noSS: %.3f\n', r_HbO);
   fprintf('Spatial corr HbR SS vs noSS: %.3f\n', r_HbR);
end


