% ==================================================
% 離散時間訊號變換分析 + 圖形視覺化
% 原始訊號 x[n] 在 n < -2 或 n > 4 時為零，非零區間為 [-2, 4]
% 假設在非零區間內 x[n] = 1 (可自訂)
% ==================================================

close all;  % 關閉所有舊圖
clear all;  % 清除變數（可選）

% 定義原始非零區間
n_start = -2;
n_end   = 4;

% 建立原始訊號 x[n] —— 我們用 1 代表非零值（你可自訂為向量）
n_range_original = n_start : n_end;
x_original = ones(1, length(n_range_original));  % 全部設為 1，或可改為 [1,2,3,4,5,6,7]

% 定義繪圖用的完整 n 範圍（涵蓋所有轉換後可能的非零區間）
n_plot_min = -10;
n_plot_max = 10;
n_plot = n_plot_min : n_plot_max;

% 初始化原始訊號在完整範圍內（預設為 0）
x_full = zeros(1, length(n_plot));
% 填入原始非零值
for i = 1:length(n_range_original)
    idx = find(n_plot == n_range_original(i));
    if ~isempty(idx)
        x_full(idx) = x_original(i);
    end
end

% 繪製原始訊號
figure(1);
subplot(3,2,1);
stem(n_plot, x_full, 'filled', 'LineWidth', 2);
title('原始訊號 x[n]');
xlabel('n');
ylabel('x[n]');
grid on;
axis([n_plot_min n_plot_max -0.5 1.5]);

% ========== (a) x[n-3] = 右移 3 ==========
x_a = zeros(1, length(n_plot));
for i = 1:length(n_plot)
    n = n_plot(i);
    original_n = n - 3;  % 因為是 x[n-3]，要查原始 x 在 n-3 的值
    if original_n >= n_start && original_n <= n_end
        % 假設原始 x[original_n] = 1，或可對應索引（這裡簡化為 1）
        x_a(i) = 1;
    else
        x_a(i) = 0;
    end
end

subplot(3,2,2);
stem(n_plot, x_a, 'filled', 'LineWidth', 2);
title('x[n-3] (右移 3)');
xlabel('n');
ylabel('x[n-3]');
grid on;
axis([n_plot_min n_plot_max -0.5 1.5]);

% ========== (b) x[n+4] = 左移 4 ==========
x_b = zeros(1, length(n_plot));
for i = 1:length(n_plot)
    n = n_plot(i);
    original_n = n + 4;  % x[n+4] 對應原始 x[n+4]
    if original_n >= n_start && original_n <= n_end
        x_b(i) = 1;
    else
        x_b(i) = 0;
    end
end

subplot(3,2,3);
stem(n_plot, x_b, 'filled', 'LineWidth', 2);
title('x[n+4] (左移 4)');
xlabel('n');
ylabel('x[n+4]');
grid on;
axis([n_plot_min n_plot_max -0.5 1.5]);

% ========== (c) x[-n] = 時間反轉 ==========
x_c = zeros(1, length(n_plot));
for i = 1:length(n_plot)
    n = n_plot(i);
    original_n = -n;  % x[-n] 對應原始 x[-n]
    if original_n >= n_start && original_n <= n_end
        x_c(i) = 1;
    else
        x_c(i) = 0;
    end
end

subplot(3,2,4);
stem(n_plot, x_c, 'filled', 'LineWidth', 2);
title('x[-n] (時間反轉)');
xlabel('n');
ylabel('x[-n]');
grid on;
axis([n_plot_min n_plot_max -0.5 1.5]);

% ========== (d) x[-n+2] = x[-(n-2)] = 反轉再右移 2 ==========
x_d = zeros(1, length(n_plot));
for i = 1:length(n_plot)
    n = n_plot(i);
    original_n = -n + 2;  % 對應原始 x 在 -n+2 的值
    if original_n >= n_start && original_n <= n_end
        x_d(i) = 1;
    else
        x_d(i) = 0;
    end
end

subplot(3,2,5);
stem(n_plot, x_d, 'filled', 'LineWidth', 2);
title('x[-n+2]');
xlabel('n');
ylabel('x[-n+2]');
grid on;
axis([n_plot_min n_plot_max -0.5 1.5]);

% ========== (e) x[-n-2] = x[-(n+2)] = 反轉再左移 2 ==========
x_e = zeros(1, length(n_plot));
for i = 1:length(n_plot)
    n = n_plot(i);
    original_n = -n - 2;  % 對應原始 x 在 -n-2 的值
    if original_n >= n_start && original_n <= n_end
        x_e(i) = 1;
    else
        x_e(i) = 0;
    end
end

subplot(3,2,6);
stem(n_plot, x_e, 'filled', 'LineWidth', 2);
title('x[-n-2]');
xlabel('n');
ylabel('x[-n-2]');
grid on;
axis([n_plot_min n_plot_max -0.5 1.5]);

% 調整子圖間距
sgtitle('離散訊號 x[n] 變換示意圖 (假設非零區間值為 1)');
set(gcf, 'Position', [100, 100, 1000, 800]);  % 調整圖形視窗大小

% ======== 同時輸出文字結果（如之前）========
fprintf('========== 最終結果總結（為零範圍） ==========\n');
a_start = n_start + 3; a_end = n_end + 3;
b_start = n_start - 4; b_end = n_end - 4;
c_start = -n_end; c_end = -n_start; if c_start > c_end; temp=c_start; c_start=c_end; c_end=temp; end
d_start = -n_end + 2; d_end = -n_start + 2; if d_start > d_end; temp=d_start; d_start=d_end; d_end=temp; end
e_start = -n_end - 2; e_end = -n_start - 2; if e_start > e_end; temp=e_start; e_start=e_end; e_end=temp; end

fprintf('(a) x[n-3]    : n < %d 或 n > %d\n', a_start, a_end);
fprintf('(b) x[n+4]    : n < %d 或 n > %d\n', b_start, b_end);
fprintf('(c) x[-n]     : n < %d 或 n > %d\n', c_start, c_end);
fprintf('(d) x[-n+2]   : n < %d 或 n > %d\n', d_start, d_end);
fprintf('(e) x[-n-2]   : n < %d 或 n > %d\n', e_start, e_end);
