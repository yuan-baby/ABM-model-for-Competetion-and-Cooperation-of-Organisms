classdef Game
    properties (Access = private)
        profit % 收益矩阵：第一组是都合作的收益，第二组是都竞争的收益，第三组是A竞争、B合作的收益，第四组是A合作、B竞争的收益
        round_num
    end

    methods
        function g = Game(profit,round_num) % 构造函数
            g.profit = profit;
            g.round_num = round_num;
        end

        function [organismA,organismB] = play(g,organismA,organismB) % 单次博弈
            strategy_pair = string([organismA.strategy(), organismB.strategy()]);
            switch strategy_pair
                case ["合作","合作"]
                    organismA = organismA.set_res(organismA.get_res() + g.profit(1,1));
                    organismB = organismB.set_res(organismB.get_res() + g.profit(1,2));
                case ["竞争","竞争"]
                    organismA = organismA.set_res(organismA.get_res() + g.profit(2,1));
                    organismB = organismB.set_res(organismB.get_res() + g.profit(2,2));
                case ["竞争","合作"]
                    organismA = organismA.set_res(organismA.get_res() + g.profit(3,1));
                    organismB = organismB.set_res(organismB.get_res() + g.profit(3,2));
                case ["合作","竞争"]
                    organismA = organismA.set_res(organismA.get_res() + g.profit(4,1));
                    organismB = organismB.set_res(organismB.get_res() + g.profit(4,2));
            end
            % 每次博弈减少一单位寿命
            organismA = organismA.set_life(organismA.get_life()-1);
            organismB = organismB.set_life(organismB.get_life()-1);
        end

        function [kind_map_array,org_list,end_round] = play_list(g,org_list) % 链表中的博弈函数
            i = 0;
            kind_map_array = cell(1,g.round_num);
            end_round = g.round_num;
            h = waitbar(0, 'Processing...','Name','博弈进度'); % 用于在外部观察博弈进程
            while i < g.round_num % 博弈轮次控制
                org_num = length(org_list);
                for j  = 1:org_num % 单次博弈中，将一个个生物拿出来，随机和数组中另外一个生物进行博弈
                    if j > length(org_list)
                        break
                    end
                    r = randi(length(org_list),1);
                    while r == j % 当r与j相同，则重新生成一个r
                        r = randi(length(org_list),1);
                    end
                    % 取出存储的生物
                    org_j = org_list.get(j);
                    org_r = org_list.get(r);
                    [org_j,org_r] = g.play(org_j,org_r); % 单次博弈
                    % 写回博弈后被修改的生物体
                    org_list.modify(j,org_j);
                    org_list.modify(r,org_r);
                    % 博弈完检查是否增殖
                    if org_j.get_res() >= org_j.get_maxres()
                        [org_j,org_list] = org_j.prolife_list(org_list);
                    end
                    if org_r.get_res() >= org_r.get_maxres()
                        [org_r,org_list] = org_r.prolife_list(org_list);
                    end
                    % 博弈完检查是否死亡（资源量少于0和寿命耗尽）
                    if org_j.get_res() <= 0 || org_j.get_life() <= 0
                        org_list.delete(j);
                        if r > j
                            r = r - 1;
                        end
                    end
                    if org_r.get_res() <= 0 || org_r.get_life() <= 0
                        org_list.delete(r);
                    end
                end
                i = i + 1; % 迭代控制
                waitbar(i/g.round_num, h, sprintf('Processing... %.2f%%', i*100/g.round_num)); % 用于在外部观察博弈进程
                kind_map = g.kind_map_list(org_list);
                if isempty(kind_map)
                    kind_map = kind_map_array{1};
                    kind = string(keys(kind_map));
                    for l = 1:length(kind)
                        kind_map(kind(1)) = 0;
                    end
                elseif i > 1 && length(keys(kind_map)) < length(keys(kind_map_array{i-1})) % 当某一种群数量变成0时，kind_map函数无法输出对应的键值对，这里在输出的kind_map中添加缺失的键值对
                    missing = setdiff( string(keys(kind_map_array{i-1})),string(keys(kind_map)) ); % 求差集：包含在前一个map中，而不包含在当前的map中的键
                    for k = 1:length(missing)
                        kind_map(missing(k)) = 0;
                    end
                end
                kind_map_array{i} = kind_map; % 装有每次迭代后种群数量信息的cell数组
                if length(org_list) > 10000
                    end_round = i;
                    break
                end
            end
            close(h);
        end

        function kind_map = kind_map_list(g,org_list) % map对象可以存储键值对，这里的kind_map存储"种类：数量"的键值对
            kind_map = containers.Map();
            for i = 1:length(org_list)
                kind = org_list.get(i).get_kind();
                % 有键则值+1，无键则新建键值对
                if isKey(kind_map,kind)
                    kind_map(kind) = kind_map(kind) + 1;
                else
                    kind_map(kind) = 1;
                end
            end
        end

        function [kind_map_array,org_mat] = play_mat(g,org_mat,max_migrate_num) % cell矩阵中的博弈函数
            num_rows = size(org_mat,1); % 地图的行数
            num_cols = size(org_mat,2); % 地图的列数
            kind_map_array = cell(1,g.round_num);
            h = waitbar(0, 'Processing...','Name','博弈进度'); % 用于在外部观察博弈进程
            for k = 1:g.round_num
                for i = 1:num_rows-1 % 一行行遍历；由于采用与下方生物进行博弈的规则，最后一行不用遍历
                    for j = 1:num_cols
                        if isempty(org_mat{i,j}) || j == num_cols % 如果这个位置没有生物，跳到下一个循环去遍历下一个生物；一行的最后一个位置由于采用与右方生物博弈的规则不需要遍历
                            continue
                        end
                        % 保证存在生物的情况下，与右方或下方的生物进行博弈（地理因素的制约，只能与临近位置的生物博弈）
                        if ~isempty(org_mat{i,j+1})
                            [org_mat{i,j},org_mat{i,j+1}] = g.play(org_mat{i,j},org_mat{i,j+1});
                        end
                        if ~isempty(org_mat{i+1,j})
                            [org_mat{i,j},org_mat{i+1,j}] = g.play(org_mat{i,j},org_mat{i+1,j});
                        end
                        % 博弈完检查是否增殖
                        if org_mat{i,j}.get_res() >= org_mat{i,j}.get_maxres()
                            [org_mat{i,j},org_mat] = prolife_mat(org_mat{i,j},org_mat,i,j,max_migrate_num);
                        end
                        % 博弈完检查是否死亡
                        if org_mat{i,j}.get_res() <= 0 || org_mat{i,j}.get_life() <= 0
                            org_mat{i,j} = [];
                        end
                    end
                end
                waitbar(k/g.round_num, h, sprintf('Processing... %.2f%%', k*100/g.round_num)); % 用于在外部观察博弈进程
                kind_map  = g.kind_map_mat(org_mat);
                if isempty(kind_map)
                    kind_map = kind_map_array{1};
                    kind = string(keys(kind_map));
                    for l = 1:length(kind)
                        kind_map(kind(1)) = 0;
                    end
                elseif k > 1 && length(keys(kind_map)) < length(keys(kind_map_array{k-1})) % 当某一种群数量变成0时，kind_map函数无法输出对应的键值对，这里在输出的kind_map中添加缺失的键值对
                    missing = setdiff( string(keys(kind_map_array{k-1})),string(keys(kind_map)) ); % 求差集：包含在前一个map中，而不包含在当前的map中的键
                    for l = 1:length(missing)
                        kind_map(missing(l)) = 0;
                    end
                end
                kind_map_array{k} = kind_map; % 装有每次迭代后种群数量信息的cell数组
                disp("迭代轮次"+num2str(k))
                g.draw_mat(org_mat)
            end
            close(h);
        end

        function kind_map = kind_map_mat(g,org_mat) % map对象可以存储键值对，这里的kind_map存储"种类：数量"的键值对
            kind_map = containers.Map();
            num_rows = size(org_mat,1); % 地图的行数
            num_cols = size(org_mat,2); % 地图的列数
            for i = 1:num_rows
                for j = 1:num_cols
                    if isempty(org_mat{i,j})
                            continue
                    end
                    kind = org_mat{i,j}.get_kind();
                    % 有键则值+1，无键则新建键值对
                    if isKey(kind_map,kind)
                        kind_map(kind) = kind_map(kind) + 1;
                    else
                        kind_map(kind) = 1;
                    end
                end
            end
        end

        function draw_mat(g,org_mat)
            % 定义每种种类的Organism对象对应的颜色
            colors = containers.Map();
            colors('A') = [0, 0, 1]; % 蓝色
            colors('B') = [1, 0, 0]; % 红色
            colors('C') = [1, 1, 0]; % 黄色
            colors('D') = [0, 1, 0]; % 绿色
            colors('E') = [1, 0, 1]; % 紫色
            colors('F') = [0, 1, 1]; % 青色
            colors('G') = [1, 0.5, 0]; % 橙色
            % 显示网格图
            figure;
            hold on;
            for i = 1:size(org_mat, 1)
                for j = 1:size(org_mat, 2)
                    x = [j - 0.5, j + 0.5, j + 0.5, j - 0.5];
                    y = [i - 0.5, i - 0.5, i + 0.5, i + 0.5];
                    if ~isempty(org_mat{i, j})
                        color = colors(org_mat{i, j}.get_kind());
                        patch(x, y, color);
                    end
                end
            end
            hold off;
            axis equal;
            xlim([0.5, size(org_mat, 2) + 0.5]);
            ylim([0.5, size(org_mat, 1) + 0.5]);
            set(gca, 'ytick', 1:size(org_mat, 1), 'xtick', 1:size(org_mat, 2), 'xticklabel', {}, 'yticklabel', {});
            xlabel('X');
            ylabel('Y');
        end
                    
    end
end