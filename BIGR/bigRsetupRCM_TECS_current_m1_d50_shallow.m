clear;close all;clear global
% Mofidication of bigrsetup so that you don't have to enter parameters interactively
% RCM Dec 2017

%   Create an input file for "bigromp.m", given inputs
%   Call as
%       filein = bigrsetup
%   In response to queries, you can enter either numbers or array names

%   K.H. Brink
%       5/18/2003, 12/23/2004, 3/31/2012

% RCM: run it like this  bigrsetupRCM; bigromp(filein)

% How many total gridpoints do you want in the cross shelf direction? (nn)
xmax = 200;
filein(1) =300;%76;%76;

mode=1;
% How many total gridpoints do you want in the vertical? (mm) 
filein(2) = 400;%180
% First guess at frequency (rad/sec)? 
load(['BIGR_Disp_Mode_',num2str(mode),'X_r07_day52.mat'])
% [~,n]=min(abs(2*pi/(23.9*3600)-dispcurve(:,2)));
filein(3) =2*pi/(23.9*3600);%dispcurve(1,2);%

% new method option when frequency and wavelength is already known. Will
% only search nearby frequencies. Otherwise method method=1 to search all
% frequencies.
method=3;
% Enter 0 for a rigid lid, 1 for a free surface (del) 
filein(4) = 0;
% Enter 0 for a closed x= 0 boundary, 1 for open (icbc)
filein(5) = 0;
% Enter 0 for a closed x =xmax boundary, 1 for an open (iobc)
filein(6) = 1;
% Enter 1 for general frequency, wavenumber or 0 for long wave limit
filein(7) = 1;
% Enter the Coriolis parameter (f) (rad/sec) 
filein(8) =sw_f(-41.4); %9.85e-5;
% Enter the domain width (xmax) (km) 
%200;
filein(9) = xmax;
% Enter the nominal fractional accuracy for the solution (eps) 
filein(10) = 0.0001;
% Enter the number of frequencies to be computed (npts) 
filein(11) =1;
if filein(7) < 0.5
    %       It only makes sense to compute one point for the long wave
    %       limit
    filein(11) = 1;
end
% Enter the first alongshore wavenumber to use (rlz) (rad/cm) 
filein(12) = -2*pi/199e5;%-3.1e-7;%dispcurve(1,1);%-2*pi/200e5;%
%    Enter the wavenumber increment to use after rlz (drl) (rad/cm)
if filein(11) < 1.1
    filein(13) = filein(12);
else
    filein(13) = -4e-8;
end
%   Read in depth
% How many distance, depth pairs will you provide (ndep >=1) 
% old=load('SI_realbathy_strat4_300km_60m_Mar14.mat');
% 
% xdep=smooth(fliplr(-old.x*1E-3));% km
% xdep=xdep(:)';
% depr=fliplr(old.h);
% % set min depth 50 m
% depr(depr<2)=2;
% xdep=xdep(1:4:end);
% depr=depr(1:4:end);
% % plot(xdep,depr)
% 
% tmp=log(1:1:11)./log(11);
% zz=depr(find(xdep<=45,1,'last'));
% depr=[depr(xdep<=45) zz:(3374-zz)/round(81-45):3374 (4088-3374).*tmp+3374 4088.*ones(1,8)];%45
% xdep=[xdep(xdep<=45) 45:1:81 82:1:92 93:100];
% depr(xdep>31 & xdep<=4088)=smooth(depr(xdep>31 & xdep<=4088),10);
% clear old
% hold on;plot(xdep,depr)
load Smoothed_bathy.mat xdep depr

filein(14) = length(xdep);
ndep = filein(14);
% Array of offshore distances for depth values (xdep in km) (dimension ndep) 
% xdep = [0 50 100 120 150 200 230 270 300]; % 75 95];
%   First value of xdep must be 0!
[n,m] = size(xdep);
if n > m
    xdep = xdep';
end
if length(xdep) ~= ndep
    disp(' ')
    disp('Error! Array size must match ndep!')
    disp(' ')
end
filein = [filein xdep];
% Array of depths corresponding to xdep (depr in m) 
% depr = [10 12.4 42 161 1223 2621 3362 3778 3783]; % 3500 4000];
if n > m
    depr = depr';
end
if length(depr) ~= ndep
    disp(' ')
    disp('Error! Array size must match ndep!')
    disp(' ')
end
if xdep(1) > 0
    disp(' ')
    disp('Error! Must have first depth at x = 0!')
end

nddd = max([n m]);
filein = [filein depr];
xdep = [xdep xmax];
depr = [depr depr(nddd)];

%       Read in bottom friction
% Number of distance, bottom friction pairs to read (nr)
nr = 1;

filein = [filein nr];

if nr > 0.05
    % Offshore distances for bottom friction values (xr in km) 
    xr = [0 ];
    %   First value of xr must be 0!
    % Array of bottom friction values corresponding to xr (rr in cm/sec) 
    rr = [ .07];
    [n m] = size(xr);
    nrr = max([n m]);
    if n > m
        xr = xr';
        rr = rr';
    end
    if length(xr) ~= nr
        disp(' ')
        disp('Error! Array size must match nr!')
        disp(' ')
    end
    if length(rr) ~= nr
        disp(' ')
        disp('Error! Array size must match nr!')
        disp(' ')
    end
    filein = [filein xr rr];
    subplot(2,1,1)
    xr = [xr xmax];
    rr = [rr rr(nrr)];
    rmax = max(rr);
    plot(xr,rr)
    title('Bottom friction parameter (cm/sec)')
    ylabel('r (cm/sec)')
    %    axis([0 xmax 0 1.5*rmax])
    if xr(1) > 0
        disp(' ')
        disp('Error! Must have first value at x = 0!')
    end
else
    subplot(2,1,1)
    rmax = 1;
    plot([0 xmax],[0 0])
    title('Bottom friction parameter (cm/sec)')
    ylabel('r (cm/sec)')
    axis([0 xmax 0 1.5*rmax])
    text(xmax/2,rmax/2,'r = 0')
end
filein_st=filein;

load CTD_strat_days.mat
nsqr=N2_days(~isnan(N2_days(:,3)),3);%
% nsqr=N2_0(~isnan(N2_0(:,3)),3);
% shift up 40 m
nsqr=nsqr(40:end);

% nsqr(1:N_ind)=((nsqr(1:N_ind)./nsqr(N_ind)-1)*.7+1)*nsqr(N_ind);
% nsqr(1:30)=((nsqr(1:30)./nsqr(30)-1)*.7+1)*nsqr(30);
zr=1;
alph=1;
clear old
    
% Number of Nsquared values to read? (nnsq) 
nnsq = length(nsqr);
[n,m] = size(nsqr);
if n > m
    nsqr = nsqr';
end
if length(nsqr) ~= nnsq
    disp(' ')
    disp('Error! Array size must match nnsq!')
    disp(' ')
end

filein = [filein_st nnsq zr alph nsqr];
   

%       Read in mean flow
if nr ~= 0
   subplot(2,1,2)
end
% Input peak value of mean alongshore flow (vzero: cm/sec) 
load Model_Currents_Mean.mat

vzero = 0;%C50.vzero;
filein = [filein vzero];
zmax = max(depr);
if vzero ~= 0
    xzero = C50.xzero;%input(' Input distance offshore to peak mean flow (km) ');
    zzero = 0;%input(' Input depth of peak mean flow (m) ');
    zscaled = C50.zscaled;%input(' Downward exponential scale of mean flow? (m) ');
    zscaleup = 200;%input(' Upward exponential scale of mean flow? (m) ');
    xscaleoff = C50.xscaleoff;%input(' Offshore exponential scale of mean flow? (km) ');
    xscaleon = C50.xscaleon;%input(' Onshore exponential scale of mean flow? (km) ');
    kk = 1;%input(' Enter 1 for undisturbed Nsquared offshore, 0 for onshore ');
    filein = [filein xzero zzero zscaled zscaleup xscaleoff xscaleon kk];

    nn = 180;
    mm = 180;

    x = 0:xmax/(nn-1):xmax;
    z = (-zmax:zmax/(mm-1):0)';
    zzero = -zzero;

    xfactoff = xscaleoff^2;
    xfacton = xscaleon^2;
    zfactu = zscaleup^2;
    zfactd = zscaled^2;

    vtemp = NaN*ones(nn,mm);

    ii = find( x < xzero);
    iic = find(x >=  xzero);
    jj = find(z < zzero);
    jjc = find(z >= zzero);

    if isempty(size(ii)) ~= 1
        for n = 1:max(ii)
            if isempty(size(jj)) ~= 1
                vtemp(jj,n) = vzero*(exp(-((x(n)-xzero).*(x(n)-xzero)/xfacton)))*(exp(-(z(jj)-zzero).*(z(jj)-zzero)/zfactd));
            end
            if isempty(size(jjc)) ~= 1
                vtemp(jjc,n) = vzero*(exp(-((x(n)-xzero).*(x(n)-xzero)/xfacton)))*(exp(-(z(jjc)-zzero).*(z(jjc)-zzero)/zfactu));
            end
        end
    end

    if isempty(size(iic)) ~= 1
        for n = min(iic):nn
            if isempty(size(jj)) ~= 1
                 vtemp(jj,n) = vzero*(exp(-((x(n)-xzero).*(x(n)-xzero)/xfactoff)))*(exp(-(z(jj)-zzero).*(z(jj)-zzero)/zfactd));
            end
            if isempty(size(jjc)) ~= 1
                 vtemp(jjc,n) = vzero*(exp(-((x(n)-xzero).*(x(n)-xzero)/xfactoff)))*(exp(-(z(jjc)-zzero).*(z(jjc)-zzero)/zfactu));
            end
        end
    end

    %   Plot out results so the user can see if they look right

    contour(x,z,vtemp,30);colorbar;xlim([0 40]);ylim([-300 0])
else
    subplot(2,1,2)
    zzm = -max(depr);
    text(xmax*0.75,zzm*0.25,'v = 0')

end

hold on
xxx = [xdep xdep(1) xdep(1)];
yyy = -[depr depr(nddd) depr(1)];
fill(xxx,yyy,'b')
hold off
axis([0 xmax -zmax 0])
title('Depth and mean flow')
ylabel('Depth (m)')
xlabel('Offshore distance (km)')
set(gca,'TickDir','out')

%Enter 0 to skip pauses to see graphics, 1 to see graphics during execution 
ipause = 0;
filein = [filein ipause];
% 
% addpath('..\BIGC\')
% fileinC = filein;
% fileinC(5:7) = filein(4:6);
% % complex frequency
% fileinC(4) = dispcurve(end,3);


%     caxis([-32 -2])
%     colorbar
%     ylim([-300 0]);xlim([0 40])

bigromp(filein,method)
% movefile('dispc.mat',['BIGR_Disp_Mode_',num2str(mode),'X_r07_Mean.mat'])
pause(5)
movefile('uvwrp.mat',['BIGR_D1_Mode',num2str(mode),'X_r07_d50_shallow.mat'])
% Cx=x;Cz=z;
% save(['BIGR_D1_Mode',num2str(mode),'X_r07_d50.mat'],'Cx','Cz','vtemp','-append')

pause(5)
