%% Experimental Case I: PR controller, output-voltage response
close all; clearvars; clc;

set(groot,'defaultTextInterpreter','latex', ...
    'defaultAxesTickLabelInterpreter','latex', ...
    'defaultLegendInterpreter','latex');

%% Settings
files  = {'PR2000_seconds.csv','PR2050_seconds.csv','PR2100_seconds.csv'};
s0     = [-2000 -2050 -2100];
names  = "PR, s0=" + string(s0');
labels = "PR @ $s_0=" + string(s0) + "$";

Vref    = 24;
tol     = 0.02;             % settling band (fraction of Vref)
riseLim = [0.10 0.90];
tAvg    = 20e-3;            % moving-average window [s]
finalFrac = 0.10;           % final window for e_ss and ripple
v0 = [];                    % initial voltage [V]; [] -> first sample

W = 3.50;  H = 1.70;
colors = [0.0000 0.4470 0.7410;
          0.8500 0.3250 0.0980;
          0.9290 0.6940 0.1250];

%% Data and metrics
for k = 1:numel(files)
    if ~isfile(files{k})
        error('The following file was not found: %s',files{k});
    end

    d = readmatrix(files{k});
    d = sortrows(d(all(isfinite(d(:,1:2)),2),1:2),1);

    t{k} = d(:,1);                                       %#ok<SAGROW>
    v{k} = d(:,2);                                       %#ok<SAGROW>

    nAvg  = round(tAvg/median(diff(t{k})));
    vf{k} = movmean(v{k},nAvg,'Endpoints','shrink');     %#ok<SAGROW>

    m(k) = prMetrics(t{k},v{k},vf{k},Vref,tol,riseLim,finalFrac,v0); %#ok<SAGROW>
end

prTable = table(names, ...
    [m.RiseTime]', [m.SettlingTime]', [m.Overshoot]', [m.Undershoot]', ...
    [m.SteadyStateError]', [m.MinimumVoltage]', [m.MaximumVoltage]', ...
    [m.RipplePeakToPeak]', [m.IAE]', ...
    'VariableNames',{'Controller','RiseTime_s','SettlingTime_2pct_s', ...
        'Mp_percent','Mu_percent','ess_V','vmin_V','vmax_V', ...
        'Ripple_pp_V','IAE_Vs'});

fprintf('\n============================================================\n');
fprintf('PR CONTROLLER: OUTPUT-VOLTAGE PERFORMANCE METRICS\n');
fprintf('============================================================\n');
disp(prTable);

%% Figure
fig = figure('Units','inches','Position',[0 0 W H],'Color','white');
set(fig,'PaperUnits','inches','PaperSize',[W H],'PaperPosition',[0 0 W H]);

ax = axes(fig);
hold(ax,'on'); box(ax,'on'); grid(ax,'on');
articleStyle(ax);

for k = 1:numel(files)
    plot(ax,t{k},v{k},'LineWidth',1.0,'Color',colors(k,:), ...
        'DisplayName',labels(k));
end

yline(ax,Vref,'--','Color',[0.85 0.20 0.20],'LineWidth',0.9, ...
    'HandleVisibility','off');
text(ax,0.78,0.89,'Reference','Units','normalized','Interpreter','latex', ...
    'FontSize',8,'HorizontalAlignment','left','VerticalAlignment','bottom', ...
    'Clipping','on');

xlabel(ax,'Time [s]');
ylabel(ax,'$v_o(t)$ [V]');
xlim(ax,[0 0.20]);
ylim(ax,[10 28]);
legend(ax,'Location','southeast','FontSize',6,'Box','on');

exportgraphics(fig,'ExperimentalCaseI_PR_OutputVoltage.pdf', ...
    'ContentType','vector','BackgroundColor','white');

%% Local functions
function m = prMetrics(t,v,vf,Vref,tol,riseLim,finalFrac,v0)
    if isempty(v0)
        v0 = v(1);
    end

    yn = (vf-v0)/(Vref-v0);

    tr = crossTime(t,yn,riseLim(2))-crossTime(t,yn,riseLim(1));

    k = find(abs(vf-Vref) > tol*Vref,1,'last');
    if isempty(k)
        ts = 0;
    elseif k >= numel(t)
        ts = NaN;
    else
        ts = t(k+1);
    end

    n = max(3,round(finalFrac*numel(v)));

    m = struct('RiseTime',tr,'SettlingTime',ts, ...
        'Overshoot',100*max(0,max(yn)-1), ...
        'Undershoot',100*max(0,-min(yn)), ...
        'SteadyStateError',abs(Vref-mean(vf(end-n+1:end))), ...
        'MinimumVoltage',min(v),'MaximumVoltage',max(v), ...
        'RipplePeakToPeak',max(v(end-n+1:end))-min(v(end-n+1:end)), ...
        'IAE',trapz(t,abs(Vref-vf)));
end

function tc = crossTime(t,y,level)
    i = find(y >= level,1,'first');
    if isempty(i)
        tc = NaN;
    elseif i == 1
        tc = t(1);
    elseif abs(y(i)-y(i-1)) <= eps
        tc = t(i);
    else
        tc = t(i-1)+(level-y(i-1))*(t(i)-t(i-1))/(y(i)-y(i-1));
    end
end

function articleStyle(ax)
    set(ax,'FontSize',8,'LineWidth',0.75,'TickDir','out');
    ax.XGrid = 'on';  ax.YGrid = 'on';
    ax.GridLineStyle = '--';  ax.MinorGridLineStyle = '--';
    ax.GridColor = [0.60 0.60 0.60];  ax.MinorGridColor = [0.75 0.75 0.75];
    ax.GridAlpha = 0.35;  ax.MinorGridAlpha = 0.25;
    ax.Layer = 'top';
end