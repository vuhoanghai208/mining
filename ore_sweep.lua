--!nocheck
-- ============================================================
-- 💎 SPACE MINE ORE SWEEP v3.1  –  Pet Simulator 99 (Space Mining Event, U94)
--   Farm quặng độc lập: vào event → tele tới khu → tele tới từng quặng đang load trong mine
--   (mọi độ sâu) → phá bằng commit → auto combine gem (Moonstone→Star Ruby→Helium-3→Nebulite→Dark Matter)
--   Chạy: execute / live-reload. Dừng: phím Stop Key hoặc getgenv()._OreSweep.Stop()
--   KHÔNG chạy cùng lúc với main_mining2.lua (2 script cùng set target sẽ đánh nhau)
-- ============================================================
getgenv().OreSweepConfig = getgenv().OreSweepConfig or {}
local DEF = {
    ["Enabled"]        = true,
    ["Auto Join"]      = true,     -- tự vào event Space Mining nếu đang ở ngoài
    ["Target Zone"]    = 5,        -- khu muốn farm (1-5); tự hạ xuống khu cao nhất đã mở
    ["Ores"]           = { Sapphire = true, Ruby = true, Emerald = true, Amethyst = true, Rainbow = true },
                                   -- Sapphire->Moonstone, Ruby->Star Ruby, Emerald->Helium-3, Amethyst->Nebulite, Rainbow("Dark Matter Ore")->Dark Matter Gem + 5.000.000 SpaceCoins
                                   -- (VERIFIED 22/09: hold-patch PHÁ ĐƯỢC Amethyst/Rainbow - ghi chú cũ "server không cho phá" là của thời commit thủ công, đã sai.
                                   --  8 Amethyst -> 1 trong 180 s, Nebulite +8. Đáng: 1 Nebulite = 400 Moonstone = ~400 cục Sapphire; 1 Dark Matter = 20 Nebulite)
    ["Max Sec"]        = 90,       -- bỏ quặng cần > N giây (HP/damage). Helium-3 Pickaxe: Sapphire 0.13s, Emerald 0.2s, Amethyst 20.1s, Rainbow 80.6s
                                   -- -> 20 cũ loại luôn Amethyst (sát nút 20.1s!). Pickaxe yếu thì chính ngưỡng này tự loại quặng cứng, khỏi sửa Ores
    ["Min Ores"]       = 1,        -- có >= N quặng lộ mặt mới quét (3 cũ = đứng "chờ quặng" dù còn 1-2 cục ngay cạnh - VERIFIED 21/09)
    ["Scan Every"]     = 0.35,     -- giây: giữa lượt quét lại TOÀN mine và nhét quặng mới respawn vào lượt đang chạy
                                   -- (quét 9.7k block chỉ tốn ~7 ms - VERIFIED 23/09 - nên quét dày vẫn rẻ; bản cũ chốt danh sách 1 lần/lượt nên quặng mọc giữa lượt phải chờ hết lượt)
    ["Idle Poll"]      = 0.4,      -- giây nghỉ khi mine chưa có quặng nào đào được (Idle Wait 5 s cũ = ngủ mù, quặng respawn xong vẫn nằm đó tới 5 s)
    ["Ore Age"]        = 1.5,      -- giây: quặng mới xuất hiện phải >= N giây mới đào (block kề stream về sau quặng -> tránh ghost)
                                   -- (23/09 hạ 2 -> 1.5: đo 4 cửa sổ 60 s, Age 1 = 247/165 quặng vs Age 2 = 119/186, fail 0-2 cả hai; server cạn thì nhánh "chờ quặng non" ăn tới 20-42% thời gian.
                                   --  Nếu thấy fail ghost tăng thì trả về 2)
    ["Break Wait Min"] = 1.5,      -- giây chờ server xoá block sau khi client commit (server nhàn 0.1-0.3 s, server tải nặng đo được 1.5-4.3 s @ping 100 ms)
    ["Break Wait Max"] = 6,        -- trần cho ngưỡng tự học; hết ngần này mà Part còn = ghost thật (quặng server coi là bị chôn)
    ["Resync On Ghost"] = 6,       -- ghost liên tiếp N cục = bản mine của client lệch với server (block "ma": client còn, server đã xoá)
                                   -- -> rời + vào lại event cho world nạp lại (1 s, KHÔNG teleport nên không cần inject lại). 0 = tắt
    ["Hop Wait"]       = 0.2,      -- giây chờ sau mỗi tele tới quặng cho server nhận vị trí (VERIFIED 22/09 A/B mine cạn: 0.35 cũ = 1/3 thời gian farm ~139/phút; 0.1 = ghost 4-6% -> 124/phút; 0.2 = 0 ghost, 206/phút)
    ["Dig Buried"]     = true,     -- hết quặng lộ -> đứng lên đỉnh cột trên quặng bị chôn, đào thẳng xuống cho lộ mặt rồi lấy (VERIFIED 22/09: đào block dưới chân = rơi xuống block kế, ~0.15 s/Gold)
    ["Dig Max Depth"]  = 30,       -- chỉ khoan tới quặng cách đỉnh cột <= N block
    ["Zone Rotate"]    = false,    -- (22/09 mặc định TẮT) mine reset theo TỪNG khu: khu thấp cạn riêng, mỗi lần ghé tốn ~6 s mà thường 0 quặng -> hop thẳng. true = vẫn quét 5->4->3->2->1
    ["Rotate Skip Empty"] = 300,   -- giây: khu ghé mà không được quặng nào thì bỏ qua N giây (server cạn: khu 4-1 chỉ còn respawn nhỏ giọt, mỗi lần ghé phí ~6 s)
    ["Server Hop"]     = false,    -- (Real: sau teleport phải inject lại -> mặc định tắt; executor có queue_on_teleport chuẩn thì bật) mine cạn -> nhảy server khác (mine mới ~16k block, ~1000 quặng). Script tự chạy lại sau hop
    ["Hop Instead Of Rotate"] = true, -- bật Server Hop thì khu gốc sạch là hop LUÔN, không quét 4/3/2/1 (server cạn: khu thấp chỉ còn 0-5 quặng/lượt, phí ~30 s/vòng). false = quét hết 5 khu rồi mới hop
    ["Hop After"]      = 120,      -- giây: chỉ hop khi đã vào server >= N giây (tránh hop liên tục lúc mới vào)
    ["Hop Prefer Empty"] = true,   -- chọn server ít người qua games.roblox.com (mine ít bị đào); false = Teleport ngẫu nhiên
    ["Hop Memory"]     = 7200,     -- giây nhớ server đã vào (file space_mine_servers.txt) để không nhảy trùng; 0 = tắt
    ["Hop If Mine Dead"] = 8000,   -- vào server mới: mine còn < N block = ĐÃ BỊ VÉT (mine đầy ~16.7k, server cạn còn vài trăm) -> hop tiếp ngay, không phí 2 phút farm thử
    ["Hop After Empty"] = 60,      -- giây liên tục không có quặng nào mà mine vẫn còn block (chỉ đang chờ respawn) thì mới hop
    ["Hop Pages"]      = 4,        -- số trang server list quét mỗi lần hop (100 server/trang, Asc/Desc ngẫu nhiên -> mỗi lần thấy bộ server khác)
                                   -- games.roblox.com rate-limit 429 rất dễ dính -> danh sách dư được cache ra file, lần hop sau dùng luôn không gọi API
    ["Slow Last"]      = true,     -- quặng lâu (> 5 s) để sau cùng
    ["Idle Mine"]      = false,    -- true = hết quặng thì đào block thường quanh chỗ đứng (lộ quặng mới, ăn coins); false = chỉ tele quặng, hết thì chờ
    ["Idle Max Sec"]   = 3,        -- Idle Mine chỉ đào block cần <= N giây (Gold 0.1 s, Magma 0.4 s...)
    ["Idle Wait"]      = 5,        -- giây nghỉ khi không đào được gì
    ["Auto Combine"]   = false,     -- true = tự combine ở máy Combine-O-Matic (script tự tele lên Pad máy khu 5, bấm UI, rồi tele về)
    ["Combine"]        = {         -- bật/tắt từng recipe (số lượng cần đọc từ UI máy, đã trừ upgrade Ore Savings)
        ["Star Ruby Gem"]             = true,   -- 1: 20 Moonstone Gem   -> Star Ruby Gem
        ["Helium-3 Gem"]              = true,   -- 2: Star Ruby Gem      -> Helium-3 Gem
        ["Nebulite Gem"]              = true,   -- 3: Helium-3 Gem       -> Nebulite Gem
        ["Dark Matter Gem"]           = true,   -- 4: 20 Nebulite Gem    -> Dark Matter Gem
        ["Combine Egg"]               = true,   -- 10: 30 Dark Matter Gem -> quay 1 Huge ngẫu nhiên (Moon Mining Cat 100 / Malachite Koi 25 / Comet Carbuncle 5 /
                                                --     Titanic Pony cap 4000; kèm Gold x0.2, Rainbow x0.04, Shiny x0.008). Pet vào túi, không có item "Combine Egg".
        -- (22/09) rung 5-9 cũ (Dark Matter -> Huge Cat -> Koi -> Carbuncle -> Titanic -> Garg) bị game tắt bằng FFlag SpaceMineCraftingN_Enabled,
        -- nút không render nữa. Garg giờ lấy qua "Garg Machine" trên cùng Pad (nộp Huge lấy điểm -> Garg Egg), script chưa làm.
    },
    ["Combine Keep"]   = 0,        -- giữ lại N input mỗi recipe (0 = combine sạch)
    ["Combine Every"]  = 300,      -- giây giữa 2 lần lên máy
    ["Auto Bomb"]      = false,    -- ném bom mine trong túi (Consumable) tại chỗ đứng để phá block quanh quặng / lộ thêm quặng
    ["Bomb Use"]       = { "Stardust Charge", "Void Charge", "Breach Charge", "Core Charge", "Drill Array", "Rover Charge" },
                                   -- xoay vòng các loại đang có (VERIFIED 22/09: debounce server ~1 s, mọi loại dùng chung). Stardust = SpawnOre (sinh quặng, budget 560),
                                   -- Void = nổ cầu 320 block, Core = khoan xuống 20 tầng, Drill = mảng 220, Breach = xuyên lên/xuống 15, Rover = 3 lần 140.
                                   -- "Big Bang" (1436 block, mua bằng Helium-3, chỉ 1 quả/lúc) không nằm mặc định -> tự thêm vào list nếu muốn.
    ["Bomb Every"]     = 5,        -- giây giữa 2 quả (server cho ~1 s; 5 s ~ 720 quả/giờ)
    ["Auto Merchant"]  = true,     -- mua TNT ở Space Mine Merchant bằng Space Coins (mua từ xa; Rover/Drill/Core/Breach Charge, Big Bang; refresh 600 s)
    ["Merchant Slots"] = 6,        -- thử mua slot 1..N mỗi chu kỳ (server tự từ chối slot khoá/hết hàng)
    ["Merchant Every"] = 120,      -- giây
    ["Merchant Reserve"] = 0,      -- chỉ mua khi Space Coins > N
    ["Auto Free Gifts"] = true,    -- tự claim Free Rewards (12 quà theo giờ chơi, chance Huge/Titanic) khi đủ giờ, kiểm tra mỗi 60 s
    ["Anti AFK"]       = true,
    ["Show UI"]        = true,
    ["UI Black Screen"] = true,    -- true = dashboard đen full màn hình + tắt render 3D (nút góc phải để ẩn); false = panel nhỏ
    ["Webhook URL"]    = "",        -- Discord webhook (rỗng = tắt): stats lúc start + mỗi Webhook Every + khi có Huge/Titanic/Gargantuan
    ["Webhook Every"]  = 1200,      -- giây
    ["Discord Tag ID"] = "",       -- <@id> khi có pet mới
    ["Stop Key"]       = Enum.KeyCode.P,
    ["Debug"]          = false,
}
local C = getgenv().OreSweepConfig
for k, v in pairs(DEF) do if C[k] == nil then C[k] = v end end
-- Bảng con ("Ores", "Combine") là DANH SÁCH TRẮNG: ghi ["Ores"]={Rainbow=true} nghĩa là CHỈ farm Rainbow,
-- các loại không ghi coi như tắt (không lấy mặc định). Đổi lại, gõ sai tên thì cảnh báo ngay - trước đây
-- "Saphire" chỉ im lặng rồi bot đứng không hiểu vì sao. Dòng log "Start." luôn liệt kê loại đang bật.
for _, sub in ipairs({ "Ores", "Combine" }) do
    if type(C[sub]) == "table" and type(DEF[sub]) == "table" then
        for k in pairs(C[sub]) do
            if DEF[sub][k] == nil then warn(("[OreSweep] %s: không có mục %q (gõ sai tên?)"):format(sub, tostring(k))) end
        end
    end
end
if type(C["Stop Key"]) == "string" then local ok, e = pcall(function() return Enum.KeyCode[C["Stop Key"]] end) C["Stop Key"] = ok and e or Enum.KeyCode.P end

-- ------------------------------------------------------------
-- services / modules
-- ------------------------------------------------------------
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
if not game:IsLoaded() then game.Loaded:Wait() end
-- BUG 22/09: AutoExec inject ngay lúc vừa vào server (sau Server Hop / teleport nội bộ) thì Players.LocalPlayer còn nil
-- -> ":91: attempt to index nil with 'Character'" và script chết luôn, hop xong không farm lại. Phải chờ LocalPlayer trước.
local lp = Players.LocalPlayer
if not lp then
    local t0 = os.clock()
    repeat task.wait(0.2) lp = Players.LocalPlayer until lp or os.clock() - t0 > 60
    if not lp then return end
end
repeat task.wait(0.2) until lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
local Client = RS:WaitForChild("Library"):WaitForChild("Client")
local BWC = require(Client.ToolCmds:WaitForChild("BlockWorldClient"))
local Network = require(Client:WaitForChild("Network"))
local Save = require(Client:WaitForChild("Save"))
local InstancingCmds = require(Client:WaitForChild("InstancingCmds"))
local ToolUtil = require(RS.Library.Util.ToolUtil)
local PickaxeUtil = require(RS.Library.Util.PickaxeUtil)
repeat task.wait(0.5) until Save.Get()

-- Chỉ 1 bản chạy: generation tăng mỗi lần chạy; bản cũ thấy generation khác thì tự dừng
-- (queue_on_teleport xếp chồng -> sau teleport mọi bản đã queue cùng chạy, check _OreSweep bị race - VERIFIED 21/09 bên main)
getgenv()._OreSweepGen = (getgenv()._OreSweepGen or 0) + 1
local MyGen = getgenv()._OreSweepGen
local function Latest() return getgenv()._OreSweepGen == MyGen end
-- đánh dấu script đang chạy (main_mining2 / ore_sweep không chạy chung): sau teleport chỉ script được đánh dấu chạy lại
pcall(writefile, "space_mine_active.txt", "sweep")
if getgenv()._SpaceMineBot then pcall(function() getgenv()._SpaceMineBot.Stop("ore_sweep start") end) task.wait(1) end
-- tự chạy lại sau teleport nội bộ của PS99 (DataModel mới -> script chết), mang theo config người dùng
local function SerializeLua(v, depth)
    depth = depth or 0
    local t = typeof(v)
    if t == "string" then return string.format("%q", v)
    elseif t == "number" or t == "boolean" then return tostring(v)
    elseif t == "EnumItem" then return tostring(v)
    elseif t == "table" and depth < 4 then
        local parts = {}
        for k, x in pairs(v) do
            local sv = SerializeLua(x, depth + 1)
            if sv then parts[#parts + 1] = "[" .. SerializeLua(k, depth + 1) .. "]=" .. sv end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return nil
end
pcall(function()
    local q = queue_on_teleport or queueonteleport
    if not q then return end
    local src = getgenv().OreSweepLoader -- loader riêng (bản bán, vd: 'loadstring(game:HttpGet("..."))()')
    if type(src) ~= "string" or src == "" then
        local ok, s = pcall(readfile, "ore_sweep.lua")
        if ok and s then src = "local f = loadstring(" .. string.format("%q", s) .. ") if f then task.spawn(f) end" end
    end
    if not src then return end
    q("task.spawn(function() if not game:IsLoaded() then game.Loaded:Wait() end task.wait(6) " ..
      "local okm, m = pcall(readfile, 'space_mine_active.txt') if okm and m ~= 'sweep' then return end " ..
      "getgenv().OreSweepConfig = " .. (SerializeLua(C) or "{}") .. " " ..
      "getgenv().OreSweepLoader = " .. string.format("%q", getgenv().OreSweepLoader or "") .. " " ..
      src .. " end)")
end)

-- tắt Auto Mine của game nếu còn bật (sót từ main_mining2 / sau teleport): nó đào block dưới chân và tele lung tung
pcall(function()
    local AM = require(Client:WaitForChild("AutoMineCmds"))
    if AM.IsEnabled() then AM.Disable() print("[OreSweep] Tắt Auto Mine của game") end
end)
-- dừng bản cũ
if getgenv()._OreSweep then pcall(getgenv()._OreSweep.Stop) task.wait(0.8) end
if not Latest() then return end -- có bản mới hơn vừa chạy trong lúc chờ
local S = { running = true, status = "init", stats = { ore = 0, blocks = 0, fail = 0, buried = 0, hops = 0, bombs = 0, combines = 0, merchant = 0, t0 = os.clock(), gems0 = {} } }
getgenv()._OreSweep = S
if typeof(STATE) == "table" and STATE.onCleanup then STATE.onCleanup(function() S.running = false end) end

local function Alive() return S.running and Latest() end
local function log(fmt, ...) print(("[OreSweep] " .. fmt):format(...)) end
local function dbg(fmt, ...) if C["Debug"] then log(fmt, ...) end end
local function HRP() return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") end

-- ------------------------------------------------------------
-- save helpers
-- ------------------------------------------------------------
local function CountItem(id)
    local d = Save.Get()
    local n = 0
    for _, cat in pairs(d.Inventory or {}) do
        if type(cat) == "table" then
            for _, it in pairs(cat) do if type(it) == "table" and it.id == id then n += (it._am or 1) end end
        end
    end
    return n
end
local function FindConsumableUID(id)
    for uid, it in pairs(Save.Get().Inventory.Consumable or {}) do
        if it.id == id and (it._am or 1) > 0 then return uid end
    end
end
local function SpaceCoins()
    for _, it in pairs(Save.Get().Inventory.Currency or {}) do if it.id == "SpaceCoins" then return it._am or 0 end end
    return 0
end
local GEMS = { "Moonstone Gem", "Star Ruby Gem", "Helium-3 Gem", "Nebulite Gem", "Dark Matter Gem" }
for _, g in ipairs(GEMS) do S.stats.gems0[g] = CountItem(g) end

-- ------------------------------------------------------------
-- zone
-- ------------------------------------------------------------
local ZoneOrigin = {
    [1] = Vector3.new(17163.0, 13.25, -8114.7),
    [2] = Vector3.new(14795.3, 13.25, -8114.7),
    [3] = Vector3.new(11113.5, 13.25, -8114.7),
    [4] = Vector3.new(8184.3, 13.25, -8114.7),
    [5] = Vector3.new(5290.0, 13.25, -8114.7),
}
local function ZoneUnlocked(n)
    if n <= 1 then return true end
    local d = Save.Get()
    local iv = d.InstanceVars and d.InstanceVars.SpaceMiningEvent
    return iv and iv.InstanceZones and iv.InstanceZones["__Zone_" .. n] == true or false
end
local function BaseZone()
    local want = math.clamp(tonumber(C["Target Zone"]) or 5, 1, 5)
    while want > 1 and not ZoneUnlocked(want) do want -= 1 end
    return want
end
local function WantZone()
    if S.rotZone and ZoneUnlocked(S.rotZone) then return S.rotZone end
    return BaseZone()
end
local function ZoneOf(loc)
    if not loc or not loc.Origin then return 0 end
    local p = loc.Origin.Position
    local best, bd = 0, nil
    for n, o in pairs(ZoneOrigin) do
        local d = (Vector2.new(o.X, o.Z) - Vector2.new(p.X, p.Z)).Magnitude
        if not bd or d < bd then best, bd = n, d end
    end
    return best
end
-- khu theo vị trí nhân vật (X của ZoneOrigin gần nhất)
local function ZoneOfPos(p)
    local best, bd = 0, nil
    for n, o in pairs(ZoneOrigin) do
        local d = math.abs(o.X - p.X)
        if not bd or d < bd then best, bd = n, d end
    end
    return best
end
-- VERIFIED 22/09: tele sang khu khác đôi khi bị game đẩy về khu cũ trong <1 s (không rõ điều kiện, ~1/3 lần) -> kiểm vị trí 1.5 s, bị đẩy thì tele lại
local function TeleZoneTop(n)
    for attempt = 1, 3 do
        local hrp = HRP()
        if not hrp then return false end
        hrp.CFrame = CFrame.new(ZoneOrigin[n] + Vector3.new(0, 5.5, 0))
        local t0, stayed = os.clock(), true
        while os.clock() - t0 < 1.5 do
            task.wait(0.25)
            hrp = HRP()
            if not hrp or ZoneOfPos(hrp.Position) ~= n then stayed = false break end
        end
        if stayed then return true end
        dbg("Tele khu %d bị đẩy về, thử lại (%d)", n, attempt)
        task.wait(0.5)
    end
    return false
end
local function EnsureInstance()
    if InstancingCmds.IsInInstance() then return true end
    if not C["Auto Join"] then return false end
    S.status = "vào event"
    log("Vào event Space Mining")
    pcall(InstancingCmds.Enter, "SpaceMiningEvent")
    local t0 = os.clock()
    repeat task.wait(0.5) until InstancingCmds.IsInInstance() or os.clock() - t0 > 25
    return InstancingCmds.IsInInstance()
end
local function GetLocal()
    local ok, loc = pcall(BWC.GetLocal)
    if ok and loc and not loc.Destroyed then return loc end
end
-- BUG 22/09: sau một lúc farm, bản mine của client lệch với server - còn hàng trăm block "ma" (client thấy Part, server đã xoá)
-- và thiếu block server vẫn có. Hậu quả: Exposed() thấy toàn lỗ giả -> đào cục nào cũng "ghost", ore/phút 204 -> 6, fail 41/90 s.
-- Rời + vào lại event (Leave/Enter, ~1 s, KHÔNG teleport -> không mất script) làm world nạp lại từ đầu: fail 41 -> 1. VERIFIED.
local lastResync = 0
local function ReSync(reason)
    if (tonumber(C["Resync On Ghost"]) or 6) <= 0 then return false end
    if os.clock() - lastResync < 60 then return false end
    lastResync = os.clock()
    log("Mine lệch (%s) -> vào lại event cho nạp lại world", tostring(reason))
    S.status = "nạp lại mine"
    S.hold = nil
    if not pcall(InstancingCmds.Leave) then return false end
    local t0 = os.clock()
    repeat task.wait(0.3) until not InstancingCmds.IsInInstance() or os.clock() - t0 > 10
    task.wait(1)
    pcall(InstancingCmds.Enter, "SpaceMiningEvent")
    t0 = os.clock()
    repeat task.wait(0.3) until InstancingCmds.IsInInstance() or os.clock() - t0 > 25
    task.wait(3) -- chờ block stream về
    S.locAt = os.clock()
    S.emptySince = nil
    return InstancingCmds.IsInInstance()
end

-- ------------------------------------------------------------
-- block helpers
-- ------------------------------------------------------------
local function valid(b) return b and b.Part and b.Part.Parent ~= nil and not b.TempBroken end
local idCache = setmetatable({}, { __mode = "k" })
local function bid(b)
    local c = idCache[b]
    if c then return c end
    local ok, d = pcall(b.GetDirectory, b)
    c = ok and d and d._id or "?"
    if c ~= "?" then idCache[b] = c end
    return c
end
local function center(b) local ok, cf = pcall(b.GetCFrame, b) return ok and cf.Position or (b.Part and b.Part.Position) or Vector3.zero end
local ORE_IDS = { Sapphire = true, Ruby = true, Emerald = true, Amethyst = true, Rainbow = true, Quartz = true, Topaz = true, Onyx = true }
local function isOreId(x) return ORE_IDS[x] == true end
local function wantOre(x) return C["Ores"][x] == true end
-- Quặng phải có >= 1 mặt lộ (ô kề trống) thì server mới cho phá. Client load TOÀN BỘ mine (~16k block) nên
-- loc.Blocks chứa cả quặng chôn kín trong đá: cố đào -> che/timeout 2–7 s mỗi cục (VERIFIED 21/09: nb=6 fail 100 %, nb<6 vỡ 0.15–0.3 s)
local N6 = { Vector3int16.new(1, 0, 0), Vector3int16.new(-1, 0, 0), Vector3int16.new(0, 1, 0), Vector3int16.new(0, -1, 0), Vector3int16.new(0, 0, 1), Vector3int16.new(0, 0, -1) }
local function Exposed(loc, b)
    local p = b.Pos
    for _, o in ipairs(N6) do
        if not valid(loc:GetBlock(Vector3int16.new(p.X + o.X, p.Y + o.Y, p.Z + o.Z))) then return true end
    end
    return false
end

-- Bảng loại quặng: tên hiển thị -> module Directory, để tính "giây/cục" cho UI kể cả khi mine chưa có loại đó
local oreSample = setmetatable({}, { __mode = "v" }) -- [id] = 1 block đang load, để tính giây/cục
local secNeeded -- khai báo trước: OreSec (ngay dưới) dùng, còn thân hàm nằm phía sau
local ORE_DIR = {
    Sapphire = "Ore 1 | Sapphire", Ruby = "Ore 2 | Ruby", Emerald = "Ore 3 | Emerald",
    Amethyst = "Ore 4 | Amethyst", Rainbow = "Ore 5 | Rainbow", Quartz = "Ore 6 | Quartz",
}
-- "giây/cục" cho UI. BẮT BUỘC tính từ block THẬT đang load (đúng đường secNeeded/Mine dùng).
-- Bản cũ require thẳng RS.__DIRECTORY.Blocks[...] (module thô, chưa qua Directory của game) -> sai nặng:
-- UI ghi Amethyst 2793 s / Rainbow 11173 s trong khi đo thật là 20.1 s / 80.7 s, lại còn gắn "!" như thể bị bỏ qua (VERIFIED 23/09).
-- Chưa thấy loại đó trong mine thì trả nil và UI ghi "—", thà không biết còn hơn báo số sai.
local function OreSec(id)
    local b = oreSample[id]
    if not valid(b) then return nil end
    local sec = secNeeded(b, id)
    if not sec or sec >= 999 then return nil end
    return sec
end
S.OreSec = OreSec
-- đổi loại quặng lúc đang chạy: getgenv()._OreSweep.SetOre("Amethyst", true) / .SetOres{ Sapphire=true, Rainbow=false }
S.SetOre = function(id, on)
    if ORE_DIR[id] == nil then return false, "không có loại quặng " .. tostring(id) end
    C["Ores"][id] = on and true or false
    log("Ore %s -> %s", id, tostring(C["Ores"][id]))
    return true
end
S.SetOres = function(t)
    for id, on in pairs(t or {}) do S.SetOre(id, on) end
    return C["Ores"]
end

local secCache, secPick = {}, nil
function secNeeded(b, id)
    local sel = ToolUtil.GetSelectedTool(lp, "Pickaxe")
    local key = sel and sel:GetId() or "?"
    if key ~= secPick then secPick = key secCache = {} end
    local c = secCache[id]
    if c then return c end
    local ok, d = pcall(b.GetDirectory, b)
    if not ok or not d then return 999 end
    local ok2, dmg = pcall(PickaxeUtil.ComputeDamage, lp, sel, ToolUtil.GetBestTool(lp, "Pickaxe"), d)
    c = (ok2 and dmg and dmg > 0) and ((d.Strength or 1) * 10 / dmg) or 999
    secCache[id] = c
    return c
end

-- tele tới dest, chờ Hop Wait giây (theo Heartbeat) rồi kiểm tra đã tới; thử 3 lần
local function TeleTo(dest, minWait)
    local hrp = HRP()
    if not hrp then return false end
    minWait = minWait or tonumber(C["Hop Wait"]) or 0.2
    for _ = 1, 3 do
        hrp.CFrame = CFrame.new(dest)
        local t0 = os.clock()
        repeat RunService.Heartbeat:Wait() until os.clock() - t0 >= minWait
        hrp = HRP()
        if hrp and (hrp.Position - dest).Magnitude < 12 then S.stats.hops += 1 return true end
        task.wait(0.25)
        hrp = HRP()
        if not hrp then return false end
    end
    return false
end
-- tele đứng lên block thường lộ mặt trên cạnh b (cùng layer / thấp hơn 1); không có thì đứng lên chính b
local function HopNear(loc, b)
    local hrp = HRP()
    if not hrp then return false end
    local bp, dest = b.Pos, nil
    for _, dy in ipairs({ 0, -1 }) do
        for dx = -2, 2 do for dz = -2, 2 do
            if dx ~= 0 or dz ~= 0 then
                local n = loc:GetBlock(Vector3int16.new(bp.X + dx, bp.Y + dy, bp.Z + dz))
                if valid(n) and not isOreId(bid(n)) then
                    local above = loc:GetBlock(Vector3int16.new(n.Pos.X, n.Pos.Y + 1, n.Pos.Z))
                    if not valid(above) then dest = center(n) break end
                end
            end
        end end
        if dest then break end
    end
    return TeleTo((dest or center(b)) + Vector3.new(0, 5.7, 0))
end

-- GIỮ ĐỂ PHÁ (VERIFIED 21/09, port từ main_mining2): client tích damage mỗi frame vào loc.Players[lp].TargetDamage, đủ HP thì
-- client TỰ commit + server xoá. MiningFrontend mỗi 0.1 s xoá target nếu không giữ chuột -> patch BlockInteraction.GetSelectedBlock
-- + GenericInput.IsInputDown trả về block đang giữ. Commit thủ công cũ không phá được quặng lâu (pickaxe yếu).
getgenv()._SpaceMineOrig = getgenv()._SpaceMineOrig or {}
local holdOrig = {}
local function HoldPatch()
    if holdOrig.done then return true end
    local ok, err = pcall(function()
        local BI = require(Client.ToolCmds:WaitForChild("BlockInteraction", 5))
        local GI = require(Client.ToolCmds.MiningFrontend:WaitForChild("GenericInput", 5))
        pcall(setreadonly, BI, false) pcall(setreadonly, GI, false)
        local SO = getgenv()._SpaceMineOrig
        SO.GetSelectedBlock = SO.GetSelectedBlock or BI.GetSelectedBlock
        SO.IsInputDown = SO.IsInputDown or GI.IsInputDown
        holdOrig.BI, holdOrig.GI = BI, GI
        BI.GetSelectedBlock = function(...) local h = S.hold if h then return h end return SO.GetSelectedBlock(...) end
        GI.IsInputDown = function(...) if S.hold then return true end return SO.IsInputDown(...) end
    end)
    holdOrig.done = ok
    if ok then log("Hold patch OK") else log("Hold patch LỖI: %s", tostring(err)) end
    return ok
end
local function HoldUnpatch()
    S.hold = nil
    if not holdOrig.done or not Latest() then return end
    pcall(function()
        holdOrig.BI.GetSelectedBlock = getgenv()._SpaceMineOrig.GetSelectedBlock
        holdOrig.GI.IsInputDown = getgenv()._SpaceMineOrig.IsInputDown
    end)
    holdOrig.done = false
end
-- BUG 22/09: ngưỡng "ghost" cũ là 1.2 s cứng kể từ lần damage tăng cuối. Khi server chậm (đo thật: xoá block mất 1.47-4.27 s, ping 100 ms)
-- thì MỌI cục đều bị kết luận ghost dù thực ra đã vỡ -> fail 93/5 phút, ore/phút tụt 204 -> 33, và block bị skip 10 s oan.
-- -> chờ theo độ trễ ĐO ĐƯỢC: giữ max của 20 lần vỡ gần nhất, chờ 1.5 lần con số đó (kẹp trong [Break Wait Min, Break Wait Max]).
local breakLat, breakLatI = {}, 0
local function NoteBreakLat(v)
    breakLatI = (breakLatI % 20) + 1
    breakLat[breakLatI] = v
end
local function GhostWait()
    local mx, n = 0, 0
    for _, v in pairs(breakLat) do n += 1 if v > mx then mx = v end end
    if n == 0 then mx = 2 end -- chưa có mẫu -> chờ ~3 s (đo thật: server chậm xoá block mất tới 4.3 s)
    return math.clamp(mx * 1.5 + 0.3, tonumber(C["Break Wait Min"]) or 1.5, tonumber(C["Break Wait Max"]) or 6)
end
-- phá 1 block: giữ target (hold patch) tới khi client commit (TempBroken) và server xoá Part. Bị che / ngoài tầm = damage không tăng 0.6 s
local function Mine(loc, b, sec)
    HoldPatch()
    local t0 = os.clock()
    S.hold = b
    pcall(loc.PlayerSetTarget, loc, lp, b.Pos, true)
    pcall(loc.LocalSetTarget, loc, b)
    local timeout = sec * 1.3 + 2 + (tonumber(C["Break Wait Max"]) or 6)
    local lastDmg, lastDmgAt, lastChk, tempAt = -1, t0, 0, nil
    while os.clock() - t0 < timeout do
        if not Alive() or not C["Enabled"] then S.hold = nil return false, "stop" end
        RunService.Heartbeat:Wait()
        if not b.Part or b.Part.Parent == nil then
            S.hold = nil
            if tempAt then NoteBreakLat(os.clock() - tempAt) end -- học độ trễ server để chỉnh ngưỡng ghost
            return true, os.clock() - t0
        end
        if b.TempBroken then
            S.hold = nil -- client đã commit, chờ server xoá
            tempAt = tempAt or os.clock()
            if os.clock() - tempAt > GhostWait() then return false, "ghost" end
        else
            local me = loc.Players and loc.Players[lp]
            local dmg, tgt = me and me.TargetDamage or 0, me and me.Target
            if tgt == nil or tgt ~= b.Pos then pcall(loc.LocalSetTarget, loc, b) end
            if dmg > lastDmg + 1e-6 then lastDmg, lastDmgAt = dmg, os.clock() end
            if os.clock() - lastDmgAt > 0.6 then S.hold = nil return false, "che" end
        end
        if os.clock() - lastChk > 0.5 then
            lastChk = os.clock()
            local h = HRP()
            if loc.Respawning then S.hold = nil return false, "reset" end
            if not h or (center(b) - h.Position).Magnitude > 41 then S.hold = nil return false, "xa" end
        end
    end
    S.hold = nil
    return false, "timeout"
end

-- ------------------------------------------------------------
-- ore sweep
-- ------------------------------------------------------------
-- Quặng vừa stream về (sau mine reset / respawn từng block) thường tới TRƯỚC block kề -> Exposed() tưởng lộ -> đào -> server từ chối (ghost).
-- VERIFIED 22/09 -> chỉ đào quặng đã thấy >= Ore Age giây (block kề tới trong ~1 s). Mine respawn liên tục nên không thể chờ "đứng yên".
local seenAt = setmetatable({}, { __mode = "k" })
local skipUntil = setmetatable({}, { __mode = "k" })
local function CollectOres(loc)
    local fast, slow, buried = {}, {}, {}
    local total, young, pendingAt = 0, 0, nil
    local now = os.clock()
    local minAge = tonumber(C["Ore Age"]) or 2
    for _, b in pairs(loc.Blocks) do
        if valid(b) then
            total += 1
            local id = bid(b)
            if not seenAt[b] then seenAt[b] = now end
            if isOreId(id) and not valid(oreSample[id]) then oreSample[id] = b end -- mẫu để UI tính "giây/cục" đúng bằng đường Mine dùng
            if wantOre(id) and now - seenAt[b] < minAge then young += 1 end -- quặng vừa respawn, chưa đủ tuổi -> đừng xoay khu, chờ nó
            if wantOre(id) and (skipUntil[b] or 0) >= now and secNeeded(b, id) <= (C["Max Sec"] or 20) and Exposed(loc, b) then
                -- quặng đang skip (ghost 10 s / che 60 s) vẫn là quặng của khu này -> RotateZone không được coi khu là trống (VERIFIED 22/09: đổi khu rồi quay lại đào đúng cục vừa ghost)
                if not pendingAt or skipUntil[b] < pendingAt then pendingAt = skipUntil[b] end
            end
            if wantOre(id) and now - seenAt[b] >= minAge and (skipUntil[b] or 0) < now then -- đang skip thì không tính (tránh Sweep rỗng + ngủ 1 s)
                local sec = secNeeded(b, id)
                if sec <= (C["Max Sec"] or 20) then
                    local e = { b = b, id = id, sec = sec }
                    if Exposed(loc, b) then
                        if sec > 5 then slow[#slow + 1] = e else fast[#fast + 1] = e end
                    else
                        buried[#buried + 1] = e
                    end
                end
            end
        end
    end
    return fast, slow, total, buried, young, pendingAt
end

-- 1 lượt: đứng đâu phá hết quặng trong tầm 39 ở đó (gần trước); hết -> tele tới quặng gần nhất còn lại
local function Sweep(loc, list)
    local n = 0
    -- quặng respawn liên tục: hết danh sách thì quét lại toàn mine và nhét cục mới vào chính lượt này,
    -- thay vì trả về "done" rồi để vòng chính ngủ (VERIFIED 23/09: 1 lần quét ~7 ms cho 9.7k block)
    local inList = {}
    for _, e in ipairs(list) do inList[e.b] = true end
    local lastScan = os.clock()
    while Alive() and C["Enabled"] do
        if loc.Destroyed or loc.Respawning then return n, "reset" end
        local hrp = HRP()
        if not hrp then return n, "no-char" end
        local now = os.clock()
        local best, bd, farBest, fd
        for _, e in ipairs(list) do
            if (skipUntil[e.b] or 0) < now and valid(e.b) then
                local d = (center(e.b) - hrp.Position).Magnitude
                if d <= 39 then
                    if not bd or d < bd then best, bd = e, d end
                elseif not fd or d < fd then farBest, fd = e, d end
            end
        end
        local e = best or farBest
        if not e then
            -- Hết danh sách: quét lại mine và nhét quặng mới vào chính lượt này. TUYỆT ĐỐI KHÔNG ngủ ở đây -
            -- lượt kết thúc 1-2 lần/giây, bản thử ngủ 0.35 s mỗi lần làm tốc độ tụt 137 -> 69 quặng/phút (VERIFIED 23/09 A/B).
            -- Chưa tới hạn quét thì trả về cho vòng chính (nó tự CollectOres ngay, không ngủ).
            local scanEvery = tonumber(C["Scan Every"]) or 0.35
            if scanEvery <= 0 or os.clock() - lastScan < scanEvery then return n, "done" end
            lastScan = os.clock()
            local fresh = CollectOres(loc) -- chỉ nhóm "nhanh": quặng chậm (Amethyst/Rainbow) để vòng chính lo, khỏi chặn lượt
            local added = 0
            for _, e2 in ipairs(fresh) do
                if not inList[e2.b] then inList[e2.b] = true list[#list + 1] = e2 added += 1 end
            end
            if added > 0 then continue end
            return n, "done"
        end
        -- mặt lộ có thể đã bị lấp (mine respawn từng block) -> kiểm lại ngay trước khi đào
        if not Exposed(loc, e.b) then skipUntil[e.b] = now + 20 S.stats.buried += 1 continue end
        if not best then
            S.status = ("tele quặng %s (y=%d)"):format(e.id, e.b.Pos.Y)
            if not HopNear(loc, e.b) then skipUntil[e.b] = now + 60 S.stats.fail += 1 continue end
        end
        S.status = ("đào %s (y=%d)"):format(e.id, e.b.Pos.Y)
        local ok, info = Mine(loc, e.b, e.sec)
        if not ok and (info == "che" or info == "timeout" or info == "xa") and not e.retried then
            -- trong tầm nhưng bị vách che (không LOS) -> tele đứng sát quặng rồi thử lại 1 lần
            e.retried = true
            task.wait(0.2)
            if HopNear(loc, e.b) then
                S.status = ("đào sát %s (y=%d)"):format(e.id, e.b.Pos.Y)
                ok, info = Mine(loc, e.b, e.sec)
            end
        end
        if ok then
            n += 1 S.stats.ore += 1 S.ghostRun = 0
            dbg("#%d %s %s %.2fs (y=%d)", S.stats.ore, e.id, tostring(e.b.Pos), info, e.b.Pos.Y)
            if S.DoBomb then S.DoBomb(loc) end -- đang đứng sát quặng = chỗ tốt để nổ (DoBomb định nghĩa phía dưới, tự gate theo Bomb Every)
        else
            S.stats.fail += 1
            -- ghost = client vỡ nhưng server không xoá: hầu hết do block kề chưa stream về (ngay sau mine reset) -> server thấy quặng bị chôn.
            -- Skip ngắn, lần sau Exposed() (đã đủ block kề) sẽ tự loại; các lỗi khác skip 60 s
            skipUntil[e.b] = now + (info == "ghost" and 10 or 60)
            dbg("fail %s %s: %s", e.id, tostring(e.b.Pos), tostring(info))
            if info == "reset" or info == "stop" then return n, info end
            -- ghost liên tiếp = world client lệch, đào nữa cũng vô ích -> nạp lại mine
            S.ghostRun = (info == "ghost") and (S.ghostRun or 0) + 1 or 0
            if S.ghostRun >= (tonumber(C["Resync On Ghost"]) or 6) then
                S.ghostRun = 0
                if ReSync(("%d ghost liên tiếp"):format(tonumber(C["Resync On Ghost"]) or 6)) then return n, "resync" end
            end
            task.wait(0.2)
        end
    end
    return n, "stop"
end

-- ------------------------------------------------------------
-- idle mine: đào block thường quanh chỗ đứng (lộ quặng mới)
-- ------------------------------------------------------------
local function FootPos(loc)
    local pb = loc:GetPlayerBlock(lp)
    if not pb then -- GetPlayerBlock trả nil ~70 % frame với một số avatar (chân đúng mép block) -> tự tính từ HRP
        local hrp = HRP()
        if not hrp then return nil end
        for _, dy in ipairs({ -3.5, -5 }) do -- (không viết `hrp and pcall(...)`: `and` cắt còn 1 giá trị -> p luôn nil)
            local ok, p = pcall(loc.WorldToBlockPos, loc, hrp.Position + Vector3.new(0, dy, 0))
            if ok and p then pb = p break end
        end
        if not pb then return nil end
    end
    for y = pb.Y, pb.Y - 3, -1 do
        local b = loc:GetBlock(Vector3int16.new(pb.X, y, pb.Z))
        if valid(b) then return b.Pos end
    end
    return pb
end
local function IdleMine(loc, budgetSec)
    local t0 = os.clock()
    local mined = 0
    while Alive() and C["Enabled"] and os.clock() - t0 < budgetSec do
        if loc.Destroyed or loc.Respawning then break end
        local hrp = HRP()
        local pb = FootPos(loc)
        if not hrp or not pb then break end
        local now = os.clock()
        local best, bd
        for _, b in pairs(loc.Blocks) do
            if valid(b) and (skipUntil[b] or 0) < now then
                local p = b.Pos
                if (p.Y == pb.Y or p.Y == pb.Y + 1) and not (p.X == pb.X and p.Y == pb.Y and p.Z == pb.Z) then
                    local id = bid(b)
                    if not isOreId(id) and Exposed(loc, b) then
                        local d = (center(b) - hrp.Position).Magnitude
                        if d <= 39 and secNeeded(b, id) <= (C["Idle Max Sec"] or 3) and (not bd or d < bd) then best, bd = b, d end
                    end
                end
            end
        end
        if best then
            S.status = ("đào lấp %s (y=%d)"):format(bid(best), pb.Y)
            local ok = Mine(loc, best, secNeeded(best, bid(best)))
            if ok then mined += 1 S.stats.blocks += 1 else skipUntil[best] = now + 10 end
            -- có quặng mới lộ ra thì quay lại sweep
            if mined % 10 == 0 then
                local fast = CollectOres(loc)
                if #fast >= (C["Min Ores"] or 3) then break end
            end
        else
            -- hết block trong tầm -> xuống block lộ thiên gần nhất ở layer dưới
            local below, bdist
            for dy = 1, 3 do
                for _, b in pairs(loc.Blocks) do
                    if valid(b) and b.Pos.Y == pb.Y - dy and not isOreId(bid(b)) then
                        local above = loc:GetBlock(Vector3int16.new(b.Pos.X, b.Pos.Y + 1, b.Pos.Z))
                        if not valid(above) then
                            local d = (center(b) - hrp.Position).Magnitude
                            if not bdist or d < bdist then below, bdist = b, d end
                        end
                    end
                end
                if below then break end
            end
            if below then
                hrp.CFrame = CFrame.new(center(below) + Vector3.new(0, 5.7, 0)) task.wait(0.4)
            else
                break
            end
        end
    end
    return mined
end

-- ------------------------------------------------------------
-- đào tới quặng chôn bằng BFS (22/09): từ quặng lan ra 6 hướng qua block hợp lệ tới ô TRỐNG gần nhất (giếng xuống, hầm ngang
-- từ giếng cũ, hay chỉ 1 block) -> đường = ít block phải phá nhất. Đứng ở block chân cạnh ô trống đầu đường, đào từ ngoài
-- vào (mỗi block vỡ lộ block kế, tầm 41 stud ~ 7 block). Ưu tiên quặng có đường ngắn + gần chỗ đứng -> tự vét theo cụm.
-- ------------------------------------------------------------
local digSkip = setmetatable({}, { __mode = "k" })
local DIRS = { Vector3int16.new(1, 0, 0), Vector3int16.new(-1, 0, 0), Vector3int16.new(0, 1, 0), Vector3int16.new(0, -1, 0), Vector3int16.new(0, 0, 1), Vector3int16.new(0, 0, -1) }
local function InRegion(loc, p)
    local r = loc.Region
    if not r then return true end
    return p.X >= r.Min.X and p.X <= r.Max.X and p.Y >= r.Min.Y and p.Y <= r.Max.Y and p.Z >= r.Min.Z and p.Z <= r.Max.Z
end
-- trả về: đường (danh sách block từ NGOÀI vào, không gồm quặng), ô trống đầu đường (Vector3int16)
-- cận trên: số block cột thẳng lên tới ô trống (đường chắc chắn tồn tại) -> BFS không cần duyệt sâu hơn
local function ColumnDepth(loc, ore, maxDepth)
    local d = 0
    for y = ore.Pos.Y + 1, ore.Pos.Y + maxDepth do
        local b = loc:GetBlock(Vector3int16.new(ore.Pos.X, y, ore.Pos.Z))
        if not valid(b) then return d end
        if (isOreId(bid(b)) and not wantOre(bid(b))) or secNeeded(b, bid(b)) > (tonumber(C["Dig Max Sec"]) or 8) then return nil end
        d += 1
    end
    return nil
end
local BFS_MAX_NODES = 5000 -- treo VM nếu không chặn (VERIFIED 22/09: mine đầy, quặng sâu -> hàng trăm nghìn GetBlock)
local function PathToAir(loc, ore, maxDepth)
    local colD = ColumnDepth(loc, ore, maxDepth)
    if colD then maxDepth = math.min(maxDepth, colD) end
    local key = function(p) return p.X .. "," .. p.Y .. "," .. p.Z end
    local start = ore.Pos
    local prev, seen = {}, { [key(start)] = true }
    local queue, qi = { start }, 1
    local depthOf = { [key(start)] = 0 }
    local nodes = 0
    while qi <= #queue do
        local p = queue[qi] qi += 1
        local d = depthOf[key(p)]
        nodes += 1
        if nodes > BFS_MAX_NODES then break end
        if nodes % 800 == 0 then task.wait() end
        if d >= maxDepth then continue end
        for _, o in ipairs(DIRS) do
            local q = Vector3int16.new(p.X + o.X, p.Y + o.Y, p.Z + o.Z)
            local k = key(q)
            if not seen[k] and InRegion(loc, q) then
                seen[k] = true
                local b = loc:GetBlock(q)
                if not valid(b) then
                    -- ô trống: dựng đường ngược về quặng
                    local path, cur = {}, p
                    while cur and key(cur) ~= key(start) do
                        path[#path + 1] = loc:GetBlock(cur)
                        cur = prev[key(cur)]
                    end
                    return path, q, d -- path[1] = block sát ô trống, path[#path] = block sát quặng
                elseif not (isOreId(bid(b)) and not wantOre(bid(b))) and secNeeded(b, bid(b)) <= (tonumber(C["Dig Max Sec"]) or 8) then
                    prev[k] = p
                    depthOf[k] = d + 1
                    queue[#queue + 1] = q
                end
            end
        end
    end
    if colD then -- BFS bị chặn -> dùng đường cột thẳng lên
        local path = {}
        for y = ore.Pos.Y + colD, ore.Pos.Y + 1, -1 do path[#path + 1] = loc:GetBlock(Vector3int16.new(ore.Pos.X, y, ore.Pos.Z)) end
        return path, Vector3int16.new(ore.Pos.X, ore.Pos.Y + colD + 1, ore.Pos.Z), colD
    end
    return nil
end
-- block chân gần ô trống 'air' nhất để đứng đào (block lộ mặt trên, cách air <= 6 block)
local function StandNear(loc, air)
    local best, bd
    for dx = -3, 3 do for dz = -3, 3 do for dy = -1, 3 do
        local p = Vector3int16.new(air.X + dx, air.Y - dy, air.Z + dz)
        local b = loc:GetBlock(p)
        if valid(b) and not isOreId(bid(b)) and not valid(loc:GetBlock(Vector3int16.new(p.X, p.Y + 1, p.Z))) then
            local d = math.abs(dx) + math.abs(dz) + dy * 0.5
            if not bd or d < bd then best, bd = b, d end
        end
    end end end
    return best
end
local buriedCache = { at = 0, loc = nil, list = {} }
local function BuriedOres(loc)
    if buriedCache.loc == loc and os.clock() - buriedCache.at < 4 then return buriedCache.list end
    local list = {}
    local now = os.clock()
    local maxDepth = tonumber(C["Dig Max Depth"]) or 30
    local hrp = HRP()
    local n = 0
    for _, b in pairs(loc.Blocks) do
        if valid(b) and (digSkip[b] or 0) < now then
            local id = bid(b)
            if wantOre(id) and not Exposed(loc, b) and secNeeded(b, id) <= (C["Max Sec"] or 20) then
                local path, air, depth = PathToAir(loc, b, maxDepth)
                if path then
                    local d = hrp and (center(b) - hrp.Position).Magnitude or 0
                    list[#list + 1] = { b = b, id = id, path = path, air = air, depth = depth, score = depth * 10 + d / 20 }
                end
                n += 1
                if n % 40 == 0 then task.wait() end -- BFS ~ms/quặng, nhường frame
            end
        end
    end
    table.sort(list, function(a, c) return a.score < c.score end)
    buriedCache.at, buriedCache.loc, buriedCache.list = os.clock(), loc, list
    return list
end
local function DigBuried(loc)
    if not C["Dig Buried"] then return false end
    local list = BuriedOres(loc)
    local e = list[1]
    if not e then return false end
    S.status = ("đào tới %s (%d block)"):format(e.id, e.depth)
    local stand = StandNear(loc, e.air)
    local hrp = HRP()
    if not hrp then return false end
    if stand then TeleTo(center(stand) + Vector3.new(0, 5.7, 0)) end
    local mined = 0
    for i = 1, #e.path do
        local b = e.path[i]
        if not Alive() or not C["Enabled"] or loc.Destroyed or loc.Respawning then return false end
        if not valid(e.b) then return true end
        if valid(b) then
            hrp = HRP()
            -- block kế ngoài tầm 41 (hầm dài / đã rơi xuống giếng) -> đứng lại gần block vừa phá
            if hrp and (center(b) - hrp.Position).Magnitude > 38 then
                local prevB = e.path[i - 1]
                local sp = prevB and StandNear(loc, prevB.Pos)
                if sp then TeleTo(center(sp) + Vector3.new(0, 5.7, 0)) end
            end
            local ok, info = Mine(loc, b, secNeeded(b, bid(b)))
            if not ok then
                dbg("Đào tới %s thất bại ở block %d/%d (%s): %s", e.id, i, #e.path, bid(b), tostring(info))
                digSkip[e.b] = os.clock() + 60
                S.stats.fail += 1
                return false
            end
            mined += 1 S.stats.blocks += 1
            task.wait(0.05)
        end
        if Exposed(loc, e.b) then break end
    end
    dbg("Lộ %s sau %d block", e.id, mined)
    buriedCache.at = 0
    return true
end

-- ------------------------------------------------------------
-- xoay khu: xem RotateZone (tuần tự 5 -> 4 -> 3 -> 2 -> 1 -> về 5). Config "Zone Rotate" = false thì chỉ ở Target Zone.
-- ------------------------------------------------------------
-- server hop: mine là per-server; hết quặng toàn bộ thì sang server khác. Ưu tiên server ít người (games API), fallback Teleport thường
-- Nhớ server đã vào (file, sống qua teleport) -> không nhảy trùng. Mỗi dòng: "<jobId> <os.time()>"
local HOP_FILE = "space_mine_servers.txt"
local function LoadVisited()
    local keep = tonumber(C["Hop Memory"]) or 7200
    local seen, now = {}, os.time()
    if keep <= 0 then return seen end
    local ok, txt = pcall(readfile, HOP_FILE)
    if ok and txt then
        for id, t in txt:gmatch("(%S+)%s+(%d+)") do
            if now - tonumber(t) < keep then seen[id] = tonumber(t) end
        end
    end
    return seen
end
local function SaveVisited(seen)
    if (tonumber(C["Hop Memory"]) or 7200) <= 0 then return end
    local parts = {}
    for id, t in pairs(seen) do parts[#parts + 1] = id .. " " .. t end
    pcall(writefile, HOP_FILE, table.concat(parts, "\n"))
end
local HOPLIST_FILE = "space_mine_hoplist.txt" -- server chưa dùng tới của lần fetch trước (API 429 rất dễ dính -> đừng gọi lại)
local function LoadHopList(seen)
    local out = {}
    local ok, txt = pcall(readfile, HOPLIST_FILE)
    if ok and txt then
        for id, n, t in txt:gmatch("(%S+)%s+(%d+)%s+(%d+)") do
            if os.time() - tonumber(t) < 1800 and not seen[id] then out[#out + 1] = { id = id, n = tonumber(n) } end
        end
    end
    return out
end
local function SaveHopList(list)
    local parts, now = {}, os.time()
    for i = 1, math.min(#list, 60) do parts[#parts + 1] = ("%s %d %d"):format(list[i].id, list[i].n, now) end
    pcall(writefile, HOPLIST_FILE, table.concat(parts, "\n"))
end
-- đánh dấu server đang chơi ngay khi script chạy -> lần hop sau không quay lại đây
do
    local seen = LoadVisited()
    if seen[game.JobId] then
        S.dupServer = true -- hop vừa rồi rơi trúng server đã farm -> được phép hop lại ngay, không chờ Hop After
        log("Server này ĐÃ vào trước đó -> sẽ hop lại sớm")
    end
    seen[game.JobId] = os.time()
    SaveVisited(seen)
end
local emptyRounds, lastHopTry = 0, 0
local function ServerHop(reason)
    if not C["Server Hop"] then return false end
    local after = (S.dupServer or S.deadMine) and 20 or (tonumber(C["Hop After"]) or 120) -- vào trúng server cũ / mine đã bị vét -> khỏi chờ 2 phút
    if os.clock() - S.stats.t0 < after or os.clock() - lastHopTry < 30 then return false end
    lastHopTry = os.clock()
    local TS = game:GetService("TeleportService")
    local HS = game:GetService("HttpService")
    log("Server hop (%s) ...", tostring(reason))
    S.status = "server hop"
    pcall(writefile, "space_mine_active.txt", "sweep")
    local seen = LoadVisited()
    seen[game.JobId] = os.time()
    -- gom nhiều trang, bỏ server đã vào; sortOrder ngẫu nhiên + cursor -> mỗi lần hop thấy bộ server khác
    -- (bản cũ: luôn trang đầu sortOrder=Asc, không nhớ gì -> nhảy trúng lại server vừa rời. VERIFIED 22/09)
    local cands = LoadHopList(seen) -- dùng server dư của lần fetch trước (khỏi gọi API -> khỏi 429)
    -- games.roblox.com khoá theo IP khá lâu khi đã 429 -> nhớ mốc, trong 5 phút sau đó khỏi gọi (đỡ phí 12 s backoff mỗi lần hop)
    local cooling = false
    do
        local okc, t = pcall(readfile, "space_mine_hop429.txt")
        cooling = okc and tonumber(t) and os.time() - tonumber(t) < 300 or false
    end
    if cooling and #cands == 0 then log("Server list đang bị rate-limit -> teleport ngẫu nhiên, vào trùng thì hop tiếp") end
    if C["Hop Prefer Empty"] ~= false and #cands < 5 and not cooling then
        local http = (syn and syn.request) or http_request or request -- có status code -> phân biệt 429 với lỗi thật
        local function get(url)
            if http then
                local ok, res = pcall(http, { Url = url, Method = "GET" })
                if ok and res then return res.StatusCode or 0, res.Body end
                return 0, nil
            end
            local ok, body = pcall(game.HttpGet, game, url)
            return ok and 200 or 0, ok and body or nil
        end
        local cursor, pages = nil, math.max(1, tonumber(C["Hop Pages"]) or 4)
        local order = (math.random() < 0.5) and "Asc" or "Desc"
        for _ = 1, pages do
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&excludeFullGames=true&limit=100"):format(game.PlaceId, order)
            if cursor then url = url .. "&cursor=" .. cursor end
            local code, body
            for try = 1, 2 do -- 429 = rate limit, chờ rồi thử lại (VERIFIED 22/09: vài lần gọi liên tiếp là dính, khoá vài phút)
                code, body = get(url)
                if code ~= 429 then break end
                log("Server list 429, chờ %ds", try * 4)
                task.wait(try * 4)
            end
            if code == 429 then pcall(writefile, "space_mine_hop429.txt", tostring(os.time())) end
            if code ~= 200 or not body then log("Server list lỗi (HTTP %s)", tostring(code)) break end
            local okj, data = pcall(HS.JSONDecode, HS, body)
            if not okj or not data then break end
            for _, sv in ipairs(data.data or {}) do
                local n = sv.playing or 0
                if sv.id and sv.id ~= game.JobId and not seen[sv.id] and n < (sv.maxPlayers or 12) then
                    cands[#cands + 1] = { id = sv.id, n = n }
                end
            end
            cursor = data.nextPageCursor
            if not cursor then break end
            task.wait(0.6) -- nhịp nhẹ giữa các trang cho đỡ 429
        end
    end
    table.sort(cands, function(a, b) return a.n < b.n end)
    local ok, err
    local total = #cands
    -- thử vài server (server có thể đầy/đóng giữa chừng); random trong 5 server vắng nhất để nhiều acc không dồn 1 chỗ
    for _ = 1, math.min(3, total) do
        local pick = table.remove(cands, math.random(1, math.min(5, #cands)))
        if not pick then break end
        log("Hop -> server %s (%d nguoi, %d server chua vao)", pick.id, pick.n, total)
        seen[pick.id] = os.time() SaveVisited(seen)
        SaveHopList(cands) -- server còn lại để dành cho lần hop sau
        ok, err = pcall(TS.TeleportToPlaceInstance, TS, game.PlaceId, pick.id, lp)
        if ok then break end
        task.wait(1)
    end
    if not ok then
        log("Hop -> server ngau nhien (%s)", tostring(err or (total == 0 and "khong con server chua vao" or "no target")))
        ok, err = pcall(TS.Teleport, TS, game.PlaceId, lp)
    end
    if ok then task.wait(15) end -- chờ teleport; nếu không đi được thì vòng sau thử lại
    return ok
end

-- KIỂM TRA MINE SAU KHI VÀO SERVER (VERIFIED 22/09: mine đầy = 16.721 block, server bị vét = 521-1.500 block; quặng sinh dần chứ không có sẵn lúc reset)
-- -> đếm block thay vì đếm quặng: mine ít block = server cũ, hop tiếp NGAY. Mine còn đầy mà 0 quặng = chỉ đang chờ respawn -> chờ Hop After Empty giây.
-- Dùng khi Zone Rotate = false (không quét 4/3/2/1); ServerHop tự lo blacklist server + chọn ngẫu nhiên.
local function HopIfDead(loc, total)
    if not C["Server Hop"] then return false end
    if S.locAt and os.clock() - S.locAt < 8 then return false end -- mine chưa stream xong, chưa kết luận
    S.emptySince = S.emptySince or os.clock()
    if total < (tonumber(C["Hop If Mine Dead"]) or 8000) then
        S.deadMine = true
        return ServerHop(("mine cạn: còn %d block"):format(total))
    end
    local waited = os.clock() - S.emptySince
    if waited >= (tonumber(C["Hop After Empty"]) or 60) then
        return ServerHop(("%.0f s không có quặng (mine %d block)"):format(waited, total))
    end
    return false
end

-- Xoay khu TUẦN TỰ (yêu cầu 22/09): farm sạch khu gốc (5) -> sang 4 farm sạch -> 3 -> 2 -> 1 -> về khu gốc (mine đã respawn) và lặp lại.
-- "Sạch" = vòng chính không còn quặng lộ / chậm / chôn đào được / quặng non (mới tới RotateZone). Mine reset (loc.Respawning) ở khu nào cũng về khu gốc.
-- Một vòng 5->1 mà không được quặng nào -> nghỉ Idle Wait ở khu gốc rồi mới đi tiếp (emptyRounds >= 2 -> Server Hop nếu bật).
local cycleOre0 = nil
local zoneArriveOre, zoneEmptyAt = {}, {} -- ore lúc tới khu / lần cuối rời khu mà 0 quặng
local function RotateZone(loc)
    if not C["Zone Rotate"] then return false end
    -- VERIFIED 22/09: ngay sau tele, loc mới có nhưng Blocks chưa stream -> fast/young đều 0 -> tưởng khu trống, nhảy tiếp sau 1 s. Chờ Ore Age + 1.5 s
    local settle = (tonumber(C["Ore Age"]) or 2) + 1.5
    if S.locAt and os.clock() - S.locAt < settle then S.status = "chờ khu load" task.wait(0.5) return true end
    local cur, base = ZoneOf(loc), BaseZone()
    -- server cạn: khu 4-1 chỉ còn 0-5 quặng/lượt -> bật Server Hop thì khu gốc sạch là hop luôn, khỏi quét xuống
    if C["Server Hop"] and C["Hop Instead Of Rotate"] ~= false and cur == base then
        if ServerHop("khu " .. base .. " hết quặng") then emptyRounds = 0 return true end
        S.status = "chờ hop"
        task.wait(C["Idle Wait"] or 5)
        return true
    end
    if zoneArriveOre[cur] and S.stats.ore - zoneArriveOre[cur] == 0 then zoneEmptyAt[cur] = os.clock() end
    local skip = tonumber(C["Rotate Skip Empty"]) or 0
    local nxt = cur - 1
    while nxt >= 1 and (not ZoneUnlocked(nxt) or os.clock() - (zoneEmptyAt[nxt] or -1e9) < skip) do nxt -= 1 end
    if cur == base then cycleOre0 = S.stats.ore end -- bắt đầu vòng mới từ khu gốc
    if nxt < 1 then
        -- hết khu 1 -> về khu gốc
        if cycleOre0 and S.stats.ore - cycleOre0 == 0 then
            emptyRounds += 1
            if emptyRounds >= 2 and ServerHop(("%d vòng 5 khu không có quặng"):format(emptyRounds)) then emptyRounds = 0 return true end
            S.status = "5 khu trống, nghỉ " .. tostring(C["Idle Wait"] or 5) .. " s"
            task.wait(C["Idle Wait"] or 5)
        else
            emptyRounds = 0
        end
        nxt = base
    end
    if nxt == cur then return false end
    local f, sl, _, bu, yo, pe = CollectOres(loc)
    log("Khu %d hết quặng (lộ %d chậm %d chôn %d non %d skip %s) -> sang khu %d", cur, #f, #sl, #bu, yo, pe and ("%.0fs"):format(pe - os.clock()) or "-", nxt)
    S.status = "sang khu " .. nxt
    S.rotZone = (nxt ~= base) and nxt or nil
    zoneArriveOre[nxt] = S.stats.ore
    TeleZoneTop(nxt)
    return true
end

-- ------------------------------------------------------------
-- auto combine: bấm UI _MACHINES.PetCraftingMachine (craft TỪ XA được, server không check khoảng cách) -> chọn recipe,
-- đọc "have/need" từ ObjectiveFrame, bấm OkMax/OkOne. Nút recipe "1".."4","10" chỉ có sau khi game render UI cho máy
-- Combine-O-Matic (đứng lên Pad máy khu 5 1 lần; máy khác có thể đè) -> thiếu nút thì tele lên Pad rồi tele về.
-- (PetCraftingMachine_Craft gọi thẳng bị server assert -> đi qua UI)
-- Kết quả đếm bằng số INPUT bị trừ (rung 10 trả pet ngẫu nhiên, không có item tên "Combine Egg" trong túi).
-- Recipe gốc: ReplicatedStorage.__DIRECTORY.PetCraftingMachines["PetCraftingMachine | MiningCraftMachine"] (rung 5-9 tắt FFlag 22/09).
-- ------------------------------------------------------------
local Recipes = {
    { idx = 1,  input = "Moonstone Gem",   out = "Star Ruby Gem" },
    { idx = 2,  input = "Star Ruby Gem",   out = "Helium-3 Gem" },
    { idx = 3,  input = "Helium-3 Gem",    out = "Nebulite Gem" },
    { idx = 4,  input = "Nebulite Gem",    out = "Dark Matter Gem" },
    { idx = 10, input = "Dark Matter Gem", out = "Combine Egg" },
}
local LAST_BTN = tostring(Recipes[#Recipes].idx) -- nút cuối có mặt = UI máy đã render đúng (Content của máy khác chỉ có "Button")
local function PressButton(btn)
    local ok, conns = pcall(getconnections, btn.Activated)
    if ok and #conns > 0 then
        for _, c in ipairs(conns) do if c.Function then task.spawn(c.Function) end end
        return true
    end
    if firesignal then pcall(firesignal, btn.Activated) return true end
    return false
end
local function MachinePad()
    local ok, pad = pcall(function()
        return workspace.__THINGS.__INSTANCE_CONTAINER.Active.SpaceMiningEvent.INTERACT.Machines.MiningCraftMachine.Pad
    end)
    return ok and pad or nil
end
-- đọc "have/need <item>" trong ObjectiveFrame sau khi chọn recipe
local function ReadNeed(frame, input)
    for _, d in ipairs(frame.ObjectiveFrame:GetDescendants()) do
        if d:IsA("TextLabel") then
            local have, need = d.Text:match("^(%d+)/(%d+)%s+" .. input:gsub("%-", "%%-") .. "$")
            if have then return tonumber(have), tonumber(need) end
        end
    end
end
local lastCombine = 0
local function DoCombine()
    if not C["Auto Combine"] or os.clock() - lastCombine < (tonumber(C["Combine Every"]) or 300) then return end
    lastCombine = os.clock()
    local want = C["Combine"] or {}
    local keep = tonumber(C["Combine Keep"]) or 0
    -- có gì để combine không (ước lượng: cần ít nhất 2 input) -> khỏi tele vô ích
    local any = false
    for _, r in ipairs(Recipes) do if want[r.out] and CountItem(r.input) - keep >= 2 then any = true break end end
    if not any then return end
    local frame = lp.PlayerGui:FindFirstChild("_MACHINES")
    frame = frame and frame:FindFirstChild("PetCraftingMachine") and frame.PetCraftingMachine:FindFirstChild("Frame")
    if not frame then return end
    local content = frame:FindFirstChild("UsingFrame") and frame.UsingFrame:FindFirstChild("Content")
    local back
    if not (content and content:FindFirstChild(LAST_BTN)) then
        -- UI máy chưa render -> lên Pad 1 lần cho game render nút recipe
        local pad, hrp = MachinePad(), HRP()
        if not pad or not hrp then return end
        back = hrp.CFrame
        S.status = "lên máy combine"
        hrp.CFrame = CFrame.new(pad.Position + Vector3.new(0, 3.8, 0))
        local t0 = os.clock()
        repeat
            task.wait(0.25)
            content = frame:FindFirstChild("UsingFrame") and frame.UsingFrame:FindFirstChild("Content")
        until (content and content:FindFirstChild(LAST_BTN)) or os.clock() - t0 > 8
    end
    local submit = frame:FindFirstChild("ObjectiveFrame") and frame.ObjectiveFrame:FindFirstChild("SubmitHolder")
    local okOne, okMax = submit and submit:FindFirstChild("OkOne"), submit and submit:FindFirstChild("OkMax")
    local crafted = {}
    if content and content:FindFirstChild(LAST_BTN) and okOne then
        for i = #Recipes, 1, -1 do -- rung cao trước (dùng gem vừa combine ở rung dưới lần sau)
            local r = Recipes[i]
            local btn = want[r.out] and content:FindFirstChild(tostring(r.idx))
            if btn and CountItem(r.input) - keep >= 2 then
                PressButton(btn) task.wait(0.5)
                local have, need = ReadNeed(frame, r.input)
                if have and need and need > 0 then
                    local times = math.floor((have - keep) / need)
                    if times >= 1 then
                        S.status = ("combine %s x%d"):format(r.out, times)
                        local in0 = CountItem(r.input)
                        if keep == 0 and okMax then
                            -- OkMax craft tối đa 100/lần -> lặp tới khi hết input (tối đa 10 lần)
                            for _ = 1, 10 do
                                local before = CountItem(r.input)
                                PressButton(okMax) task.wait(2)
                                local left = CountItem(r.input)
                                if left >= before or left < need then break end
                            end
                        else
                            for _ = 1, math.min(times, 25) do PressButton(okOne) task.wait(1.2) end
                        end
                        local got = math.floor((in0 - CountItem(r.input)) / need) -- rung 10 ra pet, không đếm được output
                        if got > 0 then crafted[r.out] = got S.stats.combines += got end
                    end
                end
            end
        end
    else
        log("Combine: UI máy không render nút recipe")
    end
    if back then
        local hrp = HRP()
        if hrp then hrp.CFrame = back end
        task.wait(0.5)
    end
    local parts = {}
    for k, v in pairs(crafted) do parts[#parts + 1] = k .. " x" .. v end
    if #parts > 0 then log("Combine: %s", table.concat(parts, ", ")) end
    return crafted
end
S.DoCombine = function() lastCombine = 0 return DoCombine() end -- gọi tay: getgenv()._OreSweep.DoCombine()

-- ------------------------------------------------------------
-- bombs
-- ------------------------------------------------------------
-- Consumables_Consume(uid, 1) nổ tại vị trí nhân vật (server đọc Player.Optional.Position), phải đang trong mine + FFlag SpaceMineExplosives.
-- res == false = debounce (~1 s) / hết hàng -> thử lại vòng sau, không tính. Xoay vòng loại để dùng hết mọi stock (bản cũ chỉ ném loại đầu list).
local lastBomb, bombIdx = 0, 0
local function DoBomb(loc)
    if not C["Auto Bomb"] or os.clock() - lastBomb < (tonumber(C["Bomb Every"]) or 5) then return end
    if not loc or loc.Destroyed or loc.Respawning then return end
    local list = C["Bomb Use"] or {}
    if #list == 0 then return end
    for _ = 1, #list do
        bombIdx = bombIdx % #list + 1
        local id = list[bombIdx]
        local uid = FindConsumableUID(id)
        if uid then
            local ok, res = pcall(Network.Invoke, "Consumables_Consume", uid, 1)
            if ok and res == true then
                lastBomb = os.clock()
                S.stats.bombs += 1
                dbg("Bom %s (còn %d)", id, CountItem(id))
                return
            end
            lastBomb = os.clock() - (tonumber(C["Bomb Every"]) or 5) + 1.5 -- bị debounce -> thử lại sau 1.5 s
            return
        end
    end
    lastBomb = os.clock() + 55 -- không còn quả nào -> 1 phút sau mới quét lại túi (merchant refresh)
end
S.DoBomb = DoBomb

-- ------------------------------------------------------------
-- merchant (copy từ main_mining2: Merchant_GetOffers luôn nil, cứ RequestPurchase từng slot, server tự validate)
-- ------------------------------------------------------------
local lastMerchant, merchantSeed, merchantDone = 0, nil, {}
local function DoMerchant()
    if not C["Auto Merchant"] or os.clock() - lastMerchant < (tonumber(C["Merchant Every"]) or 120) then return end
    lastMerchant = os.clock()
    local reserve = tonumber(C["Merchant Reserve"]) or 0
    if SpaceCoins() <= reserve then return end
    -- MerchantPurchases.SpaceMineMerchant: Seed đổi = merchant refresh (600 s) -> thử lại mọi slot
    local d = Save.Get()
    local mp = d.MerchantPurchases and d.MerchantPurchases.SpaceMineMerchant or {}
    if mp.Seed ~= merchantSeed then merchantSeed = mp.Seed merchantDone = {} end
    local bought = {}
    for slot = 1, tonumber(C["Merchant Slots"]) or 6 do
        if not merchantDone[slot] then
            local n = 0
            for _ = 1, 3 do -- stock tối đa 3
                local ok, res = pcall(Network.Invoke, "Merchant_RequestPurchase", "SpaceMineMerchant", slot)
                if ok and res == true then n += 1 task.wait(0.4) else break end
                if SpaceCoins() <= reserve then break end
            end
            merchantDone[slot] = true -- hết hàng / khoá / đã mua -> chờ refresh (Seed đổi)
            if n > 0 then bought[#bought + 1] = ("slot%d x%d"):format(slot, n) S.stats.merchant += n end
        end
    end
    if #bought > 0 then log("Merchant mua: %s (coins còn %d)", table.concat(bought, ", "), SpaceCoins()) end
end

-- ------------------------------------------------------------
-- Free Rewards (port từ main_mining2, VERIFIED 22/09): Save.FreeGiftsTime = giây đã chơi, Save.FreeGiftsRedeemed = {id...};
-- __DIRECTORY.FreeGifts "FreeGift | N".WaitTime (1:0 2:600 3:900 4:1200 5:1800 6:2400 7:3000 8:3600 9:4500 10:5400 11:7200 12:10800)
-- -> quà N sẵn sàng khi FreeGiftsTime >= WaitTime và chưa redeem; Network.Invoke("Redeem Free Gift", N) -> true
-- ------------------------------------------------------------
local giftWait, lastGiftAt = nil, 0
local function DoFreeGifts()
    if not C["Auto Free Gifts"] or os.clock() - lastGiftAt < 60 then return end
    lastGiftAt = os.clock()
    if not giftWait then
        giftWait = {}
        pcall(function()
            for _, m in ipairs(RS.__DIRECTORY.FreeGifts:GetChildren()) do
                local ok, g = pcall(require, m)
                if ok and type(g) == "table" and tonumber(g.Id) then giftWait[tonumber(g.Id)] = tonumber(g.WaitTime) or 0 end
            end
        end)
    end
    local d = Save.Get()
    local played = tonumber(d.FreeGiftsTime) or 0
    local done = {}
    for _, id in ipairs(d.FreeGiftsRedeemed or {}) do done[tonumber(id)] = true end
    local got = {}
    for id = 1, 12 do
        local wait = giftWait[id]
        if wait and not done[id] and played >= wait then
            local ok, res = pcall(Network.Invoke, "Redeem Free Gift", id)
            if ok and res == true then got[#got + 1] = tostring(id) end
            task.wait(0.3)
        end
    end
    if #got > 0 then log("Free Rewards: claim quà #%s", table.concat(got, ",")) end
end
S.DoFreeGifts = function() lastGiftAt = 0 return DoFreeGifts() end -- gọi tay: getgenv()._OreSweep.DoFreeGifts()

-- ------------------------------------------------------------
-- UI dashboard / webhook / anti-afk / stop key
-- ------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local function FmtNum(n)
    n = tonumber(n) or 0
    if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.1fk", n / 1e3) end
    return tostring(math.floor(n))
end
local function FmtTime(sec)
    sec = math.max(0, math.floor(sec))
    return ("%02d:%02d:%02d"):format(sec // 3600, (sec % 3600) // 60, sec % 60)
end
local GEM_SHORT = { "Moonstone", "Star Ruby", "Helium-3", "Nebulite", "Dark Matter" }
-- chỉ hiện số đang có trong inventory (như tab Space Mining), không hiện delta cho đỡ rối
local function GemLine(sep, ids, short)
    ids, short = ids or GEMS, short or GEM_SHORT
    local t = {}
    for i, id in ipairs(ids) do t[i] = ("%s %d"):format(short[i], CountItem(id)) end
    return table.concat(t, sep or "   ")
end
local function ZoneLayer()
    local loc = S.loc
    local z, y = 0, 0
    if loc and not loc.Destroyed then
        z = ZoneOf(loc)
        pcall(function() local pb = loc:GetPlayerBlock(lp) if pb then y = pb.Y end end)
    end
    return z, y
end

-- ---- dashboard (theo mẫu ui.lua) ----
local gui, uiHidden = nil, false
local UI = {}
if C["Show UI"] then
    pcall(function()
        local old = lp.PlayerGui:FindFirstChild("OreSweepUI")
        if old then old:Destroy() end
        local C_GOLD, C_DIM, C_WHITE, C_GREEN, C_PURPLE = Color3.fromRGB(255, 170, 0), Color3.fromRGB(200, 205, 220), Color3.new(1, 1, 1), Color3.fromRGB(80, 220, 120), Color3.fromRGB(180, 150, 255)
        gui = Instance.new("ScreenGui")
        gui.Name = "OreSweepUI" gui.DisplayOrder = 999 gui.ResetOnSpawn = false gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling gui.Parent = lp.PlayerGui
        local black = C["UI Black Screen"] ~= false
        local bg = Instance.new("Frame")
        bg.BackgroundColor3 = Color3.new(0, 0, 0) bg.BorderSizePixel = 0 bg.ZIndex = 999 bg.Parent = gui
        local container = Instance.new("Frame")
        container.BackgroundTransparency = 1 container.BorderSizePixel = 0 container.ZIndex = 1000 container.Parent = gui
        if black then
            bg.Size = UDim2.new(1, 0, 1, 0)
            -- khung nội dung (y 0..370) neo giữa màn hình
            container.Size = UDim2.new(1, 0, 0, 370)
            container.AnchorPoint = Vector2.new(0.5, 0.5)
            container.Position = UDim2.new(0.5, 0, 0.5, 0)
        else
            -- panel nhỏ góc trái, không che màn hình
            bg.Size = UDim2.new(0, 460, 0, 330) bg.Position = UDim2.new(0, 10, 0, 120) bg.BackgroundTransparency = 0.3
            Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
            container.Size = bg.Size container.Position = bg.Position
        end
        local sc = black and 1 or 0.62
        local function MkText(text, size, color, bold, y, h)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, (h or size + 6) * sc) l.Position = UDim2.new(0, 0, 0, y * sc)
            l.BackgroundTransparency = 1 l.Text = text
            l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham l.TextSize = math.floor(size * (black and 1 or 0.75))
            l.TextColor3 = color or C_WHITE l.TextXAlignment = Enum.TextXAlignment.Center l.TextYAlignment = Enum.TextYAlignment.Center
            l.ZIndex = 1000 l.Parent = container
            return l
        end
        local function MkSep(y)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(0, 420 * sc, 0, 2) f.Position = UDim2.new(0.5, -210 * sc, 0, y * sc)
            f.BackgroundColor3 = C_GOLD f.BackgroundTransparency = 0.4 f.BorderSizePixel = 0 f.ZIndex = 1000 f.Parent = container
        end
        MkText(lp.Name, 44, C_GOLD, true, 10, 50)
        MkSep(75)
        UI.time   = MkText("Session Time: 00:00:00", 24, C_WHITE, true, 90, 32)
        UI.coins  = MkText("Space Coins: 0", 22, C_GOLD, true, 130, 32)
        UI.ore    = MkText("Ore: 0 (0/min)  |  Fail 0  Hop 0", 22, C_GREEN, true, 170, 30)
        UI.gems   = MkText("---", 18, C_WHITE, false, 208, 28)
        UI.zone   = MkText("Zone 0  y=0", 18, C_DIM, false, 242, 28)
        UI.status = MkText("Status: init", 18, C_DIM, false, 276, 28)
        MkSep(316)

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 36, 0, 36) toggleBtn.Position = UDim2.new(1, -48, 0, 10)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 50) toggleBtn.BorderSizePixel = 0
        toggleBtn.Text = "-" toggleBtn.TextSize = 22 toggleBtn.Font = Enum.Font.GothamBold toggleBtn.TextColor3 = C_WHITE
        toggleBtn.ZIndex = 1001 toggleBtn.Parent = gui
        Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
        if black then pcall(function() RunService:Set3dRenderingEnabled(false) end) end
        toggleBtn.MouseButton1Click:Connect(function()
            uiHidden = not uiHidden
            container.Visible = not uiHidden
            bg.Visible = not uiHidden
            toggleBtn.Text = uiHidden and "+" or "-"
            -- ẩn dashboard = bật lại 3D (như ui.lua)
            if black then pcall(function() RunService:Set3dRenderingEnabled(uiHidden) end) end
        end)
    end)
end
local function UpdateUI()
    if not gui or not UI.time then return end
    local el = math.max(1, os.clock() - S.stats.t0)
    local z, y = ZoneLayer()
    UI.time.Text   = "Session Time: " .. FmtTime(el)
    UI.coins.Text  = "Space Coins: " .. FmtNum(SpaceCoins())
    UI.ore.Text    = ("Ore: %d (%.0f/min)  |  Fail %d  Hop %d"):format(S.stats.ore, S.stats.ore / el * 60, S.stats.fail, S.stats.hops)
    UI.gems.Text   = GemLine("   ")
    UI.zone.Text   = ("Zone %d  y=%d"):format(z, y)
    UI.status.Text = "Status: " .. tostring(S.status)
end
task.spawn(function()
    while Alive() do
        pcall(UpdateUI)
        task.wait(0.5)
    end
end)

-- ---- Discord webhook ----
local httpRequest = (syn and syn.request) or http_request or request or (fluxus and fluxus.request)
local function SendWebhook(title, fields, color, mention)
    local url = C["Webhook URL"]
    if not url or url == "" or not httpRequest then return false end
    local ok = pcall(function()
        local tag = C["Discord Tag ID"]
        local body = {
            content = (mention and tag and tag ~= "") and ("<@" .. tag .. ">") or nil,
            embeds = { {
                title = title, color = color or 0x3498db, fields = fields,
                footer = { text = lp.Name .. " • Space Mine Ore Sweep v3.1" },
            } },
        }
        httpRequest({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(body) })
    end)
    return ok
end
local function StatusFields()
    local el = math.max(1, os.clock() - S.stats.t0)
    local z, y = ZoneLayer()
    local f = {
        { name = "Uptime", value = FmtTime(el), inline = true },
        { name = "Zone / y", value = ("Zone %d  y=%d"):format(z, y), inline = true },
        { name = "Ore farmed", value = ("%d (%.0f/min)"):format(S.stats.ore, S.stats.ore / el * 60), inline = true },
        { name = "Fail / Buried / Hop", value = ("%d / %d / %d"):format(S.stats.fail, S.stats.buried, S.stats.hops), inline = true },
        { name = "Space Coins", value = FmtNum(SpaceCoins()), inline = true },
        { name = "Inventory gems", value = GemLine("\n"), inline = false },
    }
    if C["Auto Combine"] then f[#f + 1] = { name = "Combine", value = tostring(S.stats.combines), inline = true } end
    if C["Auto Merchant"] then f[#f + 1] = { name = "Merchant bought", value = tostring(S.stats.merchant), inline = true } end
    return f
end
local function StatusWebhook(title, color, mention)
    return SendWebhook(title or lp.Name, StatusFields(), color or 0x3498db, mention)
end
S.SendWebhook = StatusWebhook -- gọi tay: getgenv()._OreSweep.SendWebhook()
-- pet mới Huge/Titanic/Gargantuan -> webhook + tag
local petSnap, petInit = {}, false
local function CheckNewPets()
    pcall(function()
        local d = Save.Get()
        for uid, p in pairs(d.Inventory.Pet or {}) do
            local id = p.id or ""
            if (id:find("^Huge ") or id:find("^Titanic ") or id:find("^Gargantuan ")) and not petSnap[uid] then
                petSnap[uid] = id
                if petInit then
                    log("*** PET MỚI: %s ***", id)
                    StatusWebhook("🎉 " .. id .. " – " .. lp.Name, 0xf1c40f, true)
                end
            end
        end
        petInit = true
    end)
end
CheckNewPets()
task.spawn(function()
    if not C["Webhook URL"] or C["Webhook URL"] == "" then return end
    task.wait(5)
    StatusWebhook(lp.Name .. " – start", 0x2ecc71)
    local last = os.clock()
    while Alive() do
        task.wait(5)
        CheckNewPets()
        if os.clock() - last > (tonumber(C["Webhook Every"]) or 600) then
            last = os.clock()
            StatusWebhook()
        end
    end
end)
local afkConn
if C["Anti AFK"] then
    afkConn = lp.Idled:Connect(function() pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end) end)
end
local keyConn = UIS.InputBegan:Connect(function(input, gp)
    if not gp and C["Stop Key"] and input.KeyCode == C["Stop Key"] then S.Stop("stop key") end
end)
function S.Stop(reason)
    S.running = false
    HoldUnpatch()
    pcall(function() if afkConn then afkConn:Disconnect() end end)
    pcall(function() if keyConn then keyConn:Disconnect() end end)
    pcall(function() if gui then gui:Destroy() end end)
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    log("Stop (%s). ore %d blocks %d fail %d", tostring(reason), S.stats.ore, S.stats.blocks, S.stats.fail)
end

-- ------------------------------------------------------------
-- main loop
-- ------------------------------------------------------------
log("Start. Zone %s | Ores %s | Combine %s | Idle Mine %s", tostring(C["Target Zone"]),
    (function() local t = {} for k, v in pairs(C["Ores"]) do if v then t[#t + 1] = k end end table.sort(t) return table.concat(t, "/") end)(),
    tostring(C["Auto Combine"]), tostring(C["Idle Mine"]))
local lastReport = os.clock()
task.spawn(function()
    while Alive() do
        local ok, err = pcall(function()
            if not C["Enabled"] then S.status = "paused" task.wait(1) return end
            if not EnsureInstance() then S.status = "ngoài event" task.wait(3) return end
            local loc = GetLocal()
            if loc ~= S.loc then S.locAt = os.clock() end -- vừa sang world mới -> RotateZone chờ block stream về rồi mới được kết luận "hết quặng"
            S.loc = loc
            local want = WantZone()
            if not loc then
                S.status = "tele khu " .. want
                TeleZoneTop(want) return
            end
            if ZoneOf(loc) ~= want then
                log("Chuyển sang khu %d", want)
                TeleZoneTop(want) return
            end
            if loc.Respawning then
                S.status = "mine reset"
                if S.rotZone then log("Mine reset ở khu %d -> về khu %d", ZoneOf(loc), BaseZone()) S.rotZone = nil end -- reset -> về khu gốc quét lại từ đầu
                task.wait(1) return
            end
            -- ngoài vùng mine (bị đẩy) -> về mặt khu
            local hrp = HRP()
            local inside = true
            if hrp then pcall(function() inside = loc:IsInsideXZ(hrp.Position) end) end
            if not inside then TeleZoneTop(want) return end

            DoCombine()
            DoBomb(loc)
            DoMerchant()
            DoFreeGifts()

            local fast, slow, total, buried, young, pendingAt = CollectOres(loc)
            if #fast > 0 or #slow > 0 or young > 0 then S.emptySince = nil end -- còn quặng -> reset đồng hồ "mine chết"
            if #fast >= (C["Min Ores"] or 3) then
                local t0 = os.clock()
                local n, why = Sweep(loc, fast)
                dbg("Lượt: %d quặng / %.0fs (%s)", n, os.clock() - t0, tostring(why))
                if n == 0 and why == "done" then S.status = "chờ quặng đang skip" task.wait(math.clamp(tonumber(C["Idle Poll"]) or 0.4, 0.05, 5)) end -- còn quặng nhưng đều đang skip -> nghỉ, không quay tít
            elseif #slow > 0 and C["Slow Last"] then
                local n, why = Sweep(loc, slow)
                if n == 0 and why == "done" then S.status = "chờ quặng đang skip" task.wait(math.clamp(tonumber(C["Idle Poll"]) or 0.4, 0.05, 5)) end
            elseif C["Dig Buried"] and DigBuried(loc) then
                return -- quặng đã lộ -> vòng sau sweep lấy
            elseif young > 0 then
                S.status = ("chờ %d quặng mới load"):format(young) task.wait(math.clamp(tonumber(C["Idle Poll"]) or 0.4, 0.05, 5)) -- mine respawn từng block: quặng non sắp đào được, không xoay khu
            elseif pendingAt and pendingAt - os.clock() < 15 then
                S.status = ("chờ quặng skip %.0fs"):format(pendingAt - os.clock()) task.wait(math.clamp(pendingAt - os.clock() + 0.1, 0.2, 1)) -- quặng ghost/che sắp hết skip -> đợi, không đổi khu
            elseif C["Zone Rotate"] and RotateZone(loc) then
                return -- world đổi, vòng sau lấy loc mới
            elseif HopIfDead(loc, total) then
                return -- đang teleport sang server khác
            elseif C["Idle Mine"] then
                local mined = IdleMine(loc, 20)
                if mined == 0 then S.status = "chờ quặng" task.wait(math.clamp(tonumber(C["Idle Poll"]) or 0.4, 0.05, 5)) end
            else
                S.status = "chờ quặng"
                task.wait(math.clamp(tonumber(C["Idle Poll"]) or 0.4, 0.05, 5)) -- poll nhanh: server cạn thì quặng respawn lắt nhắt, ngủ 5 s là mất lượt
            end
        end)
        if not ok then log("Lỗi: %s", tostring(err)) task.wait(2) end
        if os.clock() - lastReport > 120 then
            lastReport = os.clock()
            local el = os.clock() - S.stats.t0
            log("=== %.0f phút | ore %d (%.0f/phút) blocks %d fail %d chôn %d hop %d | combine %d | coins %s", el / 60, S.stats.ore, S.stats.ore / el * 60, S.stats.blocks, S.stats.fail, S.stats.buried, S.stats.hops, S.stats.combines, FmtNum(SpaceCoins()))
        end
        task.wait()
    end
end)
