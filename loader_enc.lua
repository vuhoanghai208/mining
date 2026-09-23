-- Space Mine Ore Sweep - loader
-- (URL nguon duoc XOR + base64, giai ma luc chay; source tren repo van la ban goc khong obfuscate)
getgenv().OreSweepConfig = {
    ["Target Zone"]      = 5,
    ["Server Hop"]       = true,
    ["Hop After"]        = 60,
    ["Hop If Mine Dead"] = 8000,
    ["Hop After Empty"]  = 45,
    ["Auto Combine"]     = true,
    ["Combine Every"]    = 600,
    ["Auto Bomb"]        = true,
    ["Auto Merchant"]    = true,
    ["Auto Free Gifts"]  = true,
    ["Show UI"]          = true,
    ["UI Black Screen"]  = true,
}
local b64, k = "6PT08PO6r6/y4feu5+n06PXi9fPl8uPv7vTl7vSu4+/tr/b16O/h7ufo4emysLiv7enu6e7nr+3h6e6v7/Ll3/P35eXwruz14Q==", 128
local A = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local bits = ""
for c in b64:gmatch("[^=]") do
    local i = (A:find(c, 1, true) or 1) - 1
    for p = 5, 0, -1 do bits = bits .. (bit32.extract(i, p, 1)) end
end
local src = ""
for i = 1, #bits - 7, 8 do
    local n = 0
    for p = 0, 7 do n = n * 2 + tonumber(bits:sub(i + p, i + p)) end
    src = src .. string.char(bit32.bxor(n, k))
end
local ok, body = pcall(function() return game:HttpGet(src) end)
if not ok or not body then return warn("[OreSweep] khong tai duoc script: " .. tostring(body)) end
local f, err = loadstring(body)
if not f then return warn("[OreSweep] loi bien dich: " .. tostring(err)) end
task.spawn(f)
