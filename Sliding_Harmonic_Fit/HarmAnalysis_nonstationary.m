function HA_out=HarmAnalysis_nonstationary(time,data,freq,time_overlap,SNR_thresh)
%
% function HarmAnalysis_nonstationary(time,data,time_overlap,SNR_thresh)
%
% Function to perform harmonic analysis (HA) on data (e.g. velocity) on
% small time segments, with overlapping time segments averaged. A
% signal-to-noise ratio (SNR) is applied to assess the success of the
% HA, following the methodology of Pawlowicz et al 2002
% "classical tidal harmonic...".
%
% Inputs:
% time: matlab datetime format, vector (Ntx1 or 1xNt)
% data: vector or matrix of velocity, density, pressure, etc. Must be 
%   depth by time dimensions (Nz x Nt).
% freq: frequency/ies to perform HA at in 1/hours
% time_overlap: in days, length of time segment to perform HA over (single value)   
% SNR_thresh: See referenced paper for good values. Min of 2 generally
%   (single value)
%
% Output structure:
% Data_HA: new timeseries of data fitted to frequency
%
% Written by Tamara Schlosser 2015

if nargin<5
    SNR_thresh=3;
    disp('Using default SNR of 3.')
end

dtime=median(diff(time));
N=round(time_overlap/(dtime));%number timesteps 
M=length(freq);
Nz=size(data,1);
Nt=length(time);

% add 0 frequency
freq=[freq(:)',0];
alpha=freq.*time_overlap.*24;

% for SNR needs bands to integrate over
if 1/(dtime*N*24)<.0083
    fwidth=1.5/(dtime*N*24);
else
    fwidth=.0083;
end
fband = [freq'-fwidth freq'+fwidth];
fband=fband(1:end-1,:);

for kk=1:M+1
    %pre-define
    Data_sum{kk}=zeros(Nz,Nt);
    count{kk}=zeros(Nz,Nt);
end

%D is constant
D=zeros(2*M+1,2*M+1);
D(1,1) = N;

n=1:N;

for kk=1:M
    D(1+kk,1)=sum(cos(2*pi()*alpha(kk)*n/N));
    D(1,kk+1)=D(1+kk,1);

    D(M+kk+1,1)=sum(sin(2*pi()*alpha(kk)*n/N));
    D(1,M+kk+1)=D(M+kk+1,1);

    for jj=1:M
        D(kk+1,jj+1)=sum(cos(2*pi()*alpha(kk)*n/N).*cos(2*pi()*alpha(jj)*n/N));
        D(kk+M+1,jj+M+1)=sum(sin(2*pi()*alpha(kk)*n/N).*sin(2*pi()*alpha(jj)*n/N));

        D(kk+1,jj+M+1)=sum(cos(2*pi()*alpha(kk)*n/N).*sin(2*pi()*alpha(jj)*n/N));%cs
        D(jj+M+1,kk+1)=sum(cos(2*pi()*alpha(kk)*n/N).*sin(2*pi()*alpha(jj)*n/N));%sc
    end
end

for ii=1:Nt-N
    % calculate y for each timestep and z layer
    y=cell(Nz,1);

    for zz=1:Nz;
        y{zz}(1,1)=sum(data(zz,ii:ii+N-1)*cos(0));
    end

    for kk=1:M        
        for zz=1:Nz;
            y{zz}(1+kk,1)=sum(data(zz,ii:ii+N-1).*cos(2*pi()*alpha(kk)*n/N));
            y{zz}(1+M+kk,1)=sum(data(zz,ii:ii+N-1).*sin(2*pi()*alpha(kk)*n/N));
        end
    end

    for zz=1:Nz
        x{zz}=D^-1*y{zz};

        % calculate HA of data for each timestep and harmonic, sum overlapping timesteps
        for kk=1:M+1
            if kk==M+1
                tmp_data{kk}=x{zz}(1)*cos(2*pi()*freq(kk)*n)+0;
            else
                tmp_data{kk}=x{zz}(kk+1)*cos(2*pi()*freq(kk)*n*dtime*24)+x{zz}(kk+M+1)*sin(2*pi()*freq(kk)*n*dtime*24);
            end    
        end
        %% find error
        if SNR_thresh==0
            SNR(zz,ii,:)=ones(1,M+1);
            Noise(zz,ii,:)=ones(1,M+1);
        else
            [SNR(zz,ii,:),Noise(zz,ii,:)]=HarmAnalysis_SNR(data(zz,ii:ii+N-1),tmp_data,time,fband/3600);
        end

        for kk=1:M+1
            %% back to harmonic analysis
            indd=Data_sum{kk}(zz,ii:ii+N-1)~=0;
            ind_1d=find(indd);
            nkd=find(~indd);

            if ~isempty(ind_1d) && SNR(zz,ii,kk)>=SNR_thresh
                Data_sum{kk}(zz,ind_1d+ii-1)=sum([Data_sum{kk}(zz,ind_1d+ii-1);tmp_data{kk}(ind_1d)]);
                count{kk}(zz,ind_1d+ii-1)=count{kk}(zz,ind_1d+ii-1)+1;
                Data_sum{kk}(zz,nkd+ii-1)=tmp_data{kk}(nkd);
            elseif  SNR(zz,ii,kk)>=SNR_thresh
                Data_sum{kk}(zz,ii:ii+N-1)=tmp_data{kk};
                count{kk}(zz,ii:ii+N-1)=1;
            end 
            if  SNR(zz,ii,kk)>=SNR_thresh && kk<=M
                Amp(zz,ii,kk)=max(abs(tmp_data{kk}));
                phase(zz,ii,kk)=atan2(x{zz}(kk+1),x{zz}(kk+M+1));
            else
                Amp(zz,ii,kk)=NaN;
                phase(zz,ii,kk)=NaN;
            end
        end
    end
end

for kk=1:M+1
    HA_out.Data_HA{kk}=Data_sum{kk}./count{kk};% now average all the values that have been added
    HA_out.Data_HA{kk}(count{kk}==0)=NaN;
end

HA_out.phase=phase;
HA_out.phase(Amp==0)=NaN;
HA_out.Amp=Amp;
HA_out.Amp(Amp==0)=NaN;
HA_out.freq=freq;
HA_out.time=time;
HA_out.SNR=SNR;
HA_out.Noise=Noise;
end

function [SNR,Noise]=HarmAnalysis_SNR(data,HA_data,time,fband)
% [SNR,Noise]=HarmAnalysis_SNR(data,HA_data,time,fband)
%
% sub-function to calculate signal-to-noise ratio.

dres=data;
for kk=1:length(HA_data)
    dres=dres-HA_data{kk};
end

N=length(HA_data{1});
dtime=median(diff(time))*24*3600;

[Pxu,fxu]=pwelch(dres,hanning(N),ceil(N/2),N,1/dtime,'onesided'); % Pxu=m2/s if data is m/s

df=fxu(3)-fxu(2);

for ff=1:size(fband,1)
    jbandu=find(fxu>=fband(ff,1) & fxu<=fband(ff,2));
    
    if length(jbandu)==1
        Noise(ff,1)=Pxu(jbandu)*df;%m2/s*1/s 
    else
        Noise(ff,1)=trapz(fxu(jbandu),Pxu(jbandu));
    end
end

% signal std
for kk=1:length(HA_data)-1
    sigu_var(kk,1)=0.5*max(HA_data{kk})^2;
end

SNR=sigu_var./Noise;
SNR(kk+1)=10;% dummy value
end