echo on
% Use the container simulation noisy data to trian Noise Input Gaussian process 
%
% Calls:       Infante_NMTGP_3dof , Adjust angel
%
% Author:      Yifan Xue
% Date:        2020-01-15
% Revisions: 
echo off
set(0,'defaultfigurecolor','w')
%% Step1:load data 

load HSVACPMCKVLCC2Z1005 HSVACPMCKVLCC2Z1005
load HSVACPMCKVLCC2Z1505 HSVACPMCKVLCC2Z1505
load HSVACPMCKVLCC2Z2005 HSVACPMCKVLCC2Z2005
load HSVACPMCKVLCC2Z3005 HSVACPMCKVLCC2Z3005
load HSVACPMCKVLCC2Z3505 HSVACPMCKVLCC2Z3505
load HSVACPMCKVLCC2Z1010P HSVACPMCKVLCC2Z1010P 
load HSVACPMCKVLCC2Z2010P HSVACPMCKVLCC2Z2010P 

h=  0.05; sample= 12;
data_raw = [HSVACPMCKVLCC2Z1005(1:3200,:);HSVACPMCKVLCC2Z2005(1:3200,:);HSVACPMCKVLCC2Z3005(1:3200,:)];
% data_raw = [HSVACPMCKVLCC2Z1005(1:3100,:);HSVACPMCKVLCC2Z2005(1:3100,:)];

% data = wdenoise(data_raw);
data = data_raw;
num_tr = size(data,1);
t=linspace(0,num_tr,num_tr+1).*h;
data(:,1)=t(1:end-1);
% scatter(data(:,1),[data_raw(:,6),data(:,6)]);

data_train = data;
t =data_train(:,1);
psi = data_train(:,4)*pi/180;
u = data_train(:,5);
v = data_train(:,6);
r = data_train(:,7)*pi/180;
phi = data_train(:,8)*pi/180;
d =  data_train(:,9)*pi/180;

pre_data= HSVACPMCKVLCC2Z3505;
order=pre_data(:,9)*pi/180;
order= order(1:sample:end);
%% Step2 Construct data
tic
u_x = u(1:end-1);  u_y = u(2:end);
v_x = v(1:end-1);  v_y = v(2:end);
r_x = r(1:end-1);  r_y = r(2:end);
d_x = d(1:end-1);
Xm = [u_x,v_x,r_x,d_x];
Ym = [u_y,v_y,r_y];
% noise test
Xm2=[u_x,v_x,r_x];
Am = (Ym-Xm2)/h;
Am_d = wdenoise(Am);
% scatter(t(1:end-1),[Am(:,2),Am_d(:,2)]);axis([0 490 -0.05 0.05]);
figure(1)
sam=25;
scatter(t(1:sam:end-1),Am(1:sam:end,2));axis([0 490 -0.05 0.05]);hold on;

%���
t_t =t(1:sample:end-1);
Xm_t= Xm(1:sample:num_tr,:);
Am_t = Am(1:sample:num_tr,:);
Am_d_t = Am_d(1:sample:num_tr,:);

figure(1)
sam=25;
scatter(t(1:sam:end-1),Am_d(1:sam:end,2));axis([0 490 -0.05 0.05]);hold on;
%% Train and Tune the parameters for each NI-NARX GP model
%PILCO 
%Training datasets
dynmodel.inputs = Xm_t;
dynmodel.targets = Am_d_t;
dynmodel.train = @train;
dynmodel.sNum = 3;
tic
[dynmodel nlml] = dynmodel.train(dynmodel,[],-100);
% 32 -> ascii code of 'blank space'
process_mes = strcat('Successfully Training', 32, ' GP Model\n');
fprintf(process_mes);
t_MTGP_train=toc;   % counting dynamic model learning time 
%% Step3 : Apply NARX GP to predict
tic
dt= h*sample;
total_time = 160;
% m=111;
m= ceil(total_time /dt);    %���� 
x = zeros(3,1); %��ʱ״̬����
U_a = zeros(3,1);
TEMP_a = zeros(4,1); 
T = zeros(m,1);  %ʱ��
Y = zeros(m,13); %״̬����
Uci = zeros(m,1);Vci = zeros(m,1);Rci = zeros(m,1);
ua_pre= zeros(m,1);va_pre = zeros(m,1);ra_pre = zeros(m,1);
%Inatialize the ship 
u0 = 1.175; v0 = 0;  r0=0;
x0 = 0; y0 = 0; psi0 = 0;
d0 = 0;flag_lr0= -1;
Initial_input = [u0;v0;r0];
Initial_ob =  [x0; y0; psi0;d0];
spost= diag([0.01*ones(1, dynmodel.sNum)].^2);
U = Initial_input;
x = Initial_ob;
sy = flag_lr0;
uci=0;vci=0;rci=0;
for i=1:1:m
    t = dt*i;
    T(i,1)=t;
    time = t;
    % one Multi-output NARX
    rudder=order(i);
    [TEMP_a,TEMP_sm,spost,uci,vci,rci,U_a]=Infante_MTGP_3dof_HVSA_ac(dt,U,x,spost,sy,dynmodel,rudder,uci,vci,rci) ;
    %Euler
    U = U + dt.*U_a;
    x= x + dt.*TEMP_a;
    sy =TEMP_sm;
    
    %��������
    Y(i,1) = U(1);%u
    Y(i,2) = U(2);%v
    Y(i,3) = U(3);%r
    Y(i,5) = x(1);%x
    Y(i,6) = x(2);%y
    Y(i,7) = x(3);%psi
    Y(i,9) = x(4);%rudder   
    Y(i,10) =sy;%���״̬
    ua_pre(i)= U_a(1);    va_pre(i)= U_a(2);    ra_pre(i)= U_a(3);
    Uci(i) = sqrt(uci); 
    Vci(i) = sqrt(vci); 
    Rci(i) = sqrt(rci)*180/pi; 
end

U_pre  = Y(:,1);
V_pre  = Y(:,2);
R_pre  = Y(:,3)*180/pi;
Xp = Y(:,5);
Yp = Y(:,6);
psi = Y(:,7);
duo = Y(:,9);

duo = duo*180/pi;
psi = psi *180/pi;

t_MTGP_pre = toc; % time for prediction

HVSA_z35_05_MTGP = [T,U_pre,V_pre,R_pre];
save HVSA_z35_05_MTGP HVSA_z35_05_MTGP ;

% container_t21_NIGP = [T,U_pre,V_pre,R_pre];
% save container_t21_NIGP container_t21_NIGP ;


figure(4)
kk= 2;
subplot(311),
u_upper = U_pre + kk*Uci;  % upper boundry
u_lower = U_pre - kk*Uci;  % lower boundrr
patch([T', fliplr(T')], [u_lower', fliplr(u_upper')], 1, 'FaceColor', [0.85,0.85,1], 'EdgeColor', 'none');hold on;
set(gca, 'layer', 'top'); % We make sure that the grid lines and axes are above the grey area.
plot(T,U_pre,'LineWidth',1.5),xlabel('time (s)'),ylabel('u (m/s)');grid on;hold on;

subplot(312),
v_upper = V_pre + kk*Vci;  % upper boundry
v_lower = V_pre - kk*Vci;  % lower boundrr
patch([T', fliplr(T')], [v_lower', fliplr(v_upper')], 1, 'FaceColor', [0.85,0.85,1], 'EdgeColor', 'none');hold on
% set(gca, 'layer', 'top'); % We make sure that the grid lines and axes are above the grey area.
plot(T,V_pre,'linewidth',1.5),xlabel('time (s)'),ylabel('v (m/s)');grid on;hold on

subplot(313),
r_upper = R_pre + 2*Rci;  % upper boundry
r_lower = R_pre - 2*Rci;  % lower boundrr
patch([T', fliplr(T')], [r_lower', fliplr(r_upper')], 1, 'FaceColor', [0.85,0.85,1], 'EdgeColor', 'none');hold on
set(gca, 'layer', 'top'); % We make sure that the grid lines and axes are above the grey area.
plot(T,R_pre,'linewidth',1.5),xlabel('time (s)'),ylabel('r (rad/s)');grid on;hold on

% subplot(414),plot(T,psi,'linewidth',1.6);hold on
% xlabel('time (s)'),title('yaw angle \psi (deg)'),grid on;hold on

figure(3)
kk= 2;
subplot(311),
u_upper = ua_pre + kk*Uci;  % upper boundry
u_lower = ua_pre - kk*Uci;  % lower boundrr
patch([T', fliplr(T')], [u_lower', fliplr(u_upper')], 1, 'FaceColor', [0.85,0.85,1], 'EdgeColor', 'none');hold on;
set(gca, 'layer', 'top'); % We make sure that the grid lines and axes are above the grey area.
plot(T,ua_pre,'LineWidth',1.5),xlabel('time (s)'),title('speed U (m/s)');ylim([-0.05 0.05]);grid on;hold on;

subplot(312),
v_upper = va_pre + kk*Vci;  % upper boundry
v_lower = va_pre - kk*Vci;  % lower boundrr
patch([T', fliplr(T')], [v_lower', fliplr(v_upper')], 1, 'FaceColor', [0.85,0.85,1], 'EdgeColor', 'none');hold on
% set(gca, 'layer', 'top'); % We make sure that the grid lines and axes are above the grey area.
plot(T,va_pre,'linewidth',1.5),xlabel('time (s)'),title('speed V (m/s)');ylim([-0.06 0.06]);grid on;hold on

subplot(313),
r_upper = ra_pre*180/pi + 2*Rci;  % upper boundry
r_lower = ra_pre*180/pi - 2*Rci;  % lower boundrr
patch([T', fliplr(T')], [r_lower', fliplr(r_upper')], 1, 'FaceColor', [0.85,0.85,1], 'EdgeColor', 'none');hold on
set(gca, 'layer', 'top'); % We make sure that the grid lines and axes are above the grey area.
plot(T,ra_pre*180/pi,'linewidth',1.5),xlabel('time (s)'),title('speed R (rad/s)');ylim([-0.6,0.4]);grid on;hold on



% figure(4)
% subplot(411),plot(T,U_pre,'linewidth',1.6);hold on
% subplot(412),plot(T,V_pre,'linewidth',1.6);hold on
% subplot(413),plot(T,R_pre,'linewidth',1.6);hold on
% subplot(414),plot(T,psi,'linewidth',1.6);hold on
% xlabel('time (s)'),title('yaw angle \psi (deg)'),grid on;hold on