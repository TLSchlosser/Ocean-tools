ncfiles={'Y:\DATA\FIELD\RowleyShoals\SUNTANS_12_month_stations\NWS_2km_hex_20140301_Station.nc',...
    'Y:\DATA\FIELD\RowleyShoals\SUNTANS_12_month_stations\NWS_2km_hex_20140401_Station.nc',...
    'Y:\DATA\FIELD\RowleyShoals\SUNTANS_12_month_stations\NWS_2km_hex_20140501_Station.nc'};
nci=ncinfo('Y:\DATA\FIELD\RowleyShoals\SUNTANS_12_month_stations\NWS_2km_hex_20140301_Station.nc');

name={'330a','330b','330c','200a','200b','200c','150a','150b','150c','150d','150e','150f'};

for ii=8
    time=[];
    T=[];
    S=[];
    U=[];
    V=[];
    
    z=ncread(ncfiles{1},'Nk');
    lon=ncread(ncfiles{1},'lonv',2,1);
    lat=ncread(ncfiles{1},'latv',2,1);
    
    for jj=1:length(ncfiles)
        time=[time,ncread(ncfiles{jj},'time')'/3600/24+datenum(1990,1,1)];
        T=[T,squeeze(ncread(ncfiles{jj},'temp',[ii 1 1],[1 inf inf]))];
        S=[S,squeeze(ncread(ncfiles{jj},'salt',[ii 1 1],[1 inf inf]))];
        U=[U,squeeze(ncread(ncfiles{jj},'uc',[ii 1 1],[1 inf inf]))];
        V=[V,squeeze(ncread(ncfiles{jj},'vc',[ii 1 1],[1 inf inf]))];
    end
    
    rho=sw_dens(S,T,S.*0);
    
    indz=~isnan(U(:,1));
    U=U(indz,:);
    V=V(indz,:);
    rho=rho(indz,:);
    z=max(z(indz))-z(indz);% Z is HASB not depth!
    T=nanmean(T(indz,:),2);
    S=nanmean(S(indz,:),2);
    
%     % extend current to bottom
%     U=[U;U(end,:)];
%     V=[V;V(end,:)];
%     rho=[rho;rho(end,:)];
%     z=[z;-330];
    
    W=U.*0;
    
    save(['T',name{ii}(1:end-1),'_121218_150b.mat'],'U','V','W','rho','z','time','lon','lat','T','S','-append');
end