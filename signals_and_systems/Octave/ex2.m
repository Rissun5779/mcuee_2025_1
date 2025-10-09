% 清除變數與圖形
clear;
clf;

% === 連續時間函數定義 ===
t = -2:0.01:5;
x1 = 3 * exp(-t);     % x(t) = 3e^(-t)
x2 = -3 * exp(t);     % x(t) = -3e^t

% === 離散時間函數定義 ===
n = 0:10;
x3 = (1/2).^n;         % x[n] = (1/2)^n
x4 = (-1/2).^n;        % x[n] = (-1/2)^n
x5 = (2).^n;           % x[n] = 2^n
x6 = (-2).^n;          % x[n] = -2^n

% === 畫圖 ===
figure;

% 1. x(t) = 3e^(-t)
subplot(3,2,1);
plot(t, x1, 'b', 'LineWidth', 2);
title('x(t) = 3e^{-t}');
xlabel('t');
ylabel('x(t)');
grid on;

% 2. x(t) = -3e^t
subplot(3,2,2);
plot(t, x2, 'r', 'LineWidth', 2);
title('x(t) = -3e^{t}');
xlabel('t');
ylabel('x(t)');
grid on;

% 3. x[n] = (1/2)^n
subplot(3,2,3);
stem(n, x3, 'filled', 'LineWidth', 1.5);
title('x[n] = (1/2)^n');
xlabel('n');
ylabel('x[n]');
grid on;

% 4. x[n] = (-1/2)^n
subplot(3,2,4);
stem(n, x4, 'filled', 'LineWidth', 1.5);
title('x[n] = (-1/2)^n');
xlabel('n');
ylabel('x[n]');
grid on;

% 5. x[n] = 2^n
subplot(3,2,5);
stem(n, x5, 'filled', 'LineWidth', 1.5);
title('x[n] = 2^n');
xlabel('n');
ylabel('x[n]');
grid on;

% 6. x[n] = -2^n
subplot(3,2,6);
stem(n, x6, 'filled', 'LineWidth', 1.5);
title('x[n] = -2^n');
xlabel('n');
ylabel('x[n]');
grid on;

