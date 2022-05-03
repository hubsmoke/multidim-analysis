% Estimate government choice probability:
% the probability of being preferred among two bids, given the differences
% from the other bid and item quality.

cd(fileparts(mfilename('fullpath')))
addpath('functions') 

%% Import Data
clear; clc;
filename = '../calculations/Data_for_gchoice.csv';
delimiterIn = ',';
headerlinesIn = 1;
D = importdata(filename,delimiterIn,headerlinesIn);

win = D.data(:,1);
dcn = D.data(:,2);
drn = D.data(:,3);
diffc = D.data(:,4); 
diffr = D.data(:,5); 
lndiffc = D.data(:,6); 
index = D.data(:,7);

% Sieve maximum likelihood- order of polynomials:
dr = 6;
dc = 6;
dq = 2;

%% Save the relationship between
% lndiffc and its quantiles, dcn
    uniq_lndiffc = unique(lndiffc);
    uniq_dcn = NaN(length(uniq_lndiffc),1);
    for i=1:length(uniq_dcn)
        uniq_dcn(i) = mean(dcn(lndiffc==uniq_lndiffc(i)));
    end
    dcn_table = [uniq_lndiffc uniq_dcn];
% diffr and its quantiles, drn
    uniq_diffr = unique(diffr);
    uniq_drn = NaN(length(uniq_diffr),1);
    for i=1:length(uniq_drn)
        uniq_drn(i) = mean(drn(diffr==uniq_diffr(i)));
    end
    drn_table = [uniq_diffr uniq_drn];

    %% Form Bernstein polynomial bases.
    % P(r,c,q)
    bases = bernstein_bases_trivariate( drn,dcn,index, dr,dc,dq );

    %% Prepare for maximum likelihood estimation
    startval = repmat( 0.5.*ones(dr+1,1), (dc+1)*(dq+1), 1);
    options = optimset('MaxFunEvals',1e10);
    % Restrict to functions weakly increasing in r:
    Air = A_wincreasingin_x( dr+1, (dc+1)*(dq+1), 1 );
    bir = zeros( (dr+1)*(dc+1)*(dq+1) , 1);
    % Restrict to functions weakly increasing in c:
    Aic = A_wincreasingin_y( dr+1, (dc+1), dq+1 );
    bic = zeros( (dr+1)*(dc+1)*(dq+1)-(dr+1) , 1);
    % Matrix of all 4 restrictions
    A = [Air;Aic];
    b = [bir;bic];
    % Bounds for parameter vector
    lb = zeros( (dr+1)*(dc+1)*(dq+1) , 1);
    ub = ones( (dr+1)*(dc+1)*(dq+1) , 1);
    % Sieve Maximum Likelihood estimation:
    Bernstein_parameters = fmincon(@(p) -gchoiceL(p,bases,win), startval,A,b,[],[],lb,ub,[],options);
    
%% Plot estimation results
% Grid of values to evaluate for plotting
Ir = [ repmat([zeros(9,1);1],floor(length(uniq_drn)/10),1); zeros(mod(length(uniq_drn),10),1) ];
Ic = [ repmat([zeros(9,1);1],floor(length(uniq_dcn)/10),1); zeros(mod(length(uniq_dcn),10),1) ];
rgridn = uniq_drn(Ir==1);
cgridn = uniq_dcn(Ic==1);

% Plot probability contours
fig = figure;
for qgridn = [0.5] % At median quality index
    [X,Y,Z] = meshgrid(rgridn,cgridn,qgridn); % I want royalty to show up on the x-axis and bonus on the y-axis.
    X = reshape(X,[],1);
    Y = reshape(Y,[],1);
    Z = reshape(Z,[],1);
    pred = bernstein_bases_trivariate( X,Y,Z, dr,dc,dq )*Bernstein_parameters;
    predm = reshape(pred,length(cgridn),[]); % rows move through grid points of bonus.
    % Prepare to plot
    rgrid = uniq_diffr(Ir==1); % linear interpolation
    cgrid = uniq_lndiffc(Ic==1); % linear interpolation
    [C,h] = contour(rgrid,cgrid,predm,'LineColor','k','LineWidth',0.8);
    clabel(C,h,'LabelSpacing',170);
    xlabel('$a - a''$','fontsize',14,'interpreter','latex')
    ylabel('$\ln b- \ln b''$','fontsize',14,'interpreter','latex')
end

% Plot underlying data points
hold on
scatter(diffr(win==0), lndiffc(win==0),'^','MarkerEdgeColor',[0.8500, 0.3250, 0.0980])
scatter(diffr(win==1), lndiffc(win==1),'MarkerEdgeColor',[0, 0.4470, 0.7410])
hold off
xlim([-0.1,0.1])
ylim([-2,2])
print(fig,'-depsc',['../output/figure3.eps'])

save('../calculations/Estimate_gchoice','Bernstein_parameters','dr','dc','dq','drn_table','dcn_table')