# Cache Project (Verilog) - Hướng dẫn chạy mô phỏng với Icarus Verilog + GTKWave

Dự án này mô phỏng **cache** bằng Verilog. Sử dụng:
- **Icarus Verilog** (`iverilog`, `vvp`) để **biên dịch + chạy mô phỏng**
- **GTKWave** (`gtkwave`) để **xem dạng sóng** (`.vcd`)

---

## 1) Cấu trúc thư mục

```
cache_project/
├── build/
│   └── sim.out
├── rtl/
│   ├── address_decoder.v
│   ├── cache_controller.v
│   ├── cache_data_array.v
│   ├── cache_params.vh
│   ├── cache_tag_array.v
│   ├── cache_top.v
│   ├── line_assembler.v
│   └── simple_ram.v
├── tb/
│   └── tb_cache.v
└── cache_wave.vcd
```

**Mô tả ngắn gọn:**
- `rtl/`: mã nguồn thiết kế (RTL) của cache và các module con
- `tb/`: testbench (`tb_cache.v`) dùng để mô phỏng
- `build/`: file đầu ra sau biên dịch/mô phỏng (`sim.out`)
- `cache_wave.vcd`: file dạng sóng sinh ra từ mô phỏng

**Top module / Testbench:**
- **DUT / Top RTL:** `cache_top` (định nghĩa trong `rtl/cache_top.v`)
- **Testbench:** `tb_cache` (trong `tb/tb_cache.v`) gọi `cache_top` để kiểm tra
---

## 2) Yêu cầu cài đặt

### Windows
- **Icarus Verilog (iverilog + vvp)**
- **GTKWave**

> Lưu ý: GTKWave chỉ là “viewer”. Muốn có waveform thì testbench phải dump ra file (`dump.vcd`).

### Link tải chính thức (khuyến nghị)
- **Icarus Verilog (iverilog + vvp)**
  - Windows installer: https://bleyer.org/icarus/
  - Tài liệu/Install guide: https://steveicarus.github.io/iverilog/
  - GitHub Releases: https://github.com/steveicarus/iverilog/releases
- **GTKWave**
  - Trang chủ + Downloads: https://gtkwave.sourceforge.net/
  - SourceForge Files (bản binary/zip theo thư mục): https://sourceforge.net/projects/gtkwave/files/
  - GitHub Releases: https://github.com/gtkwave/gtkwave/releases
  - Documentation site: https://gtkwave.github.io/gtkwave/


### Cài  đặt  
#### Cách 1: Cài Icarus Verilog for Windows (có thể kèm GTKWave)
1. Tải installer “Icarus Verilog for Windows”.
2. Chạy file `.exe` và cài theo wizard.
3. Mở **Command Prompt / PowerShell** kiểm tra:
   ```bash
   iverilog -V
   vvp -V
   gtkwave --version
   ```
   - Nếu `gtkwave` chưa có, hãy cài GTKWave theo “Cách 2”.

#### Cách 2: Cài GTKWave riêng
- Tải GTKWave theo gói/binary phù hợp hệ điều hành (Windows).

> Gợi ý: Nhiều bản cài Icarus trên Windows có thể đã kèm GTKWave. Nếu thiếu thì cài GTKWave riêng.

Kiểm tra nhanh:
```bash
iverilog -V
vvp -V
gtkwave --version
```
### Troubleshooting nhanh

`iverilog` / `gtkwave` không nhận lệnh (Windows)
- Chưa add PATH → thêm đường dẫn cài đặt vào **Environment Variables → Path**
- Đóng/mở lại terminal sau khi chỉnh PATH

Compile báo lỗi không tìm thấy `cache_params.vh`
- Thiếu `-I rtl` → thêm `-I rtl` khi chạy `iverilog`

Không thấy `cache_wave.vcd`
- Kiểm tra `tb/tb_cache.v` có `$dumpfile("cache_wave.vcd")` và `$dumpvars(...)` chưa
- Đảm bảo bạn chạy `vvp` ở đúng thư mục gốc dự án

---

## 3) Chạy mô phỏng bằng lệnh

> Chạy lệnh trong thư mục gốc `cache_project/`.

### Compile
```bash
iverilog -g2012 -I rtl -o build/sim.out   tb/tb_cache.v   rtl/cache_top.v   rtl/address_decoder.v   rtl/cache_tag_array.v   rtl/cache_data_array.v   rtl/simple_ram.v   rtl/line_assembler.v   rtl/cache_controller.v
```

> `cache_params.vh` là file include nên **không cần** liệt kê vào danh sách compile, chỉ cần `-I rtl`.

### Run
```bash
vvp build/sim.out
```

### Mở dạng sóng
```bash
gtkwave cache_wave.vcd
```

---