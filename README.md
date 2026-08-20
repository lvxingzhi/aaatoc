# aaatoc - 副本 / 怪物 / 技能速查插件

魔兽世界插件：`/aaa` 打开，手动点击浏览副本 → 怪物 → 技能，三个窗口可拖拽移动、右下角调整大小。

## 文件结构

```
aaatoc/
├── build_data.py       # 数据转换脚本 (运行它生成 addon/data.lua)
├── package.py          # 打包脚本 (运行它生成 AAA_TOC.zip)
├── data.json           # 原始数据 (你更新这个)
├── spells_cache.json   # 技能官方文本缓存 (你更新这个)
└── addon/              # 插件本体, 整个目录拷进游戏即可
    ├── AAA_TOC.toc
    ├── AAA_TOC.lua
    └── data.lua        # 由 build_data.py 生成, 勿手改
```

## 安装

1. 把 `addon` 目录复制到 `World of Warcraft/_retail_/Interface/AddOns/`，改名为 `AAA_TOC`
2. 游戏内 `/reload`
3. `/aaa` 打开

## 使用

| 操作 | 效果 |
| --- | --- |
| `/aaa` | 显示/隐藏 |
| `/aaa reset` | 重置窗口位置、大小和选择 |
| 点副本 | 显示该副本怪物列表 |
| 再点同一个副本 | 取消选择，怪物列表消失 |
| 点怪物 | 显示该怪物技能列表 |
| 再点同一个怪物 | 取消选择，技能列表消失 |
| 点技能 | 右侧显示详情描述 |
| 再点同一个技能 | 取消选中 |
| 拖动标题栏 | 移动窗口 |
| 拖右下角手柄 | 调整窗口大小 |

位置和大小自动记忆（SavedVariables），无需配置。

## 更新数据

1. 替换 `data.json` / `spells_cache.json`
2. `python3 build_data.py`
3. 把新生成的 `addon` 目录覆盖到游戏插件目录，游戏内 `/reload`

> 若游戏提示插件过期，把 `addon/AAA_TOC.toc` 里的 `## Interface:` 改成当前版本号
> （游戏内 `/run print(GetBuildInfo())` 第一行即版本号，如 12.1.0 → 120100）。

## 打包发布

从仓库根目录执行：

```bash
python3 package.py
```

产出 `AAA_TOC.zip`
