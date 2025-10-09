% 定義時間軸
t = -1:0.001:2;

% 定義 x(t) 分段函數
x = zeros(size(t));
for i = 1:length(t)
    if t(i) >= 0 && t(i) < 1
        x(i) = 2;
    elseif t(i) >= 1 && t(i) < 2
        x(i) = 1;
    else
        x(i) = 0;
    end
end

% 計算 y(t) = x((-3t)/2 + 1)
tau = (-3*t)/2 + 1;

% 使用內插法取得 x(tau)
y = interp1(t, x, tau, 'linear', 0);  % 超出定義區間時補 0

% 畫圖
figure;

subplot(2,1,1);
plot(t, x, 'b', 'LineWidth', 2);
title('x(t)');
xlabel('t');
ylabel('x(t)');
grid on;

subplot(2,1,2);
plot(t, y, 'r', 'LineWidth', 2);
title('y(t) = x((-3t)/2 + 1)');
xlabel('t');
ylabel('y(t)');
grid on;

