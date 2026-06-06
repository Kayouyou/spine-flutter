## 0.0.2

* feat(refresh): split 716-line token interceptor into `TokenRenewalInterceptor` + `RefreshApi` + `RefreshQueue`
* refactor(refresh): unify retry entry point — `_retryRequest` is now the single private primitive
* fix(refresh): log non-2xx responses from renewal endpoint instead of silent fallback
* chore(deps): remove unused `pretty_dio_logger`, `connectivity_plus`, `queue` from `api/pubspec.yaml`

## 0.0.1

* TODO: Describe initial release.
