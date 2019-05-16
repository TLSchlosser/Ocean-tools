function [N2,N]=TS_bfrq(rho,Z,lat,omega,time,flag)
% n2=rad2/sec2, n=rad/sec
% omega=rad/s
%
% e.g. [N2,N]=TS_bfrq(rho_mat,HASB,lat(mm),omega,datetime);
%
% Written TS Sep 2016

[n,m]=size(rho);

if m==length(time) && m==1
    rho=[rho,rho];
    time=[time,time+1];
end

g = mean(sw_g(lat,-Z));
% mid_g=(g(1:end-1)+g(2:end))/2;
% mid_pden=(rho(1:end-1,:)+rho(2:end,:))/2;
% N2= -repmat(mid_g,1,m) .* diff(rho) ./ (repmat(diff(Z),1,m) .* mid_pden);
% N2(N2<0)=omega.^2;
% N=sqrt(N2);

% Calc N^2
% g=9.81;
rho0=nanmean(rho(:));
[~,drho_dz] = gradient(rho,time,Z);
N2 = -g/rho0 .* (drho_dz);
if ~exist('flag','var') || flag==1 
N2(N2<=0)=omega.^2; % set omega as min
end
N= sqrt(N2);

if m==1 && length(time)==2
    N2=N2(:,1);
    N=N(:,1);
end
end