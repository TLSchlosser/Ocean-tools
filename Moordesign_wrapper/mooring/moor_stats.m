function table=moor_stats(moviefile,outPNG,clim,moormat)
load(moviefile)
figure('position',[10.0013    4.8154    8.3079   18])
zplt=sort(nanmean(Zts'),'descend');
%% tilt
for zz=1:length(zplt)
[N(zz,:),EDGES] = histcounts(psits(zz,:).*180/pi,[0:2.5:17.5 inf],'Normalization','probability');
end
% it looks like it need to be flipped!
subplot(4,1,1)
contourf(EDGES(1:end-1),zplt,(N),clim(1):diff(clim)/20:clim(2),'EdgeColor','none');
ylabel('HASB')
xlabel('tilt (degrees)')
title('%')
caxis(clim)

%% dropdown
clear N
for zz=1:length(zplt)
[N(zz,:),EDGES] = histcounts(abs(Zts(zz,:)-nanmean(Zts(zz,:))),[0:0.5:5 inf],'Normalization','probability');
end

subplot(4,1,2)
contourf(EDGES(1:end-1),zplt,(N),clim(1):diff(clim)/20:clim(2),'EdgeColor','none');
ylabel('HASB')
xlabel('Dropdown (m)')
title('%')
caxis(clim)

%% Y displacement
clear N
for zz=1:length(zplt)
[N(zz,:),EDGES] = histcounts(abs(Yts(zz,:)),[0:2:30 inf],'Normalization','probability');
end

subplot(4,1,3)
contourf(EDGES(1:end-1),zplt,(N),clim(1):diff(clim)/20:clim(2),'EdgeColor','none');
ylabel('HASB')
xlabel('Y-displacement (m)')
title('%')
caxis(clim)

%% X displacement
clear N
for zz=1:length(zplt)
[N(zz,:),EDGES] = histcounts(abs(Xts(zz,:)),[0:2:30 inf],'Normalization','probability');
end

subplot(4,1,4)
contourf(EDGES(1:end-1),zplt,(N),clim(1):diff(clim)/20:clim(2),'EdgeColor','none');
ylabel('HASB')
xlabel('X-displacement (m)')
title('%')
caxis(clim)

colorbar('position',[.1 .05 .8 .02],'Orientation','horizontal')

print(outPNG,'-dpng','-r300')

%% now some stats listed
load(moormat)

psits=psits*180/pi;
Z=fliplr(cumsum(fliplr(H(1,:))));
count=2;

table{1,1}='Element';
table{1,2}='Max tilt (deg)';
table{1,3}='Ind of max';
table{1,4}='99th prctile tilt';
table{1,5}='Number time steps exceeding 15 deg';
for ii=1:length(typeM)
    if typeM(ii)==3 || contains(moorele(ii,:),'Monitor') || contains(moorele(ii,:),'Sentinel') ||...
            contains(moorele(ii,:),'75kHz') || contains(moorele(ii,:),'150kHz') || contains(moorele(ii,:),'ADV') ||...
            contains(moorele(ii,:),'Signature')
        table{count,1}=moorele(ii,:);
        [~,zind]=min(abs(mean(Zts')-Z(ii)));
        [table{count,2},table{count,3}]=max(psits(zind,:));
        table{count,4}=prctile(psits(zind,:),99);
        table{count,5}=length(find(psits(zind,:)>=15));
        count=count+1;
    end
end
% pcolor(jday(time),zp,Zts);shading flat