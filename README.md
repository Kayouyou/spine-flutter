# Flutter Project Scaffold

A reusable Flutter scaffold based on the ovsx architecture.

## Architecture

- **Monorepo-style**: Local packages under packages/ and packages/features/
- **Repository pattern**: Data access in packages/*_repository/
- **Feature packages**: UI features in packages/features/*
- **GoRouter navigation**: RouteModule pattern
- **Hive storage**: KeyValueStorage for local caching
- **Dio HTTP**: API package with interceptors

## Quick Start

```bash
fvm install
make get
make debug-simulator
```

## Creating New Repositories

```bash
make create-repo name=my_repository
```

## Creating New Features

```bash
make create-feature name=my_feature
```

## Adding API Modules

```bash
make add-api name=my_api
```
