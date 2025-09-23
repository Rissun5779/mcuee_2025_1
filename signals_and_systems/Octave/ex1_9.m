% ==================================================
% 週期性訊號分析 - 使用 Octave 模擬與繪圖
% ==================================================

close all;
clear all;

%% ========== (a) x1(t) = j * exp(j*10*t) = j * cos(10t) + j^2 sin(10t) = j*cos(10t) - sin(10t)
% 即：x1(t) = -sin(10t) + j*cos(10t)
% 這是純虛數振盪，頻率 ω = 10 rad/s
% 週期：T0 = 2π / 10 = π/5 ≈ 0.628

figure(1);
subplot(3,2,1);
t = linspace(0, 2*pi, 1000);  % 足夠長以觀察週期
x1 = 1j * exp(1j*10*t);
plot(t, real(x1), 'r', 'LineWidth', 1.5); hold on;
plot(t, imag(x1), 'b--', 'LineWidth', 1.5);
legend('Real', 'Imag');
title('x_1(t) = j e^{j10t}');
xlabel('t');
ylabel('x_1(t)');
grid on;
hold off;

fprintf('\n(a) x_1(t) = j e^{j10t}\n');
fprintf('   週期性：是\n');
fprintf('   基本週期 T_0 = 2π/10 = %.4f\n', 2*pi/10);

%% ========== (b) x2(t) = exp((-1 + j)t) = e^{-t} * e^{jt}
% 實部：e^{-t}cos(t)，虛部：e^{-t}sin(t)
% 因為有 e^{-t} → 指數衰減，不會重複 → 不週期！

figure(2);
t = 0:0.01:5;
x2 = exp((-1 + 1j)*t);
subplot(2,1,1);
plot(t, real(x2), 'r', 'LineWidth', 1.5);
title('Real part of x_2(t)');
xlabel('t');
ylabel('Re[x_2(t)]');
grid on;

subplot(2,1,2);
plot(t, imag(x2), 'b', 'LineWidth', 1.5);
title('Imaginary part of x_2(t)');
xlabel('t');
ylabel('Im[x_2(t)]');
grid on;

fprintf('(b) x_2(t) = e^{(-1+j)t}\n');
fprintf('   週期性：否\n');
fprintf('   原因：有衰減因子 e^{-t}，非週期\n');

%% ========== (c) x3[n] = e^{j7πn}
% ω₀ = 7π
% 檢查是否週期：ω₀ / (2π) = 7π / 2π = 7/2 = 3.5 → 有理數 → 是週期
% 找最小 N 使得 7π N = 2π k ⇒ 7N = 2k ⇒ N = 2k/7
% 最小整數 N：令 k=7 → N=2 → 檢查：7π×2 = 14π = 2π×7 → 成立
% 故基本週期 N₀ = 2

n_c = 0:10;
x3 = exp(1j*7*pi*n_c);
figure(3);
stem(n_c, real(x3), 'r', 'filled');
hold on;
stem(n_c, imag(x3), 'b', 'filled');
legend('Real', 'Imag');
title('x_3[n] = e^{j7πn}');
xlabel('n');
ylabel('x_3[n]');
grid on;
hold off;

fprintf('(c) x_3[n] = e^{j7πn}\n');
fprintf('   週期性：是\n');
fprintf('   基本週期 N_0 = 2\n');

%% ========== (d) x4[n] = 3 e^{j3π(n + 1/2)/5} = 3 e^{j3πn/5 + j3π/10}
% 化簡：x4[n] = 3 e^{j3π/10} e^{j3πn/5}
% 由於常數相位不影響週期性，只看 e^{j3πn/5}
% ω₀ = 3π/5
% ω₀/(2π) = (3π/5)/(2π) = 3/10 → 有理數 → 是週期
% 找最小 N 使得 (3π/5)N = 2πk ⇒ 3N/5 = 2k ⇒ 3N = 10k
% 最小整數解：k=3, N=10 → 3×10 = 10×3 → 成立
% 故基本週期 N₀ = 10

n_d = 0:15;
x4 = 3 * exp(1j * 3*pi*(n_d + 0.5)/5);
figure(4);
stem(n_d, real(x4), 'r', 'filled');
hold on;
stem(n_d, imag(x4), 'b', 'filled');
legend('Real', 'Imag');
title('x_4[n] = 3 e^{j3π(n+1/2)/5}');
xlabel('n');
ylabel('x_4[n]');
grid on;
hold off;

fprintf('(d) x_4[n] = 3 e^{j3π(n+1/2)/5}\n');
fprintf('   週期性：是\n');
fprintf('   基本週期 N_0 = 10\n');

%% ========== (e) x5[n] = 3 e^{j3(5n + 1/2)} = 3 e^{j15n + j3/2}
% = 3 e^{j3/2} e^{j15n}
% ω₀ = 15 rad
% ω₀/(2π) = 15/(2π) ≈ 2.387 → 無理數？但注意：離散時訊號週期性取決於 ω₀ 是否為 2π 的有理倍數
% ω₀ = 15 → ω₀/(2π) = 15/(2π) → 無理數 → 不週期！

% 檢查：是否存在 N 使得 15N = 2πk？→ 除非 k/N = 15/(2π)，但 15/(2π) 是無理數 → 不可能
% 所以不是週期！

n_e = 0:15;
x5 = 3 * exp(1j * 3*(5*n_e + 0.5));
figure(5);
stem(n_e, real(x5), 'r', 'filled');
hold on;
stem(n_e, imag(x5), 'b', 'filled');
legend('Real', 'Imag');
title('x_5[n] = 3 e^{j3(5n+1/2)}');
xlabel('n');
ylabel('x_5[n]');
grid on;
hold off;

fprintf('(e) x_5[n] = 3 e^{j3(5n+1/2)}\n');
fprintf('   週期性：否\n');
fprintf('   原因：ω₀ = 15 rad，ω₀/(2π) = 15/(2π) 是無理數 → 不週期\n');

%% ======== 最終總結 ========
fprintf('\n================== 總結 ==================\n');
fprintf('(a) x_1(t): 是週期，T_0 = %.4f\n', 2*pi/10);
fprintf('(b) x_2(t): 否，因有衰減項 e^{-t}\n');
fprintf('(c) x_3[n]: 是週期，N_0 = 2\n');
fprintf('(d) x_4[n]: 是週期，N_0 = 10\n');
fprintf('(e) x_5[n]: 否，因 ω₀/(2π) = 15/(2π) 無理數\n');
