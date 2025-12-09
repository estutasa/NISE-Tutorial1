% Class Draw Coordinate System in figure
%
%   [h] = drawCoordinateSystem3D(T,varargin)
%   [h] = drawCoordinateSystem3D(T,scale,varargin)
%
%   T:      the homogenous transformation matrix wrt to origin
%               T is 4x4
%   scale:  the scaling of the axes; 1 <=> axes have length 1
%
classdef drawCoordinateSystem3D < handle
    properties (SetAccess = private, GetAccess = private)
        AxesHandle
        Initialized = false
    end
    
    properties (SetAccess = private, GetAccess = public)
        XAxis
        YAxis
        ZAxis
    end
    
    properties
        Scale = 1
        T = eye(4)      % homogenous transformation
    end
    
    methods
        function obj = drawCoordinateSystem3D(T,arg,varargin)
            if ~obj.isT(T)
                error('T has to be homogenous matrix of 4x4.');
            end
            
            obj.T = T;
            
            if nargin > 1
                if obj.isNumber(arg)
                    obj.Scale = arg;
                else
                    varargin = [arg varargin];
                end
            end
            
            % set properties values from varargin
            if nargin > 2
                for k=1:2:length(varargin)
                    obj.(varargin{k}) = varargin{k+1};
                end
            end
            
            obj.Initialized = true;
            
            updateAxes(obj);
            
        end
        
        function set.Scale(obj,scale)
            obj.Scale = scale;
            updateAxes(obj);
        end
        
        function set.T(obj,T)
            obj.T = T;
            updateAxes(obj);
        end
    end
    
    methods (Access=private)
        
        function updateAxes(obj)
            if ~obj.Initialized
                return
            end
            
            scale = obj.Scale;
            
            x = obj.T(1:3,1);
            y = obj.T(1:3,2);
            z = obj.T(1:3,3);
            t = obj.T(1:3,4);
            
            ax = [t, t + x*scale];
            ay = [t, t + y*scale];
            az = [t, t + z*scale];
            
            
            h{1} = obj.XAxis;
            h{2} = obj.YAxis;
            h{3} = obj.ZAxis;
            
            for k=1:3
                if ~isempty(h{k})
                    delete(h{k});
                end
            end

            h{1} = plot3(ax(1,:),ax(2,:),ax(3,:),'r','LineWidth',1);
            h{2} = plot3(ay(1,:),ay(2,:),ay(3,:),'g','LineWidth',1);
            h{3} = plot3(az(1,:),az(2,:),az(3,:),'b','LineWidth',1);

            obj.XAxis = h{1};
            obj.YAxis = h{2};
            obj.ZAxis = h{3};

        end        
        
    end
    
    methods (Static,Access=private)
        
        % check if argument is a number
        function [cond] = isNumber(arg)
            cond = isnumeric(arg) && isequal(size(arg),[1,1]);
        end
        
        function [cond] = isT(arg)
            cond = ismatrix(arg) && isequal(size(arg),[4,4]);
        end
    end
end