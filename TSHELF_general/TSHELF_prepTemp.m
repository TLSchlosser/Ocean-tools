function [T_mat_new,Tlf]=TSHELF_prepTemp(Ttime,T_mat,Z,Temp_tc,newtime,newZ)
%
% function [T_mat_new,Tlf]=TSHELF_prepTemp(datetime,T_mat,Z,Temp_tc,newtime,newZ)
%
% Given a temperature matrix, low-pass filter and remap to new dimensions (optional).
%
% Temp_tc=[6/24 30/24];

if Temp_tc(2)~=0
    % low pass filter for mean variable
    Tlf=pl66tn(T_mat',median(diff(Ttime)),Temp_tc(2))';% 40 hours
%     
%     Wn=median(diff(datetime))*2/Temp_tc(2);
%     [Cl,Dl]= butter(3,Wn,'low'); %butterworth filter
end
if Temp_tc(1)~=0
    % remove very high frequency
    Wn=median(diff(Ttime))*2/Temp_tc(1);
    [Ch,Dh]= butter(3,Wn,'low'); %butterworth filter
    T_mat=filtfilt(Ch,Dh,T_mat')';
end
if nargin>4
    % prefill
    Tlf2=zeros(size(T_mat,1),length(newtime));
    T_mat2=zeros(size(T_mat,1),length(newtime));

    for nn = 1:size(T_mat,1)
        if Temp_tc(2)~=0
            lf=interp1(Ttime,Tlf(nn,:),newtime,'linear');
        else
            lf=interp1(Ttime,T_mat(nn,:),newtime,'linear');
        end
        tmp=interp1(Ttime,T_mat(nn,:),newtime,'linear');

        Tlf2(nn,:)= interp1(newtime(~isnan(lf)),lf(~isnan(lf)),newtime,'nearest','extrap');
        T_mat2(nn,:)=interp1(newtime(~isnan(tmp)),tmp(~isnan(tmp)),newtime,'nearest','extrap');
    end
    % also interp to current depth
    tmplf=zeros(length(newZ),length(newtime));
    tmp=zeros(length(newZ),length(newtime));
    for nn = 1:size(T_mat2,2)
        lf= interp1(Z,Tlf2(:,nn),newZ,'linear');
        tmp1=interp1(Z,T_mat2(:,nn),newZ,'linear');
        tmplf(:,nn)=interp1(newZ(~isnan(lf)),lf(~isnan(lf)),newZ,'nearest','extrap');
        tmp(:,nn)=interp1(newZ(~isnan(tmp1)),tmp1(~isnan(tmp1)),newZ,'nearest','extrap');
    end
    Tlf=tmplf;
    T_mat_new=tmp;
else
    T_mat_new=T_mat;
end