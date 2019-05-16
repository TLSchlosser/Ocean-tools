clear all;close all;
load('T330_111218_movie.mat')
figure('position',[10.0013    4.8154    8.3079   18])

%% tilt
for zz=1:length(nanmean(Zts'))
[N(zz,:),EDGES] = histcounts(psits(zz,:).*180/pi,[0:2.5:15 inf],'Normalization','probability');
end
% it looks like it need to be flipped!
subplot(4,1,1)
contourf(EDGES(1:end-1),nanmean(Zts'),(N),0:.01:1,'EdgeColor','none');
ylabel('HASB')
xlabel('tilt (degrees)')
title('T330 Design- March to May (%)')
caxis([0 1])

%% dropdown
clear N
for zz=1:length(nanmean(Zts'))
[N(zz,:),EDGES] = histcounts(abs(Zts(zz,:)-nanmean(Zts(zz,:))),[0:0.5:5 inf],'Normalization','probability');
end

subplot(4,1,2)
contourf(EDGES(1:end-1),nanmean(Zts'),(N),'EdgeColor','none');
ylabel('HASB')
xlabel('Dropdown (m)')
title('T330 Design- March to May (%)')
caxis([0 1])

%% Y displacement
clear N
for zz=1:length(nanmean(Zts'))
[N(zz,:),EDGES] = histcounts(abs(Yts(zz,:)-nanmean(Yts(zz,:))),[0:2:30 inf],'Normalization','probability');
end

subplot(4,1,3)
contourf(EDGES(1:end-1),nanmean(Zts'),(N),'EdgeColor','none');
ylabel('HASB')
xlabel('Y-displacement (m)')
title('T330 Design- March to May (%)')
caxis([0 1])

%% X displacement
clear N
for zz=1:length(nanmean(Zts'))
[N(zz,:),EDGES] = histcounts(abs(Xts(zz,:)-nanmean(Xts(zz,:))),[0:2:30 inf],'Normalization','probability');
end

subplot(4,1,4)
contourf(EDGES(1:end-1),nanmean(Zts'),(N),'EdgeColor','none');
ylabel('HASB')
xlabel('X-displacement (m)')
title('T330 Design- March to May (%)')
caxis([0 1])

colorbar('position',[.1 .05 .8 .02],'Orientation','horizontal')

print T330_tilt_displacement.png -dpng -r300


% pcolor(jday(time),nanmean(Zts'),Zts);shading flat