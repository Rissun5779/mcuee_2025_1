% === 離散時間諧波訊號範例 ===
%
% 腳本目的：
% 1. 產生不同頻率 (k 值) 的離散時間訊號。
% 2. 證明當 k 值增加 N 時，訊號會重複。

clear; % 清除所有變數
clc;   % 清除命令視窗

% --- 設定參數 ---
% 訊號的週期長度
N = 8;

% 離散時間索引，從 0 到 N-1
n = 0:(N-1);

% --- 產生並繪製訊號 ---
% 這裡我們只繪製訊號的實部 (cos 波形) 以便觀察

% 1. 基本頻率訊號 (k=1)
% 理論上，這是最基本的波形，在 N=8 的點內完成一個週期。
k1 = 1;
phi1 = exp(j * (2 * pi / N) * k1 * n);

figure;
stem(n, real(phi1));
title('phi_1[n] (k=1)');
xlabel('n (時間索引)');
ylabel('振幅');
axis tight;
grid on;
set(gca, 'xtick', 0:N-1); % 設定 x 軸刻度為整數

% ---

% 2. 更高頻率的訊號 (k=3)
% 理論上，波形會在 N=8 的點內重複 3 次。
k3 = 3;
phi3 = exp(j * (2 * pi / N) * k3 * n);

figure;
stem(n, real(phi3));
title('phi_3[n] (k=3)');
xlabel('n (時間索引)');
ylabel('振幅');
axis tight;
grid on;
set(gca, 'xtick', 0:N-1);

% ---

% 3. 證明重複性：k = N+1 (也就是 k=9)
% 理論上，這個訊號會和 k=1 的訊號完全一樣。
k_replicate = N + 1; % k = 8 + 1 = 9
phi_replicate = exp(j * (2 * pi / N) * k_replicate * n);

figure;
stem(n, real(phi_replicate));
title('phi_{9}[n] (k=9)');
xlabel('n (時間索引)');
ylabel('振幅');
axis tight;
grid on;
set(gca, 'xtick', 0:N-1);

% ---

% 4. 數值比較 (可選)
% 檢查 phi1 和 phi_replicate 是否在每個點上都相等。
% 注意：由於浮點數運算，可能會有微小的誤差，所以通常用容忍度來比較。
% 這裡的結果會是 1 (true)，代表兩個矩陣在每一個點上都相同。
disp('--- 數值比較 ---');
is_equal = isequal(round(real(phi1)*1e6), round(real(phi_replicate)*1e6));
if is_equal
    disp('phi_1[n] 和 phi_9[n] 數值完全相等，證明週期性。');
else
    disp('phi_1[n] 和 phi_9[n] 數值不相等。');
end
