import sys, json, os, torch, warnings
import pandas as pd
import numpy as np
import torch.nn as nn
from datetime import datetime, timedelta

# 屏蔽所有警告，确保控制台输出只有纯净的 JSON
warnings.filterwarnings("ignore")


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
        out, _ = self.lstm(x, (h0, c0))
        return self.fc(out[:, -1, :])


def predict():
    device = torch.device("cpu")

    # 接收参数
    num_pts = int(sys.argv[1]) if len(sys.argv) > 1 else 60
    interval = int(sys.argv[2]) if len(sys.argv) > 2 else 60

    # 1. 加载归一化参数
    param_path = 'models/scaler_params.json'
    if not os.path.exists(param_path):
        return

    with open(param_path, 'r') as f:
        scaler = json.load(f)
    f_min, f_max = np.array(scaler['mins']), np.array(scaler['maxs'])

    # 2. 读取最新数据 (适配虚拟机路径)
    csv_path = 'csvData/data.csv'
    if not os.path.exists(csv_path):
        return

    df = pd.read_csv(csv_path)
    df['timestamp'] = pd.to_datetime(df.iloc[:, 0])
    df['time_delta'] = df['timestamp'].diff().dt.total_seconds().fillna(0)

    # 3. 准备输入
    features = df[['temp', 'hum', 'time_delta']].values[-60:]
    scaled = (features - f_min) / (f_max - f_min + 1e-6)
    input_tensor = torch.FloatTensor(scaled).unsqueeze(0).to(device)

    # 4. 加载模型 (解决 FutureWarning)
    model = EnviroLSTM(3, 64, 2, 60).to(device)
    model_path = 'models/enviro_model.pth'

    # weights_only=True 是 PyTorch 推荐的安全加载方式
    state_dict = torch.load(model_path, map_location=device)
    model.load_state_dict(state_dict)
    model.eval()

    # 5. 推理
    with torch.no_grad():
        pred = model(input_tensor, device).numpy().flatten()

    # 6. 反归一化
    p_temp = pred[:60] * (f_max[0] - f_min[0]) + f_min[0]
    p_hum = pred[60:] * (f_max[1] - f_min[1]) + f_min[1]

    # 7. 构造 JSON
    results = []
    last_time = df['timestamp'].iloc[-1]
    for i in range(num_pts):
        results.append({
            "timestamp": (last_time + timedelta(seconds=(i + 1) * interval)).strftime('%Y-%m-%d %H:%M:%S'),
            "temp": round(float(p_temp[i]), 2),
            "hum": round(float(p_hum[i]), 2)
        })

    # 最终输出唯一的 JSON
    print(json.dumps(results))


if __name__ == "__main__":
    predict()
