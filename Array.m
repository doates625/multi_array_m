classdef Array < multi_array.Abstract
    %ARRAY Data-holding multi-array
    %   
    %   Author: Dan Oates (WPI Class of 2020)
    
    properties (SetAccess = protected)
        data;   % Data array [double]
    end
    
    methods (Access = public)
        function obj = Array(size_, data)
            %obj = ARRAY(size_, data)
            %   Construct multi-array
            %   
            %   Inputs:
            %   - size_ = Array size [int]
            %   - data = Init data [double, default = 0]
            obj@multi_array.Abstract(size_);
            if nargin < 2
                data = zeros(size_);
            else
                if ~isequal(size_, size(data))
                    error('Data size mismatch.');
                end
            end
            obj.data = data;
        end
        
        function val = get(obj, pos, fmt)
            %GET Get value in mutli-array
            %   
            %   val = GET(obj, ind, 'Ind') Get by single index
            %   val = GET(obj, sub, 'Sub') Get by subscript array
            val = obj.data(obj.conv(pos, fmt, 'Ind'));
        end
        
        function set(obj, pos, fmt, val)
            %SET Set value in multi-array
            %
            %   SET(obj, ind, 'Ind', val) Set by single index
            %   SET(obj, sub, 'Sub', val) Set by subscript array
            obj.data(obj.conv(pos, fmt, 'Ind')) = val;
        end
    end
end