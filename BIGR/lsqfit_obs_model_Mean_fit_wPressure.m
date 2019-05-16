clear;close all;

%% I want to least-squares fit obs and model results

path='D:\Dropbox\TSHELF_2015\Modelling\BIGR\';
name={'BIGR_D1_Mode0X_r07_','BIGR_D1_Mode1X_r07_','BIGR_D1_Mode2X_r07_'};%,'BIGR_D1_Mode3X_r07_d38'
obs_HA_path='D:\Dropbox\TSHELF_2015\Data_Processing\Harmonic Analysis\NewSep_Op4_Total_SNR_thresh_3_Days_3\';
zstep=1;
obs_H=10:zstep:90;% 5 spots over full depth

moorings={'bore_deep','shelf_break','T4','T3'};%'WW_Shallow','bore_shallow','WW_Deep', 
[lon_mm,lat_mm,depth_mm,label]=TSHELF_siteinfo(moorings);
% label={'W10','M17','W21','M25','M29','M32','M44'};
load('D:\Dropbox\TSHELF_2015\Data_Processing\Density_Parameters.mat')
Dind=3;
day=[38 46 50 56];

% load data
model=load(sprintf('%sd%i_check.mat',name{2},day(Dind)));

BBL=34;
SBL=[42 34 34];
BL=[BBL SBL(Dind)];%BBL and SBL

for mm=1:length(lon_mm)
    % find index based on closest depth
    [~,nind]=min(abs(-model.zf-depth_mm(mm)));
    [~,n_mm(mm)]=min(abs(model.xf(nind)-model.xpl));
end
x_pos_mm=model.xpl(n_mm);
clear merge

%% get model data
for ii=1:length(name)
    model=load(sprintf('%sd%i_check.mat',name{ii},day(Dind)));
    scale=max(sqrt(abs(model.ug(:).^2+model.vg(:).^2)));
    tmp_U=model.ug(n_mm,:)'./scale;
    tmp_V=model.vg(n_mm,:)'./scale;
    tmp_P=model.pg(n_mm,:)'./scale;

    for mm=1:length(lon_mm)
        [~,nind]=min(abs(model.xpl(n_mm(mm))-model.xf));
        zind=model.z>model.zf(nind);
        % set z
        Model_U(ii,:,mm)=interp1((model.z(zind)+depth_mm(mm))./depth_mm(mm).*100,tmp_U(zind,mm),obs_H,'linear');
        Model_U(ii,isnan(Model_U(ii,:,mm)),mm)=interp1((model.z(~isnan(Model_U(ii,:,mm)))+depth_mm(mm))./depth_mm(mm).*100,....
            tmp_U(~isnan(Model_U(ii,:,mm)),mm),obs_H(isnan(Model_U(ii,:,mm))),'nearest','extrap');
        Model_V(ii,:,mm)=interp1((model.z(zind)+depth_mm(mm))./depth_mm(mm).*100,tmp_V(zind,mm),obs_H,'linear');
        Model_V(ii,isnan(Model_V(ii,:,mm)),mm)=interp1((model.z(~isnan(Model_V(ii,:,mm)))+depth_mm(mm))./depth_mm(mm).*100,....
            tmp_V(~isnan(Model_V(ii,:,mm)),mm),obs_H(isnan(Model_V(ii,:,mm))),'nearest','extrap');
        Model_P(ii,:,mm)=interp1((model.z(zind)+depth_mm(mm))./depth_mm(mm).*100,tmp_P(zind,mm),obs_H,'linear');
        Model_P(ii,isnan(Model_P(ii,:,mm)),mm)=interp1((model.z(~isnan(Model_P(ii,:,mm)))+depth_mm(mm))./depth_mm(mm).*100,....
            tmp_P(~isnan(Model_P(ii,:,mm)),mm),obs_H(isnan(Model_P(ii,:,mm))),'nearest','extrap');
    end
    k(ii)=model.rl*100;
end
Nz=length(model.z);

%% dummy dataset
for ii=1:length(name)
    model=load(sprintf('%sd%i_check.mat',name{ii},day(Dind)));
    scale=max(sqrt(abs(model.ug(:).^2+model.vg(:).^2)));
    
    % dummy amp and phase
    r1(ii)=rand(1);
    r2(ii)=sin(rand(1)*pi);
    
    tmp_U=model.ug(n_mm,1:10:end)'./scale*r1(ii)*exp(1i*r2(ii));
    tmp_V=model.vg(n_mm,1:10:end)'./scale*r1(ii)*exp(1i*r2(ii));
    tmp_P=model.pg(n_mm,1:10:end)'./scale*r1(ii)*exp(1i*r2(ii));
    model.z=model.z(1:10:end);
    for mm=1:length(lon_mm)
        [~,nind]=min(abs(model.xpl(n_mm(mm))-model.xf));
        zind=model.z>model.zf(nind);
        % set z
        Dummy_U(ii,:,mm)=interp1((model.z(zind)+depth_mm(mm))./depth_mm(mm).*100,tmp_U(zind,mm),obs_H,'linear');
        Dummy_U(ii,isnan(Dummy_U(ii,:,mm)),mm)=interp1((model.z(~isnan(Dummy_U(ii,:,mm)))+depth_mm(mm))./depth_mm(mm).*100,....
            tmp_U(~isnan(Dummy_U(ii,:,mm)),mm),obs_H(isnan(Dummy_U(ii,:,mm))),'nearest','extrap');
        Dummy_V(ii,:,mm)=interp1((model.z(zind)+depth_mm(mm))./depth_mm(mm).*100,tmp_V(zind,mm),obs_H,'linear');
        Dummy_V(ii,isnan(Dummy_V(ii,:,mm)),mm)=interp1((model.z(~isnan(Dummy_V(ii,:,mm)))+depth_mm(mm))./depth_mm(mm).*100,....
            tmp_V(~isnan(Dummy_V(ii,:,mm)),mm),obs_H(isnan(Dummy_V(ii,:,mm))),'nearest','extrap');
        Dummy_P(ii,:,mm)=interp1((model.z(zind)+depth_mm(mm))./depth_mm(mm).*100,tmp_P(zind,mm),obs_H,'linear');
        Dummy_P(ii,isnan(Dummy_P(ii,:,mm)),mm)=interp1((model.z(~isnan(Dummy_P(ii,:,mm)))+depth_mm(mm))./depth_mm(mm).*100,....
            tmp_P(~isnan(Dummy_P(ii,:,mm)),mm),obs_H(isnan(Dummy_P(ii,:,mm))),'nearest','extrap');
    end
    k(ii)=model.rl*100;
end

%% now obs
Obs_U=ones(length(obs_H),length(moorings)).*NaN;
Obs_V=Obs_U;
Obs_P=Obs_U;
Obs_VP=Obs_U;
Obs_UP=Obs_U;
Obs_PP=Obs_P;

% use W21 surface elevation for every mooring
load([obs_HA_path,'shelf_break','_HA.mat'],'HA_pbot')
rho0=1026;

for mm=1:length(moorings)
    load([obs_HA_path,moorings{mm},'_HA.mat'],'HA_u','HA_v','HA_p_pet2','HA_p_pet')
    
    if exist('HA_u','var')
        HASB=HA_u.HASB;
        N=(length(HA_u.time)-size(HA_u.Amp,2))/2;
        
        if diff(HASB)>0
            HA_p_pet2.Amp=flipud(HA_p_pet2.Amp);
            HA_p_pet2.phase=flipud(HA_p_pet2.phase);
            HA_p_pet2.Data_HA{3}=flipud(HA_p_pet2.Data_HA{3});
        end
        %% redefine pressure with surface perturbation
%         ppet=HA_p_pet2.Data_HA{3};
%         ppet(isnan(ppet))=0;
%         ppet=ppet+repmat(interp1(HA_pbot.time,rho0*9.81.*HA_pbot.Data_HA{3},HA_p_pet2.time),length(HASB),1);
%         % now find amp and phase
%         clear A
%         rind=round(3/median(diff(HA_p_pet2.time)));
%         for zz=1:length(HASB)
%             A(zz,:)=movmax((ppet(zz,:)),rind);
%         end
%         HA_p_pet2.Amp(:,:,3)=A(:,N:end-N-1);
%         for zz=1:length(HASB)
%             for tt=1:size(HA_p_pet2.Amp,2)
%                 n=find(ppet(zz,N+tt-round(rind/2):N+tt+round(rind/2))==A(zz,tt+N));
%                 
%                 ph(zz,tt)=(n-round(rind/2))*median(diff(HA_p_pet2.time))*24/23.9*2*pi;
%             end
%         end
%         ph=wrapToPi(ph);
        HA_p_pet2=HA_p_pet;
        
        %% back to code
        % correct for varying phase with time
        tmp=2*pi*(HA_u.time(N:end-N-1)-HA_u.time(N))/(HA_u.freq(3)*24);
        tmp=tmp-floor(tmp./(2*pi))*2*pi;
        up=wrapToPi(squeeze(HA_u.phase(:,:,3))-repmat(tmp(:)',length(HASB),1));
        vp=wrapToPi(squeeze(HA_v.phase(:,:,3))-repmat(tmp(:)',length(HASB),1));
        tind=HA_p_pet2.time(N:end-N-1)<=HA_u.time(end-N-1);
        pp=wrapToPi(squeeze(HA_p_pet2.phase(:,tind,3))-repmat(tmp(:)',length(HASB),1));
        
%         % now matches HASB
        [~,Tind]=min(abs(jday(HA_u.time(N:end-N-1))-day(Dind)));
        [~,Tind2]=min(abs(jday(HA_u.time(N:end-N-1))-day(Dind+1)));
        if Tind~=Tind2
            tmpu=nanmean(HA_u.Amp(:,Tind:Tind2,3)');
            tmpv=nanmean(HA_v.Amp(:,Tind:Tind2,3)');
            tmpp=nanmean(HA_p_pet2.Amp(:,Tind:Tind2,3)');
            
            % I think it's more accurate to find ave of sin of angle
            tmppu=asin(nanmean(sin(up(:,Tind:Tind2))'));
            tmppv=asin(nanmean(sin(vp(:,Tind:Tind2))'));
            tmppp=asin(nanmean(sin(pp(:,Tind:Tind2))'));
            
            % account for distortion within BBL and SBL
            ind=HASB>BL(1) & -depth_mm(mm)+HASB<-BL(2);

            Obs_U(:,mm)=interp1(HASB(ind)./depth_mm(mm),abs(tmpu(ind)),obs_H/100,'linear');
            Obs_V(:,mm)=interp1(HASB(ind)./depth_mm(mm),abs(tmpv(ind)),obs_H/100,'linear');
            Obs_P(:,mm)=interp1(HASB(ind)./depth_mm(mm),abs(tmpp(ind)),obs_H/100,'linear');
            Obs_UP(:,mm)=interp1(HASB(ind)./depth_mm(mm),(tmppu(ind)),obs_H/100,'linear');
            Obs_VP(:,mm)=interp1(HASB(ind)./depth_mm(mm),(tmppv(ind)),obs_H/100,'linear');
            Obs_PP(:,mm)=interp1(HASB(ind)./depth_mm(mm),(tmppp(ind)),obs_H/100,'linear');
        end
    end

    clear HA* 
end

%% first fit dummy data
% do along-shore velocities only
ind=sum(isnan(Obs_U))<length(obs_H);

% get model data in right format
clear U V P
for il = 1:size(Model_U,1) 
    tmp=squeeze(Model_U(il,:,ind));%+1i*Model_V(il,:,2:end)
    U(:,il)=tmp(:);
    tmp=squeeze(Model_V(il,:,ind));
    V(:,il)=tmp(:);
    tmp=squeeze(Model_P(il,:,ind));
    P(:,il)=tmp(:);
%     tmp=squeeze(Model_Uph(il,:,ind));
%     Uph(:,il)=tmp(:);
%     tmp=squeeze(Model_Vph(il,:,ind));
%     Vph(:,il)=tmp(:);
end

uin=Obs_U(:,ind);
vin=Obs_V(:,ind);
pin=Obs_P(:,ind);
upin=Obs_UP(:,ind);
vpin=Obs_VP(:,ind);
ppin=Obs_PP(:,ind);

% first test dummy
for ii=1:size(Model_U,1)
    tmp_UP=angle(squeeze(sum(Dummy_U(1:ii,:,:),1)));
    tmp_U=abs(squeeze(sum(Dummy_U(1:ii,:,:),1)));
    tmp_VP=angle(squeeze(sum(Dummy_V(1:ii,:,:),1)));
    tmp_V=abs(squeeze(sum(Dummy_V(1:ii,:,:),1)));
    tmp_PP=angle(squeeze(sum(Dummy_P(1:ii,:,:),1)));
    tmp_P=abs(squeeze(sum(Dummy_P(1:ii,:,:),1)));
    [dummy_CC(ii,:),dummy_MAE(:,ii),dummy_bias(:,ii),~,coef]=compareModelObs_fituvp({tmp_U(:,ind),tmp_V(:,ind),tmp_P(:,ind),...
        tmp_UP(:,ind),tmp_VP(:,ind),tmp_PP(:,ind)},{U(:,1:ii),V(:,1:ii),P(:,1:ii)});
    allcoef{ii}=coef;
end

%% now fit obs
for ii=1:size(Model_U,1)
    [CC(ii,:),MAE(:,ii),bias(:,ii),out,coef]=compareModelObs_fituvp({uin,vin,pin,upin,vpin,ppin},...
        {U(:,1:ii),V(:,1:ii),P(:,1:ii)});%,Uph(:,1:ii),Vph(:,1:ii)
%     disp(coef)
    if ii==2
        coef_m4=coef;
        dom=abs(coef_m4)./sum(abs(coef_m4));
        vel=out;
        note='coef gives units of cgs!';
        save(['d',num2str(day(Dind)),'_2mode_wP_Sol.mat'],'out','coef','dom','uin','vin','U','V','Dind','note')
    end
end
% [CC(ii+1),MAE(:,ii+1),bias(:,ii+1),out,coef]=compareModelObs_fitv({uin,vin,upin,vpin},{U(:,[2]),V(:,[2]),Uph(:,[2]),Vph(:,[2])});
[CC(ii+1,:),MAE(:,ii+1),bias(:,ii+1),out,coef]=compareModelObs_fituvp({uin,vin,pin,upin,vpin,ppin},...
    {U(:,1:ii),V(:,1:ii),P(:,1:ii)});%,Uph(:,[1 3]),Vph(:,[1 3])
% disp(coef)

table(:,1)=CC(:,1);
table(:,2)=CC(:,2);
table(:,3)=CC(:,3);
table(:,4)=MAE(1,:);%./max(abs(uin(:)))
table(:,5)=MAE(2,:);%./max(abs(vin(:)))
table(:,6)=MAE(3,:);%./max(abs(pin(:)))
% table(:,7)=bias(1,:)./1e-2;
% table(:,8)=bias(2,:)./1e-2;
% table(:,9)=bias(3,:)./1e-2;

%% check fit with plots
figure('position',[5 5 12 16]);
x=x_pos_mm;
subplot(5,2,1);contourf(x(ind),obs_H,uin);caxis([-.1 .1]);ylabel('obs u')
subplot(5,2,2);contourf(x(ind),obs_H,vin);caxis([-.1 .1]);ylabel('obs v')
subplot(5,2,3);contourf(x(ind),obs_H,abs(reshape(vel{1}(:,end),size(uin))));caxis([-.1 .1]);ylabel('fitted u (all modes)')
subplot(5,2,4);contourf(x(ind),obs_H,abs(reshape(vel{2}(:,end),size(uin))));caxis([-.1 .1]);ylabel('fitted v (all modes)')
for ii=1:2
    subplot(5,2,5+(ii-1)*2);
    contourf(x(ind),obs_H,abs(reshape(vel{1}(:,ii),size(uin))).*sign(real(reshape(vel{1}(:,ii),size(uin)))));
    caxis([-.1 .1])
    ylabel(['mode ',num2str(ii-1)])
    subplot(5,2,6+(ii-1)*2);
    contourf(x(ind),obs_H,abs(reshape(vel{2}(:,ii),size(uin))).*sign(real(reshape(vel{2}(:,ii),size(uin)))));
    caxis([-.1 .1])
end
colorbar('position',[.92 .1 .02 .5])
load brewer_white.mat;colormap(cmap)
% print Fitted_Velocities_d38_2fit_Vonly_pos2.png -dpng -r600

% figure;
% subplot(3,1,1);contourf(squeeze(velv(:,:,1)));caxis([-.1 .1])
% subplot(3,1,2);contourf(squeeze(velv(:,:,2)));caxis([-.1 .1])
% subplot(3,1,3);contourf(squeeze(velv(:,:,3)));caxis([-.1 .1])
% 
% tmp1=squeeze(abs(reshape(vel{1}(:,1),size(uin))).*sign(real(reshape(vel{1}(:,1),size(uin))))+...
%     1i*abs(reshape(vel{2}(:,1),size(uin))).*sign(real(reshape(vel{2}(:,1),size(uin)))));
% x=1:4;
% save fitted_kelvin_test2.mat tmp1 x obs_H

figure;
mi=length(find(ind));

vel{1}(:,end)=abs(vel{1}(:,end));
vel{2}(:,end)=abs(vel{2}(:,end));
Model_U=imag(Model_U);
Model_V=real(Model_V);
for ii=1:mi
    
    subplot(2,mi,ii)
    plot(uin(:,ii)./max(abs(uin(:,ii))),obs_H,'k','LineWidth',1.2)
    hold on;
    plot(vel{1}(1+(ii-1)*length(obs_H):ii*length(obs_H),end)./max(abs(vel{1}(1+(ii-1)*length(obs_H):ii*length(obs_H),end))),obs_H,'LineWidth',1.2)
    for jj=1:size(vel{1},2)-1
        plot(abs(vel{1}(1+(ii-1)*length(obs_H):ii*length(obs_H),jj))./...
            max(abs(vel{1}(1+(ii-1)*length(obs_H):ii*length(obs_H),jj))).*sign(squeeze(Model_U(jj,:,ii)))',obs_H)
    end
    title(label{ii});xlim([-1.1 1.1]);ylim([0 100])
    
    subplot(2,mi,ii+mi)
    plot(vin(:,ii)./max(abs(vin(:,ii))),obs_H,'k','LineWidth',1.2)
    hold on;
    plot(vel{2}(1+(ii-1)*length(obs_H):ii*length(obs_H),end)./max(abs(vel{2}(1+(ii-1)*length(obs_H):ii*length(obs_H),end))),obs_H,'LineWidth',1.2)
    for jj=1:size(vel{1},2)-1
        plot(abs(vel{2}(1+(ii-1)*length(obs_H):ii*length(obs_H),jj))./...
            max(abs(vel{2}(1+(ii-1)*length(obs_H):ii*length(obs_H),jj))).*sign(squeeze(Model_V(jj,:,ii)))',obs_H)
    end
    title(label{ii});xlim([0 1.1]);ylim([0 100])
end
subplot(2,mi,1);ylabel('Cross-shore');
subplot(2,mi,mi+1);ylabel('Along-shore');
subplot(2,mi,mi*2);legend({'Obs','Fit','m0','m1','m2'},'position',[.89 .4 .1 .1])
% print Fit_UV_Mode0_1_Vonly_pos2.png -dpng -r300

% figure;
% subplot(2,1,1)
% plot(x(ind),nanmean(abs(uin)./max(abs(uin(:)))),'k','LineWidth',1.2)
% hold on;
% plot(x(ind),nanmean(reshape(vel{1}(:,end),size(uin))./max(abs(vel{1}(:,end)))),'LineWidth',1.2)
% for jj=1:3
%     plot(x(ind),nanmean(reshape(abs(vel{1}(:,jj)),size(uin))./max(abs(vel{1}(:,jj)))),'LineWidth',1)
% end
% ylabel('Mean Cross Velocity')
% subplot(2,1,2)
% plot(x(ind),nanmean(abs(vin)./max(abs(vin(:)))),'k','LineWidth',1.2)
% hold on;
% plot(x(ind),nanmean(reshape(vel{2}(:,end),size(uin))./max(abs(vel{2}(:,end)))),'LineWidth',1.2)
% for jj=1:3
%     plot(x(ind),nanmean(reshape(abs(vel{2}(:,jj)),size(uin))./max(abs(vel{2}(:,jj)))),'LineWidth',1)
% end
% xlabel('Distance (km)')
% ylabel('Mean Along Velocity')
% legend({'Obs','Fit','m0','m1','m2'},'position',[.89 .4 .1 .1])
% print Fit_CrossView_UV_Mode0_1_2_Vonly_pos2.png -dpng -r300

%% fit individual moorings
nl=length(obs_H);
for jj=1:length(find(ind))
for ii=1:size(Model_U,1)
    [CC(ii,:),MAE(:,ii),bias(:,ii),out,coef]=compareModelObs_fituvp({uin(:,jj),vin(:,jj),pin(:,jj),upin(:,jj),vpin(:,jj),ppin(:,jj)},...
        {U((jj-1)*nl+1:jj*nl,1:ii),V((jj-1)*nl+1:jj*nl,1:ii),P((jj-1)*nl+1:jj*nl,1:ii)});
%     [CC(ii),MAE(:,ii),bias(:,ii),out,coef]=compareModelObs_fitv({uin(:,jj),vin(:,jj),upin(:,jj),vpin(:,jj)},...
%         {U((jj-1)*nl+1:jj*nl,1:ii),V((jj-1)*nl+1:jj*nl,1:ii)});%,Uph((jj-1)*nl+1:jj*nl,1:ii),Vph((jj-1)*nl+1:jj*nl,1:ii)
    
end
[CC(ii+1),MAE(:,ii+1),bias(:,ii+1),out,coef]=compareModelObs_fitv({uin(:,jj),vin(:,jj),pin(:,jj),upin(:,jj),vpin(:,jj),ppin(:,jj)},...
    {U((jj-1)*nl+1:jj*nl,[1 3]),V((jj-1)*nl+1:jj*nl,[1 3]),P((jj-1)*nl+1:jj*nl,[1 3])});%,Uph((jj-1)*nl+1:jj*nl,[1 3]),Vph((jj-1)*nl+1:jj*nl,[1 3])

table2(:,1)=[table(:,1);NaN;real(CC(:))];
table2(:,2)=[table(:,2);NaN;imag(CC(:))];
table2(:,3)=[table(:,3);NaN;MAE(1,:)'./1e-2];
table2(:,4)=[table(:,4);NaN;MAE(2,:)'./1e-2];
table2(:,5)=[table(:,5);NaN;bias(1,:)'./1e-2];
table2(:,6)=[table(:,6);NaN;bias(2,:)'./1e-2];
table=table2;clear table2
end
