function [lon,lat,depth,name,alpha]=TSHELF_siteinfo(mooring)

% The lander adv is .3 above seafloor and says depth is 181.918m. I should
% double check all depths! Old lander value was 188m

label={'WW_shallow','bore_shallow','WW_Deep','bore_deep','shelf_break','lander','T4','T7','T3','T2','T1'};
allname={'W10','M17','W21','M25','M29','L29','M32','T7','M44','T2','T1'};
lon_all=[148.39953 148.48845 148.534567 148.57603 148.63175 148.6314 148+39.807/60 148.9542 148+49.489/60 149+1.019/60 148+59.294/60];
lat_all=[-41.4134167 -41.4005167 -41.38543 -41.39163 -41.38385 -41.3865 -41-23.320/60 -41.6990 -41-20.661/60 -41-20.049/60 -41-20.077/60];
% dpth=[80 105 114 115 184 181.918 467];
dpth=[80 108.66 114 117.37 184.78 182.1 478 1685 1216 1889 1978];%1505 1199 1957 1978, did have T4 as 467 but that was wrong
a=[0.0078 0.0007 0.0020 0.0016 0.0485 0.0443 0.1339 0.0435 1 1 1];% for 3 km width

% WW shallow ADCP:
% -41.41081667 148.3977
% WW Deep ADCP:
% -41.38296667	148.5363333 ?? (mooring;-41.38543333	148.5345667)


% used below code to calc dpth
% load('D:\Dropbox\TSHELF_2015\TSHELF_Data\Bathymetry\TTide_all_RR_legs_merge_multibeam_oz_50_TSmod.mat')
% [~,nx]=min(abs(lon(mm)-merge.lon));
% [~,ny]=min(abs(lat(mm)-merge.lat));
% dpth(mm)=-double(merge.D_TS(ny,nx));
% z=-double(merge.D_TS(ny,nx-dind:nx+dind));
% % ~3km
% distance=lldistkm([merge.lat(ny) merge.lon(nx-dind)],[merge.lat(ny) merge.lon(nx+dind)])*1000;
% alpha(mm)=((z(end)-z(1))./distance);%deg

if iscell(mooring)
    for mm=1:length(mooring)
        ind=strcmpi(mooring{mm},label);
        if isempty(ind)
            error([mooring{mm},' is not a correct name! Use: %s',label])
        end
        lon(mm)=lon_all(ind);
        lat(mm)=lat_all(ind);
        depth(mm)=dpth(ind);
        alpha(mm)=a(ind);
        name{mm}=allname{ind};
    end
else
    ind=strcmpi(mooring,label);
    if isempty(ind)
        error([mooring,' is not a correct name! Use: %s',label])
    end
    lon=lon_all(ind);
    lat=lat_all(ind);
    depth=dpth(ind);
    alpha=a(ind);
    name=allname{ind};
end