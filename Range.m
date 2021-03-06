classdef Range < multi_array.Abstract
    %RANGE Class for mapping discrete to continuous subscripts
    %   
    %   Author: Dan Oates (WPI Class of 2020)
    
    properties (SetAccess = protected)
        vals_min;    % Min dim values [double]
        vals_max;    % Max dim values [double]
    end
    
    properties (Access = protected)
        sub_to_val;  % Sub to Val array [double]
        val_to_sub;  % Val to Sub array [double]
    end
    
    methods (Access = public)
        function obj = Range(vals_min, vals_max, size_)
            %obj = RANGE(vals_min, vals_max, size_)
            %   Construct multi-range object
            %   
            %   Inputs:
            %   - vals_min = Min dim values [double]
            %   - vals_max = Max dim values [double]
            %   - size_ = Array size [int]
            
            % Format inputs
            if isrow(vals_min), vals_min = vals_min.'; end
            if isrow(vals_max), vals_max = vals_max.'; end
            
            % Construction
            obj@multi_array.Abstract(size_);
            obj.vals_min = vals_min;
            obj.vals_max = vals_max;
            obj.sub_to_val = (vals_max - vals_min) ./ (obj.size_.' - 1);
            obj.val_to_sub = 1 ./ obj.sub_to_val;
        end
        
        function val = get(obj, pos, fmt)
            %GET Get value in multi-range
            %   
            %   val = GET(obj, ind, 'Ind') Get by single index
            %   val = GET(obj, sub, 'Sub') Get by subscript array
            val = obj.conv(pos, fmt, 'Val');
        end
        
        function val = limit(obj, val)
            %val = LIMIT(obj, val) Limit val to range
            val = min(max(obj.vals_min, val), obj.vals_max);
        end
        
        function c = has(obj, val)
            %c = HAS(obj, val) Check if range contains val
            c = all(and(val >= obj.vals_min, val <= obj.vals_max));
        end
        
        function arr = get_arr(obj, dim)
            %arr = GET_ARR(obj, dim)
            %   Get array of dimension samples
            %   
            %   Inputs:
            %   - dim = Dimension [int, [1, obj.rank_]]
            arr = linspace(...
                obj.vals_min(dim), ...
                obj.vals_max(dim), ...
                obj.size_(dim));
        end
        
        function pos2 = conv(obj, pos1, fmt1, fmt2)
            %pos2 = CONV(obj, pos1, fmt1, fmt2)
            %   Convert between position formats
            %   
            %   Inputs:
            %   - pos1 = Input position
            %   - fmt1 = Format of input [char]
            %   - fmt2 = Format of output [char]
            %   
            %   Outputs:
            %   - pos2 = Output position
            %   
            %   Valid formats: 'Ind', 'Sub', 'Val'
            if isrow(pos1), pos1 = pos1.'; end
            if strcmp(fmt1, fmt2)
                pos2 = pos1;
            elseif strcmp(fmt1, 'Sub') && strcmp(fmt2, 'Val')
                pos2 = obj.conv_sub_val(pos1);
            elseif strcmp(fmt1, 'Val') && strcmp(fmt2, 'Sub')
                pos2 = obj.conv_val_sub(pos1);
            elseif strcmp(fmt1, 'Ind') && strcmp(fmt2, 'Val')
                pos2 = obj.conv_ind_val(pos1);
            elseif strcmp(fmt1, 'Val') && strcmp(fmt2, 'Ind')
                pos2 = obj.conv_val_ind(pos1);
            else
                pos2 = conv@multi_array.Abstract(obj, pos1, fmt1, fmt2);
            end
        end
    end
    
    methods (Access = protected)
        function pos2 = conv_sub_val(obj, pos1)
            %pos2 = CONV_SUB_VAL(obj, pos1) Convert Sub to Val
            pos2 = obj.sub_to_val .* (pos1 - 1) + obj.vals_min;
        end
        
        function pos2 = conv_val_sub(obj, pos1)
            %pos2 = CONV_VAL_SUB(obj, pos1) Convert Val to Sub
            pos2 = obj.val_to_sub .* (pos1 - obj.vals_min) + 1;
        end
        
        function pos2 = conv_ind_val(obj, pos1)
            %pos2 = CONV_IND_VAL(obj, pos1) Convert Ind to Val
            pos3 = obj.conv_ind_sub(pos1);
            pos2 = obj.conv_sub_val(pos3);
        end
        
        function pos2 = conv_val_ind(obj, pos1)
            %pos2 = CONV_VAL_IND(obj, pos1) Convert Val to Ind
            pos3 = obj.conv_val_sub(pos1);
            pos2 = obj.conv_sub_ind(round(pos3));
        end
    end
end