# Task 6: Makefile API code generation targets

- Spec directory `packages/infrastructure/api/spec/` already existed with `auth.json`
- Added 3 new targets after `%:` catch-all rule:
  - `gen-api` — single spec file generation (`make gen-api spec=auth.json`)
  - `gen-all-apis` — batch generate all specs in spec/
  - `refresh-api` — full pipeline: generate all → get deps → build_runner → analyze
- New targets placed after line 183 (after `%: @:`), no existing targets modified
