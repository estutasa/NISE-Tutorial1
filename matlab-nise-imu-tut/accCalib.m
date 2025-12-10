%==========================================================================
% ANSWERS FOR T.1.3 AND T.1.4
%==========================================================================

% T.1.3 How many parameters are needed for A_fit when R is constrained to 90-degree rotations?
%
% 3 parameters. The 90-degree constraint forces the general 3x3 symmetric matrix 
% A_fit to be diagonal (A_fit = diag(A11, A22, A33)). Only the three unique 
% diagonal elements are needed.

% T.1.4 Which parameters (A, B, K) of the approximated ellipsoid matrix become zero?
%
% The off-diagonal terms of A_fit become zero (A12, A13, A23).The constraint implies 
% the ellipsoid is aligned with the accelerometer's axes, meaning there is no cross-axis 
% sensitivity (non-orthogonality) to be solved by the fit. 
% The B and K terms, related to offset and gain, are non-zero.


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

% 1. CONSTRUCT THE DATA MATRIX X AND VECTOR y (Ax = y form)
% We fit the constrained ellipsoid model: ax^2 + by^2 + cz^2 + dx + ey + fz = 1
% The unknown parameters are the 6 coefficients: p = [a; b; c; d; e; f]
% The raw measurements are x_raw = [ax; ay; az]

% X is N x 6, where N is the number of samples
X = [ax.^2; ay.^2; az.^2; ax; ay; az]'; 

% y is N x 1, a vector of ones (based on the equation form)
y = ones(size(ax, 2), 1); 

% 2. SOLVE FOR THE COEFFICIENTS p using Least Squares (pinv/pseudo-inverse)
% p = (X'X)^-1 X'y
p = pinv(X) * y; % p = [a; b; c; d; e; f]

% 3. EXTRACT A_fit, B_fit, K_fit, AND g_squared (radius)
% The solved equation is: a*x^2 + b*y^2 + c*z^2 + d*x + e*y + f*z = 1
% The standard form is: x_raw^T * A_fit * x_raw + B_fit^T * x_raw + K_fit = 0
% Comparing terms:
%   A_fit = diag(a, b, c)  (A_fit = diag(p(1:3)))
%   B_fit = [d; e; f]      (B_fit = p(4:6))
%   K_fit = -1

A_fit = diag(p(1:3));
B_fit = p(4:6);

% 4. EXTRACT GAIN (G) and OFFSET (w)
% The offset w is related to the center of the ellipsoid:
%   w = -1/2 * A_fit^-1 * B_fit
w = -0.5 * (A_fit \ B_fit); % Use backslash for matrix division (A_fit^-1 * B_fit)

% The scaling matrix S = M^T * M is related to A_fit and the radius (g^2):
%   S = M^T * M = A_fit / g^2
% The radius squared (g^2) can be calculated from the constant term K_unit:
%   g^2 = (1 + w^T * A_fit * w)^-1
g_sq_inv = (1 + w' * A_fit * w); 
g_sq = 1 / g_sq_inv;

% M^T * M = A_fit / g_sq_inv
M_sq = A_fit * g_sq_inv;

% Since R is constrained to identity or 90-degree rotations,
% we use the Singular Value Decomposition (SVD) for M_sq to get M = G*R.
% For the constrained case, M should be a diagonal matrix (M=G).
% We can solve directly for G using the square root of the diagonal elements of M_sq.

% M_sq = G * R * R^T * G = G^2 (since R*R^T = I and R is identity or 90-deg rot)
G_sq = M_sq; 
G = sqrt(G_sq); % G is a diagonal matrix of gains.

% R is fixed to Identity (or the 90-degree solution if we solve that separately).
% Since the problem constraint is used to simplify the fit, R remains I here.
R = eye(3); 

% G is the diagonal matrix of gains
% G = diag(1/sx, 1/sy, 1/sz) (inverse of the scale factors)
% We typically want G to be the diagonal matrix of inverse scale factors.

% Final output matrices M, w, R, G
G = sqrt(diag(G_sq)); % G must be a 3x1 vector of gains for output, not a diagonal matrix
G = diag(G);

%??????????????????????????????????????????????????????????????????????????

M = G*R;

end