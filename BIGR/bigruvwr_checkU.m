
function [u,v,wvel,rho] = bigruvwr(ww,BB)

%   Compute u, v, w and rho once the pressure is known
%   ww is the frequency and BB is the pressure vector

%   7/16/2003, 12/23/2004, 2/1/2006

%  Mar 2018 RCM made changes to output fields and fluxes

global nn mm dx dt rl f vm vmx n2 m2 h hx ilong

w = ww;

u = 0*ones(nn-2,mm-2);
v = u;
wvel = u;
rho = u;
ptop = 0*ones(nn-2);

% Max ratio of real/imag or imag/real to allow plotting of the smaller 
%ratnplot = 1000;

g = 980;
rhob = 1.03;
dt2 = 2*dt;
dx2 = 2*dx;
th = -1 + dt*(0:(mm-3));

for n = 1:(nn-2)
    
    irow = (n*mm + 2):((n+1)*mm -1);
    wp = w + rl*vm(n,:);
    m2n2 = m2(n,:)./n2(n,:);
    fs = f + vmx(n,:) - m2(n,:).*m2n2/f;
    fsw = f*fs - ilong*wp.*wp;
    thx = -(hx(n)/h(n))*th;
    
    ptop(n) = BB((n+1)*mm-1);
    p = BB(irow);
    pt = (BB(irow+1)-BB(irow-1))/dt2;
    pxp = (BB(irow+mm) - BB(irow-mm))/dx2;
       
    px = pxp + thx'.*pt;
    pz = pt/h(n);
        
   %u(n,:) = conj(((-i*conj(wp').*px - i*rl*f*p + i*conj((wp.*m2n2)').*pz)./fsw.')');
    v(n,:) = conj(((conj(fs').*px + ilong*rl*conj(wp').*p - ilong*(conj((wp.*wp).*m2n2)').*pz/f)./fsw.')');
    wvel(n,:) = conj((-conj((m2n2./fsw)').*(-i*conj(wp').*px - i*rl*f*p))');
    wtemp = ((conj(wp').*pz)./n2(n,:)').*(1 +conj(((m2n2.*m2(n,:))./fsw)'));
    wvel(n,:) = wvel(n,:) - i*conj(wtemp');
    rho(n,:) = conj((-pz/g)');
    
    u(n,:) = ((-i*(wp.').*px - i*rl*f*p -i*((wp.*m2n2).').*pz)./(fsw.')).';

    pp(n,:) = p;
end

% redo calcs in z-grid
[ppz,~]=sigtoextraz(pp,mm,nn,dt,h);
[vmz,~]=sigtoextraz(vm,mm,nn,dt,h);
[m2z,~]=sigtoextraz(m2,mm,nn,dt,h);
[n2z,~]=sigtoextraz(n2,mm,nn,dt,h);
[vmxz,zout]=sigtoextraz(vmx,mm,nn,dt,h);

xpl = dx*(0:nn-3);
[dpdz,~]=gradient(ppz,zout,xpl);
dpdx=(ppz(2:end,:)-ppz(1:end-1,:))./median(diff(xpl));
dpdx(end+1,:)=dpdx(end,:);

for n = 1:(nn-2)
    wp = w + rl*vmz(n,:);
    m2n2 = m2z(n,:)./n2z(n,:);
    fs = f + vmxz(n,:) - m2z(n,:).*m2n2/f;
    fsw = f*fs - ilong*wp.*wp;
%     thx = -(hx(n)/h(n))*th;
    
    p = ppz(n,:)';
%     pt = ppz(n+1,:)-ppz(n-1,:);%(BB(irow+1)-BB(irow-1));%/dt2;
%     pxp = ppz(n,1:end-1)-ppz(n,2:end)./dx2;%(BB(irow+mm) - BB(irow-mm))/dx2;
       
    px = dpdx(n,~isnan(dpdx(n,:)))';% + thx'.*pt;
    px=[px(1).*ones(mm*10-2-length(px),1);px];
    pz = dpdz(n,:)';%h(n);
        
   %u(n,:) = conj(((-i*conj(wp').*px - i*rl*f*p + i*conj((wp.*m2n2)').*pz)./fsw.')');
    vz(n,:) = conj(((conj(fs').*px + ilong*rl*conj(wp').*p - ilong*(conj((wp.*wp).*m2n2)').*pz/f)./fsw.')');
    wvelz(n,:) = conj((-conj((m2n2./fsw)').*(-i*conj(wp').*px - i*rl*f*p))');
    wtempz = ((conj(wp').*pz)./n2z(n,:)').*(1 +conj(((m2n2.*m2z(n,:))./fsw)'));
    wvelz(n,:) = wvelz(n,:) - i*conj(wtempz');
    rhoz(n,:) = conj((-pz/g)');
    
    uz(n,:) = ((-i*(wp.').*px - i*rl*f*p -i*((wp.*m2n2).').*pz)./(fsw.')).';

%     ppz(n,:) = p;
end
uz = uz/rhob;
vz = vz/rhob;
wvelz = wvelz/rhob;


%   Plot results
% map from sigma to z coordinates
[ug,~]=downsize_u(uz,zout);
[vg,~]=downsize_u(vz,zout);
[wg,~]=downsize_u(wvelz,zout);
[rhog,~]=downsize_u(rhoz,zout);
[pg,~]=downsize_u(ppz,zout);
[n2g,z]=downsize_u(n2z,zout);
z=z./100;
hh = -h/100;
xpl = dx*(0:nn-3)/1e5;
ax = [0 max(xpl) min(hh) 0];
% z = zout(1:100:end)./100;z=z(1:end-2);%th*max(h)/100;
xf = [0 xpl max(xpl) 0];
zf = [min(hh) hh min(hh) min(hh)];


% RCM: make horizontal profile of alongshore flux 
vp = mean(real(v).*real(pp),2).*-hh';

% say we'd done it using a baroclinic decomposition?
vbc = bsxfun(@minus,real(v),mean(real(v),2));
pbc = bsxfun(@minus,real(pp),mean(real(pp),2));
vbcpbc = mean(vbc.*pbc,2).*-hh';

figure(3)
clf
subplot(2,2,1)

[C,hhh] = contourf(xpl,z,imag(ug.'));
clabel(C,hhh)
hold on
axis(ax)
fill(xf,zf,'b')
title('u (Imaginary in red)');
ylabel('Depth (m)')
hold off
set(gca,'TickDir','out')

subplot(2,2,2)
[C,hhh] = contourf(xpl,z,real(vg.'));
clabel(C,hhh)
hold on
axis(ax)
fill(xf,zf,'b')
title('v (Real in black)');
hold off
set(gca,'TickDir','out')

subplot(2,2,3)
%[C,hhh] = contour(xpl,z,imag(wg.'),'r');
[C,hhh] = contourf(xpl,z,imag(wg.'));
clabel(C,hhh)
hold on
fill(xf,zf,'b')
title('w');
axis(ax)
xlabel('x (km)')
ylabel('Depth (m)')
hold off
set(gca,'TickDir','out')

subplot(2,2,4)
%[C,hhh] = contour(xpl,z,real(rhog.'),'k');
[C,hhh] = contourf(xpl,z,real(rhog.'));
clabel(C,hhh)
hold on
axis(ax)
fill(xf,zf,'b')
title('rho');
xlabel('x (km)')
hold off
set(gca,'TickDir','out')

%       Plot surface values

figure(6)
clf
xa = [0 max(xpl)];
ya = [0 0];

subplot(4,1,1)
plot(xpl,real(ptop),'k',xpl,imag(ptop),'r',xa,ya,'k')
ylabel('Pressure')
title(['Surface variables (cgs units) (Real in black, imaginary in red), \omega, l = ' num2str(ww(1)) ', ' num2str(rl)])

subplot(4,1,2)
plot(xpl,real(v(:,mm-2)),'k',xpl,imag(v(:,mm-2)),'r',xa,ya,'k')
ylabel('v')

subplot(4,1,3)
plot(xpl,real(u(:,mm-2)),'k',xpl,imag(u(:,mm-2)),'r',xa,ya,'k')
ylabel('u')

subplot(4,1,4)
hold on
if max(max(abs(vm))) > 0.01
    [vmg,~]=downsize_u(vmz,zout);
%     vmg = bigcsigtoz(vm);
    contour(xpl,z,vmg')
end
fill(xf,zf,'b')
axis(ax)
hold off
ylabel('Depth (m) and vm')
xlabel('x (km)')
set(gca,'TickDir','out')

if exist('uvwrp.mat','file')
    save('uvwrp.mat','xpl','z','ug','vg','wg','rhog','pg','n2g','ww','rl','xf','zf','vp','vbcpbc','ptop','-append')
else
    save('uvwrp.mat','xpl','z','ug','vg','wg','rhog','pg','n2g','ww','rl','xf','zf','vp','vbcpbc','ptop')
end
