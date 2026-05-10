.PHONY: get clean debug debug-simulator release lint test coverage-local create-repo create-feature add-api dev staging prod build-prod create-api scaffold-api create-model create-hive-model help

# ============================================================================
# 基础命令
# ============================================================================

# 安装依赖
get:
	melos bs

# 清理构建缓存
clean:
	fvm flutter clean

# 代码分析
lint:
	melos analyze

# 运行测试
test:
	melos test

# 本地覆盖率报告
coverage-local:
	@chmod +x scripts/coverage_local.sh
	@./scripts/coverage_local.sh

# ============================================================================
# 开发环境
# ============================================================================

# 调试模式运行
debug: get
	fvm flutter run --debug

# 模拟器调试
debug-simulator: get
	fvm flutter run -d simulator --debug

# Release 构建（iOS）
release: get
	fvm flutter build ios --release --no-codesign

# ============================================================================
# 多环境运行
# ============================================================================

# 开发环境
dev: get
	fvm flutter run --dart-define-from-file=env/.env.dev --debug

# 预发布环境
staging: get
	fvm flutter run --dart-define-from-file=env/.env.staging --debug

# 生产环境
prod: get
	fvm flutter run --dart-define-from-file=env/.env.prod --debug

# 生产环境构建（APK）
build-prod: get
	fvm flutter build apk --dart-define-from-file=env/.env.prod --release

# ============================================================================
# 生成命令（Mason）
# ============================================================================

# 生成 Feature 包
create-feature:
	@if [ -z "$(name)" ]; then \
		echo "用法: make create-feature name=test_mason"; \
		exit 1; \
	fi
	@echo "=== 1/3 生成 Feature 包 ==="
	mason make feature --name $(name) --output-dir packages/features/feature_$(name)
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 生成 freezed 代码 ==="
	cd packages/features/feature_$(name) && dart run build_runner build --delete-conflicting-outputs
	@echo ""
	@echo "=== ✅ 完成！后续手动步骤 ==="
	@echo "1. 在 routing 包中添加路由"
	@echo "2. 在 lib/core/di/setup.dart 注册 setupFeatureXxx(sl)"

# 生成 Retrofit API 模块
create-api:
	@if [ -z "$(name)" ]; then echo "用法: make create-api name=user baseUrl=/api/v1 [model=UserModel]"; exit 1; fi
	@if [ -z "$(baseUrl)" ]; then echo "错误: 请提供 baseUrl 参数"; exit 1; fi
	@if [ -n "$(model)" ]; then \
		echo "=== 1/3 生成 API 模块 (绑定模型: $(model)) ==="; \
		mason make api --name $(name) --baseUrl $(baseUrl) --hasModel true --modelName $(model) --output-dir packages/infrastructure/api --on-conflict skip; \
	else \
		echo "=== 1/3 生成 API 模块 (无模型) ==="; \
		mason make api --name $(name) --baseUrl $(baseUrl) --hasModel false --output-dir packages/infrastructure/api --on-conflict skip; \
	fi
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 自动导出并生成 retrofit 代码 ==="
	@if ! grep -q "export 'src/api/$(name)_api.dart';" packages/infrastructure/api/lib/api.dart; then \
		echo "export 'src/api/$(name)_api.dart';" >> packages/infrastructure/api/lib/api.dart; \
	fi
	cd packages/infrastructure/api && dart run build_runner build --delete-conflicting-outputs
	@echo "=== 完成 ==="

# 一键生成 Model + API 组合包
scaffold-api:
	@if [ -z "$(name)" ]; then echo "用法: make scaffold-api name=user baseUrl=/api/v1"; exit 1; fi
	@if [ -z "$(baseUrl)" ]; then echo "错误: 请提供 baseUrl 参数"; exit 1; fi
	@echo "🚀 开始一键生成 $(name) 的 Model 和 API..."
	@make create-model name=$(name)
	@make create-api name=$(name) baseUrl=$(baseUrl) model=$(name)
	@echo "🎉 一键生成完毕！"

# 生成 Freezed 数据模型
create-model:
	@if [ -z "$(name)" ]; then echo "用法: make create-model name=user_profile"; exit 1; fi
	@echo "=== 1/3 生成 Model ==="
	mason make model --name $(name) --output-dir packages/domain
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 自动导出模型并生成 freezed 代码 ==="
	@if ! grep -q "export 'src/models/$(name).dart';" packages/domain/lib/domain.dart; then \
		echo "export 'src/models/$(name).dart';" >> packages/domain/lib/domain.dart; \
	fi
	cd packages/domain && dart run build_runner build --delete-conflicting-outputs
	@echo "=== 完成 ==="

# 生成 Hive 本地存储模型
create-hive-model:
	@if [ -z "$(name)" ]; then echo "用法: make create-hive-model name=user_settings typeId=50"; exit 1; fi
	@if [ -z "$(typeId)" ]; then echo "错误: 请提供 typeId 参数"; exit 1; fi
	@echo "=== 1/4 生成 HiveModel ==="
	mason make hive_model --name $(name) --typeId $(typeId) --output-dir packages/infrastructure/key_value_storage
	@echo "=== 2/4 安装依赖 ==="
	melos bs
	@echo "=== 3/4 自动注册并导出 Hive 模型 ==="
	@if ! grep -q "export 'src/models/$(name).dart';" packages/infrastructure/key_value_storage/lib/key_value_storage.dart; then \
		echo "export 'src/models/$(name).dart';" >> packages/infrastructure/key_value_storage/lib/key_value_storage.dart; \
	fi
	@ADAPTER_NAME=$$(echo $(name) | awk -F_ '{for(i=1;i<=NF;i++) printf toupper(substr($$i,1,1)) substr($$i,2)}')Adapter; \
	if ! grep -q "Hive.registerAdapter($$ADAPTER_NAME());" packages/infrastructure/key_value_storage/lib/src/hive_registrar.dart; then \
		awk "/_registered = true;/{print \"    Hive.registerAdapter($$ADAPTER_NAME());\"}1" packages/infrastructure/key_value_storage/lib/src/hive_registrar.dart > tmp_file && mv tmp_file packages/infrastructure/key_value_storage/lib/src/hive_registrar.dart; \
	fi
	@if ! grep -q "import 'models/$(name).dart';" packages/infrastructure/key_value_storage/lib/src/hive_registrar.dart; then \
		awk "NR==1{print \"import 'models/$(name).dart';\"}1" packages/infrastructure/key_value_storage/lib/src/hive_registrar.dart > tmp_file && mv tmp_file packages/infrastructure/key_value_storage/lib/src/hive_registrar.dart; \
	fi
	@echo "=== 4/4 生成 Adapter 代码 ==="
	cd packages/infrastructure/key_value_storage && dart run build_runner build --delete-conflicting-outputs
	@echo "=== 完成 ==="

# ============================================================================
# 帮助命令（纯文档，显示手动步骤）
# ============================================================================

# 显示创建 Repository 的手动步骤
create-repo:
	@echo "📦 创建新 Repository 的步骤："
	@echo "1. 在 packages/services/ 下创建目录: packages/services/<name>/"
	@echo "2. 创建 pubspec.yaml + lib/<name>.dart + lib/src/"
	@echo "3. 参考 packages/services/auth/ 的结构"
	@echo "4. 在 lib/core/di/setup.dart 注册依赖"
	@echo "5. 在根 pubspec.yaml 添加 path 依赖"
	@echo "6. 运行 make get"

# 显示添加 API 端点的手动步骤
add-api:
	@echo "🔌 添加 API 端点的步骤："
	@echo "1. 在 domain 定义 Repository 接口"
	@echo "2. 在对应 service 或 feature 中创建 RepositoryImpl"
	@echo "3. RepositoryImpl 通过构造函数接收 Dio："
	@echo "   class XxxRepositoryImpl implements XxxRepository {"
	@echo "     final Dio _dio;"
	@echo "     XxxRepositoryImpl(this._dio);"
	@echo "   }"
	@echo "4. 在 DI setup 中注册 Repository"
	@echo "5. 参考 packages/services/auth/lib/src/repository/"

# ============================================================================
# Catch-all 规则（防止未知目标报错）
# ============================================================================

%:
	@:

# ============================================================================
# API 代码生成（从 JSON spec）
# ============================================================================

# 单文件生成
gen-api:
	@if [ -z "$(spec)" ]; then echo "用法: make gen-api spec=auth.json"; exit 1; fi
	@echo "🚀 从 spec/$(spec) 生成 API 代码..."
	@dart run scripts/gen_api.dart --spec=packages/infrastructure/api/spec/$(spec)

# 批量生成所有 spec
gen-all-apis:
	@for f in packages/infrastructure/api/spec/*.json; do \
		echo "📄 $$(basename $$f)"; \
		dart run scripts/gen_api.dart --spec=$$f; \
	done
	@echo "✅ 所有 API spec 生成完成"

# 完整刷新: 生成 + build_runner + 校验
refresh-api:
	@make gen-all-apis
	@make get
	@cd packages/infrastructure/api && dart run build_runner build --delete-conflicting-outputs
	@cd packages/infrastructure/key_value_storage && dart run build_runner build --delete-conflicting-outputs
	@melos analyze
