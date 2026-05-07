.PHONY: get clean debug debug-simulator release lint test coverage-local create-repo create-feature add-api dev staging prod build-prod

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
	@echo "📱 创建新 Feature 的步骤："
	@echo "1. 在 packages/features/ 下创建目录: packages/features/feature_<name>/"
	@echo "2. 创建 pubspec.yaml + lib/feature_<name>.dart"
	@echo "3. 内部结构: cubit/ repository/ ui/ di/ models/"
	@echo "4. 参考 packages/features/feature_home/ 的结构"
	@echo "5. 在 routing 包中添加路由"
	@echo "6. 在 lib/core/di/setup.dart 中调用 setupFeature<Name>(sl)"
	@echo "7. 运行 make get"

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

%:
	@:
