function [dydt,sm,U,sPost,uci,vci,rci] = Infante_MTGP_3dof_uncertain(time,U,x,spost,sy,dynmodel) 
%״̬����
tic
dydt = zeros(4,1);
u = U(1); v = U(2); r = U(3);
x_p = x(1); y_p = x(2); 
psi = x(3); d=x(4);
Xs = [u;v;r] ; %trial poionts
% flag_lr=sm;
% %NARX_MT
% [mPost,sPost] = predNIGP(model,Xs,0);
% [mPost,sPost] = predNIGP(model,Xs,2);
%% PILCO
[tileM, tileS] = jointDistribution(Xs,spost,d);
[mPost,sPost,~] = gp0(dynmodel, tileM, tileS);
uci = sum(sPost(1,:))+sum(sPost(:,1))-sPost(1,1);
vci = sum(sPost(2,:))+sum(sPost(:,2))-sPost(2,2);
rci = sum(sPost(3,:))+sum(sPost(:,3))-sPost(3,3);
%% pass the values
u= mPost(1); 
v= mPost(2);
r= mPost(3);
U = [u,v,r];
%����ϵ����ת��
dydt(1) = u*cos(psi)-v*sin(psi); %dx   
dydt(2) = u*sin(psi)+v*cos(psi); %dy
dydt(3) = r;                     %dpsi    
% %scheduled maneuver
% dydt(4) = AdjustAngle_t30_r(d,psi,time);
% % dydt(4) = AdjustAngle_t30_r(d,psi,time);
% sm= 1; %psi״̬

% % % %zigzag
[dydt(4),sm] = AdjustAngle_z15_5(d,psi,sy);
t4=toc;
end

