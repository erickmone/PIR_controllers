%% Nonideal boost converter vs PLECS: modified PIR controller
%  Operating point, duty-to-output model, PIR tuning, comparison against
%  the PLECS voltage response and time-domain metrics.
%  Only PLECS_comparison.pdf is exported.

close all; clearvars; clc;

set(groot,'defaultTextInterpreter','latex', ...
    'defaultAxesTickLabelInterpreter','latex', ...
    'defaultLegendInterpreter','latex');

%% Settings
Vin = 12;                    % input voltage [V]
Vo  = 42;                    % output reference [V]
s0  = -20000;                % prescribed quadruple root [1/s]
Ts  = 10e-6;                 % sampling period [s]
padeOrder = 6;
useDigitalDelay = true;      % false -> theoretical delay h
plecsFile = 'PLECS_Voltage.csv';
averagePLECS = true;         % moving average over one switching period

tol = 0.02;                  % settling band
riseLim = [0.10 0.90];       % rise-time limits
finalFrac  = 0.05;           % final window for steady-state value
rippleFrac = 0.10;           % final window for ripple

%% Converter parameters
Cin = 51.7e-6;  rCin = 0.1e-3;           %#ok<NASGU>
C = 40e-6;  L = 15e-6;  R = 50;
rL = 9e-3;  rds = 31e-3;  rC = 0.4e-3;
Vf = 0.7;   rf = 0;
Fsw = 500e3;  Tsw = 1/Fsw;

alpha = R/(R+rC);
beta  = R*rC/(R+rC);

%% Nonideal operating point
D  = fzero(@(D) boostResidual(D,Vin,Vo,R,rL,rds,rf,Vf,alpha,beta), ...
    [0.05 0.95]);
Dp = 1-D;
I  = Vo/(R*Dp);
Vc = Vo;
rSigma = rL+D*rds+Dp*(rf+beta);

if I > 14
    warning('The equilibrium current %.4f A exceeds the 14 A limit.',I);
end

%% Linear model
A = [-rSigma/L, -alpha*Dp/L;
      alpha*Dp/C, -1/(C*(R+rC))];

B = [(I*(beta+rf-rds)+alpha*Vc+Vf)/L;
     -alpha*I/C];

GvCd = minreal(tf(ss(A,B,[0 1],0)));                     % capacitor voltage
Gvod = minreal(tf(ss(A,B,[beta*Dp alpha],-beta*I)));     % terminal voltage

%% Canonical form: c(1-zs)/(s^2+as+b)
a = -trace(A);
b = det(A);
n1 = B(2);
n0 = A(2,1)*B(1)-A(1,1)*B(2);
c = n0;
z = -n1/n0;
Gcanonical = minreal(tf([-c*z c],[1 a b]));

%% Modified PIR tuning
if s0 == -20000
    x0 = [3.3272e-5, 3.8011e-2, 7.9197e1, 2.9139e-2];
else
    x0 = [6.6e-4, -1.3e-2, 6.1e-2, 2.1e-5];
end

[h,kp,ki,kr,resMult] = tunePIR(s0,a,b,c,z,x0);

% Sufficient dominance condition
A2 = a-c*kp*z;
A1 = b+c*kp-c*ki*z;
A0 = c*ki;

P0   = s0^3+A2*s0^2+A1*s0+A0;
P0p  = 3*s0^2+2*A2*s0+A1;
P0pp = 6*s0+2*A2;

Rb = abs(P0)*h^4+3*abs(P0p)*h^3+abs(P0pp)*h^2+6*h;

%% Digital delay
Nh = round(h/Ts);
hd = Nh*Ts;
deltaH = hd-h;

if useDigitalDelay
    hSim = hd;
    delayText = "Implemented digital delay";
else
    hSim = h;
    delayText = "Theoretical continuous delay";
end

%% Report
banner('NONIDEAL BOOST-CONVERTER OPERATING POINT');
fprintf('Vin               = %.9f V\n',Vin);
fprintf('Vo                = %.9f V\n',Vo);
fprintf('D                 = %.12f\n',D);
fprintf('1-D               = %.12f\n',Dp);
fprintf('I_L               = %.12f A\n',I);
fprintf('rSigma            = %.12e ohm\n',rSigma);
fprintf('f_sw              = %.3f kHz\n',Fsw/1e3);

banner('CANONICAL PARAMETERS');
fprintf('a                 = %.15g s^-1\n',a);
fprintf('b                 = %.15g s^-2\n',b);
fprintf('c                 = %.15g\n',c);
fprintf('z                 = %.15g s\n',z);
fprintf('RHP-zero location = %.15g rad/s\n',1/z);

banner('MODIFIED PIR PARAMETERS');
fprintf('s0                = %.6f s^-1\n',s0);
fprintf('h                 = %.9f us\n',h*1e6);
fprintf('kp                = %.15g\n',kp);
fprintf('ki                = %.15g\n',ki);
fprintf('kr                = %.15g\n',kr);
fprintf('Multiplicity res. = %.3e\n',resMult);
fprintf('Rb                = %.15g\n',Rb);
fprintf('Rb < 3!           = %d\n',Rb < factorial(3));

banner('DIGITAL DELAY IMPLEMENTATION');
fprintf('Ts                = %.6f us\n',Ts*1e6);
fprintf('Nh                = %d samples\n',Nh);
fprintf('hd                = %.6f us\n',hd*1e6);
fprintf('Delta h           = %.6f us\n',deltaH*1e6);
fprintf('Compared model    = %s\n',delayText);

%% PLECS data
if ~isfile(plecsFile)
    [fname,fpath] = uigetfile({'*.csv','CSV files (*.csv)'}, ...
        'Select the PLECS voltage CSV file');
    if isequal(fname,0)
        error('No PLECS CSV file was selected.');
    end
    plecsFile = fullfile(fpath,fname);
end

raw = readmatrix(plecsFile);

if size(raw,2) < 2
    error('The PLECS file must contain time and voltage columns.');
end

tRaw = raw(:,1);
vRaw = raw(:,2);
ok = isfinite(tRaw) & isfinite(vRaw);
tRaw = tRaw(ok);
vRaw = vRaw(ok);

if numel(tRaw) < 10
    error('The PLECS file does not contain enough valid samples.');
end

% Sort and average repeated time stamps; first sample at t = 0
[tRaw,idx] = sort(tRaw);
vRaw = vRaw(idx);
[tU,~,grp] = unique(tRaw);
vU = accumarray(grp,vRaw,[],@mean);
tU = tU-tU(1);

% Common time grid for model and PLECS
tEnd = tU(end);
t = linspace(0,tEnd,min(12000,max(3000,numel(tU)))).';
vInterp = interp1(tU,vU,t,'linear','extrap');

if averagePLECS
    nAvg = max(1,round(Tsw/median(diff(t))));
    vPlecs = movmean(vInterp,nAvg,'Endpoints','shrink');
    plecsLegend = 'PLECS switching model, averaged';
else
    nAvg = 1;
    vPlecs = vInterp;
    plecsLegend = 'PLECS switching model';
end

%% Closed-loop nonideal model
s = tf('s');
[nd,dd] = pade(hSim,padeOrder);
Cpir = kp+ki/s-kr*tf(nd,dd);

Tmod = minreal((Gvod*(ki/s))/(1+Gvod*Cpir),1e-8);
vModel = squeeze(step(Vo*Tmod,t));

%% Metrics
mModel = perfMetrics(t,vModel,Vo,tol,riseLim,finalFrac,rippleFrac);
mPlecs = perfMetrics(t,vPlecs,Vo,tol,riseLim,finalFrac,rippleFrac);

% Ripple comes from the raw (unaveraged) switching waveform
nR = max(3,round(rippleFrac*numel(vInterp)));
vR = vInterp(end-nR+1:end);
mPlecs.RipplePeakToPeak = max(vR)-min(vR);

err  = vModel-vPlecs;
rmse = sqrt(mean(err.^2,'omitnan'));
mae  = mean(abs(err),'omitnan');
nrmse = 100*rmse/max(abs(Vo-vPlecs(1)),eps);

M = [mModel;mPlecs];

performanceTable = table(["Nonideal model";"PLECS"], ...
    1e3*[M.RiseTime]', 1e3*[M.SettlingTime]', [M.Overshoot]', ...
    [M.Undershoot]', [M.SteadyStateError]', 1e3*[M.RipplePeakToPeak]', ...
    [M.IAE]', [rmse;0], ...
    'VariableNames',{'Response','RiseTime_ms','SettlingTime_2pct_ms', ...
        'Mp_percent','Mu_percent','ess_V','Ripple_pp_mV','IAE_Vs', ...
        'RMSE_vs_PLECS_V'});

banner('TIME-DOMAIN PERFORMANCE METRICS');
disp(performanceTable);

fprintf('MAE between model and PLECS   = %.9g V\n',mae);
fprintf('NRMSE between model and PLECS = %.6f %%\n',nrmse);
fprintf('PLECS averaging window        = %d samples\n',nAvg);

%% Figure: model vs PLECS
fig = figure('Units','inches','Position',[0 0 3.50 1.85],'Color','white');
set(fig,'PaperUnits','inches','PaperSize',[3.50 1.85], ...
    'PaperPosition',[0 0 3.50 1.85]);

ax = axes(fig);
hold(ax,'on'); box(ax,'on'); grid(ax,'on');
articleStyle(ax);

plot(ax,1e3*t,vPlecs,'LineWidth',1.0,'DisplayName',plecsLegend);
plot(ax,1e3*t,vModel,'--','LineWidth',1.2, ...
    'DisplayName','Nonideal averaged model');
yline(ax,Vo,':','LineWidth',0.9,'HandleVisibility','off');

xlabel(ax,'Time [ms]');
ylabel(ax,'$v_o(t)$ [V]');
xlim(ax,[0 1e3*tEnd]);

v = [vPlecs(:);vModel(:);Vo];
vLo = min(v,[],'omitnan');
vHi = max(v,[],'omitnan');
margin = 0.05*max(vHi-vLo,1);
ylim(ax,[min(0,vLo-margin) vHi+margin]);

legend(ax,'Location','southeast','FontSize',6,'Box','on');

exportgraphics(fig,'PLECS_comparison.pdf', ...
    'ContentType','vector','BackgroundColor','white');

%% Local functions
function r = boostResidual(D,Vin,Vo,R,rL,rds,rf,Vf,alpha,beta)
    Dp = 1-D;
    if Dp <= 0
        r = Inf;
        return
    end
    I = Vo/(R*Dp);
    rSigma = rL+D*rds+Dp*(rf+beta);
    r = rSigma*I+alpha*Dp*Vo+Dp*Vf-Vin;
end

function [h,kp,ki,kr,res] = tunePIR(s0,a,b,c,z,x0)
    f = @(x) pirResidual(x,s0,a,b,c,z);

    if exist('fsolve','file') == 2
        opt = optimoptions('fsolve','Display','off', ...
            'FunctionTolerance',1e-12,'StepTolerance',1e-12, ...
            'OptimalityTolerance',1e-12,'MaxIterations',2000, ...
            'MaxFunctionEvaluations',20000);
        [x,~,flag] = fsolve(f,x0,opt);
        if flag <= 0
            error('fsolve did not converge for the PIR tuning.');
        end
    else
        % Fallback: h is optimised in log scale to keep it positive
        unpack = @(p) [exp(p(1)) p(2:4)];
        opt = optimset('Display','off','TolX',1e-12,'TolFun',1e-16, ...
            'MaxIter',30000,'MaxFunEvals',100000);
        p = fminsearch(@(p) sum(f(unpack(p)).^2),[log(x0(1)) x0(2:4)],opt);
        x = unpack(p);
    end

    h = x(1);  kp = x(2);  ki = x(3);  kr = x(4);
    res = norm(f(x),2);

    if h <= 0
        error('The computed intentional delay is not positive.');
    end
    if res > 1e-6
        warning('The quadruple-root residual is %.3e.',res);
    end
end

function F = pirResidual(x,s0,a,b,c,z)
    h = x(1);  kp = x(2);  ki = x(3);  kr = x(4);

    A2 = a-c*kp*z;
    A1 = b+c*kp-c*ki*z;
    A0 = c*ki;

    g0 = z*s0^2-s0;
    g1 = 2*z*s0-1-h*g0;
    g2 = 2*z-2*h*(2*z*s0-1)+h^2*g0;
    g3 = -6*h*z+3*h^2*(2*z*s0-1)-h^3*g0;

    e = c*kr*exp(-h*s0);

    Q = [s0^3+A2*s0^2+A1*s0+A0+e*g0;
         3*s0^2+2*A2*s0+A1+e*g1;
         6*s0+2*A2+e*g2;
         6+e*g3];

    F = Q./[max(abs(s0)^3,1); max(abs(s0)^2,1); max(abs(s0),1); 1];
end

function m = perfMetrics(t,y,ref,tol,riseLim,finalFrac,rippleFrac)
    t = t(:);  y = y(:);
    ok = isfinite(t) & isfinite(y);
    t = t(ok);  y = y(ok);

    if numel(t) < 3
        error('At least three valid samples are required for metrics.');
    end

    y0  = y(1);
    amp = ref-y0;
    if abs(amp) <= eps
        error('The reference transition has zero amplitude.');
    end
    yn = (y-y0)/amp;

    t1 = crossTime(t,yn,riseLim(1));
    t2 = crossTime(t,yn,riseLim(2));
    tr = NaN;
    if isfinite(t1) && isfinite(t2) && t2 >= t1
        tr = t2-t1;
    end

    k = find(abs(y-ref) > tol*abs(amp),1,'last');
    if isempty(k)
        ts = 0;
    elseif k >= numel(t)
        ts = NaN;
    else
        ts = t(k+1);
    end

    nF = max(3,round(finalFrac*numel(y)));
    yF = mean(y(end-nF+1:end),'omitnan');
    nR = max(3,round(rippleFrac*numel(y)));
    yR = y(end-nR+1:end);

    m = struct('RiseTime',tr,'SettlingTime',ts, ...
        'Overshoot',100*max(0,max(yn)-1), ...
        'Undershoot',100*max(0,-min(yn)), ...
        'SteadyStateError',abs(ref-yF), ...
        'RipplePeakToPeak',max(yR)-min(yR), ...
        'IAE',trapz(t,abs(ref-y)), ...
        'InitialValue',y0,'FinalValue',yF);
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

function banner(txt)
    bar = repmat('=',1,60);
    fprintf('\n%s\n%s\n%s\n',bar,txt,bar);
end