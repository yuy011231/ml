# Makefile

# --- 変数定義 ---
# Dockerイメージ名を定義します (プロジェクト名に合わせるのが一般的です)
IMAGE_NAME := ml-env

# 実行するコンテナ名を定義します
CONTAINER_NAME := ml-container

# --- ターゲット定義 ---
# .PHONY: 以下のターゲットがファイル名と衝突しないようにするためのおまじない
.PHONY: help build up down run logs shell install install-pkg sync rebuild

# デフォルトのターゲット (makeコマンドだけ打った時に実行される)
.DEFAULT_GOAL := help

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build    Dockerイメージをビルドします"
	@echo "  up       コンテナをバックグラウンドで起動します"
	@echo "  down     バックグラウンドで起動したコンテナを停止します"
	@echo "  run      コンテナをフォアグラウンドで起動します (ログがターミナルに表示されます)"
	@echo "  logs     起動中のコンテナのログを表示します"
	@echo "  shell       起動中のコンテナ内でシェル (bash) を起動します"
	@echo "  install     起動中のコンテナに新しいパッケージをインストールします (高速)"
	@echo "  install-pkg 特定のパッケージを直接インストールします (例: make install-pkg PKG=lightgbm)"
	@echo "              ※パッケージをpyproject.tomlに追加してインストールします"
	@echo "  sync        コンテナ内のpyproject.tomlをホスト側にコピーします"
	@echo "  rebuild     pyproject.tomlの変更を反映してイメージを再ビルドします (確実)"


# Dockerイメージをビルドします
build:
	@echo "Building Docker image: $(IMAGE_NAME)..."
	docker build -t $(IMAGE_NAME) .
	@echo "Build complete."

# コンテナをバックグラウンドで起動します
up: build
	@echo "Starting container $(CONTAINER_NAME) in the background..."
	docker run -d --rm -p 8888:8888 -v "$(CURDIR)":/app --name $(CONTAINER_NAME) $(IMAGE_NAME)
	@echo ""
	@echo "JupyterLab is running at: http://localhost:8888"
	@echo "To see the logs, run: make logs"
	@echo "To stop the container, run: make down"

# バックグラウンドで起動したコンテナを停止します
down:
	@echo "Stopping container $(CONTAINER_NAME)..."
	docker stop $(CONTAINER_NAME)
	@echo "Container stopped."

# コンテナをフォアグラウンドで起動します (Ctrl+Cで停止)
run: build
	@echo "Starting container $(CONTAINER_NAME) in the foreground..."
	@echo "Access JupyterLab at: http://localhost:8888"
	@echo "Press Ctrl+C to stop."
	docker run --rm -p 8888:8888 -v "$(CURDIR)":/app --name $(CONTAINER_NAME) $(IMAGE_NAME)

# 起動中のコンテナのログを表示します
logs:
	@echo "Showing logs for $(CONTAINER_NAME)... (Press Ctrl+C to exit)"
	docker logs -f $(CONTAINER_NAME)

# 起動中のコンテナ内でシェルを起動します
shell:
	@echo "Connecting to shell in $(CONTAINER_NAME)..."
	docker exec -it $(CONTAINER_NAME) bash

# 起動中のコンテナに新しいパッケージをインストールします (高速)
install:
	@echo "Installing packages from pyproject.toml to running container..."
	@if [ -z "$$(docker ps -q -f name=$(CONTAINER_NAME))" ]; then \
		echo "Error: Container $(CONTAINER_NAME) is not running."; \
		echo "Please start the container first with 'make up' or 'make run'."; \
		exit 1; \
	fi
	@echo "Copying updated pyproject.toml to container..."
	docker cp pyproject.toml $(CONTAINER_NAME):/app/pyproject.toml
	@echo "Installing packages..."
	docker exec $(CONTAINER_NAME) uv pip install --system .
	@echo "Package installation complete."
	@echo "You may need to restart your Jupyter kernel to use new packages."

# 特定のパッケージを直接インストールします
install-pkg:
	@if [ -z "$(PKG)" ]; then \
		echo "Error: Package name not specified."; \
		echo "Usage: make install-pkg PKG=package_name"; \
		echo "Example: make install-pkg PKG=lightgbm"; \
		exit 1; \
	fi
	@if [ -z "$$(docker ps -q -f name=$(CONTAINER_NAME))" ]; then \
		echo "Error: Container $(CONTAINER_NAME) is not running."; \
		echo "Please start the container first with 'make up' or 'make run'."; \
		exit 1; \
	fi
	@echo "Installing package: $(PKG)..."
	docker exec $(CONTAINER_NAME) uv add $(PKG)
	@echo "Copying updated pyproject.toml back to host..."
	docker cp $(CONTAINER_NAME):/app/pyproject.toml pyproject.toml
	@echo "Package $(PKG) installation complete."
	@echo "Host pyproject.toml has been updated to reflect the changes."
	@echo "You may need to restart your Jupyter kernel to use the new package."

# コンテナ内のpyproject.tomlをホスト側にコピーします
sync:
	@if [ -z "$$(docker ps -q -f name=$(CONTAINER_NAME))" ]; then \
		echo "Error: Container $(CONTAINER_NAME) is not running."; \
		echo "Please start the container first with 'make up' or 'make run'."; \
		exit 1; \
	fi
	@echo "Copying pyproject.toml from container to host..."
	docker cp $(CONTAINER_NAME):/app/pyproject.toml pyproject.toml
	@echo "Sync complete. Host pyproject.toml has been updated."

# pyproject.tomlの変更を反映してイメージを再ビルドします (確実)
rebuild:
	@echo "Rebuilding Docker image with updated pyproject.toml..."
	@if [ ! -z "$$(docker ps -q -f name=$(CONTAINER_NAME))" ]; then \
		echo "Stopping running container..."; \
		docker stop $(CONTAINER_NAME); \
	fi
	docker build -t $(IMAGE_NAME) .
	@echo "Rebuild complete."
	@echo "You can now start the container with 'make up' or 'make run'."