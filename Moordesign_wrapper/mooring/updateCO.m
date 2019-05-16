function updateCO(inMat,inXLSX,inSheet,outMat)

% function to update clamped-on instruments in existing moordesign mat file
% from list of instruments with label and heights.
% e.g. updateCO('T330_111218.mat','Mooring_List.xlsx','T330','T330_111218_upd.mat')

[num,txt,raw]=xlsread(inXLSX,inSheet);

load(inMat)
load('mdcodes.mat')
md=cellstr(miscs(:,1:16));
mdv=str2num(miscs(:,18:end));

clear *CO *obj
tmp='                       ';

if isempty(str2num(raw{1,2}))
    st=2;
else
    st=1;
end
en=size(txt,1);

ZCO=raw(st:en,2)';
ZCO=[ZCO{:}];
Z=fliplr(cumsum(fliplr(H(1,:))));
[allz,I]=sort([Z(:)' ZCO],'descend');


SerialCO=raw(st:en,3);

for ii=st:en
    if length(txt{ii})<16
        mooreleCO(ii-(st-1),:)=[txt{ii},tmp(1:16-length(txt{ii}))];
    else
        mooreleCO(ii-(st-1),:)=txt{ii}(1:16);
    end
    
    [~,n]=ismember({strtrim(txt{ii})},md);
    
    if n==0
        error('Could not find match for %s!',txt{ii,1})
    end
    
%     for jj=1:size(miscs,1)
%         n=strcmpi(mooreleCO(ii,:),miscs(jj,1:16));
%         if n==1
%             break
%         end
%     end
    BCO(1,ii-(st-1))=mdv(n,1);
    HCO(1:2,ii-(st-1))=mdv(n,2:3)./100;%str2num(miscs(jj,26:31))/100;
    HCO(3:4,ii-(st-1))=0;
%     =str2num(miscs(jj,39:43));
    CdCO(1,ii-(st-1))=mdv(n,5);%str2num(miscs(jj,45:48));
    
    % now find what it attaches to
    Iobj(ii-(st-1),1)=find((ii-(st-1)+length(Z)) == I);
    if all(Z<ZCO(ii-(st-1)))
        warning(['Item at ',num2str(ZCO(ii-(st-1))),...
            ' m ASB is above top float at a height of ',num2str(max(Z)),' m. Moving it down.'])
        ZCO(ii-(st-1))=max(Z)-1;
    end
    Jobj(ii-(st-1),1)=find(Z>ZCO(ii-(st-1)),1,'last');
    dz=ZCO(ii-(st-1))-Z(min([Jobj(ii-(st-1))+1 length(Z)]));
    Pobj(ii-(st-1),1)=dz/H(1,Jobj(ii-(st-1),1)); % percentage of length along Jobj where we've clamped.
end
if all(inMat~=outMat)
    copyfile(inMat,outMat)
end
save(outMat,'*CO','*obj','-append')