# Learnings - API Auto Generation

## Completed Tasks

### Task 4: Create Retrofit API template
- Created `bricks/api_gen/__brick__/api.dart` — Retrofit `@RestApi` interface template for Mason brick
- Handles: model imports, domain-specific class naming, endpoint generation with body/params/no-params variants
- Uses `{{{path}}}` triple-brace syntax for unescaped path rendering (Mason requirement)
- Template structure mirrors the existing `bricks/feature/` brick pattern
