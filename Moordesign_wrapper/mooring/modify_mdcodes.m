load('mdcodes.mat')
% example below for miscellaneous elements.
tmp='Empty (UWA)';% name, up to 16 characters. 
miscs(end+1,1:min([length(tmp) 16]))=tmp;
miscs(end,50)='1';%steel=1, etc.
miscs(end,45:48)=sprintf('%3.2f',1.3);% drag coefficient
miscs(end,41:43)=sprintf('%2.1f',0);%set to 0 for circular elements
miscs(end,35:37)=sprintf('%3.1f',.1);%width
miscs(end,28:31)=sprintf('%4.1f',.1);%height
miscs(end,20:25)=sprintf('%5.3f',-1);%Buoyancy (kg)
save('mdcodes.mat')