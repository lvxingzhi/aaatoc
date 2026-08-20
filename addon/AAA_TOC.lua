-- AAA TOC - 副本 / 怪物 / 技能速查手册
-- /aaa 打开, /aaa reset 重置位置
-- 全部手动点击: 点副本显示怪物, 再点同一个取消; 点怪物显示技能, 再点同一个取消
-- 三个窗口可分别拖拽移动(标题栏)与调整大小(右下角手柄)
-- 仅使用 1.x 时代基础 API, 不依赖 BackdropTemplate / FauxScrollFrame / SetResizable

local ADDON_NAME, NS = ...

local D = AAATOC_Data
if not D or type(D.m) ~= 'table' or next(D.m) == nil then
    print('|cffff6666AAA TOC|r: 未找到数据, 请先运行 build_data.py 生成 data.lua, 然后 /reload')
    return
end

AAATOCDB = AAATOCDB or {}

local ROW_H = 24
local unpack = unpack or table.unpack

-- 技能标志: bit / 行内短标 / 颜色 / 徽章全名
local FLAGS = {
    { bit = 1,  txt = '断', color = { 1, 0.55, 0.2 },  name = '可打断' },
    { bit = 2,  txt = '魔', color = { 0.45, 0.7, 1 },  name = '魔法' },
    { bit = 4,  txt = '怒', color = { 1, 0.3, 0.25 },  name = '激怒' },
    { bit = 8,  txt = '血', color = { 0.85, 0.35, 0.35 }, name = '流血' },
    { bit = 16, txt = '毒', color = { 0.4, 0.85, 0.4 }, name = '中毒' },
    { bit = 32, txt = '病', color = { 0.9, 0.8, 0.3 }, name = '疾病' },
    { bit = 64, txt = '咒', color = { 0.75, 0.45, 0.95 }, name = '诅咒' },
}

local COLORS = {
    bg     = { 0.07, 0.08, 0.11, 0.95 },
    bar    = { 0.13, 0.16, 0.22, 1 },
    border = { 0.45, 0.36, 0.2, 0.75 },
    select = { 0.22, 0.45, 0.85, 0.42 },
    hover  = { 1, 1, 1, 0.06 },
    text   = { 0.92, 0.92, 0.94 },
    sub    = { 0.6, 0.62, 0.68 },
    boss   = { 1, 0.82, 0.3 },
    gold   = { 1, 0.85, 0.4 },
}

local MIN_W, MIN_H = 200, 160

local function Clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function ShowTooltip(lines)
    GameTooltip:SetOwner(UIParent, 'ANCHOR_CURSOR')
    GameTooltip:ClearLines()
    for _, l in ipairs(lines) do
        GameTooltip:AddLine(l)
    end
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- 窗口框架: 纯纹理背景边框, 标题栏拖动, 右下角手柄缩放
-------------------------------------------------------------------------------
local function SaveFrame(f)
    local l, t = f:GetLeft(), f:GetTop()
    if not l or not t then return end
    local W, H = UIParent:GetWidth(), UIParent:GetHeight()
    if W <= 0 or H <= 0 then return end
    AAATOCDB[f.key] = { x = l / W, y = t / H, w = f:GetWidth(), h = f:GetHeight() }
end

local function LoadFrame(f, anchor)
    local s = AAATOCDB[f.key]
    f:ClearAllPoints()
    if s and s.x and s.y and s.w then
        local W, H = UIParent:GetWidth(), UIParent:GetHeight()
        f:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', s.x * W, -s.y * H)
        f:SetSize(math.max(s.w, MIN_W), math.max(s.h, MIN_H))
    else
        f:SetPoint(unpack(anchor))
    end
end

-- 纯色线条纹理
local function MakeLine(parent, r, g, b, a)
    local t = parent:CreateTexture(nil, 'ARTWORK')
    t:SetTexture(1, 1, 1, 1)
    t:SetVertexColor(r, g, b, a)
    return t
end

local function CreateBox(key, title, w, h, onLayout)
    local f = CreateFrame('Frame', nil, UIParent)
    f.key = key
    f:SetSize(w, h)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)

    -- 背景
    local bg = f:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')
    bg:SetAllPoints()
    bg:SetVertexColor(unpack(COLORS.bg))

    -- 边框
    local line = MakeLine(f, unpack(COLORS.border))
    line:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, 0)
    line:SetPoint('TOPRIGHT', f, 'TOPRIGHT', 0, 0)
    line:SetHeight(1)
    line = MakeLine(f, unpack(COLORS.border))
    line:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 0, 0)
    line:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 0)
    line:SetHeight(1)
    line = MakeLine(f, unpack(COLORS.border))
    line:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, 0)
    line:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 0, 0)
    line:SetWidth(1)
    line = MakeLine(f, unpack(COLORS.border))
    line:SetPoint('TOPRIGHT', f, 'TOPRIGHT', 0, 0)
    line:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 0)
    line:SetWidth(1)

    -- 标题栏 (拖动)
    local bar = CreateFrame('Button', nil, f)
    bar:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, 0)
    bar:SetPoint('TOPRIGHT', f, 'TOPRIGHT', 0, 0)
    bar:SetHeight(24)
    local barBg = bar:CreateTexture(nil, 'BACKGROUND')
    barBg:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')
    barBg:SetAllPoints()
    barBg:SetVertexColor(unpack(COLORS.bar))
    bar:RegisterForDrag('LeftButton')
    bar:SetScript('OnDragStart', function() f:StartMoving() end)
    bar:SetScript('OnDragStop', function() f:StopMovingOrSizing() SaveFrame(f) end)
    local label = bar:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    label:SetPoint('LEFT', 10, 0)
    label:SetText(title)
    label:SetTextColor(unpack(COLORS.gold))
    f.bar = bar

    -- 标题栏下分隔线
    local sep = MakeLine(f, 1, 1, 1, 0.12)
    sep:SetPoint('TOPLEFT', f, 'TOPLEFT', 4, -24)
    sep:SetPoint('TOPRIGHT', f, 'TOPRIGHT', -4, -24)
    sep:SetHeight(1)

    -- 右下角 resize 手柄
    local grip = CreateFrame('Frame', nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', -1, 1)
    grip:EnableMouse(true)
    grip:RegisterForDrag('LeftButton')
    grip:SetScript('OnMouseDown', function(self, btn)
        if btn == 'LeftButton' then f:StartSizing('BOTTOMRIGHT') end
    end)
    grip:SetScript('OnMouseUp', function() f:StopMovingOrSizing() SaveFrame(f) end)
    grip:SetScript('OnDragStop', function() f:StopMovingOrSizing() SaveFrame(f) end)
    local gtex = grip:CreateTexture(nil, 'OVERLAY')
    gtex:SetTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabberUp')
    gtex:SetSize(14, 14)
    gtex:SetPoint('BOTTOMRIGHT', grip, 'BOTTOMRIGHT', -1, 1)
    gtex:SetVertexColor(1, 1, 1, 0.45)

    -- 最小尺寸约束 + 布局回调
    f:SetScript('OnSizeChanged', function(self, w, h)
        if w < MIN_W then w = MIN_W end
        if h < MIN_H then h = MIN_H end
        if w ~= self:GetWidth() or h ~= self:GetHeight() then
            self:SetSize(w, h)
        end
        if onLayout then onLayout(self, w, h) end
    end)

    return f
end

-------------------------------------------------------------------------------
-- 通用列表: 原生 ScrollFrame + 手动按钮池 (无任何模板依赖)
-------------------------------------------------------------------------------
local function CreateListBox(parent)
    local box = { items = {}, selected = 0, emptyText = '暂无数据' }
    box.frame = CreateFrame('Frame', nil, parent)

    local scroll = CreateFrame('ScrollFrame', nil, box.frame)
    scroll:SetPoint('TOPLEFT', box.frame, 'TOPLEFT', 2, -2)
    scroll:SetPoint('BOTTOMRIGHT', box.frame, 'BOTTOMRIGHT', -2, 2)
    scroll:EnableMouseWheel(true)
    box.scroll = scroll

    -- 滚动条
    local sb = CreateFrame('Slider', nil, scroll, 'UIPanelScrollBarTemplate')
    sb:SetPoint('TOPLEFT', scroll, 'TOPRIGHT', -18, -18)
    sb:SetPoint('BOTTOMLEFT', scroll, 'BOTTOMRIGHT', -18, 18)
    sb:SetWidth(16)
    sb:SetValueStep(1)
    sb:Hide()
    box.sb = sb

    local empty = box.frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    empty:SetPoint('TOP', box.frame, 'TOP', 0, -40)
    empty:SetTextColor(unpack(COLORS.sub))
    box.empty = empty

    -- 按钮池
    local buttons = {}
    for i = 1, 40 do
        local b = CreateFrame('Button', nil, scroll)
        b:SetHeight(ROW_H)
        b:RegisterForClicks('AnyUp')
        b:SetHighlightTexture('Interface\\Tooltips\\UI-Tooltip-Background', 'ADD')
        b:GetHighlightTexture():SetVertexColor(unpack(COLORS.hover))

        -- 选中背景
        local sel = b:CreateTexture(nil, 'BACKGROUND')
        sel:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')
        sel:SetAllPoints()
        sel:SetVertexColor(unpack(COLORS.select))
        sel:Hide()
        b.sel = sel

        -- 主文字
        local txt = b:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        txt:SetPoint('LEFT', 8, 0)
        txt:SetPoint('RIGHT', -56, 0)
        txt:SetJustifyH('LEFT')
        txt:SetWordWrap(false)
        txt:SetHeight(ROW_H)
        txt:SetTextColor(unpack(COLORS.text))
        b.txt = txt

        -- 右侧文字 (最右)
        local sub = b:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        sub:SetPoint('RIGHT', -10, 0)
        sub:SetJustifyH('RIGHT')
        sub:SetTextColor(unpack(COLORS.sub))
        b.sub = sub

        -- 7 个标志短标 (sub 左侧)
        b.tags = {}
        local anchor = sub
        for fi = 1, 7 do
            local t = b:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
            t:SetJustifyH('CENTER')
            t:SetWidth(20)
            t:SetPoint('RIGHT', anchor, 'LEFT', -1, 0)
            anchor = t
            b.tags[fi] = t
        end

        b:SetScript('OnClick', function(self, btn)
            if box.onClick then box.onClick(self.index, btn) end
        end)
        b:SetScript('OnEnter', function(self)
            if box.onTooltip then box.onTooltip(self.index) end
        end)
        b:SetScript('OnLeave', function() GameTooltip:Hide() end)

        b:Hide()
        buttons[i] = b
    end
    box.buttons = buttons

    scroll:SetScript('OnVerticalScroll', function(self, offset)
        sb:SetValue(offset)
        box:Update()
    end)
    scroll:SetScript('OnMouseWheel', function(self, delta)
        local max = box:GetMaxOffset()
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(Clamp(cur - delta * ROW_H, 0, max))
    end)
    sb:SetScript('OnValueChanged', function(self, value)
        local max = box:GetMaxOffset()
        scroll:SetVerticalScroll(Clamp(value, 0, max))
    end)
    scroll:SetScript('OnSizeChanged', function() box:Update() end)

    function box:GetMaxOffset()
        return math.max(0, #self.items * ROW_H - self.scroll:GetHeight())
    end

    function box:SetItems(items, onRender, onClick, onTooltip)
        self.items = items or {}
        self.onRender = onRender
        self.onClick = onClick
        self.onTooltip = onTooltip
        self.selected = 0
        self:Update()
    end

    function box:SetSelected(idx)
        self.selected = idx or 0
        self:Update()
    end

    function box:Update()
        local n = #self.items
        local h = self.scroll:GetHeight()
        local maxOffset = math.max(0, n * ROW_H - h)
        local offset = Clamp(self.scroll:GetVerticalScroll(), 0, maxOffset)
        self.scroll:SetVerticalScroll(offset)
        if maxOffset > 0 then
            self.sb:Show()
            self.sb:SetMinMaxValues(0, maxOffset)
            self.sb:SetValue(offset)
        else
            self.sb:Hide()
        end
        local shown = math.floor(h / ROW_H)
        local first = math.floor(offset / ROW_H)
        local pixel = offset - first * ROW_H
        for i = 1, #self.buttons do
            local b = self.buttons[i]
            local idx = first + i
            if idx <= n then
                b:Show()
                b:ClearAllPoints()
                b:SetPoint('TOPLEFT', self.scroll, 'TOPLEFT', 2, -((i - 1) * ROW_H) + pixel)
                b:SetPoint('TOPRIGHT', self.scroll, 'TOPRIGHT', -26, -((i - 1) * ROW_H) + pixel)
                b.index = idx
                if idx == self.selected then
                    b.sel:Show()
                else
                    b.sel:Hide()
                end
                if self.onRender then self.onRender(b, self.items[idx], idx) end
            else
                b:Hide()
            end
        end
        if n == 0 then
            self.empty:SetText(self.emptyText)
            self.empty:Show()
        else
            self.empty:Hide()
        end
    end

    return box
end

-------------------------------------------------------------------------------
-- 行渲染
-------------------------------------------------------------------------------
local function ClearRowFlags(b)
    for i = 1, 7 do b.tags[i]:SetText('') end
end

local function RenderDungeonRow(b, item)
    b.txt:SetText(item[1])
    b.txt:SetTextColor(unpack(COLORS.text))
    ClearRowFlags(b)
    b.sub:SetText(string.format('%d 技能', item[4]))
end

local function RenderMobRow(b, item)
    local meta = item[1]
    b.txt:SetText(meta[1])
    if meta[5] == 1 then
        b.txt:SetTextColor(unpack(COLORS.boss))
    else
        b.txt:SetTextColor(unpack(COLORS.text))
    end
    ClearRowFlags(b)
    local parts = {}
    if meta[5] == 1 then table.insert(parts, '首领') end
    if meta[4] ~= '' then table.insert(parts, meta[4]) end
    if meta[6] ~= '' then table.insert(parts, '控:' .. meta[6]) end
    b.sub:SetText(table.concat(parts, ' · '))
end

local function RenderSpellRow(b, item)
    b.txt:SetText(item[1])
    b.txt:SetTextColor(unpack(COLORS.text))
    for i = 1, 7 do
        local f = FLAGS[i]
        if bit.band(item[4], f.bit) ~= 0 then
            b.tags[i]:SetText(f.txt)
            b.tags[i]:SetTextColor(unpack(f.color))
        else
            b.tags[i]:SetText('')
        end
    end
    b.sub:SetText('')
end

-------------------------------------------------------------------------------
-- 描述面板 (技能框右侧)
-------------------------------------------------------------------------------
local descName, descNameEn, descId, descTags, tagRow, descScroll, descText

local function ShowSpell(sp)
    if not sp then
        descName:SetText('')
        descNameEn:SetText('')
        descId:SetText('')
        descText:SetText('点击左侧技能查看详情')
        descText:SetTextColor(unpack(COLORS.sub))
        for i = 1, 7 do descTags[i]:Hide() end
        return
    end
    local name, nameEn, id, flags, desc = unpack(sp)
    descName:SetText(name)
    descName:SetTextColor(1, 1, 1)
    descNameEn:SetText(nameEn ~= '' and nameEn or '')
    descId:SetText('ID ' .. id)
    for i = 1, 7 do
        local f = FLAGS[i]
        local tag = descTags[i]
        if bit.band(flags, f.bit) ~= 0 then
            tag:Show()
            tag.bg:SetVertexColor(unpack(f.color))
            tag.txt:SetText(f.name)
        else
            tag:Hide()
        end
    end
    descText:SetText((desc and desc ~= '') and desc or '（无描述）')
    descText:SetTextColor(unpack(COLORS.text))
    descScroll:SetVerticalScroll(0)
    descScroll.sb:SetValue(0)
    descScroll.sb:SetMinMaxValues(0, descScroll:GetVerticalScrollRange())
end

-------------------------------------------------------------------------------
-- 导航: 默认不选, 再点同一个取消, 联动显示/隐藏
-------------------------------------------------------------------------------
local dungeonList, mobList, spellList
local dungeonBox, mobBox, spellBox
local currentDungeon, currentMob, currentSpell

local function SelectDungeon(idx)
    if currentDungeon == idx then
        -- 再点同一个: 取消选择
        currentDungeon, currentMob, currentSpell = nil, nil, nil
        dungeonList:SetSelected(0)
        mobBox:Hide()
        spellBox:Hide()
    else
        currentDungeon = idx
        currentMob, currentSpell = nil, nil
        dungeonList:SetSelected(idx)
        mobBox:Show()
        spellBox:Hide()
        local mobs = D.m[idx] or {}
        mobList:SetItems(mobs, RenderMobRow, SelectMob, function(mi)
            local meta = mobs[mi][1]
            ShowTooltip({ meta[1], '|cff888888' .. meta[2] .. '|r', '|cff666666NPC ' .. meta[3] .. '|r' })
        end)
    end
end

local function SelectMob(mi)
    if currentMob == mi then
        -- 再点同一个: 取消选择
        currentMob, currentSpell = nil, nil
        mobList:SetSelected(0)
        spellBox:Hide()
    else
        currentMob = mi
        currentSpell = nil
        mobList:SetSelected(mi)
        spellBox:Show()
        local mobs = D.m[currentDungeon]
        local spells = mobs and mobs[mi] and mobs[mi][2] or {}
        spellList:SetItems(spells, RenderSpellRow, SelectSpell, function(si)
            local sp = spells[si]
            ShowTooltip({ sp[1], '|cff888888' .. sp[2] .. '|r', '|cff666666ID ' .. sp[3] .. '|r' })
        end)
        ShowSpell(nil)
    end
end

local function SelectSpell(si)
    local mobs = D.m[currentDungeon]
    local spells = mobs and mobs[currentMob] and mobs[currentMob][2] or {}
    if currentSpell == si then
        -- 再点同一个: 取消选中
        currentSpell = nil
        spellList:SetSelected(0)
        ShowSpell(nil)
    else
        currentSpell = si
        spellList:SetSelected(si)
        ShowSpell(spells[si])
    end
end

-------------------------------------------------------------------------------
-- 构建界面
-------------------------------------------------------------------------------
local function BuildUI()
    -- 副本框
    dungeonBox = CreateBox('dungeon', '副本', 240, 400)
    dungeonList = CreateListBox(dungeonBox)
    dungeonList.frame:SetPoint('TOPLEFT', dungeonBox, 'TOPLEFT', 4, -28)
    dungeonList.frame:SetPoint('BOTTOMRIGHT', dungeonBox, 'BOTTOMRIGHT', -4, -18)
    dungeonList.emptyText = '暂无副本数据'
    local metaText = dungeonBox:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    metaText:SetPoint('BOTTOMLEFT', dungeonBox, 'BOTTOMLEFT', 6, 4)
    metaText:SetPoint('BOTTOMRIGHT', dungeonBox, 'BOTTOMRIGHT', -6, 4)
    metaText:SetJustifyH('CENTER')
    local built = D.meta and D.meta.builtAt or ''
    metaText:SetText(string.format('数据 %s · %d 技能', built:sub(1, 10), D.meta.total or 0))
    metaText:SetTextColor(unpack(COLORS.sub))

    -- 怪物框
    mobBox = CreateBox('mob', '怪物', 320, 400)
    mobList = CreateListBox(mobBox)
    mobList.frame:SetPoint('TOPLEFT', mobBox, 'TOPLEFT', 4, -28)
    mobList.frame:SetPoint('BOTTOMRIGHT', mobBox, 'BOTTOMRIGHT', -4, 4)
    mobList.emptyText = '该副本暂无怪物记录'

    -- 技能框
    spellBox = CreateBox('spell', '技能', 560, 400, function(self, w)
        divider:ClearAllPoints()
        divider:SetPoint('TOP', self, 'TOP', -0.45 * w, -28)
        divider:SetPoint('BOTTOM', self, 'BOTTOM', -0.45 * w, 4)
        if descText then
            descText:SetWidth(self:GetWidth() * 0.55 - 46)
        end
    end)

    -- 列表/描述分隔线
    local divider = spellBox:CreateTexture(nil, 'ARTWORK')
    divider:SetTexture(1, 1, 1, 0.12)
    divider:SetWidth(1)

    spellList = CreateListBox(spellBox)
    spellList.frame:SetPoint('TOPLEFT', spellBox, 'TOPLEFT', 4, -28)
    spellList.frame:SetPoint('BOTTOMLEFT', spellBox, 'BOTTOMLEFT', 4, 4)
    spellList.frame:SetPoint('TOPRIGHT', divider, 'TOPLEFT', -2, 0)
    spellList.frame:SetPoint('BOTTOMRIGHT', divider, 'BOTTOMLEFT', -2, 0)
    spellList.emptyText = '选择怪物查看技能'

    -- 描述区: 技能名 / 英文名+ID / 徽章 / 描述
    descName = spellBox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    descName:SetPoint('TOPLEFT', divider, 'TOPRIGHT', 10, -2)
    descName:SetPoint('RIGHT', spellBox, 'RIGHT', -60, 0)
    descName:SetJustifyH('LEFT')
    descName:SetWordWrap(false)

    descNameEn = spellBox:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    descNameEn:SetPoint('TOPLEFT', descName, 'BOTTOMLEFT', 0, -2)
    descNameEn:SetPoint('RIGHT', spellBox, 'RIGHT', -60, 0)
    descNameEn:SetJustifyH('LEFT')
    descNameEn:SetWordWrap(false)

    descId = spellBox:CreateFontString(nil, 'OVERLAY', 'GameFontDisableSmall')
    descId:SetPoint('TOPRIGHT', spellBox, 'TOPRIGHT', -16, -30)
    descId:SetTextColor(unpack(COLORS.sub))

    tagRow = CreateFrame('Frame', nil, spellBox)
    tagRow:SetPoint('TOPLEFT', descNameEn, 'BOTTOMLEFT', 0, -6)
    descTags = {}
    for i = 1, 7 do
        local tag = CreateFrame('Frame', nil, tagRow)
        tag:SetHeight(18)
        local bg = tag:CreateTexture(nil, 'BACKGROUND')
        bg:SetTexture('Interface\\Tooltips\\UI-Tooltip-Background')
        bg:SetAllPoints()
        tag.bg = bg
        local t = tag:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        t:SetPoint('LEFT', 5, 0)
        t:SetPoint('RIGHT', -5, 0)
        t:SetTextColor(1, 1, 1)
        tag.txt = t
        if i == 1 then
            tag:SetPoint('LEFT', tagRow, 'LEFT', 0, 0)
        else
            tag:SetPoint('LEFT', descTags[i - 1], 'RIGHT', 4, 0)
        end
        tag:Hide()
        descTags[i] = tag
    end

    -- 描述滚动区
    descScroll = CreateFrame('ScrollFrame', nil, spellBox)
    descScroll:SetPoint('TOPLEFT', tagRow, 'BOTTOMLEFT', 0, -10)
    descScroll:SetPoint('BOTTOMRIGHT', spellBox, 'BOTTOMRIGHT', -18, 6)
    descScroll:EnableMouseWheel(true)
    descText = descScroll:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    descText:SetPoint('TOPLEFT')
    descText:SetJustifyH('LEFT')
    descText:SetJustifyV('TOP')
    descText:SetTextColor(unpack(COLORS.text))
    descScroll:SetScrollChild(descText)
    descScroll:SetScript('OnMouseWheel', function(self, delta)
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(Clamp(self:GetVerticalScroll() - delta * 24, 0, max))
    end)
    local sb = CreateFrame('Slider', nil, descScroll, 'UIPanelScrollBarTemplate')
    sb:SetPoint('TOPLEFT', descScroll, 'TOPRIGHT', -16, -18)
    sb:SetPoint('BOTTOMLEFT', descScroll, 'BOTTOMRIGHT', -16, 18)
    sb:SetWidth(16)
    sb:SetMinMaxValues(0, 0)
    sb:SetValueStep(1)
    sb:SetScript('OnValueChanged', function(self, value)
        local max = self:GetParent():GetVerticalScrollRange()
        self:GetParent():SetVerticalScroll(Clamp(value, 0, max))
    end)
    descScroll.sb = sb
    descScroll:SetScript('OnVerticalScroll', function(self, offset)
        local s = self.sb
        s:SetValue(offset)
        s:SetMinMaxValues(0, self:GetVerticalScrollRange())
    end)

    -- 初始布局
    local onSize = spellBox:GetScript('OnSizeChanged')
    onSize(spellBox, spellBox:GetWidth(), spellBox:GetHeight())

    -- 列表数据 (不预选副本)
    dungeonList:SetItems(D.d, RenderDungeonRow, SelectDungeon, function(di)
        local d = D.d[di]
        local lines = { d[1], '|cff888888' .. d[2] .. '|r' }
        if d[3] and d[3] ~= '' then table.insert(lines, '|cff666666' .. d[3] .. '|r') end
        ShowTooltip(lines)
    end)
end

-------------------------------------------------------------------------------
-- 显示 / 命令
-------------------------------------------------------------------------------
local function ShowAll(show)
    dungeonBox:SetShown(show)
    if show then
        if currentDungeon then
            mobBox:SetShown(true)
            if currentMob then spellBox:SetShown(true) end
        end
    else
        mobBox:SetShown(false)
        spellBox:SetShown(false)
    end
end

local function ResetFrames()
    AAATOCDB = {}
    LoadFrame(dungeonBox, { 'CENTER', UIParent, 'CENTER', -420, 20 })
    LoadFrame(mobBox, { 'TOPLEFT', dungeonBox, 'TOPRIGHT', 8, 0 })
    LoadFrame(spellBox, { 'TOPLEFT', mobBox, 'TOPRIGHT', 8, 0 })
end

BuildUI()
LoadFrame(dungeonBox, { 'CENTER', UIParent, 'CENTER', -420, 20 })
LoadFrame(mobBox, { 'TOPLEFT', dungeonBox, 'TOPRIGHT', 8, 0 })
LoadFrame(spellBox, { 'TOPLEFT', mobBox, 'TOPRIGHT', 8, 0 })
dungeonBox:Show()
mobBox:Hide()
spellBox:Hide()

SLASH_AAATOC1 = '/aaa'
SlashCmdList.AAATOC = function(msg)
    msg = (msg or ''):trim():lower()
    if msg == 'reset' then
        ResetFrames()
        ShowAll(true)
        print('|cff88ccffAAA TOC|r: 位置与大小已重置')
    elseif msg == 'show' then
        ShowAll(true)
    elseif msg == 'hide' then
        ShowAll(false)
    elseif msg == 'help' then
        print('|cff88ccffAAA TOC|r 命令:')
        print('  /aaa        显示/隐藏')
        print('  /aaa reset  重置窗口位置和大小')
    else
        ShowAll(not dungeonBox:IsShown())
    end
end
