function [yearday]=jday(mattime)

[Y,~,~]=datevec(mattime(1));
yearday=mattime-datenum(Y,1,1)+1;