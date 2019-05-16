clear all;close all;
% script to first update the in-line elements of a mooring, then update the
% clamped-on elements.
str='T330';
inMat=[str,'_1.0xVel.mat'];
inXLSX='Mooring_List.xlsx';
InLineSheet=[str(1:4),'_IL'];
ClampsSheet=[str(1:4),'_CO'];
clim=[1/1200 .4];
ScaleFactor=1.0;
outMat=[str,'_',sprintf('%2.1f',ScaleFactor),'xVel.mat'];
% note, for T150 I modified z to be within 0 and 150 by 'squeezing'.

%% compute
% this updates the in-line mooring elements based on the input excel file
updateIL(inMat,inXLSX,InLineSheet,outMat,ScaleFactor)

if exist('ClampsSheet','var')
    % this updates the clamped on elements, 'ClampsSheet' is defined.
    updateCO(outMat,inXLSX,ClampsSheet,outMat)
end
% this simply plots the mooring
plot_mooring(outMat,[outMat(1:end-4),'_design.pdf'])

loadmd(outMat)

%% run movie
makemovie(101)
savemovie([outMat(1:end-4),'_movie.mat'])

% check anchor weight from all timesteps
global WoBts gammats
fprintf('\n********\n')
fprintf('Minimum weight under anchor is %5.1f.\n',max(WoBts))
fprintf('Max surface buoyancy is %5.1f, 95th percentile is %3.1f.\n\n',max(gammats)*100,prctile(gammats,95)*100)
if any(WoBts>-50)
    warning('Anchor might be too light with weight under anchor of %5.1f!',max(WoBts))
end
close;clear global 

% plot mooring statistics
table=moor_stats([outMat(1:end-4),'_movie.mat'],[outMat(1:end-4),'_stats.png'],clim,outMat);

% write statitstics to excel file as added sheet
xlswrite(inXLSX,table,[InLineSheet,'_stats'],['A1:',char(size(table,2)+96),num2str(size(table,1))]);

%% simple calc to determine if all floats will be on surface during mooring retrieval
% For subsurface deployment only.
% Essentially if there's too much weight on floats then they won't be on
% the surface during the retrieval and could move underneath the ship,
% wrapping around propelors, etc. This calc isn't perfect, but gives some
% estimate.
load(outMat,'B','BCO','ZCO','H')
Z=fliplr(cumsum(fliplr(H(1,:))));
[zall,zi]=sort([Z ZCO],'descend');
Ball=[B BCO];
Ball=Ball(zi);

ind=find(Ball>1);
% remove consecutive floats
tmp=[0 diff(ind)];
ind=ind(tmp~=1);
ind=[ind length(Ball)-1];
for ii=1:length(ind)-1
    % sum all elements between buoyancy, including top float
    Bsum(ii)=sum(Ball(ind(ii):ind(ii+1)));
end

if any(Bsum<0)
    warning('Mooring section is too heavy! %i float/s will not surface during retrieval!',length(find(Bsum<0)))
end