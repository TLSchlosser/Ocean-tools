clear

moorings={'WW_Deep','shelf_break','bore_deep','T4','WW_Shallow','bore_shallow','T3','T1'};%,'T7'
SNR_thresh=3;
load('..\Density_parameters.mat')

[~,lat,depth,~,~]=TSHELF_siteinfo(moorings);
Temp_tc=[0 40/24];
force_run=[0 0 0 0 0 0];
% UV p_pet rho_pet eta dT N

for mm=7;%[1 4:length(moorings)]
    
    % try and fit harmonics using Shroyer 2011 approach...
    % u(t) = u_0 + sigma(1to 3)[ a_i*cos(2*pi()*w_i*t) + b_i*sin(2*pi()*w_i*t)]+u_r
    label=moorings{mm};
    
    % using "Data Analysis Methods in Physical Methodology"
    T=3;%days
    f=sw_f(lat(mm));
    T_inertial=2*pi/f/3600; %in hours
    f_q=[0.0805114 1/T_inertial 0.0417807];%/hour M2 f K1
    
    folder=['.\NewSep_Op4_Total_SNR_thresh_',num2str(SNR_thresh),'_Days_',num2str(T),'\'];
    mkdir(folder)
    
    if exist([folder,label,'_HA.mat'],'file')
        matObj = matfile([folder,label,'_HA.mat']);
        details=whos(matObj,'HA_u');
    else
        details=[];
    end
    
    if force_run(1)==1 || (isempty(details) && exist(['..\',label,'_Currents_noNaNs.mat'],'file'))
        disp('Processing currents...')
        load(['..\',label,'_Currents_noMeso.mat'])

        HA_u=HarmAnalysis_nonstationary(mattime,UVEL-Meso.east,f_q,T,SNR_thresh);
        HA_v=HarmAnalysis_nonstationary(mattime,VVEL-Meso.north,f_q,T,SNR_thresh);
        HA_u.HASB=HASB;
        HA_v.HASB=HASB;
%         HA_u_bc.u_ba=BT.east;
%         HA_v_bc.v_ba=BT.north;
        
        if exist([folder,label,'_HA.mat'],'file')
            save([folder,label,'_HA.mat'],'HA_u','HA_v','-append')
            clear HA_u HA_v
        else
            save([folder,label,'_HA.mat'],'HA_u','HA_v')
            clear HA_u HA_v
        end
    elseif exist(['..\',label,'_Currents_noMeso.mat'],'file')
        load(['..\',label,'_Currents_noMeso.mat'])
        cHASB=HASB;
    end

    %% I also want to do pressure

    if exist([folder,label,'_HA.mat'],'file')
        matObj = matfile([folder,label,'_HA.mat']);
        details=whos(matObj,'HA_p_pet');
    else
        details=[];
    end

    if force_run(2)==1 || (isempty(details) && exist(['..\',label,'_Temperature_noNaNs.mat'],'file'))
        disp('Processing pressure...')
        load(['..\',label,'_Temperature_noNaNs.mat'])
        [T_mat]=TSHELF_replace_NaNs_ADCP_data(T_mat,Ttime,HASB,1,1);

        if ~exist('mattime','var')
            mattime=Ttime(1):2/60/24:Ttime(end);
        else
            mattime=[mattime(:)',mattime(end)+2/60/24:2/60/24:Ttime(end)];
        end
        if ~exist('cHASB','var')
            cHASB=min(HASB):2:max(HASB);
        end

        [T_mat2,Tlf]=TSHELF_prepTemp(Ttime,T_mat,HASB,Temp_tc,mattime,cHASB);
        tHASB=HASB;
        HASB=cHASB;
        clear tmp tmplf

        rho_lf=polyval(ALL_p,Tlf);
        rho=polyval(ALL_p,T_mat2);

        rho_pet=rho-rho_lf;

        % next calc surface pressure
        P_z=-depth(mm)+HASB(:)';
        if P_z(end)>P_z(1)
            P_z=fliplr(P_z);
            rho_pet=flipud(rho_pet);
            HASB=flipud(HASB(:));
        end

        % finally pressure peterbation
        p_pet=9.81*cumtrapz(-[0 P_z],[rho_pet(1,:);rho_pet]);
        p_pet=p_pet(2:end,:);%-repmat(mean(p_pet(2:end,:)),length(P_z),1);
        
        % now add surface perturbation
        pbot=load('..\WW_deep_Currents_NaNs.mat','totaldepth','mattime');
        p_pet=p_pet+repmat(interp1(pbot.mattime,1026*9.81.*pbot.totaldepth,mattime),length(HASB),1);%rho_0*g*eta

        HA_p_pet=HarmAnalysis_nonstationary(mattime,p_pet,f_q,T,SNR_thresh);
        HA_p_pet.HASB=HASB;
        HA_p_pet.note='no baroclinicity condition applied';

        if exist([folder,label,'_HA.mat'],'file')
            save([folder,label,'_HA.mat'],'HA_p_pet','-append')
        else
            save([folder,label,'_HA.mat'],'HA_p_pet')
        end
        clear HA_p_pet
    elseif exist(['..\',label,'_Temperature_noNaNs.mat'],'file')
        load(['..\',label,'_Temperature_noNaNs.mat'])
        [T_mat]=TSHELF_replace_NaNs_ADCP_data(T_mat,Ttime,HASB,1,1);
        if ~exist('mattime','var')
            mattime=Ttime(1):2/60/24:Ttime(end);
        end
    end
    %% density perturbation

    if exist([folder,label,'_HA.mat'],'file')
        matObj = matfile([folder,label,'_HA.mat']);
        details=whos(matObj,'HA_rho_pet');
    else
        details=[];
    end

    if force_run(3)==1 || (isempty(details) && exist(['..\',label,'_Temperature_noNaNs.mat'],'file'))
        disp('Processing density perturbation...')
        load(['..\',label,'_Temperature_noNaNs.mat'])
        [T_mat]=TSHELF_replace_NaNs_ADCP_data(T_mat,Ttime,HASB,1,1);

        if ~exist('mattime','var')
            mattime=Ttime(1):2/60/24:Ttime(end);
        else
            mattime=[mattime(:)',mattime(end)+2/60/24:2/60/24:Ttime(end)];
        end
        if ~exist('cHASB','var')
            cHASB=min(HASB):2:max(HASB);
        end

        [T_mat2,Tlf]=TSHELF_prepTemp(Ttime,T_mat,HASB,Temp_tc,mattime,cHASB);
        tHASB=HASB;
        HASB=cHASB;
        clear tmp tmplf

        rho_lf=polyval(ALL_p,Tlf);
        rho=polyval(ALL_p,T_mat2);

        rho_pet=rho-rho_lf;

        HA_rho_pet=HarmAnalysis_nonstationary(mattime,rho_pet,f_q,T,SNR_thresh);
        HA_rho_pet.HASB=HASB;
        HA_rho_pet.rholf=rho_lf;

        if exist([folder,label,'_HA.mat'],'file')
            save([folder,label,'_HA.mat'],'HA_rho_pet','-append')
        else
            save([folder,label,'_HA.mat'],'HA_rho_pet')
        end
        clear HA_rho_pet
    end
%     %% then isotherm displacement (eta)
%     if exist([folder,label,'_HA.mat'],'file')
%         matObj = matfile([folder,label,'_HA.mat']);
%         details=whos(matObj,'HA_eta');
%     else
%         details=[];
%     end
% 
%     if force_run(4)==1 || (isempty(details) && exist(['..\',label,'_Temperature_noNaNs.mat'],'file'))
%         if ~exist('Tlf','var')
%             if ~exist('mattime','var')
%                 mattime=Ttime(1):2/60/24:Ttime(end);
%             else
%                 mattime=[mattime(:)',mattime(end)+2/60/24:2/60/24:Ttime(end)];
%             end
%             if ~exist('cHASB','var')
%                 cHASB=min(HASB):2:max(HASB);
%             end
% 
%             [T_mat2,Tlf]=TSHELF_prepTemp(Ttime,T_mat,HASB,Temp_tc,mattime,cHASB);
%             tHASB=HASB;
%             HASB=cHASB;
%             clear tmp tmplf
%         end
%         [dT_dt,dT_dz] = gradient(Tlf,mattime,depth(mm)+HASB);
%         % moving average of dT_dz
%         HASB1=conv(HASB, ones(1,5), 'valid')./5;
%         clear dT_dz1 dT_dz2
%         for tt=1:length(mattime)
%             % ave over 5 depth points (20m)
%             dT_dz1(:,tt)=conv(dT_dz(:,tt), ones(1,5), 'valid')./5;
%             dT_dz(:,tt)=interp1(HASB1,dT_dz1(:,tt),HASB,'linear','extrap');
%         end
%         % ave over 3 days
%         Tind=round(3./median(diff(mattime)));
%         time2=conv(mattime, ones(1,Tind), 'valid')./Tind;
%         for zz=1:length(HASB)
%             dT_dz2(zz,:)=conv(dT_dz(zz,:), ones(1,Tind), 'valid')./Tind;
%             dT_dz(zz,:)=interp1(time2,dT_dz2(zz,:),mattime,'linear','extrap');
%         end
% 
%         eta=(T_mat2-Tlf)./dT_dz;
% 
%         disp('Processing eta...')
%         HA_eta=HarmAnalysis_nonstationary(mattime,eta,f_q,T,SNR_thresh);
%         HA_eta.HASB=HASB;
% 
%         save([folder,label,'_HA.mat'],'HA_eta','-append')
%         clear HA_eta
%     end
% 
    %% temp diff
    if exist([folder,label,'_HA.mat'],'file')
        matObj = matfile([folder,label,'_HA.mat']);
        details=whos(matObj,'HA_dT');
    else
        details=[];
    end

    if force_run(5)==1 || (isempty(details) && exist(['..\',label,'_Temperature_noNaNs.mat'],'file'))
        if ~exist('Tlf','var')
            if ~exist('mattime','var')
                mattime=Ttime(1):2/60/24:Ttime(end);
            else
                mattime=[mattime(:)',mattime(end)+2/60/24:2/60/24:Ttime(end)];
            end
            if ~exist('cHASB','var')
                cHASB=min(HASB):2:max(HASB);
            end

            [T_mat2,Tlf]=TSHELF_prepTemp(Ttime,T_mat,HASB,Temp_tc,mattime,cHASB);
            tHASB=HASB;
            HASB=cHASB;
        end

        dT=T_mat2-Tlf;

        disp('Processing temperature difference...')
        HA_dT=HarmAnalysis_nonstationary(mattime,dT,f_q,T,SNR_thresh);
        HA_dT.HASB=HASB;
        HA_dT.Tlf=Tlf;

        save([folder,label,'_HA.mat'],'HA_dT','-append')
        clear HA_dT
    end
% 
%     %% next nitrogen and salinity
%     if exist([folder,label,'_HA.mat'],'file')
%         matObj = matfile([folder,label,'_HA.mat']);
%         details=whos(matObj,'HA_S');
%     else
%         details=[];
%     end
% 
%     if isempty(details) && exist(['..\',label,'_Temperature_noNaNs.mat'],'file') && exist('S','var') 
%         disp('Processing salinity...')
%         S_interp=zeros(size(S,1),length(mattime));
%         for nn = 1:size(S,1)
%             S_interp(nn,:)=interp1(Ttime,S(nn,:),mattime,'linear','extrap');
%         end
%         HA_S=HarmAnalysis_nonstationary(mattime,S_interp,f_q,T,SNR_thresh);
%         HA_S.HASB=HASB;
%         save([folder,label,'_HA.mat'],'HA_S','-append')
%     end
% 
%     if exist([folder,label,'_HA.mat'],'file')
%         matObj = matfile([folder,label,'_HA.mat']);
%         details=whos(matObj,'HA_NT');
%     else
%         details=[];
%     end
% 
%     if force_run(6)==1 || (isempty(details) && exist(['..\',label,'_Temperature_noNaNs.mat'],'file'))
%         disp('Processing nitrogen...')
%         if ~exist('NT','var')
%             warning('Using South Africa T-N relationship')
%             NT=zeros(size(T_mat));
%             NT(T_mat<16)=T_mat(T_mat<16)*-4.5+4.5*16;
%         end
%         NT2=zeros(size(NT,1),length(mattime));
%         for nn = 1:size(NT,1)
%             NT2(nn,:)=interp1(Ttime,NT(nn,:),mattime,'linear','extrap');
%         end
%         HA_NT=HarmAnalysis_nonstationary(mattime,NT2,f_q,T,SNR_thresh);
%         HA_NT.HASB=HASB;
% 
%         save([folder,label,'_HA.mat'],'HA_NT','-append')
%         clear HA_NT
%     end
%     clear S NT T_mat mattime

end