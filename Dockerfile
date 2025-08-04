# Dockerfile (変更後)

# 1. ベースイメージの指定
FROM python:3.11-slim

# 2. システムパッケージのインストール
RUN apt-get update && apt-get install -y \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# 3. uvのインストール
RUN pip install uv
ENV PATH="/root/.local/bin:${PATH}"

# 4. 作業ディレクトリの作成と設定
WORKDIR /app

# 5. pyproject.tomlをコンテナにコピー
COPY pyproject.toml .

# 6. pyproject.tomlを元に、uvでライブラリをインストール
# '.' はカレントディレクトリのpyproject.tomlを指します
RUN uv pip install --system .

# 7. コンテナ起動時のコマンド設定
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''"]