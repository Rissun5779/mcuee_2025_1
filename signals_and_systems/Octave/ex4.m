% 離散時間訊號
n = 0:20;
x_n = cos((2*pi/3)*n);

% 連續時間訊號
t = 0:0.01:20;
x_t = sin((2*pi/3)*t);

% 畫圖
figure;

subplot(2,1,1);
stem(n, x_n, 'filled');
title('A. x[n] = cos(2πn/3)');
xlabel('n');
ylabel('x[n]');
grid on;

subplot(2,1,2);
plot(t, x_t);
title('B. x(t) = sin(2πt/3)');
xlabel('t');
ylabel('x(t)');
grid on;

