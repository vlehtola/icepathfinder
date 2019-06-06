classdef Heap < handle
%
% Abstract superclass for all heap classes
%
% Note: You cannot instantiate Heap objects directly; use MaxHeap or
%       MinHeap
%

    %
    % Protected properties
    %
    properties (Access = public)
        size;               % current number of elements
        nextId;             % next id value to use when adding elements to heap
        n;                  % heap capacity
        h;                  % heap array of elements to be sorted
        ids;                % array of integer ids associated with elements of h
      
    end
    
    %
    % Public methods
    %
    methods (Access = public)
        %
        % Constructor
        %
        function this = Heap(n,x0)
            % Initialize heap
            if (n == 0)
                Heap.ZeroCapacityError();
            end
            this.n = n;
            this.h = nan(n,1);
            this.ids = nan(n,1);
            this.nextId = 1;
            
            if ((nargin == 2) && ~isempty(x0))
                % Insert given elements
                k0 = numel(x0);
                if (k0 > n)
                    % Heap overflow
                    Heap.OverflowError();
                else
                    this.h(1:k0) = x0(:);
                    this.ids(1:k0) = 1:k0;
                    this.SetLength(k0);
                    this.nextId = k0+1;
                end
            else
                % Empty heap
                this.Clear();
            end
        end
        
        %
        % Return number of elements in heap
        %
        function count = Count(this)
            %-------------------------- Count -----------------------------
            % Syntax:       count = H.Count();
            %               
            % Outputs:      count is the number of values in H
            %               
            % Description:  Returns the number of values in H
            %--------------------------------------------------------------
            
            count = this.size;
        end
        
        %
        % Return heap capacity
        %
        function capacity = Capacity(this)
            %------------------------- Capacity ---------------------------
            % Syntax:       capacity = H.Capacity();
            %               
            % Outputs:      capacity is the size of H
            %               
            % Description:  Returns the maximum number of values that can 
            %               fit in H
            %--------------------------------------------------------------
            
            capacity = this.n;
        end
        
        %
        % Check for empty heap
        %
        function bool = IsEmpty(this)
            %------------------------- IsEmpty ----------------------------
            % Syntax:       bool = H.IsEmpty();
            %               
            % Outputs:      bool = {true,false}
            %               
            % Description:  Determines if H is empty
            %--------------------------------------------------------------
            
            if (this.size == 0)
                bool = true;
            else
                bool = false;
            end
        end
        
        %
        % Check for full heap
        %
        function bool = IsFull(this)
            %-------------------------- IsFull ----------------------------
            % Syntax:       bool = H.IsFull();
            %               
            % Outputs:      bool = {true,false}
            %               
            % Description:  Determines if H is full
            %--------------------------------------------------------------
            
            if (this.size == this.n)
                bool = true;
            else
                bool = false;
            end
        end
        
        %
        % Clear the heap
        %
        function Clear(this)
            %-------------------------- Clear -----------------------------
            % Syntax:       H.Clear();
            %               
            % Description:  Removes all values from H
            %--------------------------------------------------------------
            
            this.SetLength(0);
        end
    end
    
    %
    % Abstract methods
    %
    methods (Abstract)
        %
        % Sort elements
        %
        Sort(this);
        
        %
        % Insert key
        %
        InsertKey(this,key);
    end
    
    %
    % Protected methods
    %
    methods (Access = protected)
        %
        % Swap elements
        %
        function Swap(this,i,j)
            val = this.h(i);
            id = this.ids(i);
            this.h(i) = this.h(j);
            this.ids(i) = this.ids(j);
            this.h(j) = val;
            this.ids(j) = id;
        end
        
        %
        % Set length
        %
        function SetLength(this,k)
            if (k < 0)
                Heap.UnderflowError();
            elseif (k > this.n)
                Heap.OverflowError();
            end
            this.size = k;
        end
    end
    
    %
    % Protected static methods
    %
    methods (Access = protected, Static = true)
        %
        % Parent node
        %
        function p = parent(i)
            p = floor(i / 2);
        end
        
        %
        % Left child node
        %
        function l = left(i)
            l = 2 * i;
        end
        
        % Right child node
        function r = right(i)
            r = 2 * i + 1;
        end
        
        %
        % Overflow error
        %
        function OverflowError()
            error('Heap overflow');
        end
        
        %
        % Underflow error
        %
        function UnderflowError()
            error('Heap underflow');
        end
        
        %
        % No capacity error
        %
        function ZeroCapacityError()
            error('Heap with no capacity is not allowed');
        end
    end
end
