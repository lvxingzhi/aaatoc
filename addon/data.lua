-- 本文件由 build_data.py 自动生成, 请勿手动修改
-- 生成时间: 2026-08-20T18:47:20
-- 数据源: data.json / spells_cache.json
--
-- 结构:
--   Data.d[di]      = {中文名, 英文名, 赛季, 技能数}
--   Data.m[di][mi]  = {怪物信息, 技能列表}
--   怪物信息         = {中文名, 英文名, npcId, 类型, 是否首领, 控制类型}
--   技能             = {名称, 英文名, spellId, 标志位, 描述, 英文描述}
--   标志位: 1可打断 2魔法 4激怒 8流血 16中毒 32疾病 64诅咒
local Data = {
  meta = {
    builtAt = "2026-08-19T08:38:08+00:00",
    mdtSha = "9cf9263e757faab9a56fbf269da1f9f884a4407c",
    total = 5,
    dungeons = 4,
  },
  d = {
    {"密谋小径","Murder Row","Midnight",4},
    {"纳洛拉克的洞穴","Den of Nalorakk","Midnight",0},
    {"夺目谷","The Blinding Vale","Midnight",0},
    {"红玉新生法池","Ruby Life Pools","Midnight",1},
  },
  m = {
    [1] = {
      { {"邪能浮龙","Felwyrm",236085,"Beast",0,""}, {
        {"邪能灌注","Fel Infused",1214966,0,"死亡时释放邪能，对4码范围内的所有敌人造成193965点火焰伤害。","Releases fel energy upon death inflicting 193965 Fire damage to all enemies within 4 yds."},
        {"邪能引爆","Fel Detonation",1216538,2,"施法者死亡后发生爆炸，对4码范围内的所有敌人造成193965点火焰伤害。","The caster explodes upon death, inflicting 193965 Fire damage to all enemies within 4 yds."},
      } },
      { {"歼灭者萨祖克斯","Xathuux the Annihilator",234647,"Demon",1,""}, {
        {"军团打击","Legion Strike",473898,0,"歼灭者萨祖克斯用战斧猛烈挥击，造成533403点物理伤害，并使目标受到的治疗效果降低80%，持续8秒。","Xathuux the Annihilator performs a powerful swing with his axe that inflicts 533403 Physical damage and reduces healing received by 80% for 8 sec."},
      } },
      { {"凶邪的法师","Felonious Mage",236084,"Humanoid",0,""}, {
        {"邪能飞弹","Fel Missiles",1216571,1,"朝敌人发射混乱飞弹，每1秒造成火焰伤害，持续5秒。","Launches disorderly missiles at an enemy, inflicting Fire damage every 1 sec for 5 sec."},
      } },
    },
    [4] = {
      { {"原始主宰","Primal Juggernaut",188244,"Elemental",0,"Taunt"}, {
        {"毁灭猛击","Crushing Smash",372730,0,"施法者对当前目标造成533403点物理伤害和145474点自然伤害。","The caster inflicts 533403 Physical damage and 145474 Nature damage to its current target."},
      } },
    },
  },
}
AAATOC_Data = Data
