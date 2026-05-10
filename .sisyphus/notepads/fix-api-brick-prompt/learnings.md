# Learnings: Fix API Brick Prompt

## Mason 0.1.2 limitations
- `if:` conditional vars are NOT supported (Mason 0.1.2 only supports: type, description, default, defaults, prompt, values, separator)
- Setting `prompt: ""` does NOT suppress interactive prompting — Mason still prompts with empty prompt text
- Mason ALWAYS prompts for any var not explicitly passed via CLI, even if it has a `default`
- To make a var not prompt: remove it from `vars` entirely. Mason still passes unknown `--key value` CLI args as template variables without requiring them to be in `vars`.

## retrofit_generator ^8.1.0 limitations
- `Future<List<dynamic>>` as a return type causes a null crash (`Null check operator used on a null value` in `_displayString`)
- Use `Future<dynamic>` instead for model-less API methods
- `Future<Map<String, dynamic>>` works fine

## Template pattern
- `modelName` was only used inside `{{#hasModel}}` blocks — safe to remove from vars since `{{^hasModel}}` blocks never reference it
- When `--hasModel true --modelName X` is passed from CLI, Mason still sets modelName in template context even without it in vars

## Second fix: modelName back in vars + Makefile change

### Key discovery
Mason 0.1.2 ALWAYS prompts for any var not explicitly passed via CLI. Setting `prompt: ""` does NOT suppress interactive prompting — the prompt still appears with empty text and fails in non-interactive mode.

### Actual fix required TWO changes:
1. **bricks/api/brick.yaml** — Keep `modelName` as a declared var (with `prompt: ""` and `default: "dynamic"`) so `--modelName` CLI arg is accepted
2. **makefile** — Add `--modelName dynamic` to the no-model mason make command (line 94). This prevents Mason from prompting for modelName when not explicitly passed

### Why both are needed
- Without modelName in vars: `--modelName` CLI arg is rejected ("Could not find an option named '--modelName'")
- Without `--modelName dynamic` in makefile: Mason prompts interactively and crashes in non-interactive mode
- Mason validates CLI args against declared vars in brick.yaml — no way to pass extra vars

### Template fix (from previous round)
- `bricks/api/__brick__/lib/src/api/{{name}}_api.dart`: `Future<List<dynamic>>` → `Future<dynamic>` to avoid retrofit_generator null crash on `List<dynamic>` return type
