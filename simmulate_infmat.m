% clear all
format long

% Settings for the structure
k_tr = 1; % truncation parameters as in remark 3.3
N = 2; % number of the resonators inside the unit cell
inft = 50; % number of reoccuring unit cells to simmulate an infinite material
N_tot = N*inft; % total number of resonators
spacing = 2; 
if N > 1
    pre_lij = ones(1,N-1).*spacing; % spacing between the resonators
    lij = repmat([pre_lij,pre_lij(end)],1,inft-1); lij = [lij,pre_lij];
else
    pre_lij = spacing;
    lij = spacing.*ones(1,inft);
end
len = 1; pre_li = ones(1,N).*len; % length of the resonator
li = repmat(pre_li,1,inft);

if N > 1
    L = sum(pre_li)+sum(pre_lij)+pre_lij(end); % length of the unit cell
else
    L = pre_lij+len; % length of the unit cell
end
xm = [0]; % left boundary points of the resonators
for i = 1:N_tot-1
    xm = [xm,xm(end)+li(i)+lij(i)];
end
xp = xm + li; % right boundary points of the resonators

delta = 0.0001; % small contrast parameter
t = 0; % time
vr = 1; % wave speed inside the resonators
eta_i = 1.5; % perturbance of the wave speed in the i-th resonator
v0 = 1; % wave speed outside the resonators

% implement perturbation
i_pertr = floor(N_tot/2); % indicates which resonator is perturbed
vr = ones(1,N).*vr; 
vr = repmat(vr,1,inft); vr(i_pertr) = vr(i_pertr)+eta_i;


% Settings for modulation
Omega = 0.034; % modulation frequency
T = 2*pi/Omega;
phase_kappa = zeros(1,N); % modulation phases of kappa
phase_rho = zeros(1,N); % modulation phases of rho
for i = 1:(N-1)
    phase_kappa(i+1) = pi/i;
    phase_rho(i+1) = pi/i;
end
epsilon_kappa = 0; % modulation amplitude of kappa
epsilon_rho = 0; % modulation amplitude of rho
rs = []; % Fourier coefficients of 1/rho
ks = []; % Fourier coefficients of 1/kappa
for j = 1:N
    rs_j = [epsilon_rho*exp(-1i*phase_rho(j))./2,1,epsilon_rho*exp(1i*phase_rho(j))./2];
    ks_j = [epsilon_kappa*exp(-1i*phase_kappa(j))./2,1,epsilon_kappa*exp(1i*phase_kappa(j))./2];
    ks = [ks; ks_j];
    rs = [rs; rs_j];
end
ks = repmat(ks,inft,1);
rs = repmat(rs,inft,1);
phase_kappa = repmat(phase_kappa,1,inft);
phase_rho = repmat(phase_rho,1,inft);

% figure()
% hold on
% plot(0,0,'b*')
% for i = 1:N_tot
%     plot([xm(i),xp(i)],zeros(1,2),'r-')
% end
% for i = 1:inft
%     plot(i*L,0,'b*')
% end


%% Compute the subwavelength resonant frequencies and eigenmodes for the static case

% generalised capacitance matrix
C = make_capacitance_finite(N_tot,lij); % capacitance matrix
GCM = delta*diag(vr)^2*diag(1./li)*C;
[V,w_res] = eig(GCM);
w_res = diag(w_res); w_res = sqrt(w_res); w_res_neg = (-1).*w_res; w_res = [w_res;w_res_neg];
V_neg = (-1).*V; V = [V,V_neg];

if N_tot > 1
    C = make_capacitance_finite(N_tot,lij); % capacitance matrix
    [w_cap,v_cap] = get_capacitance_approx_rhokappa(Omega,epsilon_kappa,epsilon_rho,phase_kappa,phase_rho,vr,delta,li,k_tr,C); % subwavelength resonant frequencies
else
    w_cap = get_capacitance_approx_spec_im_N1_1D(epsilon_kappa,Omega,len,delta,vr,v0); % subwavelength resonant frequencies
end
w_cap = diag(w_cap); %w_cap = w_cap(real(w_cap)>=0);
v_cap_rev = [];
for j = 1:2*N_tot
    for i = 1:N_tot
        v_cap_rev(i,j) = sum(abs(v_cap((i-1)*(2*k_tr+1)+1:i*(2*k_tr+1),j)).^2);
    end
end
V_abs = abs(V).^2;

V_norms = zeros(1,2*N_tot);
for i = 1:2*N_tot
    V_norms(i) = norm(V_abs(:,i));
end

loc_measure = zeros(1,N_tot);
for i = 1:N_tot
    loc_measure(i) = norm(v_cap_rev(i,:),Inf)/norm(v_cap_rev(i,:),2);
end
loc_idx = [];
for i = 1:N_tot
    if loc_measure(i) > (mean(loc_measure)+0.1)
        loc_idx = [loc_idx,i];
    end
end

% % plot eigenvectors
% fig = figure()
% hold on
% for i = 1:size(v_cap,2)
%     plot(1:length(v_cap_rev(:,i)),v_cap_rev(:,i),'-','LineWidth',1.2, 'color', [.5 .5 .5])
% end
% % legend 
% xlabel('$i$','fontsize',18,'Interpreter','latex')
% ylabel('$v_i$','fontsize',18,'Interpreter','latex')
% xlim([1,length(v_cap_rev(:,i))])
% dim = [0.2 0.671111111111111 0.203633567216567 0.128888888888889];
% str = {['$\varepsilon_{\kappa}=$ ',num2str(epsilon_kappa)],['$\varepsilon_{\rho}=$ ',num2str(epsilon_rho)]};
% annotation('textbox',dim,'String',str,'FitBoxToText','on','Interpreter','latex','FontSize',18);

% plot degree of localisation
figure(1)
hold on
plot(1:length(loc_measure),loc_measure,'*','LineWidth',1.2, 'color', [.8 .5 .8], ...
    'DisplayName', ['$\varepsilon_{\kappa}=$ ',num2str(epsilon_kappa),', $\varepsilon_{\rho}=$ ',num2str(epsilon_rho)])
% labels 
xlabel('$i$','fontsize',18,'Interpreter','latex')
ylabel('$\frac{||v_i^{\alpha}||_{\infty}}{||v_i^{\alpha}||_2}$','fontsize',18,'Interpreter','latex','rotation',0)
xlim([1,length(v_cap_rev(:,i))])
dim = [0.2 0.671111111111111 0.203633567216567 0.128888888888889];
% str = {['$\varepsilon_{\kappa}=$ ',num2str(epsilon_kappa)],['$\varepsilon_{\rho}=$ ',num2str(epsilon_rho)]};
% annotation('textbox',dim,'String',str,'FitBoxToText','on','Interpreter','latex','FontSize',18);
legend('Interpreter','latex','FontSize',14)

% plot eigenvalues \omega
fig = figure()
% hold on
% subplot(2,2,4)
hold on
plot(real(w_cap),imag(w_cap),'*',LineWidth=2)
plot(real(w_cap(loc_idx)),imag(w_cap(loc_idx)),'r*',LineWidth=2)
% plot(real(w_cap(13)),imag(w_cap(13)),'r*',LineWidth=2)
% plot(real(w_cap(23)),imag(w_cap(23)),'r*',LineWidth=2)
% plot(real(w_cap(25)),imag(w_cap(25)),'r*',LineWidth=2)
% plot(real(w_cap(27)),imag(w_cap(27)),'r*',LineWidth=2)
xlabel('Re($\omega$)',Interpreter='latex',FontSize=14)
ylabel('Im($\omega$)',Interpreter='latex',FontSize=14)
dim = [0.2 0.671111111111111 0.203633567216567 0.128888888888889];
str = {['$\varepsilon_{\kappa}=$ ',num2str(epsilon_kappa)],['$\varepsilon_{\rho}=$ ',num2str(epsilon_rho)]};
annotation('textbox',dim,'String',str,'FitBoxToText','on','Interpreter','latex','FontSize',18);



