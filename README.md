# mining

Space Mine Ore Sweep — script farm quặng cho Pet Simulator 99 (Space Mining Event).

## Dùng nhanh

Đặt config **trước**, rồi gọi loader (loader không chứa config để bạn tự obfuscate thêm lớp nữa):

```lua
getgenv().OreSweepConfig = {
    ["Target Zone"]      = 5,
    ["Server Hop"]       = true,
    ["Auto Combine"]     = true,
    ["Auto Bomb"]        = true,
    ["Auto Merchant"]    = true,
    ["Auto Free Gifts"]  = true,
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/vuhoanghai208/mining/main/loader_enc.lua"))()
```

Không đặt `OreSweepConfig` cũng chạy được — script dùng mặc định trong file.

Chạy thẳng không qua loader:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/vuhoanghai208/mining/main/ore_sweep.lua"))()
```

Dừng: phím `P` hoặc `getgenv()._OreSweep.Stop()`.

## Chọn loại quặng

Trên dashboard có hàng nút 5 loại quặng, mỗi nút kèm **số giây phá 1 cục với pickaxe đang cầm**:
bấm để bật/tắt ngay lúc đang chạy. Xanh = đang farm, xám = tắt, vàng kèm `!` = cần nhiều giây hơn `Max Sec` nên sẽ bị bỏ qua.

Đổi bằng code cũng được:

```lua
getgenv()._OreSweep.SetOre("Rainbow", false)                 -- tắt 1 loại
getgenv()._OreSweep.SetOres{ Amethyst = true, Ruby = false } -- đổi nhiều loại
getgenv()._OreSweep.OreSec("Amethyst")                       -- ~20.1 (giây/cục)
```

Hoặc đặt sẵn lúc khởi động: `getgenv().OreSweepConfig = { ["Ores"] = { Sapphire = true, Ruby = true, Emerald = true, Amethyst = true, Rainbow = true } }`.

## Tham số hay dùng

| Key | Mặc định | Ý nghĩa |
|---|---|---|
| `Target Zone` | 5 | Khu muốn farm (1–5), tự hạ xuống khu cao nhất đã mở |
| `Ores` | 5 loại bật hết | Sapphire→Moonstone, Ruby→Star Ruby, Emerald→Helium-3, Amethyst→Nebulite, Rainbow→Dark Matter + 5.000.000 coins |
| `Max Sec` | 90 | Bỏ quặng cần > N giây (Helium-3 Pickaxe: Amethyst 20 s, Rainbow 81 s) |
| `Server Hop` | false | Mine cạn thì nhảy server khác (nhớ server đã vào, tránh trùng) |
| `Hop If Mine Dead` | 8000 | Vào server mà mine còn < N block = đã bị vét → hop tiếp ngay |
| `Resync On Ghost` | 6 | N cục "ghost" liên tiếp → rời/vào lại event cho world nạp lại |
| `Auto Combine` | false | Tự combine gem ở Combine-O-Matic (kể cả rung 30 Dark Matter → Combine Egg) |
| `Auto Bomb` | false | Ném bom mine trong túi để lộ thêm quặng |
| `Auto Merchant` | true | Mua bom bằng Space Coins |
| `Auto Free Gifts` | true | Tự nhận 12 quà Free Rewards |
| `Show UI` / `UI Black Screen` | true | Dashboard; màn đen tắt render 3D cho nhẹ máy |
| `Webhook URL` | "" | Discord webhook báo stats + pet Huge/Titanic |
| `Debug` | false | In log từng cục quặng |

Toàn bộ tham số nằm ở bảng `DEF` đầu file `ore_sweep.lua`.
