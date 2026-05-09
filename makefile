.PHONY: get clean debug debug-simulator release lint test coverage-local create-repo create-feature add-api dev staging prod build-prod create-api create-model create-hive-model

get:
	melos bs

clean:
	fvm flutter clean

debug: get
	fvm flutter run --debug

debug-simulator: get
	fvm flutter run -d simulator --debug

release: get
	fvm flutter build ios --release --no-codesign

lint:
	melos analyze

test:
	melos test

coverage-local:
	@chmod +x scripts/coverage_local.sh
	@./scripts/coverage_local.sh

create-repo:
	@echo "📦 创建新 Repository 的步骤："
	@echo "1. 在 packages/services/ 下创建目录: packages/services/<name>/"
	@echo "2. 创建 pubspec.yaml + lib/<name>.dart + lib/src/"
	@echo "3. 参考 packages/services/auth/ 的结构"
	@echo "4. 在 lib/core/di/setup.dart 注册依赖"
	@echo "5. 在根 pubspec.yaml 添加 path 依赖"
	@echo "6. 运行 make get"

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

# 开发环境运行
dev: get
	fvm flutter run --dart-define-from-file=env/.env.dev --debug

# 预发布环境运行
staging: get
	fvm flutter run --dart-define-from-file=env/.env.staging --debug

# 生产环境运行
prod: get
	fvm flutter run --dart-define-from-file=env/.env.prod --debug

# 生产环境构建
build-prod: get
	fvm flutter build apk --dart-define-from-file=env/.env.prod --release

coverage-local:
	@chmod +x scripts/coverage_local.sh
	@./scripts/coverage_local.sh

create-api:
	@if [ -z "$(name)" ]; then echo "用法: make create-api name=user baseUrl=/api/v1"; exit 1; fi
	@if [ -z "$(baseUrl)" ]; then echo "错误: 请提供 baseUrl 参数"; exit 1; fi
	@echo "=== 1/3 生成 API 模块 ==="
	mason make api --name $(name) --base-url $(baseUrl) --output-dir packages/apis/api_$(name)
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 生成 retrofit 代码 ==="
	cd packages/apis/api_$(name) && dart run build_runner build --delete-conflicting-outputs
	@echo "=== 完成 ==="

create-model:
	@if [ -z "$(name)" ]; then echo "用法: make create-model name=user_profile"; exit 1; fi
	@echo "=== 1/3 生成 Model ==="
	mason make model --name $(name) --output-dir packages/models/model_$(name)
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 生成 freezed 代码 ==="
	cd packages/models/model_$(name) && dart run build_runner build --delete-conflicting-outputs
	@echo "=== 完成 ==="

create-hive-model:
	@if [ -z "$(name)" ]; then echo "用法: make create-hive-model name=user_settings typeId=50"; exit 1; fi
	@if [ -z "$(typeId)" ]; then echo "错误: 请提供 typeId 参数"; exit 1; fi
	@echo "=== 1/3 生成 HiveModel ==="
	mason make hive_model --name $(name) --type-id $(typeId) --output-dir packages/models/hive_model_$(name)
	@echo "=== 2/3 安装依赖 ==="
	melos bs
	@echo "=== 3/3 生成 Hive Adapter 代码 ==="
	cd packages/models/hive_model_$(name) && dart run build_runner build --delete-conflicting-outputs
	@echo "=== 完成 ==="

%:
	@:
