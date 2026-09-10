# GifShot

框选屏幕区域录制成 GIF，自动压缩到指定体积，录完直接进剪贴板。

Linux / X11 / GNOME 下的单文件 Python 工具，除 `ffmpeg` 等系统命令外无第三方 Python 依赖。

```
Super+Shift+G   拖拽框选区域
Super+Shift+R   开始录制  →  再按一次结束
                自动转 GIF → 压到 20 MB 以内 → 复制到剪贴板
```

---

## 特性

- **拖拽框选**：全屏压暗覆盖层，选区透明可见，实时显示 `800 × 600` 尺寸；单击不拖则退化为「选中鼠标下的整个窗口」
- **同键起停**：一个快捷键开始，同一个键结束，不用记两组
- **体积上限**：超出目标大小自动降规格重编码，直到塞进去（默认 20 MB）
- **自动进剪贴板**：同时提供 `image/gif` 和 `text/uri-list`，浏览器 / Slack / 聊天软件
  Ctrl+V 粘出来是**会动的**，文件管理器 / 邮件里粘出来是**文件**
- **多显示器**：覆盖层横跨所有屏幕，选区可跨屏
- **CSD 阴影裁剪**：读 `_GTK_FRAME_EXTENTS` 去掉 GNOME 窗口四周的不可见阴影边框
- **原子输出**：多轮压缩在临时目录进行，输出目录不会出现写到一半的文件

## 安装

```bash
git clone https://github.com/KaiqingSun/gifshot.git
cd gifshot
./install.sh --hotkeys
```

脚本会装系统依赖（需要 sudo）、把 `gifshot` 放进 `~/.local/bin`、写桌面入口、注册快捷键，最后跑一遍体检。

```
./install.sh              只装，不注册快捷键
./install.sh --no-deps    依赖已装过，跳过 apt
./install.sh --prefix /usr/local/bin
```

支持 apt / dnf / pacman。认不出包管理器时会打印需要手装的清单。

**卸载**：`./uninstall.sh`（保留你已经录好的 GIF，不动系统依赖）

### 依赖

| 包 | 用途 |
|---|---|
| `ffmpeg` | 屏幕采集 + GIF 编码 |
| `xdotool` | 点选窗口 |
| `x11-utils` | `xwininfo` 量尺寸、`xprop` 读阴影边框、`xdpyinfo` 探测剪贴板上限 |
| `python3-gi` `python3-gi-cairo` `gir1.2-gtk-3.0` | GTK3 界面和框选覆盖层 |
| `gir1.2-gtk-4.0` | GTK4，用来持有剪贴板（见下） |
| `libnotify-bin` | 桌面通知 |

随时可以 `gifshot doctor` 逐项体检。

## 用法

### 快捷键

| 键 | 动作 |
|---|---|
| `Super+Shift+G` | 框选区域（Super = Windows 徽标键） |
| `Super+Shift+W` | 点选整个窗口 |
| `Super+Shift+R` | 开始 / 结束录制 |

框选时：**拖拽**画框，**单击**选中鼠标下的窗口，**Esc / 右键**取消。

改键改 `~/.config/gifshot/config.json` 里的 `region_key` / `window_key` / `toggle_key`，
写成 GTK accelerator 格式（如 `<Control><Alt>g`），然后 `gifshot hotkeys install` 生效。

非 GNOME 桌面没有 `gsettings` 自定义快捷键，自行在桌面环境里把三个命令
`gifshot region` / `gifshot select` / `gifshot toggle` 绑到按键上即可。

### 命令行

```
gifshot                          启动 GUI
gifshot region                   拖拽框选区域
gifshot select                   十字光标点选整个窗口
gifshot toggle                   开始 / 结束录制
gifshot start | stop | cancel
gifshot compress <文件> [上限MB]   单独压缩已有 gif / 视频
gifshot status
gifshot hotkeys install|remove|show
gifshot doctor
gifshot --version
```

## 压缩

录完先按当前设置编一版，超出上限就自动降规格重编码，**按画质损失从小到大**依次动三个旋钮：

1. **缩尺寸** — 预测式，用 `√(上限/实际)` 一步跳到位，不是一格格试
2. **降帧率** — 15 → 12 → 10 → 8
3. **减调色板** — 256 → 192 → 128 → 96 → 64 色

实测：

```
上限 20 MB / 640×480 3s     第1次 640px 15fps 256色 = 202 KB     一次过
上限 0.3 MB / 1280×720 6s   第1次 800px = 587 KB
                            第2次 578px = 341 KB
                            第3次 520px = 288 KB                达标
```

压不到目标**不会静默交付**——通知会标红提示「已压到极限仍超标」并给出实际体积。
宁可给一个诚实的超标文件，也不会把画质砍成马赛克。

单独压已有文件：

```bash
gifshot compress demo.gif 5      # 压到 5 MB 以内，输出 demo-small.gif
gifshot compress screen.mp4 2
```

## 配置

`~/.config/gifshot/config.json`，首次运行自动生成。

| 键 | 默认 | 说明 |
|---|---|---|
| `out_dir` | `~/Pictures/GIFs` | 输出目录 |
| `fps` | `15` | 帧率 |
| `max_width` | `800` | 超过就等比缩放 |
| `draw_mouse` | `true` | 是否录鼠标指针 |
| `clipboard` | `"gif"` | `gif` / `uri` / `off`，见下 |
| `max_size_mb` | `15` | 体积上限（默认值贴着 X11 剪贴板上限，见下） |
| `compress` | `true` | 关掉就只编一版，不管多大 |
| `min_width` | `320` | 压缩时不会缩得比这更窄 |
| `min_fps` | `8` | 也不会降得比这更低 |
| `compress_tries` | `9` | 最多重编码次数 |
| `max_seconds` | `300` | 录制硬上限，防止忘记停止 |
| `keep_video` | `false` | 保留 x264 中间文件 |
| `dither` | `bayer:bayer_scale=5` | ffmpeg `paletteuse` 的抖动参数 |

体积上限和开关在 GUI 里也能直接调。

**`clipboard` 的三种模式**

- `"gif"`（默认）— 同时提供 `image/gif` 和 `text/uri-list`，粘到哪儿都合适
- `"uri"` — 只提供 `text/uri-list`，粘的是文件，适合文件管理器、邮件附件
- `"off"` — 不碰剪贴板

### 为什么不用 xclip

剪贴板由一个常驻的 GTK4 子进程持有，别的程序接管时它自动退出。不用 `xclip`，因为：

- **xclip 0.13 的 INCR 实现是坏的**。X11 传输超过约 1 MB 就要走 INCR 分块协议，
  而 xclip 一旦写入这么大的数据，进程虽然还在，却再也不响应任何选区请求——
  连 4 字节的 `TARGETS` 都不回。实测 312 KB 正常，1 MB 起全挂。
- **xclip fork 后立刻 `exit 0`**，调用方拿到的返回码永远是成功，无从发现失败。
  现在改成子进程自报 `READY` 才算数。
- GTK3 的 `Gtk.Clipboard.set_with_data` 在 PyGObject 里不存在（调了会 core dump），
  GTK4 的 `Gdk.ContentProvider` 才可用，顺带还能同时提供多个 MIME 类型。

**剪贴板有个 ~15 MB 的硬上限**，由 X 服务器的 `maximum request size` 决定
（`xdpyinfo | grep "maximum request"`）。超过这条线就必须走 INCR，实测传不完。
所以 `max_size_mb` 默认设成 15，让 GIF 正好能进剪贴板；万一还是超了，
会自动退回只放 `text/uri-list`（还能粘成文件），并在通知里说明。

## 平台支持

**只支持 Linux + X11。** 每一层都绑在 X11 上：`ffmpeg -f x11grab` 采集、
`xdotool`/`xwininfo`/`xprop` 找窗口、X11 selection 传剪贴板、GNOME `gsettings` 注册快捷键。

- **Wayland** — 不工作。`x11grab` 和 `xdotool` 在 Wayland 下都失效，需要换成
  `wf-recorder` 或 xdg-desktop-portal 的 ScreenCast 接口。目前没做。
  注销后在登录界面点齿轮 ⚙ 选「Ubuntu on Xorg」即可。
  注意 Wayland 下的 XWayland 兼容层**照样会设置 `DISPLAY`**，所以不能靠 `DISPLAY`
  判断——`gifshot doctor` 看的是 `XDG_SESSION_TYPE`。
- **macOS** — 不支持。采集要换 `avfoundation`（且不能直接指定区域，得整屏采集再 crop）、
  窗口枚举换 CoreGraphics、剪贴板换 NSPasteboard（`pbcopy` 不支持二进制图片类型）、
  快捷键换 Hammerspoon 或 `RegisterEventHotKey`，还要过屏幕录制权限。
  Mac 上建议直接用 [Kap](https://getkap.co)。
- **Windows** — 不支持。

唯一跨平台的部分是压缩引擎（`render_gif`），它只调 ffmpeg。

## 排错

| 现象 | 原因 |
|---|---|
| 录出来全黑 / 尺寸不对 | 多半在 Wayland 下，跑 `gifshot doctor` 会直接指出来 |
| 框选层不显示、报 cairo 错 | 缺 `python3-gi-cairo` |
| 快捷键没反应 | `gifshot hotkeys show` 看是否注册；GNOME 下检查有无按键冲突 |
| 粘贴出来是静态图 | 目标应用不接受 `image/gif`，改用 `"clipboard": "uri"` 粘文件 |
| 粘不出东西 | GIF 可能超过 ~15 MB 剪贴板上限，`gifshot doctor` 会显示实际上限 |
| 录制没停下来 | `gifshot cancel` 丢弃当前录制 |

日志在 `~/.local/state/gifshot/gifshot.log`，每次编码的尺寸/帧率/颜色/体积都有记录。

## License

MIT
