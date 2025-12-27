% Calculates the poses of skin cells using the orientations computed by the
%   acceleration measurements and the constant port distances.
%
%   [scs] = calcposes(scs,id,poseName)
%
%   scs:        array of skin cell structs
%   id:         the id of the root cell with a given pose
%   poseName:   optional name for the sub-struct where the pose will be
%                   stored.
%
%   Note:       All poses are with respect to the world. The pose of the 
%               root cell is assumed to be identity.
%
%   Note:       The rotations between the cells are calculated from
%               calibrated acceleration data between the root cell and the 
%               respective cell.
%
function [scs] = calcposes(scs,id,poseName)

if nargin == 1
    id = 1;
    poseName = 'pose';    
elseif nargin == 2
    poseName = 'pose';
end
    
poseValid = false(size(scs));


% Set the pose of the root cell to identity and mark it as valid
ind = sc_findid(scs,id);
pose.p = [0 0 0]';
pose.T = eye(4);
scs(ind).(poseName) = pose;
poseValid(ind) = true;


%??????????????????????????????????????????????????????????????????????????
%   Compute the calibrated accelerations of different poses of the root cell
%
%   Note: acc_raw is 3 x P where P is the number of poses
%
%   Use the homogenous transformation matrix T in the sc.acc sub-struct
%   which contains the pre-computed calibration and adjust acc_0 

sc = scs(ind);
acc_raw = sc.acc.mean;
T = sc.acc.T;

acc_0 = acc_raw;

%??????????????????????????????????????????????????????????????????????????


% Port positions wrt. cell coordinate systems
pP = sc_portpos();

% Port index mapping: Get neighbor cell port with indP(portOfCurrentCell)
indP = [3,4,1,2];

% brute force loop: loop until all skin cells have a pose
while 1

    % get true/false vector: true: cell has pose, false: cell doesn't have
    % pose
    tf = poseValid == true;
    
    % exit if all cells have a pose
    if(all(tf))
        break;
    end
    
    % get all cells that have a pose
    scswp = scs(tf);

   
    % loop through all cells that have a pose
    for k = 1:length(scswp)
        
        % Get the current cell
        sc = scswp(k);
    
        % Get the neighbors of the current cell
        neighs = sc.neighs;
        
        % Get the cell ids of the neighbors of the current cell
        ids = neighs.ids;
        
        % Loop through all neighbors, the neighbor index is equal to the
        % port id of the current cell 
        for l=1:length(ids)
            
            % If the id of the neighbor cell is zero then there is no
            % neighbor and we continue with the neighbor on the next port.
            id = ids(l);
            if id == 0
                continue;
            end
            
            % Get the cell struct of the current neighbor
            ind = sc_findid(scs,id);
            ind = ind(1);
            scn = scs(ind);

            % The neighbor has already a pose, so we can continue with the
            % neighbor on the next port
            if poseValid(ind)
                continue;
            end
            
            % Get the pose of the current cell (the parent of the current
            % neighbor)
            p0 = sc.(poseName).p;
            R0 = sc.(poseName).T(1:3,1:3);
            
            
            %??????????????????????????????????????????????????????????????
            %   Compute the calibrated acceleration of different poses of 
            %   the neighbor cell
            %
            %   Note: acc_raw is 3 x P where P is the number of poses
            %
            %   Use the homogenous transformation matrix T in the 
            %   scn.acc sub-struct which contains the pre-computed 
            %   calibration and adjust acc_n
                        
            acc_raw = scn.acc.mean;
            T = scn.acc.T;
            
            acc_n = acc_raw;
            

            %??????????????????????????????????????????????????????????????

            
            %??????????????????????????????????????????????????????????????
            %   Compute the rotation of the neighbor cell wrt to the root 
            %   cell using the calibrated accellerations acc_n and acc_0.
            %   
            %   Preferably implement the Procrustes algorithm in the 
            %   function estRot().

            R_n_0 = eye(3);
            
            %??????????????????????????????????????????????????????????????
            
            % The rotation is wrt to the root cell/world, thus we can
            % simply write:
            Rn = R_n_0;
            
            
            % Get the port position of the current cell (the parent of the
            % current neighbor) wrt the to cell coordinate system
            pP0 = pP(:,l);
            
            % Get the port position of the neighbor cell wrt the to cell
            % coordinate system
            pPn = pP(:,indP(l));
            
            
            %??????????????????????????????????????????????????????????????
            %   Compute the postion of the neighbor cell wrt to the reference
            %   frame using R0, p0, pP0, pPn, and Rn.
            
            pn = zeros(3,1);    
            
            %??????????????????????????????????????????????????????????????
            
            % Assemble the pose for the neighbor cell and mark it as valid.
            Tn = eye(4);
            Tn(1:3,1:3) = Rn;
            Tn(1:3,4) = pn;
            
            pose.p = pn;
            pose.T = Tn;
            
            scs(ind).(poseName) = pose;
            
            poseValid(ind) = true;
            
        end % neighbors
    end % cells with poses

end % infinite loop


end
