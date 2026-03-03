import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import pandas as pd
import numpy as np
import json
import os


# ==========================================
# 1. 网络结构 (严格参考文章 nn.LSTM 规范)
# ==========================================
class EnviroLSTM(nn.Module):
    def __init__(self, input_size, hidden_size, num_layers, output_points):
        super(EnviroLSTM, self).__init__()
        self.hidden_size = hidden_size
        self.num_layers = num_layers
        self.lstm = nn.LSTM(input_size, hidden_size, num_layers, batch_first=True)
        self.fc = nn.Linear(hidden_size, output_points * 2)

    def forward(self, x, device):
        h0 = torch.zeros(self.num_layers, x.size(0), self.hidden_size).to(device)
        c0 = torch.zeros(self.num_layers, x.size(0), self.hidden_size).to(device)
        out, (hn, cn) = self.lstm(x, (h0, c0))
        return self.fc(out[:, -1, :])


# ==========================================
# 2. 数据处理 (遵循 double 指令)
# ==========================================
class EnviroDataset(Dataset):
    def __init__(self, csv_path, window_size=60, output_points=60):
        df = pd.read_csv(csv_path)
        df['timestamp'] = pd.to_datetime(df.iloc[:, 0])
        df['time_delta'] = df['timestamp'].diff().dt.total_seconds().fillna(0)

        # 初始处理使用 double
        self.data_raw = df[['temp', 'hum', 'time_delta']].values.astype(np.float64)

        # 归一化
        self.mins = self.data_raw.min(axis=0)
        self.maxs = self.data_raw.max(axis=0)
        self.data = (self.data_raw - self.mins) / (self.maxs - self.mins + 1e-6)

        self.window_size = window_size
        self.output_points = output_points

    def __len__(self):
        return len(self.data) - self.window_size - self.output_points

    def __getitem__(self, idx):
        x = self.data[idx: idx + self.window_size]
        y_temp = self.data[idx + self.window_size: idx + self.window_size + self.output_points, 0]
        y_hum = self.data[idx + self.window_size: idx + self.window_size + self.output_points, 1]
        # 返回 float32 供网络计算
        return torch.FloatTensor(x.astype(np.float32)), torch.FloatTensor(
            np.concatenate([y_temp, y_hum]).astype(np.float32))


# ==========================================
# 3. 训练主函数 (CPU 稳定版)
# ==========================================
def main_train():
    device = torch.device("cpu")  # 锁定 CPU，避开 DirectML 算子冲突
    print(f"环境就绪: 使用 CPU 进行训练...")

    if not os.path.exists('models'): os.makedirs('models')

    dataset = EnviroDataset('csvData/data.csv')
    dataloader = DataLoader(dataset, batch_size=32, shuffle=True)

    # 导出归一化参数供预测端使用
    with open('models/scaler_params.json', 'w') as f:
        json.dump({"mins": dataset.mins.tolist(), "maxs": dataset.maxs.tolist()}, f)

    model = EnviroLSTM(3, 64, 2, 60).to(device)
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    criterion = nn.MSELoss()

    print("开始训练...")
    model.train()
    for epoch in range(50):
        total_loss = 0
        for x_batch, y_batch in dataloader:
            x_batch, y_batch = x_batch.to(device), y_batch.to(device)
            optimizer.zero_grad()
            outputs = model(x_batch, device)
            loss = criterion(outputs, y_batch)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()

        if (epoch + 1) % 10 == 0:
            print(f"Epoch [{epoch + 1}/50], Loss: {total_loss / len(dataloader):.6f}")

    torch.save(model.state_dict(), 'models/enviro_model.pth')
    print("训练成功！模型已保存至 models/ 文件夹。")


if __name__ == "__main__":
    main_train()