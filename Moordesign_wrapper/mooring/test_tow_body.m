% clear;
close
figure('position',[5 5 6 12])

outMat='tow_test.mat';
loadmd(outMat)

load(outMat)
Bt(3)=-60;

Ws=0:1:2;
for ii=1:length(Ws)

for tt=1:length(time)
    [X(:,tt),Y(:,tt),Z(:,tt),iobj(:,tt),psi(:,tt),Wa(tt)]=towdyn(U(:,tt)*1.0,z,Ht,Bt,Cdt,MEt,...
        V(:,tt)*1.0,W(:,tt),rho(:,tt),Usp,Vsp,Ws(ii),0);
end

subplot(length(Ws),1,ii)
for zz=1:length(nanmean(Z'))
[N(zz,:),EDGES] = histcounts(180-psi(zz,:)*180/pi,[0:1:20 inf],'Normalization','probability');
end
contourf(EDGES(1:end-1),-nanmean(Z'),N,0:.01:.4,'EdgeColor','none');

% pcolor(jday(time),-nanmean(Z'),180-psi*180/pi);shading flat
axis tight
xlabel('\theta (%)')
title(['Ws = ',num2str(Ws(ii)),'m/s. Surface tension = ',num2str(max(round(Wa))),' kg'])
caxis([0 .4]);
end

colorbar('position',[.05 .04 .8 .02],'orientation','horizontal')
print WW_test_60kg_weight_x1vel.png -dpng -r300