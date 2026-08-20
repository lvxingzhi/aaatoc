#!/usr/bin/env python3
"""打包插件为 AAA_TOC.zip (内含 AAA_TOC/ 目录, 解压到 Interface/AddOns/ 即可加载)
用法: python3 package.py [输出路径]   (默认输出到仓库根目录 AAA_TOC.zip)
"""
import os
import sys
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.join(ROOT, "addon")
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "AAA_TOC.zip")


def main() -> int:
    if not os.path.isdir(ADDON_DIR):
        print(f"错误: 未找到 addon 目录 ({ADDON_DIR})", file=sys.stderr)
        return 1

    out_abs = os.path.abspath(OUT)
    out_dir = os.path.dirname(out_abs)
    if out_dir and not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    with zipfile.ZipFile(out_abs, "w", zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(ADDON_DIR):
            # 剔除 macOS 冗余文件
            dirs[:] = [d for d in dirs if d not in (".DS_Store", "__MACOSX")]
            files = [f for f in files if f != ".DS_Store"]
            for f in files:
                full = os.path.join(root, f)
                rel = os.path.relpath(full, ADDON_DIR).replace(os.sep, "/")
                zf.write(full, os.path.join("AAA_TOC", rel))

    print(f"已打包: {out_abs}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
