.PHONY: get clean debug debug-simulator release lint

get:
	cd packages/api && fvm flutter pub get
	cd packages/key_value_storage && fvm flutter pub get
	cd packages/domain_models && fvm flutter pub get
	cd packages/component_library && fvm flutter pub get
	cd packages/routing && fvm flutter pub get
	fvm flutter pub get

clean:
	fvm flutter clean

debug: get
	fvm flutter run --debug

debug-simulator: get
	fvm flutter run -d simulator --debug

release: get
	fvm flutter build ios --release --no-codesign

lint:
	fvm flutter analyze

create-repo:
	@tools/create_repo.sh name=$(filter-out $@,$(MAKECMDGOALS))

create-feature:
	@tools/create_feature.sh name=$(filter-out $@,$(MAKECMDGOALS))

add-api:
	@tools/add_api_module.sh name=$(filter-out $@,$(MAKECMDGOALS))

%:
	@:
