# MODIFICATIONS

本仓库的补丁基于 [JamesQiu2005/SpektraLab](https://github.com/JamesQiu2005/SpektraLab) 的 `02d82b5`（1.3.5）。
按 GPL-3.0 第 5(a) 条，以下逐文件列出改动与用途。日期：2026-11-06。

## engine/src/gpu/metal_gpu.cpp
引擎启动时的数学一致性探针：`a*b - a*b` 在 safe math 下应为 fma 误差项（非零），在 fast math 下恰为 0。
实测在 AMD（Radeon Pro 5500M）上即使 metallib 用 safe math 编译也返回全 0，引擎据此拒绝渲染。
改动：把该分支从 `return false`（硬失败）改为 `return true`（继续渲染，注释说明原因）。
影响：跳过 float32 逐位一致性自检；成片与 Apple GPU 结果可能有极微小数值差。

## modern_UI/Spektrafilm/Spektrafilm/Canvas/CineonLUT.swift
`Float16` 在 macOS x86_64 上不可用（仅 arm64 提供），`rgba.map { Float16($0) }` 无法编译。
改动：改用 Accelerate 的 `vImageConvert_PlanarFtoPlanar16F` 批量转换，输出仍是 `rgba16Float` 的位布局；新增 `import Accelerate`。

## modern_UI/Spektrafilm/Spektrafilm/Diagnostics/DiagnosticBundle.swift
`dosStamp` 里一个 `<<`、`|`、`??` 混合的表达式让 Swift 类型检查器报「unable to type-check this expression in reasonable time」。
改动：把时/分/秒、年/月/日分别声明为 `UInt16` 局部变量再组合，语义不变。

## modern_UI/Spektrafilm/Spektrafilm/Model/Session.swift
`maskHandleDragged` 里 `dx * cos(a) + dy * sin(a)` 混用 `CGFloat` 与 `Double`，在 `CGFloat`↔`Double` 隐式转换下产生重载歧义。
改动：先把 `dx`/`dy` 显式转成 `Double` 再做三角运算，结果再参与原来的赋值，数值语义不变。

## modern_UI/Spektrafilm/Spektrafilm/Canvas/MaskOverlay.swift
`MaskGeometry.point(on:at:scale:imageSize:)` 同类混用导致 `cos`/`sin` 歧义。
改动：把半径与 `scale` 转成 `Double` 计算，返回 `CGPoint` 前再转回 `CGFloat`；数值语义不变。

## modern_UI/Spektrafilm/Spektrafilm/Panels/Sections/FilmEdgeSection.swift
`FormatGlyph` 里 `min(1, 0.35 + gate.long / 120)` 让 `along`（进而 `w`）类型不定，`(size.width - w) / 2` 报「ambiguous use of operator /」。
改动：`min(1.0, …)` 明确用 Double，`let w: CGFloat = size.width * CGFloat(along)` 固定类型；片孔坐标拆成 `step` 与 `x` 两行。渲染结果不变。

## modern_UI/Spektrafilm/Spektrafilm/Model/Geometry.swift
`CropHandle` 命中测试里把 `(handle, rank)` 赋给 `(handle: CropHandle, rank: Double)`，`rank` 是 `CGFloat`，隐式转换后仍不匹配。
改动：`let rank = Double(...)`，赋值处写全标签 `(handle: handle, rank: rank)`。
