load('mdcodes.mat')
miscs(end+1,1:11)='Empty (UWA)';
miscs(end,50)='1';
miscs(end,45:48)=sprintf('%3.2f',1.3);
miscs(end,41:43)=sprintf('%2.1f',0);
miscs(end,35:37)=sprintf('%3.1f',.1);%width
miscs(end,28:31)=sprintf('%4.1f',.1);%height
miscs(end,20:25)=sprintf('%5.3f',-1);%B
save('mdcodes.mat')