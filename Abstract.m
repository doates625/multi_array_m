classdef (Abstract) Abstract < handle
    %ABSTRACT Superclass for multi-array objects
    %   
    %   Author: Dan Oates (WPI Class of 2020)
    
    properties (SetAccess = protected)
        size_;      % Size array [int]
        rank_;      % Dimension count [int]
        numel_;     % Element count [int]
    end
    
    properties (Access = protected)
        sub_to_ind; % Sub to Ind array [double]
        ind_to_sub; % Ind to Sub array [double]
    end
    
    methods (Access = public)
        function obj = Abstract(size_)
            %obj = ABSTRACT(size_) Construct abstract of given size
            obj.rank_ = length(size_);
            if iscolumn(size_), size_ = size_.'; end
            if length(size_) == 1, size_ = [size_, 1]; end
            obj.size_ = size_;
            obj.numel_ = prod(size_);
            obj.sub_to_ind = cumprod([1, size_(1:end-1)]).';
            obj.ind_to_sub = 1 ./ obj.sub_to_ind;
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
            %   Valid formats: 'Ind', 'Sub'
            if isrow(pos1), pos1 = pos1.'; end
            if strcmp(fmt1, fmt2)
                pos2 = pos1;
            elseif strcmp(fmt1, 'Ind') && strcmp(fmt2, 'Sub')
                pos2 = obj.conv_ind_sub(pos1);
            elseif strcmp(fmt1, 'Sub') && strcmp(fmt2, 'Ind')
                pos2 = obj.conv_sub_ind(pos1);
            else
                error('Invalid: %s to %s', fmt1, fmt2);
            end
        end
    end
    
    methods (Access = protected)
        function pos2 = conv_ind_sub(obj, pos1)
            %pos2 = CONV_IND_SUB(obj, pos1) Convert Ind to Sub
            pos2 = mod(ceil(obj.ind_to_sub * pos1 - 1), obj.size_.') + 1;
        end
        
        function pos2 = conv_sub_ind(obj, pos1)
            %pos2 = CONV_SUB_IND(obj, pos1) Convert Sub to Ind
            pos2 = dot(obj.sub_to_ind, pos1 - 1) + 1;
        end
    end
end