% Compute the gain and the offset of the accelerometer
%
%   [M,w] = accCalib(acc)
%
%   acc: 3 x N matrix containing the acceleration measurements for the
%           calibration
%
%   M:  gain matrix, 3 x 3
%   w:  offset, 3 x 1
%   R:  rotation matrix (normalized matrix), 3 x 3
%   G:  gain matrix (diagonal matrix), 3 x 3
%
function [M,w,R,G] = accCalib(acc)

ax = acc(1,:);
ay = acc(2,:);
az = acc(3,:);

G = eye(3);
R = eye(3);

w = zeros(3,1);

%??????????????????????????????????????????????????????????????????????????
%   Implement the ellipsoid fitting algorthm which finally delivers w, R,
%   and G.

%   M is the model matrix and describes the transformation of the
%   uncalibrated acceleration measurement to the unit sphere. The
%   cooridnate system of the elliposid is not necessarily aligned to the
%   coordinate system of the accelerometer, i.e. R is usually not an
%   identiy matrix. R can later be used to transform the calibrated
%   measurements back to the coordinate system of the accelerometer.

%   Lecture ellipsoid form: A x1^2 + B x2^2 + C x3^2 + 2D x1 x2 + 2E x1 x3
%   + 2F x2 x3 + 2G x1 + 2H x2 + 2K x3 = 1
%   but we have already determined that D, E, F = 0 due to rotation being
%   divisible by 90°
%   ---> A x1^2 + B x2^2 + C x3^2 + 2G x1 + 2H x2 + 2K x3 = 1

% 1. FIND ELLIPSOID PARAMETERS: FITTING A, B, C, G, H, K 

% make sure x,y,z are column vectors as expected by least squares
x = ax(:);
y = ay(:);
z = az(:);
N = numel(x); % number of samples

M_meas = [ x.^2, y.^2, z.^2, 2*x, 2*y, 2*z ];
d = ones(N,1);

% Least squares (using SVD)
[U,S,V] = svd(M_meas, 0);
p = V * (S \ (U' * d));

A  = p(1);  B  = p(2);  C  = p(3);
G1 = p(4);  H1 = p(5);  K1 = p(6); % named G1 and not G to avoid clash with matrix G

Atilde = diag([A,B,C]); % quadratic ellipsoid matrix
btilde = [2*G1; 2*H1; 2*K1]; % line vector b


% 2. FIND ELLIPSOID OFFSET
% w from -2*Atilde*w = btilde
w = -0.5 * ((Atilde' * Atilde) \ (Atilde' * btilde)); 


% 3. FIND GENERAL ELLIPSOID MATRIX A
Abar = [Atilde, 0.5*btilde;
        (0.5*btilde)', -1];

T = [eye(3), w;
     0 0 0  1];

Ahat = T' * Abar * T;
a44 = Ahat(4,4);
Ahat33 = Ahat(1:3, 1:3);

A_fit = -(1/a44) * Ahat33;

% 4. FIND MODEL MATRIX
% rotation a multitude of 90°, so: R=I 
% A_fit = Q V Q^T = R^T V R = I V I = V
% G = sqrt(V) = sqrt(A_fit)
R = eye(3);
G = diag(sqrt(diag(A_fit))); 
% M = G*R


%??????????????????????????????????????????????????????????????????????????

M = G*R;

end