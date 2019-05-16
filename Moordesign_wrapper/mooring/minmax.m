function mm = minmax(x)
% [m,n]=size(x);
% if m>1 & n>1
    mm(:,1)=min(x,[],2);
    mm(:,2)=max(x,[],2);
% else
%     mm(1)=min(x)
% end