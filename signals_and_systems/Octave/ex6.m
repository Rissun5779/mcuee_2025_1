% 清除環境
clear; clf;

%% 連續時間系統 y(t) = x(t + 2)
% 定義時間軸
t = 0:0.01:5;

% 定義原訊號 x(t)
x_t = sin(t);

% 計算 y(t) = x(t+2)，用插值處理超出範圍部分補0
y_t = interp1(t, x_t, t + 2, 'linear', 0);

% 繪圖
subplot(2,1,1);
plot(t, x_t, 'b', 'LineWidth', 1.5);
hold on;
plot(t, y_t, 'r--', 'LineWidth', 1.5);
title('連續時間系統 y(t) = x(t+2)');
xlabel('t');
ylabel('Amplitude');
legend('x(t)', 'y(t) = x(t+2)');
grid on;
hold off;

%% 離散時間系統 y[n] = x[n/2 - 1]
% 定義原訊號 x[n]
n_x = 0:20;
x_n = sin(0.3 * pi * n_x);  % 範例訊號

% 定義輸出時間軸
n_y = 0:40;

% 計算 y[n] = x[n/2 - 1]
query_points = n_y / 2 - 1;

% 插值（超出範圍補0）
y_n = interp1(n_x, x_n, query_points, 'linear', 0);

% 繪圖
subplot(2,1,2);
stem(n_x, x_n, 'b', 'filled'); hold on;
stem(n_y, y_n, 'r', 'filled');
title('離散時間系統 y[n] = x[n/2 - 1]');
xlabel('n');
ylabel('Amplitude');
legend('x[n]', 'y[n] = x[n/2 - 1]');
grid on;
hold off;

