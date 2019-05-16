function [ vel_comp_matrix_new ] = TSHELF_replace_NaNs_ADCP_data(vel_comp_matrix, t,z,extrap_flag,nan_perc,interp_type)
%replacing_NaNs_ADCP_data is used to replace any NANs that result from ADCP
%data being processed using RDI_ADCP and clean_ADCP. 
%
%vel_comp_matrix- rows are velocities at depths, column is for sequential samples in time
%dt- time between samples in days

if nargin<4
    extrap_flag=0;
end
if nargin<5
    nan_perc=.08;
end
if nargin<6
    interp_type='linear';
end

AS=vel_comp_matrix;
nan_ind=find(sum(isnan(AS),2)/size(AS,2)<=nan_perc);

% [t,z]=meshgrid(t,z);
%
z_ind=~isnan(AS);

for nn=nan_ind'
     if sum(isnan(AS(nn,:)))>0
         % first time interp
       ind=  find(~isnan(AS(nn,:)));
       ind2=  find(isnan(AS(nn,:)));
       AS_interp_z=ones(length(t),1)*NaN;
       if extrap_flag
           AS_interp_t=interp1(t(ind),AS(nn,ind),t,interp_type,'extrap');
           for mm=ind
                % next space interp
                AS_interp_z(mm)=interp1(z(z_ind(:,mm)),AS(z_ind(:,mm),mm),z(nn),interp_type,'extrap');
           end
       else
            AS_interp_t=interp1(t(ind),AS(nn,ind),t,interp_type);       
            for mm=ind
                if sum(z_ind(:,mm))>1
                    % next space interp
                    AS_interp_z(mm)=interp1(z(z_ind(:,mm)),AS(z_ind(:,mm),mm),z(nn),interp_type);
                end
            end
       end
       [m,~]=size(AS_interp_t);
       if m==1
           AS_interp_t=AS_interp_t';
       end
        AS_interp=nanmean([AS_interp_t,AS_interp_z],2);
        AS(nn,ind2)=AS_interp(ind2);
     end
end

vel_comp_matrix_new=AS;

end
