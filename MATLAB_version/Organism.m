% 此处设定的一个种群的特征包括寿命均值，初始资源均值和策略
classdef Organism
    properties (Access = private)
        kind
        resource % 资源
        max_res % 最大资源，达到最大资源时分裂增殖（经过随机处理的真实资源）
        lifespan % 寿命（经过随机处理的真实寿命）
        op_prob % 选择合作的概率
        avg_resource % 种群初始平均资源
        avg_lifespan % 种群平均寿命（参与博弈的次数）
    end

    methods

        function o = Organism(kind,avg_resource,max_res,avg_lifespan,op_prob) % 构造函数
            % 随机量设置
            r_life = 0.1 * avg_lifespan * randn();
            if (r_life > avg_lifespan) || (r_life < -avg_lifespan)
                r_life = 0;
            end
            r_res = 0.1 * avg_resource * randn();
            if (r_res > avg_resource) || (r_res < -avg_resource)
                r_res = 0;
            end
            % 对象初始化
            o.kind = kind;
            o.resource = avg_resource + r_res; % 为种群中初始资源配置增加随机性
            o.max_res = max_res;
            o.lifespan = avg_lifespan + r_life; % 为种群中寿命配置增加随机性
            o.op_prob = op_prob;
            o.avg_resource = avg_resource;
            o.avg_lifespan = avg_lifespan;
        end

        function result = strategy(o) % 概率分布型策略
            if rand() < o.op_prob
                result = "合作";
            else
                result = "竞争";
            end
        end

        function [o,org_list] = prolife_list(o,org_list) % 链表中的增殖函数
            o.resource = o.avg_resource; % 增殖后原生物回归平均初始资源
            org = Organism(o.kind,o.avg_resource,o.max_res,o.avg_lifespan,o.op_prob);
            org_list.append(org);
        end

        function [o,org_mat] = prolife_mat(o,org_mat,i,j,max_migrate_num) % cell矩阵中的增殖函数
            o.resource = o.avg_resource;
            num_rows = size(org_mat,1); % 地图的行数
            num_cols = size(org_mat,2); % 地图的列数
            org = Organism(o.kind,o.avg_resource,o.max_res,o.avg_lifespan,o.op_prob);
            migrate_num = 0; % 迁移次数
            % 每一步随机选择方向，直到到达一个无生物的位置，模拟生物为了空间和资源而进行的迁移
            % 但是迁移的长度是有限度的，在超出限度时会进行生存斗争（资源比较）以栖息于新的地方
            while ~isempty(org_mat{i,j}) || migrate_num <= max_migrate_num
                migrate_num  = migrate_num + 1;
                ri = randi([-1,1], 1);
                rj = randi([-1,1], 1);
                i_before = i;
                j_before = j;
                i = i + ri;
                j = j + rj;
                if i < 1 || i > num_rows || j < 1 || j > num_cols % 如果跳出地图外，回到上次的位置，并来到下一个循环重新跳
                    i = i_before;
                    j = j_before;
                    continue
                end
            end
            if isempty(org_mat{i,j}) % 迁移到了空的位置，在此定居
                org_mat{i,j} = org;
            elseif migrate_num >= max_migrate_num  % 迁移到的位置有生物存在，达到了最大迁移次数，进行生存斗争
                if org.get_res() >= org_mat{i,j}
                    org_mat{i,j} = org;
                end
            end
        end

        function output = get_res(o) % 获取resource
            output = o.resource;
        end

        function o = set_res(o,new_res) % 更改resource
            o.resource = new_res;
        end

        function output = get_maxres(o) % 获取max_resource
            output = o.max_res;
        end

        function o = set_life(o,new_life) % 更改所剩寿命
            o.lifespan = new_life;
        end

        function output = get_life(o) % 获取所剩寿命
            output = o.lifespan;
        end

        function output = get_kind(o) % 获取所属种类
            output = o.kind;
        end

    end
end