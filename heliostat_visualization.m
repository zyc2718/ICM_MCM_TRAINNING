function heliostat_visualization_fixed
    % 1. 参数设置
    H_t = 100;       % 塔高(m)
    N = 48;          % 定日镜数量
    rho = 0.88;      % 反射率
    phi = 35;        % 纬度(°)
    
    % 2. 生成定日镜场布局
    [x, y, z] = generate_heliostat_layout(N);
    
    % 3. 创建主图形窗口
    fig_main = figure('Position', [100, 100, 1400, 800], 'Name', 'Heliostat Field Simulation', 'Color', [0.95 0.95 0.95]);
    
    % 3.1 主3D视图
    ax1 = subplot(2, 3, [1, 2, 4, 5]);
    hold(ax1, 'on');
    axis equal;
    grid on;
    view(45, 30);
    xlabel('East (m)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('North (m)', 'FontSize', 12, 'FontWeight', 'bold');
    zlabel('Height (m)', 'FontSize', 12, 'FontWeight', 'bold');
    title('3D Heliostat Field with Real-time Reflection Tracking', 'FontSize', 14, 'FontWeight', 'bold');
    xlim([-150, 150]);
    ylim([-150, 150]);
    zlim([0, 180]);
    
    % 3.2 能量热力图
    ax2 = subplot(2, 3, 3);
    title('Energy Collection Efficiency Heatmap', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('East (m)', 'FontSize', 10);
    ylabel('North (m)', 'FontSize', 10);
    grid on;
    axis equal;
    xlim([-150, 150]);
    ylim([-150, 150]);
    
    % 3.3 效率统计图
    ax3 = subplot(2, 3, 6);
    title('Performance Metrics', 'FontSize', 12, 'FontWeight', 'bold');
    xlabel('Time (hours)', 'FontSize', 10);
    ylabel('Efficiency', 'FontSize', 10);
    grid on;
    hold on;
    ylim([0, 1]);
    
    % 4. 创建单独的雷达图窗口
    fig_radar = figure('Position', [200, 200, 600, 600], 'Name', 'Sun Path Radar', 'Color', [0.98 0.98 0.98]);
    ax_radar = polaraxes;
    hold on;
    ax_radar.ThetaZeroLocation = 'top';
    ax_radar.ThetaDir = 'clockwise';
    ax_radar.RLim = [0, 90];
    grid on;
    
    % 5. 绘制静态装饰元素
    draw_static_elements(ax1, x, y, z, H_t);
    draw_sun_path_grid(ax_radar);
    
    % 6. 初始化数据存储
    time_data = [];
    total_energy_data = [];
    avg_efficiency_data = [];
    
    % 7. 动画循环
    for frame = 1:100
        % 计算当前时间
        doy = 172;  % 夏至日
        hour = 6 + frame/10;  % 从6点到16点
        
        [alpha_s, gamma_s] = solar_position(doy, hour, phi);
        
        if alpha_s < 0
            continue;
        end
        
        % 清除动态元素
        clear_dynamic_elements(ax1, ax2, ax3, ax_radar);
        
        % 更新可视化
        [total_energy, avg_efficiency, active_mirrors] = update_visualization(ax1, ax2, ax3, ax_radar, ...
            x, y, z, H_t, alpha_s, gamma_s, rho, hour, frame);
        
        % 存储数据用于趋势图
        time_data(end+1) = hour;
        total_energy_data(end+1) = total_energy;
        avg_efficiency_data(end+1) = avg_efficiency;
        
        % 更新趋势图 - 修复xlim错误
        update_trend_plot(ax3, time_data, total_energy_data, avg_efficiency_data);
        
        % 更新标题
        update_titles(fig_main, fig_radar, doy, hour, total_energy, avg_efficiency, active_mirrors, N);
        
        drawnow;
        pause(0.05);
    end
end

function [x, y, z] = generate_heliostat_layout(N)
    % 生成多圈复杂布局
    circles = 3;
    mirrors_per_circle = round(N / circles);
    x = []; y = []; z = [];
    
    for circle = 1:circles
        radius = 30 + circle * 25;
        theta = linspace(0, 2*pi, mirrors_per_circle);
        x_circle = radius * cos(theta);
        y_circle = radius * sin(theta);
        z_circle = 6 + rand(1, mirrors_per_circle) * 2;
        
        x = [x, x_circle];
        y = [y, y_circle];
        z = [z, z_circle];
    end
end

function draw_static_elements(ax, x, y, z, H_t)
    % 绘制地面网格
    [X, Y] = meshgrid(-150:20:150, -150:20:150);
    Z = zeros(size(X));
    surf(ax, X, Y, Z, 'FaceColor', [0.3 0.6 0.3], 'FaceAlpha', 0.15, 'EdgeColor', [0.4 0.4 0.4], 'EdgeAlpha', 0.3);
    
    % 绘制吸收塔
    plot3(ax, [0, 0], [0, 0], [0, H_t], 'r-', 'LineWidth', 8, 'Color', [0.8 0.2 0.2]);
    scatter3(ax, 0, 0, H_t, 300, 'r', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 2);
    
    % 绘制定日镜底座
    for i = 1:length(x)
        plot3(ax, [x(i), x(i)], [y(i), y(i)], [0, z(i)], 'k-', 'LineWidth', 2);
        scatter3(ax, x(i), y(i), z(i), 80, 'b', 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
    end
    
    % 添加坐标指示器
    quiver3(ax, -140, -140, 5, 30, 0, 0, 'r', 'LineWidth', 2, 'MaxHeadSize', 1);
    quiver3(ax, -140, -140, 5, 0, 30, 0, 'g', 'LineWidth', 2, 'MaxHeadSize', 1);
    quiver3(ax, -140, -140, 5, 0, 0, 30, 'b', 'LineWidth', 2, 'MaxHeadSize', 1);
    text(ax, -100, -140, 5, 'East', 'Color', 'r', 'FontWeight', 'bold');
    text(ax, -140, -100, 5, 'North', 'Color', 'g', 'FontWeight', 'bold');
    text(ax, -140, -140, 40, 'Up', 'Color', 'b', 'FontWeight', 'bold');
end

function draw_sun_path_grid(ax_radar)
    % 绘制太阳轨迹网格
    thetas = 0:30:330;
    radii = 0:15:90;
    
    for r = radii
        polarplot(ax_radar, deg2rad(0:360), r*ones(1,361), '--', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
    end
    
    for theta = thetas
        polarplot(ax_radar, deg2rad([theta, theta]), [0, 90], '--', 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);
    end
end

function clear_dynamic_elements(ax1, ax2, ax3, ax_radar)
    % 清除动态元素
    delete(findobj(ax1, 'Tag', 'dynamic'));
    delete(findobj(ax2, 'Type', 'scatter'));
    delete(findobj(ax3, 'Type', 'line'));
    delete(findobj(ax_radar, 'Type', 'scatter'));
    delete(findobj(ax_radar, 'Type', 'text'));
end

function [total_energy, avg_efficiency, active_mirrors] = update_visualization(ax1, ax2, ax3, ax_radar, x, y, z, H_t, alpha_s, gamma_s, rho, hour, frame)
    % 计算太阳向量
    sun_vec = [cosd(alpha_s)*sind(gamma_s), ...
               cosd(alpha_s)*cosd(gamma_s), ...
               sind(alpha_s)];
    
    % 绘制太阳光线
    quiver3(ax1, 0, 0, 0, sun_vec(1)*200, sun_vec(2)*200, sun_vec(3)*200, ...
            'Color', [1 0.8 0], 'LineWidth', 3, 'MaxHeadSize', 0.3, 'Tag', 'dynamic');
    
    % 计算能量和绘制反射
    energies = zeros(1, length(x));
    valid_mirrors = 0;
    
    for i = 1:length(x)
        M_i = [x(i), y(i), z(i)];
        T = [0, 0, H_t];
        r_vec = (T - M_i) / norm(T - M_i);
        i_vec = -sun_vec;
        
        % 计算法向量
        n_vec = (i_vec + r_vec) / norm(i_vec + r_vec);
        
        % 绘制反射光线
        quiver3(ax1, x(i), y(i), z(i), r_vec(1)*40, r_vec(2)*40, r_vec(3)*40, ...
                'Color', [1 0.5 0], 'LineWidth', 1.5, 'MaxHeadSize', 0.2, 'Tag', 'dynamic');
        
        % 计算能量
        eta_cos = max(0, dot(n_vec, -i_vec));
        if eta_cos > 0.1
            d = norm(M_i - T) / 1000;
            eta_atm = 0.99^d;
            energies(i) = eta_cos * eta_atm * rho;
            valid_mirrors = valid_mirrors + 1;
        end
    end
    
    % 更新热力图
    scatter(ax2, x, y, 120, energies, 'filled');
    colormap(ax2, 'hot');
    caxis(ax2, [0, 1]);
    colorbar(ax2);
    
    % 更新雷达图
    polarscatter(ax_radar, deg2rad(gamma_s), 90-alpha_s, 200, [1 0.8 0], 'filled');
    
    % 添加信息文本到雷达图
    [text_x, text_y] = pol2cart(deg2rad(45), 70);
    text(ax_radar, text_x, text_y, sprintf('Elevation: %.1f°\nAzimuth: %.1f°\nEfficiency: %.1f%%', ...
         alpha_s, gamma_s, mean(energies(energies>0))*100), 'FontSize', 10, ...
         'BackgroundColor', 'white', 'VerticalAlignment', 'top');
    
    % 计算统计信息
    total_energy = sum(energies);
    active_energies = energies(energies > 0);
    if ~isempty(active_energies)
        avg_efficiency = mean(active_energies);
    else
        avg_efficiency = 0;
    end
    active_mirrors = valid_mirrors;
end

function update_trend_plot(ax3, time_data, energy_data, efficiency_data)
    % 更新趋势图 - 修复xlim错误
    cla(ax3);
    
    if length(time_data) > 1
        % 确保有足够的数据点
        if max(energy_data) > 0
            normalized_energy = energy_data / max(energy_data);
        else
            normalized_energy = zeros(size(energy_data));
        end
        
        % 绘制曲线
        plot(ax3, time_data, normalized_energy, 'b-', 'LineWidth', 2, 'DisplayName', 'Normalized Energy');
        plot(ax3, time_data, efficiency_data, 'r-', 'LineWidth', 2, 'DisplayName', 'Avg Efficiency');
        legend(ax3, 'show', 'Location', 'northwest');
        
        % 修复xlim设置 - 确保是递增的二元素向量
        if length(time_data) >= 2
            x_min = min(time_data);
            x_max = max(time_data);
            if x_min < x_max
                xlim(ax3, [x_min, x_max]);
            else
                xlim(ax3, [x_min-1, x_max+1]);
            end
        end
    end
    
    ylim(ax3, [0, 1.1]);
    grid(ax3, 'on');
end

function update_titles(fig_main, fig_radar, doy, hour, total_energy, avg_efficiency, active_mirrors, total_mirrors)
    % 修复字符串格式问题
    time_str = sprintf('Day %d, %.1f:00', doy, hour);
    info_str = sprintf('Total Energy: %.2f | Avg Efficiency: %.1f%%', total_energy, avg_efficiency*100);
    
    % 更新主窗口标题
    figure(fig_main);
    sgtitle({sprintf('Heliostat Field Simulation - %s', time_str), info_str}, ...
            'FontSize', 16, 'FontWeight', 'bold');
    
    % 更新雷达图标题
    figure(fig_radar);
    title_str = sprintf('Sun Path Tracking - Day %d, %.1f:00\nTotal Mirrors: %d | Active: %d', ...
        doy, hour, total_mirrors, active_mirrors);
    title(title_str, 'FontSize', 14, 'FontWeight', 'bold');
end

function [alpha_s, gamma_s] = solar_position(doy, hour, phi)
    delta = 23.45 * sind(360*(doy-80)/365);
    h = 15 * (hour - 12);
    
    alpha_s = asind(sind(phi)*sind(delta) + cosd(phi)*cosd(delta)*cosd(h));
    
    % 修正方位角计算
    sin_gamma = cosd(delta) * sind(h) / cosd(alpha_s);
    cos_gamma = (sind(delta)*cosd(phi) - cosd(delta)*sind(phi)*cosd(h)) / cosd(alpha_s);
    gamma_s = atan2d(sin_gamma, cos_gamma);
    
    if gamma_s < 0
        gamma_s = gamma_s + 360;
    end
end
