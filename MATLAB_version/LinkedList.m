% 一开始使用的是普通的数组直接存储生物，但是由于频繁删除或增加数组中的数据会拖慢运行速度，就改成了用链表存储，但是链表的访问和修改操作都需要递归，这在链表较长时也是耗时的，故收效甚微
% 之后可以学习一下使用GPU运行和并行运算等方法加快速度
classdef LinkedList < handle
    properties
        data % 存储节点中的数据
        next % 存储下一个节点对象的引用
    end
    
    methods
        function obj = LinkedList(data)
            % 构造函数：创建一个新的链表节点，
            % 并将输入的数据存储在该节点中
            obj.data = data;
            obj.next = [];
        end
        
        function append(obj, data)
            % 向链表中添加新的节点，
            % 并将输入的数据存储在新节点中
            if isempty(obj.next)
                obj.next = LinkedList(data);
            else
                obj.next.append(data);
            end
        end
        
        function delete(obj, index)
            % 删除指定位置的节点，
            % index是要删除的节点的位置（从1开始计数）
            if index == 1
                % 如果要删除的节点是链表头节点
                if ~isempty(obj.next)
                    obj.data = obj.next.data;
                    obj.next = obj.next.next;
                else
                    obj.data = [];
                end
            else
                % 如果要删除的节点不是链表头节点
                if ~isempty(obj.next)
                    obj.next.delete(index - 1);
                else
                    error('Index out of range');
                end
            end
        end
        
        function node = get(obj, index)
            % 获取指定位置的节点的值，
            % index是要获取的节点的位置（从1开始计数）
            if index == 1
                % 如果要获取的节点是链表头节点
                node = obj.data;
            else
                % 如果要获取的节点不是链表头节点
                if ~isempty(obj.next)
                    node = obj.next.get(index - 1);
                else
                    error('Index out of range');
                end
            end
        end
        
        function modify(obj, index, value)
            % 修改指定位置的节点的值，
            % index是要修改的节点的位置（从1开始计数），
            % value是要修改的值
            if index == 1
                % 如果要修改的节点是链表头节点
                obj.data = value;
            else
                % 如果要修改的节点不是链表头节点
                if ~isempty(obj.next)
                    obj.next.modify(index - 1, value);
                else
                    error('Index out of range');
                end
            end
        end
        
        function len = length(obj)
            % 返回链表中节点的数量
            if isempty(obj.data)
                len = 0;
            elseif isempty(obj.next)
                len = 1;
            else
                len = obj.next.length() + 1;
            end
        end

        function merge(obj, varargin)
            % 合并多个链表到当前链表中
            for i = 1:numel(varargin)  % 遍历输入的多个链表
                list = varargin{i};
                if ~isempty(list)  % 如果链表非空
                    obj.append(list.data);  % 将链表头节点的数据添加到当前链表中
                    obj.next.merge(list.next);  % 递归合并链表中剩余的节点
                end
            end
        end
        
        function display(obj)
            % 显示链表中所有节点的数据
            disp(obj.data);
            if ~isempty(obj.next)
                obj.next.display();
            end
        end
    end
end