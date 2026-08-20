#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
build_data.py - 将 data.json / spells_cache.json 转换为 WoW 插件使用的紧凑高效 Lua 数据文件。

用法:
    python3 build_data.py
    可选参数:
      --data  <path>  data.json 路径         (默认 data.json)
      --cache <path>  spells_cache.json 路径 (默认 spells_cache.json)
      --out   <path>  输出 Lua 文件          (默认 addon/data.lua)

说明:
    - 技能的名称/描述优先使用 spells_cache.json 中的官方文本, 缺失时回退到 data.json 行内字段
    - 8 个布尔标记(可打断/魔法/激怒/流血/中毒/疾病/诅咒)压缩为单个位掩码数字
    - 输出为纯 Lua 数组结构, 无多余字段名, 运行时 ipairs 遍历最快

数据更新流程:
    1. 替换 data.json 和 spells_cache.json
    2. 运行 python3 build_data.py
    3. 将 addon 目录复制到 WoW 的 Interface/AddOns 下
    4. 游戏内 /reload 或 /aaa
"""
import argparse
import datetime
import json
import os
import sys

# 布尔标记 -> 位掩码 (与插件端 FLAGS 定义一一对应)
FLAG_FIELDS = [
    ("interruptible", 1),  # 可打断
    ("isMagic", 2),        # 魔法
    ("isEnrage", 4),       # 激怒
    ("isBleed", 8),        # 流血
    ("isPoison", 16),      # 中毒
    ("isDisease", 32),     # 疾病
    ("isCurse", 64),       # 诅咒
]


def lua_str(s):
    """转义任意字符串为 Lua 双引号字面量 (保留 UTF-8)。"""
    if s is None:
        return '""'
    s = str(s)
    out = ['"']
    for ch in s:
        o = ord(ch)
        if ch == '"':
            out.append('\\"')
        elif ch == '\\':
            out.append('\\\\')
        elif ch == '\n':
            out.append('\\n')
        elif ch == '\r':
            out.append('\\r')
        elif ch == '\t':
            out.append('\\t')
        elif o < 32 or o == 127:
            out.append('\\%d' % o)  # Lua 十进制转义
        else:
            out.append(ch)
    out.append('"')
    return ''.join(out)


def lua_val(x):
    """按类型生成 Lua 字面量: 数字保持数字, 其余转字符串。"""
    if isinstance(x, bool):
        return 'true' if x else 'false'
    if isinstance(x, int):
        return str(x)
    if isinstance(x, float):
        return repr(x)
    return lua_str(x)


def lua_list(items):
    """生成单行 Lua 数组字面量。"""
    return '{' + ','.join(lua_val(x) for x in items) + '}'


def to_int(s):
    try:
        return int(str(s))
    except (ValueError, TypeError):
        return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', default='data.json')
    ap.add_argument('--cache', default='spells_cache.json')
    ap.add_argument('--out', default='addon/data.lua')
    args = ap.parse_args()

    if not os.path.exists(args.data):
        sys.exit('找不到数据文件: %s (可用 --data 指定)' % args.data)

    with open(args.data, encoding='utf-8') as f:
        data = json.load(f)

    cache = {}
    if os.path.exists(args.cache):
        with open(args.cache, encoding='utf-8') as f:
            cache = json.load(f) or {}
    else:
        print('提示: 未找到 %s, 技能文本将仅使用 data.json 行内字段' % args.cache)

    # ---- 副本列表: 保持 data.json 中 dungeons 数组的顺序, rows 中未出现的副本追加 ----
    # 每项: [中文名, 英文名, 赛季, 技能数]
    dungeons = []
    dindex = {}
    for d in data.get('dungeons', []):
        name = d.get('name', '')
        if name and name not in dindex:
            dindex[name] = len(dungeons)
            dungeons.append([name, d.get('en', ''), d.get('season', ''), 0])

    # ---- 怪物分组: 同一副本+同一怪物 的多个技能合并 ----
    # mobs[副本索引] = { mobKey -> {zh,en,npc,type,boss,cc,spells:[...]} }
    mobs = {}
    total = 0

    for row in data.get('rows', []):
        dzh = row.get('dungeonZh', '')
        if dzh not in dindex:
            dindex[dzh] = len(dungeons)
            dungeons.append([dzh, row.get('dungeonEn', ''), row.get('season', ''), 0])
        di = dindex[dzh]
        key = (row.get('mobZh', ''), row.get('mobEn', ''))
        mm = mobs.setdefault(di, {})
        if key not in mm:
            mm[key] = {
                'zh': row.get('mobZh', ''),
                'en': row.get('mobEn', ''),
                'npc': to_int(row.get('npcId')),
                'type': row.get('creatureType', ''),
                'boss': 1 if row.get('isBoss') else 0,
                'cc': row.get('ccTypes', ''),
                'spells': [],
            }
        mob = mm[key]

        # 技能字段: spells_cache 的官方文本优先
        sid = to_int(row.get('spellId'))
        sc = cache.get(str(sid)) or {}
        zh = sc.get('zhCN') or {}
        en = sc.get('enUS') or {}
        name = zh.get('name') or row.get('spellName') or ''
        name_en = en.get('name') or row.get('spellNameEn') or ''
        desc = zh.get('description') or row.get('description') or ''
        desc_en = en.get('description') or row.get('descriptionEn') or ''

        flags = 0
        for field, bit in FLAG_FIELDS:
            if row.get(field):
                flags |= bit

        mob['spells'].append([name, name_en, sid, flags, desc, desc_en])
        total += 1

    # 补全副本技能数
    for di, mm in mobs.items():
        dungeons[di][3] = sum(len(m['spells']) for m in mm.values())

    # ---- 生成 Lua ----
    lines = []
    lines.append('-- 本文件由 build_data.py 自动生成, 请勿手动修改')
    lines.append('-- 生成时间: %s' % datetime.datetime.now().isoformat(timespec='seconds'))
    lines.append('-- 数据源: %s / %s' % (os.path.basename(args.data), os.path.basename(args.cache)))
    lines.append('--')
    lines.append('-- 结构:')
    lines.append('--   Data.d[di]      = {中文名, 英文名, 赛季, 技能数}')
    lines.append('--   Data.m[di][mi]  = {怪物信息, 技能列表}')
    lines.append('--   怪物信息         = {中文名, 英文名, npcId, 类型, 是否首领, 控制类型}')
    lines.append('--   技能             = {名称, 英文名, spellId, 标志位, 描述, 英文描述}')
    lines.append('--   标志位: 1可打断 2魔法 4激怒 8流血 16中毒 32疾病 64诅咒')
    lines.append('local Data = {')
    lines.append('  meta = {')
    lines.append('    builtAt = %s,' % lua_str(data.get('builtAt', '')))
    lines.append('    mdtSha = %s,' % lua_str(data.get('mdtSha', '')))
    lines.append('    total = %d,' % total)
    lines.append('    dungeons = %d,' % len(dungeons))
    lines.append('  },')
    lines.append('  d = {')
    for d in dungeons:
        lines.append('    %s,' % lua_list(d))
    lines.append('  },')
    lines.append('  m = {')
    for di in sorted(mobs):
        lines.append('    [%d] = {' % (di + 1))
        for mob in mobs[di].values():
            meta = [mob['zh'], mob['en'], mob['npc'], mob['type'], mob['boss'], mob['cc']]
            lines.append('      { %s, {' % lua_list(meta))
            for sp in mob['spells']:
                lines.append('        %s,' % lua_list(sp))
            lines.append('      } },')
        lines.append('    },')
    lines.append('  },')
    lines.append('}')
    lines.append('AAATOC_Data = Data')

    out_dir = os.path.dirname(args.out)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    with open(args.out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')

    n_mobs = sum(len(m) for m in mobs.values())
    print('完成: %s' % args.out)
    print('  副本: %d  怪物: %d  技能: %d' % (len(dungeons), n_mobs, total))
    print('  提示: 将 addon 目录复制到 Interface/AddOns, 游戏内 /reload 后 /aaa 打开')


if __name__ == '__main__':
    main()
