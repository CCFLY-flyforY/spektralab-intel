# spektralab-intel — 让 SpektraLab 在 Intel Mac 上跑起来（非官方补丁）

**非官方、非官方、非官方。** 这里只是一组让 [SpektraLab](https://github.com/JamesQiu2005/SpektraLab)（GPL-3.0）能在 x86_64 Mac 上编译运行的补丁与构建脚本，与原作者无关，也不代表他认可。

## 为什么需要它

SpektraLab 的官方发行版只提供 **arm64** 的 DMG（`SpektraLab-1.3.5-arm64.dmg`），README 写明「需要 Apple 芯片」。Intel Mac 双击会得到 `Bad CPU type in executable`（退出码 126）。

但这套源码里有三处隐含的「Apple 芯片」假设，改掉之后就能用本机的 Command Line Tools 编出 x86_64 版——不需要完整 Xcode。

## 改了什么（详见 `MODIFICATIONS.md`）

| 位置 | 问题 | 改法 |
| --- | --- | --- |
| `engine/src/gpu/metal_gpu.cpp` | 启动自检 `a*b - a*b` 在 Apple GPU 上非零，在 AMD 上恒为 0，引擎据此判定「metallib 是 fast math 编的」而拒绝渲染 | 降级为警告，继续渲染 |
| `CineonLUT.swift` | `Float16` 在 macOS x86_64 上不可用 | 改用 Accelerate 的 `vImageConvert_PlanarFtoPlanar16F` |
| `DiagnosticBundle.swift` | 一个位运算表达式让 Swift 类型检查器超时 | 拆成多行 |
| `Session.swift` / `MaskOverlay.swift` / `FilmEdgeSection.swift` / `Geometry.swift` | `CGFloat` ↔ `Double` 隐式转换在复杂表达式里造成重载歧义 | 显式转换、拆表达式 |

## 直接下载（Intel 版，已改名换图标）

不想自己编的，可以下我构建好的版本：

- **FilmLab-1.0.0-x86_64.zip**（约 30MB）— 见本仓库 Releases
- SHA-256：`695df366e53f0d20217517468d78811cc0a8bc2b0448b3df51cd5d6a75cd632f`

它是 ad-hoc 签名（没有开发者账号、未公证），首次打开会被 Gatekeeper 拦一次：右键 → 打开，或 `xattr -dr com.apple.quarantine /Applications/FilmLab.app`。

为什么叫 FilmLab：`SpektraLab™` 的名称与图标归上游作者的公司，对外分发必须换掉（见下文「关于名字与图标」）。功能与上游 1.3.5 相同。

## 怎么编

前置：一台 Intel Mac、macOS 15+、**Command Line Tools**（`xcode-select --install`），以及**官方的 arm64 DMG**（只用来当资源骨架：`Assets.car`、`default.metallib`、胶片与相纸配置、DI LUT 都在里面，`actool` 与 `metal` 这两个只有 Xcode 才有的工具因此不用碰）。

```bash
git clone https://github.com/JamesQiu2005/SpektraLab.git
cd SpektraLab && git checkout 02d82b5   # 补丁对应的版本
git apply /path/to/patches/intel-x86_64.patch

# 挂载官方 dmg，把 .app 拷出来当骨架
hdiutil attach SpektraLab-1.3.5-arm64.dmg -nobrowse
cp -R "/Volumes/SpektraLab 1.3.5/SpektraLab.app" /tmp/SpektraLab-x86.app

# 把本仓库的脚本拿过来，--src 指向刚才 checkout 的源码
bash /path/to/spektralab-intel/build-intel.sh \
     --src "$(pwd)" --app /tmp/SpektraLab-x86.app --out ./build
```

脚本会：编 C++ 引擎（25 个 `.cpp`）→ 编 105 个 Swift 文件 → 替换 `Contents/MacOS/SpektraLab` → 删掉旧签名 → ad-hoc 重签。

## 已知问题（Intel 版）

- **命令行渲染产出全黑**：`spektralab cli preview` / `cli export` 生成的是全黑图（JPEG 与 16-bit TIFF 都是），而同一个文件在窗口里显影正常。批量/脚本通路目前不可用，只能在界面里用 ⌘E 导出。
- 首次配一张 80MP 的图在这类机器上要几十秒（`-Onone` 编的 Swift 更慢；引擎本来就是 `-O2`）。改 `-O` 会明显快一些。
- 因为放宽了数学探针，float32 一致性自检被跳过，成片与 Apple 芯片上的结果可能有极微小数值差。

## 许可与署名

代码 GPL-3.0-or-later（见 `LICENSE`）；胶片与相纸配置、放大 LUT 由 Andrea Volpato 以 CC BY-SA 4.0 提供；metal-cpp 为 Apache-2.0。

署名链：**Andrea Volpato**（[spektrafilm](https://github.com/andreavolpato/spektrafilm)，胶片过程模型与 28 款实测配置）→ **JamesQiu2005**（SpektraLab，C++/Metal 移植与应用）→ 本仓库（仅 Intel 构建补丁）。

**关于名字与图标**：`SpektraLab™` 名称与图标由广州松子智能科技服务有限公司管理。本仓库**不发布任何构建产物**，只提供补丁与脚本，供你为自己编一份自用版本（原作者明确允许个人 fork 保留名称与图标）。如果你要**对外分发**编出来的 App，请换成你自己的名称与图标——这是原作者的明确要求。

## English

Unofficial patch that makes [SpektraLab](https://github.com/JamesQiu2005/SpektraLab) build and run on **Intel (x86_64) Macs**. The official DMG is arm64-only. Four source-level assumptions about Apple silicon are patched (see table above); everything else builds unchanged with Command Line Tools only. **No binaries are published here** — build your own copy. Not affiliated with the upstream author.
