-- Space Mine Ore Sweep - loader
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
loadstring(game:HttpGet("https://raw.githubusercontent.com/vuhoanghai208/mining/main/ore_sweep.lua"))()
