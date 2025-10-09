% 清除變數
clear;
clf;

% 定義離散時間軸 n (包含負數)
n = -15:31;  % 從 -15 到 31

% 定義訊號
x1 = cos((pi/8)*n);
x2 = cos((15*pi/8)*n);

% 畫圖
figure;

subplot(2,1,1);
stem(n, x1, 'filled');
title('x_1[n] = cos(n\pi/8)');
xlabel('n');
ylabel('x_1[n]');
grid on;

subplot(2,1,2);
stem(n, x2, 'filled');
title('x_2[n] = cos(15n\pi/8)');
xlabel('n');
ylabel('x_2[n]');
grid on;

