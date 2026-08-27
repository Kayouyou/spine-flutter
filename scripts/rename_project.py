#!/usr/bin/env python3
"""rename_project.py <old_snake> <new_snake> <old_ns> [new_ns] [--check]

e.g. rename_project.py spine_flutter ifisher com.scaffold com.kayouyou
     rename_project.py spine_flutter ifisher com.scaffold com.kayouyou --check

按命名形式全局替换 + 迁移 Android Kotlin 包目录 + 校验残留。
覆盖 8 种形式：{ns}.{snake} / {ns}.{camel} / Title / Pascal / camel /
kebab(spine-flutter) / snake / 裸 {ns}。new_ns 缺省时沿用 old_ns。

排除 .git/ build/ .dart_tool/ .fvm/ .gradle/ ios/Pods/ ios/Flutter/
ios/.symlinks/ macos/Pods/ macos/Flutter/ .mason/ mason-lock.json *.lock
"""
import os
import sys
import subprocess
import fnmatch


def camel(s: str) -> str:
    """snake → camel: spine_flutter → spineFlutter"""
    parts = s.split('_')
    return parts[0] + ''.join(p.title() for p in parts[1:])


def pascal(s: str) -> str:
    """snake → pascal: spine_flutter → SpineFlutter"""
    return ''.join(p.title() for p in s.split('_'))


def title(s: str) -> str:
    """snake → human title: spine_flutter → Spine Flutter"""
    return ' '.join(p.title() for p in s.split('_'))


def kebab(s: str) -> str:
    """snake → kebab: spine_flutter → spine-flutter"""
    return s.replace('_', '-')


def main():
    dry_run = '--check' in sys.argv
    argv = [a for a in sys.argv[1:] if a != '--check']
    if len(argv) not in (3, 4):
        print(__doc__)
        sys.exit(1)

    old_snake, new_snake, old_ns = argv[0], argv[1], argv[2]
    new_ns = argv[3] if len(argv) == 4 else old_ns

    # 最具体的（带 ns 前缀）排最前，裸替换放最后，防止短串先替换破坏长串
    replacements = [
        (f'{old_ns}.{old_snake}', f'{new_ns}.{new_snake}'),
        (f'{old_ns}.{camel(old_snake)}', f'{new_ns}.{camel(new_snake)}'),
        (title(old_snake), title(new_snake)),
        (pascal(old_snake), pascal(new_snake)),
        (camel(old_snake), camel(new_snake)),
        (kebab(old_snake), kebab(new_snake)),
        (old_snake, new_snake),
        (old_ns, new_ns),
    ]

    exclude_dirs = {'.git', '.dart_tool', '.fvm', '.gradle', '.idea', 'build',
                    'Pods', 'Flutter', '.symlinks', '.mason'}
    exclude_globs = ('*.lock', '*.lock.hash', 'mason-lock.json', 'bricks.json')

    modified = []
    for root, dirs, files in os.walk('.'):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        for f in files:
            path = os.path.join(root, f)
            if any(fnmatch.fnmatch(f, g) for g in exclude_globs):
                continue
            try:
                with open(path, 'r', encoding='utf-8') as fp:
                    content = fp.read()
            except (UnicodeDecodeError, IOError, IsADirectoryError):
                continue
            new_content = content
            for old, new in replacements:
                new_content = new_content.replace(old, new)
            if new_content != content:
                if not dry_run:
                    with open(path, 'w', encoding='utf-8') as fp:
                        fp.write(new_content)
                modified.append(path)

    # Kotlin 包目录迁移（支持 ns 段变化: com/scaffold/spine_flutter → com/kayouyou/ifisher）
    kt_base = 'android/app/src/main/kotlin'
    old_rel = os.path.join(*[*old_ns.split('.'), old_snake])
    new_rel = os.path.join(*[*new_ns.split('.'), new_snake])
    old_kt, new_kt = os.path.join(kt_base, old_rel), os.path.join(kt_base, new_rel)
    if os.path.isdir(old_kt) and old_rel != new_rel:
        if not dry_run:
            os.makedirs(os.path.dirname(new_kt), exist_ok=True)
            subprocess.run(['git', 'mv', old_kt, new_kt], check=True)
            # 清理因迁移而空掉的旧父目录
            probe = os.path.dirname(old_kt)
            while probe.startswith(kt_base):
                try:
                    os.rmdir(probe)
                except OSError:
                    break
                probe = os.path.dirname(probe)
        print(f'git mv: {old_kt} -> {new_kt}')

    print(f'\n{"Would modify" if dry_run else "Modified"} {len(modified)} files:')
    for m in modified:
        print(f'  {"?" if dry_run else " "} {m}')

    if not dry_run:
        # 校验残留 (用 grep, 排除已知的生成/缓存目录)
        print('\n=== 残留校验 ===')
        leftovers = 0
        for old, _ in replacements:
            r = subprocess.run(
                ['grep', '-rl',
                 '--exclude-dir=.git', '--exclude-dir=.dart_tool',
                 '--exclude-dir=build', '--exclude-dir=.mason',
                 '--exclude-dir=.gradle', '--exclude-dir=.fvm',
                 '--exclude-dir=Pods', '--exclude=mason-lock.json',
                 '-l', old, '.'],
                capture_output=True, text=True
            )
            files = [l for l in r.stdout.strip().split('\n') if l]
            if files:
                leftovers += len(files)
                print(f'  {old}: 残留 {len(files)} 个文件')
                for f in files[:5]:
                    print(f'    {f}')
                if len(files) > 5:
                    print(f'    ... 还有 {len(files)-5} 个')
        if leftovers == 0:
            print('  ✅ 无任何残留')
        print()

        sys.exit(1 if leftovers else 0)


if __name__ == '__main__':
    main()
