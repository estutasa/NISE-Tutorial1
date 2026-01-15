close all
clear all
% Load reconstructed reference patch
% regexFile = 'data/p21_shape1.mat';
regexFile = 'data/p21_shape2.mat';
files = dir(regexFile);
file = files(1);
name = file.name;
path = file.folder;
fileNamePath = [path '/' name];
temp = load(fileNamePath);
sp = temp.patch.scs;
% Load acc measurements
regexFile = 'data/accExpt*.mat';
files = dir(regexFile);
for k=1:length(files)
    file = files(k);
    name = file.name;
    path = file.folder;
    fileNamePath = [path '/' name];
    
    disp(['Load experiment: ' name]);
    
    temp = load(fileNamePath);
    expt(k) = temp.expt;
end
sc = expt(1).sc(:);
for k=1:length(sc)
    for l=2:length(expt)
        sc(k).acc = [sc(k).acc expt(l).sc(k).acc];
        sc(k).accMean = [sc(k).accMean expt(l).sc(k).accMean];
    end
end
for k=1:length(sc)
    accMeas = sc(k).accMean;
    disp(['Acc calib: ' num2str(sc(k).id)]);
    
    [T,M,w] = accCalib(accMeas);
    sc(k).T = T;
    sc(k).M = M;
    sc(k).w = w;
    
    % eval measurement (ideal: sigmas are all 1/3)
    % often: z is too dominant
    % v1,v2,v3: direction vectors of sigmas
    M = sc(k).acc;
    [~,S,V] = svd(M*M');
    N = size(M,2);
    
    disp(['Eval: ' num2str(diag(S)'/N)]);
    V
    
end
scacc = sc;
% Attach the acc meas to the skin cells of the patch
for k=1:length(sp)
    sc = sc_id2sc(scacc,sp(k).id);
    
    id = sc.id;
    
    acc.meas = sc.acc;
    acc.mean = sc.accMean;
    acc.T = sc.T;
    acc.w = sc.w;
    acc.M = sc.M;
    sp(k).acc = acc;
end
% add poses calc with brute force 3d recon with calibrated acc
sp = calcposes(sp,4,'poseAcc');
% sp = sc_calcposes_acc(sp,4,'poseAcc');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw patch in grid
scl = sp;
figure
hold on
grid on
daspect([1 1 1]);
g = [scl(:).grid];
xH = [g(:).xH];
yH = [g(:).yH];
[x,y] = hexa2cart(xH,yH);
plot(x,y,'bx')
h = drawHexagon(x,y,1/3*sqrt(3),deg2rad(30));
for k=1:length(scl)
    sc = scl(k);
    str = [num2str(sc.id)];
    h = text(x(k),y(k)-0.15,str);
    set(h,'HorizontalAlignment','center');
    set(h,'FontSize',8);
end
title('Skin Patch: 2D representation using neighbor information')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw reference patch
props = sc_props();
rPCB = props.rPCB;
figure
hold on
grid on
daspect([5 5 5]);
view([-84,68]);
xlabel('X')
ylabel('Y')
zlabel('Z')
drawCoordinateSystem3D(eye(4),0.1);
scl = sp;
% plot all cells with pose
for k=1:length(scl)
    sc = scl(k);
    pose = sc.pose;
   
    if ~isempty(pose)
        T = pose.T;
              
        h = drawSkinCell3Dv2(T,sc.id);
        h.CellRadius = rPCB;
        h.FaceFilled = true;
        p = h.Label.Position;
        h.Label.Position = p + [0 0 0.005];
    end
end
title('Reference Skin Patch (Online 3D Recon)')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw patch of restructed from acc measurements
figure
hold on
grid on
daspect([5 5 5]);
view([-84,68]);
xlabel('X')
ylabel('Y')
zlabel('Z')
drawCoordinateSystem3D(eye(4),0.1);
scl = sp;
% plot all cells with pose
for k=1:length(scl)
    sc = scl(k);
    pose = sc.poseAcc;
    
    if ~isempty(pose)
        T = pose.T;
              
        h = drawSkinCell3Dv2(T,sc.id);
        h.CellRadius = rPCB;
        h.FaceFilled = true;
        p = h.Label.Position;
        h.Label.Position = p + [0 0 0.005];
    end
end
title('Skin Patch (3D Recon Brute Force)')


