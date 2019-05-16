function updateIL(inMat,inXLSX,inSheet,outMat,ScaleFactor)

% function to update clamped-on instruments in existing moordesign mat file
% from list of instruments with label and heights.
% e.g. updateIL('T330_111218.mat','Mooring_List.xlsx','T330','T330_111218_upd.mat')

[num,txt,raw]=xlsread(inXLSX,inSheet);
[num,txt,~]=xlsread(inXLSX,inSheet,'A1:C10000');

% load(inMat)
load('mdcodes.mat')
% add " so I can strcmp
md{1}=cellstr(miscs(:,1:18));
md{2}=cellstr(chains(:,1:18));
md{3}=cellstr(cms(:,1:18));
md{4}=cellstr(floats(:,1:18));
md{5}=cellstr(wires(:,1:18));
md{6}=cellstr(anchors(:,1:17));
md{7}=cellstr(acrels(:,1:18));
mdv{1}=str2num(miscs(:,19:end));
mdv{2}=str2num(chains(:,19:end));
mdv{3}=str2num(cms(:,19:end));
mdv{4}=str2num(floats(:,19:end));
mdv{5}=str2num(wires(:,19:end));
mdv{6}=str2num(anchors(:,18:end));
mdv{7}=str2num(acrels(:,19:end));

tmp='                       ';

if isempty(str2num(raw{1,2}))
    st=2;
else
    st=1;
end
en=size(txt,1);
H(1,:)=([raw{st:en,2}]);
ME=H;
ME(~isnan(ME))=1.38e11;
ME(isnan(ME))=Inf;

SerialIL=raw(st:en,4);

for ii=st:size(txt,1)
    if isempty(txt{ii,1})
        break
    elseif length(txt{ii,1})<18
        moorele(ii-(st-1),:)=[txt{ii,1},tmp(1:18-length(txt{ii,1}))];
    else
        moorele(ii-(st-1),:)=txt{ii,1}(1:18);
        txt{ii,1}=txt{ii,1}(1:18);
    end
    
    for jj=1:length(md)
        [~,ind]=ismember({strtrim(txt{ii,1})},strtrim(md{jj}));
        if ind>0
            break
        end
    end
    if jj==length(md) && ind==0
        error('Could not find match for %s!',txt{ii,1})
    end
    
    B(1,ii-(st-1))=mdv{jj}(ind,1);    
    if jj==2
        H(4,ii-(st-1))=2;
    end
    if isnan(H(1,ii-(st-1)))
        H(1:3,ii-(st-1))=mdv{jj}(ind,2:4)./100;
    else
        H(2:3,ii-(st-1))=mdv{jj}(ind,3:4)./100;
        H(4,ii-(st-1))=1;
    end
    
    Cd(1,ii-(st-1))=mdv{jj}(ind,5);
%     ME(1,ii-(st-1))=mdv{jj}(ind,end); it seems the indices in moordyn are
%     incorrect...

    typeM(ii-(st-1),1)=jj;
end
if ~strcmpi(inMat,outMat)
    copyfile(inMat,outMat)
end

save(outMat,'B','Cd','moorele','H','ME','typeM','SerialIL','md','mdv','-append')
if ScaleFactor~=1
    load(outMat,'U','V','W')
    U=U.*ScaleFactor;
    V=V.*ScaleFactor;
    W=W.*ScaleFactor;
    save(outMat,'U','V','W','-append')
end

Z=fliplr(cumsum(fliplr(H(1,:))));
if st==1
    raw=[raw,{Z}];
elseif st==2
    raw{1,3}='HASB';
    raw(st:en,1:3)=[raw(st:en,1:2),num2cell(Z')];
end

xlswrite(inXLSX,raw,inSheet);