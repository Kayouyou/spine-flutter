#!/usr/bin/env python3
"""rename_project.py <old_snake> <new_snake> <namespace_prefix>
e.g. rename_project.py spine_flutter spine_flutter com.scaffold

按 6 种命名形式全局替换 + git mv Kotlin 目录 + 校验残留。
排除 .git/ build/ .dart_tool/ .fvm/ .gradle/ ios/Pods/ ios/Flutter/ ios/.symlinks/
       macos/Pods/ macos/Flutter/ .mason/ mason-lock.json *.lock
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


def main():
    dry_run = '--check' in sys.argv
    if dry_run:
        sys.argv.remove('--check')
    if len(sys.argv) != 4:
        print(__doc__)
        sys.exit(1)

    old_snake, new_snake, ns = sys.argv[1], sys.argv[2], sys.argv[3]

    # 6 forms, longest first to prevent overlap
    replacements = [
        (f'{ns}.{old_snake}', f'{ns}.{new_snake}'),
        (f'{ns}.{camel(old_snake)}', f'{ns}.{camel(new_snake)}'),
        (title(old_snake), title(new_snake)),
        (pascal(old_snake), pascal(new_snake)),
        (camel(old_snake), camel(new_snake)),
        (old_snake, new_snake),
    ]

    exclude_dirs = {'.git', '.dart_tool', '.fvm', '.gradle', '.idea', 'build',
                    'Pods', 'Flutter', '.symlinks', '.mason'}
    exclude_globs = ('*.lock', '*.lock.hash', 'mason-lock.json', 'bricks.json')

    dry_run = False

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

    # Kotlin 目录 (Android namespace 包路径)
    ns_parts = ns.split('.')
    if len(ns_parts) == 2:
        old_kotlin = f'android/app/src/main/kotlin/{ns_parts[0]}/{ns_parts[1]}/{old_snake}'
        new_kotlin = f'android/app/src/main/kotlin/{ns_parts[0]}/{ns_parts[1]}/{new_snake}'
        if os.path.isdir(old_kotlin):
            if not dry_run:
                subprocess.run(['git', 'mv', old_kotlin, new_kotlin], check=True)
            print(f'git mv: {old_kotlin} -> {new_kotlin}')

    print(f'\n{"Would modify" if dry_run else "Modified"} {len(modified)} files:')
    for m in modified:
        print(f'  {"?" if dry_run else " "} {m}')

    if not dry_run:
        # 校验残留 (用 grep, 排除已知的生成/缓存目录)
        print('\n=== 残留校验 ===')
        for old, _ in replacements:
            r = subprocess.run(
                ['grep', '-rl', '--exclude-dir=.git', '--exclude-dir=.dart_tool',
                 '--exclude-dir=build', '--exclude-dir=.mason', '--exclude-dir=.gradle',
                 '--exclude-dir=Pods', '--exclude=mason-lock.json',
                 '-l', old, '.'],
                capture_output=True, text=True
            )
            files = [l for l in r.stdout.strip().split('\n') if l]
            if files:
                print(f'  {old}: 残留 {len(files)} 个文件')
                for f in files[:5]:
                    print(f'    {f}')
                if len(files) > 5:
                    print(f'    ... 还有 {len(files)-5} 个')
        print()


if __name__ == '__main__':
    main()
