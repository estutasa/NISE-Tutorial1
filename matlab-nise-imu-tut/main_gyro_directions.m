close all
clear all

regexFile = 'data/gyro*.mat';
files = dir(regexFile);

acc = [];

for k=1:length(files)
    file = files(k);
    name = file.name;
    path = file.folder;
    fileNamePath = [path '/' name];
    
    disp(['Load experiment: ' name]);
    
    temp = load(fileNamePath);
    expt(k) = temp.expt;
end

name2el = @(s,name) s(strcmp({s(:).name},name));

names = {'gyroX','gyroY','gyroZ'};
descr = {'roll','pitch','yaw'};

figure
hold on
grid on

leg = [];

for k=1:length(names)
    leg = [];
    
    el = name2el(expt,names{k});
    imu = el.imu;

    subplot(1,3,k);
    hold on
    grid on
    set(gca,'TickLabelInterpreter', 'latex');
    set(gca,'FontSize',10);
    
    x = imu.t;
    y = imu.gyro(1,:);
    h = plot(x,y);
    leg(end+1).h    = h;
    leg(end).label  = '$x$';
    
    x = imu.t;
    y = imu.gyro(2,:);
    h = plot(x,y);
    leg(end+1).h    = h;
    leg(end).label  = '$y$';
    
    x = imu.t;
    y = imu.gyro(3,:);
    h = plot(x,y);
    leg(end+1).h    = h;
    leg(end).label  = '$z$';
    
    h = xlabel('$t$ [$\mathrm{s}$]');
    set(h,'Interpreter','latex');

    h = ylabel('{\boldmath$\omega$} [$\mathrm{deg/s}$]');
    set(h,'Interpreter','latex');
    
    
    h = legend([leg(:).h], {leg(:).label});
    set(h,'Interpreter','latex');
    set(h,'FontSize',10);
    set(h,'Location','NorthEast');

    h = title(['\textbf{' descr{k} '}']);
    set(h,'Interpreter','latex');
    set(h,'FontSize',12);
    
end

fprintf('\n');
str=['NOTE: The Rotation direction is first positive, then negative, ...'];
disp(str);
fprintf('\n');

% Transformation between gyro coordinate system and coordinate system 0
%   gyro wrt. 0
T_gyro_0 = eye(4);

%??????????????????????????????????????????????????????????????????????????
%   Define the transformation between the coordinate frame of the
%   gyroscope and the base frame 0.
%
%   Use the plot of this script to get the represenatation of the x,
%   y, and z axes of the gyroscope wrt. the coordinates of the base
%   frame.
%
%   NOTE: You only need to dermine the rotation, the translation is assumed
%   to be zero. All rotations are devidable by 90 degrees.
%

T_gyro_0(1:3,1) = [1 0 0];
T_gyro_0(1:3,2) = [0 1 0];
T_gyro_0(1:3,3) = [0 0 1];

%??????????????????????????????????????????????????????????????????????????

disp('Transformation between gyro coordinate system and coordinate system 0:');
disp('T_gyro_0 =')
disp(T_gyro_0);

save('T_gyro_0.mat','T_gyro_0');



