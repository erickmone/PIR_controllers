%% ================================================================
%  Experimental Case I
%% ================================================================

close all;
clearvars;
clc;

%% ========================= Files =================================

voltageFiles = { ...
    'ExperimentalCaseI_Voltage_PIRm1250.csv', ...
    'ExperimentalCaseI_Voltage_PIRm1500.csv', ...
    'ExperimentalCaseI_Voltage_PIRm2000.csv', ...
    'ExperimentalCaseI_Voltage_fPID1000.csv'};

controlFile = 'ExperimentalCaseI_Control_All.csv';

voltageFigureFile = 'ExperimentalCaseI_OutputVoltage.pdf';
controlFigureFile = 'ExperimentalCaseI_DutyCycle.pdf';

for f = [voltageFiles,{controlFile}]
    if ~isfile(f{1})
        error('The following file was not found: %s',f{1});
    end
end

%% ===================== Figure configuration =======================

W = 3.50;
H = 1.70;

comparisonWindow = [-0.002 0.060];
comparisonTicks  = 0:0.01:0.06;

maximumPlotPoints = 3000;

referenceVoltage  = 24;
settlingTolerance = 0.02;
riseLimits        = [0.10 0.90];
finalWindowFraction = 0.10;

set(groot,'defaultTextInterpreter','latex');
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');

%% ================== Controllers (plot order) ======================
%  1: PIR -1250, 2: PIR -1500, 3: PIR -2000, 4: Filtered PID -1000

controllerNames = [ ...
    "Modified PIR, s0=-1250";
    "Modified PIR, s0=-1500";
    "Modified PIR, s0=-2000";
    "Filtered PID, s0=-1000"];

legendNames = { ...
    'Modified PIR @ $s_0=-1250$', ...
    'Modified PIR @ $s_0=-1500$', ...
    'Modified PIR @ $s_0=-2000$', ...
    'Filtered PID @ $s_0=-1000$'};

colors = [ ...
    0.0000 0.4470 0.7410;
    0.8500 0.3250 0.0980;
    0.9290 0.6940 0.1250;
    0.4940 0.1840 0.5560];

% Validated temporal shifts
shifts = [0.00199 0.00303 0.00502 0];

nC = numel(voltageFiles);

%% ================================================================
%  PART A: OUTPUT-VOLTAGE DATA
%% ================================================================

D = cell(nC,1);

for k = 1:nC
    D{k} = readTwoColumnFile(voltageFiles{k});
    D{k}(:,1) = D{k}(:,1)-shifts(k);
end

% Common time origin (from the filtered PID step)
tOriginVoltage = detectStepOnset(D{4}(:,1),D{4}(:,2));

for k = 1:nC
    D{k}(:,1) = D{k}(:,1)-tOriginVoltage;

    metricsV(k) = calculateVoltageMetrics(D{k}(:,1),D{k}(:,2), ...
        referenceVoltage,settlingTolerance,riseLimits, ...
        finalWindowFraction); %#ok<SAGROW>
end

voltagePerformanceTable = table( ...
    controllerNames, ...
    1e3*[metricsV.RiseTime]', ...
    1e3*[metricsV.SettlingTime]', ...
    [metricsV.Overshoot]', ...
    [metricsV.Undershoot]', ...
    [metricsV.SteadyStateError]', ...
    [metricsV.MinimumVoltage]', ...
    [metricsV.MaximumVoltage]', ...
    [metricsV.RipplePeakToPeak]', ...
    [metricsV.IAE]', ...
    'VariableNames',{ ...
        'Controller','RiseTime_ms','SettlingTime_2pct_ms', ...
        'Mp_percent','Mu_percent','ess_V','vmin_V','vmax_V', ...
        'Ripple_pp_V','IAE_Vs'});

fprintf('\n============================================================\n');
fprintf('OUTPUT-VOLTAGE PERFORMANCE METRICS\n');
fprintf('============================================================\n');
disp(voltagePerformanceTable);

%% ====================== Voltage figure ============================

[figVoltage,axVoltage] = createArticleFigure(W,H);

for k = 1:nC
    plotReduced(axVoltage,D{k}(:,1),D{k}(:,2),maximumPlotPoints, ...
        colors(k,:),legendNames{k});
end

yline(axVoltage,referenceVoltage,'--', ...
    'Color',[0.85 0.20 0.20],'LineWidth',0.9, ...
    'HandleVisibility','off');

text(axVoltage,0.78,0.89,'Reference', ...
    'Units','normalized','Interpreter','latex','FontSize',8, ...
    'HorizontalAlignment','left','VerticalAlignment','bottom', ...
    'Clipping','on');

xlabel(axVoltage,'Time [s]');
ylabel(axVoltage,'$v_o(t)$ [V]');

xlim(axVoltage,comparisonWindow);
ylim(axVoltage,[10 26.5]);
xticks(axVoltage,comparisonTicks);

legend(axVoltage,'Location','southeast','FontSize',6,'Box','on');

exportgraphics(figVoltage,voltageFigureFile, ...
    'ContentType','vector','BackgroundColor','white');

%% ================================================================
%  PART B: CONTROL-SIGNAL DATA
%% ================================================================

T = readtable(controlFile,'VariableNamingRule','preserve');

if width(T) < 5
    error(['The control CSV must contain five columns: ', ...
        'time, filtered PID, PIR -1250, PIR -1500, and PIR -2000.']);
end

X = T{:,1:5};
X = sortrows(X(all(isfinite(X),2),:),1);

tControl = X(:,1);
U        = X(:,[3 4 5 2]);      % PIR -1250, -1500, -2000, PID

%% ====================== Control metrics ===========================

for k = 1:nC
    metricsU(k) = calculateControlMetrics(tControl,U(:,k), ...
        settlingTolerance,finalWindowFraction); %#ok<SAGROW>
end

controlPerformanceTable = table( ...
    controllerNames, ...
    [metricsU.InitialValue]', ...
    [metricsU.FinalValue]', ...
    [metricsU.MinimumValue]', ...
    [metricsU.MaximumValue]', ...
    [metricsU.PeakExcursion]', ...
    [metricsU.RMS]', ...
    [metricsU.RipplePeakToPeak]', ...
    [metricsU.TotalVariation]', ...
    1e3*[metricsU.SettlingTime]', ...
    'VariableNames',{ ...
        'Controller','d_initial','d_final','d_min','d_max', ...
        'PeakExcursion','d_RMS','Ripple_pp','TotalVariation', ...
        'SettlingTime_2pct_ms'});

fprintf('\n============================================================\n');
fprintf('DUTY-CYCLE PERFORMANCE METRICS\n');
fprintf('Control traces\n');
fprintf('============================================================\n');
disp(controlPerformanceTable);

%% ====================== Control figure ============================

[figControl,axControl] = createArticleFigure(W,H);

for k = 1:nC
    plotReduced(axControl,tControl,U(:,k),inf,colors(k,:), ...
        legendNames{k});
end

xlabel(axControl,'Time [s]');
ylabel(axControl,'$d(t)$');

xlim(axControl,comparisonWindow);
ylim(axControl,[0.0 0.55]);
xticks(axControl,comparisonTicks);

legend(axControl,'Location','southeast','FontSize',6,'Box','on');

exportgraphics(figControl,controlFigureFile, ...
    'ContentType','vector','BackgroundColor','white');

fprintf('\nGenerated figures:\n');
fprintf('  %s\n',voltageFigureFile);
fprintf('  %s\n',controlFigureFile);
fprintf('\nNo CSV data files were generated.\n');

%% ================================================================
%  LOCAL FUNCTIONS
%% ================================================================

function data = readTwoColumnFile(fileName)

    data = readmatrix(fileName);

    if size(data,2) < 2
        error('The file %s must contain at least two columns.',fileName);
    end

    data = data(:,1:2);
    data = data(all(isfinite(data),2),:);

    if isempty(data)
        error('No valid numeric data were found in %s.',fileName);
    end

    data = sortrows(data,1);

end

function t0 = detectStepOnset(t,y)

    t = t(:);
    y = y(:);

    n = numel(y);
    ySmooth = movmean(y,max(5,round(0.002*n)));

    nEdge = min(max(20,round(0.10*n)),n);

    yInitial = median(ySmooth(1:nEdge));
    yFinal   = median(ySmooth(end-nEdge+1:end));

    amplitude = yFinal-yInitial;

    if abs(amplitude) < eps
        t0 = t(1);
        return;
    end

    threshold = yInitial+0.05*amplitude;

    if amplitude > 0
        onsetIndex = find(ySmooth >= threshold,1,'first');
    else
        onsetIndex = find(ySmooth <= threshold,1,'first');
    end

    if isempty(onsetIndex)
        t0 = t(1);
    else
        t0 = t(onsetIndex);
    end

end

function [tPost,yPost,initialValue] = splitAtStep(t,y)
% Removes invalid samples, estimates the pre-step value and returns
% the post-step (t >= 0) portion of the signal.

    t = t(:);
    y = y(:);

    valid = isfinite(t) & isfinite(y);
    t = t(valid);
    y = y(valid);

    preStep = t < 0;

    if nnz(preStep) >= 3
        initialValue = median(y(preStep));
    else
        initialValue = median(y(1:max(3,round(0.05*numel(y)))));
    end

    postStep = t >= 0;
    tPost = t(postStep);
    yPost = y(postStep);

    if numel(tPost) < 3
        error('Insufficient post-transition samples for metrics.');
    end

end

function settlingTime = settlingTimeFrom(tPost,outsideBand)

    lastOutside = find(outsideBand,1,'last');

    if isempty(lastOutside)
        settlingTime = 0;
    elseif lastOutside >= numel(tPost)
        settlingTime = NaN;
    else
        settlingTime = tPost(lastOutside+1);
    end

end

function metrics = calculateVoltageMetrics( ...
    t,y,referenceValue,settlingTolerance,riseLimits, ...
    finalWindowFraction)

    [tPost,yPost,initialValue] = splitAtStep(t,y);

    transitionAmplitude = referenceValue-initialValue;

    if abs(transitionAmplitude) <= eps
        error('The output-voltage transition amplitude is zero.');
    end

    normalizedOutput = (yPost-initialValue)/transitionAmplitude;

    t10 = firstCrossingTime(tPost,normalizedOutput,riseLimits(1));
    t90 = firstCrossingTime(tPost,normalizedOutput,riseLimits(2));

    riseTime = NaN;
    if isfinite(t10) && isfinite(t90) && t90 >= t10
        riseTime = t90-t10;
    end

    settlingTime = settlingTimeFrom(tPost, ...
        abs(yPost-referenceValue) > ...
        settlingTolerance*abs(transitionAmplitude));

    numberFinal = max(3,round(finalWindowFraction*numel(yPost)));
    yFinal = yPost(end-numberFinal+1:end);

    metrics = struct( ...
        'RiseTime',riseTime, ...
        'SettlingTime',settlingTime, ...
        'Overshoot',100*max(0,max(normalizedOutput)-1), ...
        'Undershoot',100*max(0,-min(normalizedOutput)), ...
        'SteadyStateError',abs(referenceValue-median(yFinal)), ...
        'MinimumVoltage',min(yPost), ...
        'MaximumVoltage',max(yPost), ...
        'RipplePeakToPeak',max(yFinal)-min(yFinal), ...
        'IAE',trapz(tPost,abs(referenceValue-yPost)), ...
        'InitialValue',initialValue, ...
        'FinalValue',median(yFinal));

end

function metrics = calculateControlMetrics( ...
    t,u,settlingTolerance,finalWindowFraction)

    [tPost,uPost,initialValue] = splitAtStep(t,u);

    numberFinal = max(3,round(finalWindowFraction*numel(uPost)));
    uFinal = uPost(end-numberFinal+1:end);

    finalValue    = median(uFinal);
    controlChange = finalValue-initialValue;

    settlingTime = settlingTimeFrom(tPost, ...
        abs(uPost-finalValue) > ...
        settlingTolerance*max(abs(controlChange),eps));

    metrics = struct( ...
        'InitialValue',initialValue, ...
        'FinalValue',finalValue, ...
        'MinimumValue',min(uPost), ...
        'MaximumValue',max(uPost), ...
        'PeakExcursion',max(abs(uPost-initialValue)), ...
        'RMS',sqrt(mean(uPost.^2)), ...
        'RipplePeakToPeak',max(uFinal)-min(uFinal), ...
        'TotalVariation',sum(abs(diff(uPost))), ...
        'SettlingTime',settlingTime);

end

function crossingTime = firstCrossingTime(t,y,level)

    i = find(y >= level,1,'first');

    if isempty(i)
        crossingTime = NaN;
    elseif i == 1
        crossingTime = t(1);
    elseif abs(y(i)-y(i-1)) <= eps
        crossingTime = t(i);
    else
        crossingTime = t(i-1)+(level-y(i-1))*(t(i)-t(i-1)) ...
            /(y(i)-y(i-1));
    end

end

function plotReduced( ...
    ax,t,y,maximumPlotPoints,lineColor,displayName)
% maximumPlotPoints = inf plots every sample.

    valid = isfinite(t(:)) & isfinite(y(:));
    t = t(valid);
    y = y(valid);

    n = numel(t);

    if n > maximumPlotPoints
        idx = unique(round(linspace(1,n,maximumPlotPoints)));
    else
        idx = 1:n;
    end

    plot(ax,t(idx),y(idx), ...
        'LineWidth',1.0,'Color',lineColor,'DisplayName',displayName);

end

function [fig,ax] = createArticleFigure(W,H)

    fig = figure('Units','inches','Position',[0 0 W H], ...
        'Color','white');

    set(fig,'PaperUnits','inches','PaperSize',[W H], ...
        'PaperPosition',[0 0 W H]);

    ax = axes(fig);
    hold(ax,'on');
    box(ax,'on');
    grid(ax,'on');

    applyArticleStyle(ax);

end

function applyArticleStyle(ax)

    set(ax,'FontSize',8,'LineWidth',0.75,'TickDir','out');

    ax.XGrid = 'on';
    ax.YGrid = 'on';

    ax.GridLineStyle = '--';
    ax.MinorGridLineStyle = '--';

    ax.GridColor = [0.60 0.60 0.60];
    ax.MinorGridColor = [0.75 0.75 0.75];

    ax.GridAlpha = 0.35;
    ax.MinorGridAlpha = 0.25;

    ax.Layer = 'top';

end