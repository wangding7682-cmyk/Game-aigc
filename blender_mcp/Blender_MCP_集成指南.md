# Blender MCP 集成指南 - 狙击外星人游戏项目

## 一、概述

BlenderMCP 是基于 Model Context Protocol (MCP) 的开源插件系统，将 Blender 与 AI 无缝连接。通过自然语言指令，即可驱动 Blender 完成 3D 建模、材质编辑、场景搭建等工作。

**项目位置**: `blender_mcp/`
**插件版本**: BlenderMCP 1.5.4
**GitHub**: https://github.com/ahujasid/blender-mcp

---

## 二、架构说明

```
┌─────────────┐    MCP协议    ┌──────────────┐   Socket   ┌───────────┐
│   TRAE AI   │ ◄──────────► │  MCP Server  │ ◄───────► │  Blender  │
│  (客户端)   │   stdin/out  │ (blender-mcp) │  TCP:9876 │  (插件)   │
└─────────────┘               └──────────────┘            └───────────┘
```

**两个核心组件**:
1. **MCP 服务器** (`blender-mcp` Python 包) - 实现 MCP 协议，作为 AI 与 Blender 之间的桥梁
2. **Blender 插件** (`addon.py`) - 在 Blender 内部创建 TCP Socket 服务器，接收并执行命令

---

## 三、安装步骤

### 前置条件
- ✅ Python 3.10+ (已安装: 3.12.10)
- ✅ uv 包管理器 (已安装: 0.11.25)
- ✅ blender-mcp Python 包 (已安装: 1.5.4)
- ⬜ Blender 3.0+ (需手动安装)
- ⬜ Blender MCP 插件 (需手动安装)
- ⬜ TRAE MCP 配置 (需手动添加)

### 第一步：安装 Blender

1. 访问 https://www.blender.org/download/
2. 下载最新稳定版 Blender (推荐 4.0+)
3. 运行安装程序，按默认设置安装
4. 记录安装路径，例如：`C:\Program Files\Blender Foundation\Blender 4.x\`

### 第二步：安装 Blender MCP 插件

插件文件已下载至项目根目录：`blender_mcp_addon.py`

1. 启动 Blender
2. 进入菜单：**Edit → Preferences → Add-ons**
3. 点击右上角 **Install...** 按钮
4. 选择项目中的 `blender_mcp_addon.py` 文件
5. 搜索 `Blender MCP`，勾选复选框启用插件
6. 关闭偏好设置窗口

### 第三步：启动 Blender MCP 服务器

1. 在 Blender 中切换到 **3D Viewport** 视图
2. 按 **N 键** 打开右侧侧边栏
3. 切换到 **BlenderMCP** 标签页
4. （可选）勾选 **Poly Haven** 以启用免费素材库
5. 点击 **Connect to Claude** 按钮
6. 状态栏显示 "Connected" 表示服务器已启动

> 💡 默认端口：9876，可通过环境变量 `BLENDER_PORT` 修改

### 第四步：配置 TRAE MCP

#### 方式一：使用一键安装脚本（推荐）

双击运行项目中的 `blender_mcp/install_blender_mcp.bat`，脚本会自动配置。

#### 方式二：手动配置

1. 打开文件：`C:\Users\Admin\AppData\Roaming\TRAE SOLO CN\User\mcp.json`
2. 在 `mcpServers` 对象中添加以下配置：

```json
{
  "mcpServers": {
    "godot": {
      "...": "..."
    },
    "blender": {
      "command": "cmd",
      "args": [
        "/c",
        "set Path=C:\\Users\\Admin\\.local\\bin;%Path% && uvx blender-mcp"
      ],
      "env": {
        "BLENDER_HOST": "localhost",
        "BLENDER_PORT": "9876",
        "DISABLE_TELEMETRY": "true"
      }
    }
  }
}
```

3. 保存文件
4. **重启 TRAE** 使配置生效

### 第五步：验证连接

1. 确保 Blender 已打开且 MCP 服务器已启动
2. 在 TRAE 中新建对话
3. 输入指令：`查看当前 Blender 场景信息`
4. 如果 AI 能返回场景信息（如默认立方体、灯光、相机），说明连接成功

---

## 四、核心功能清单

### 4.1 场景与对象操作
| 功能 | 描述 |
|------|------|
| `get_scene_info` | 获取当前场景完整信息 |
| `get_object_info` | 获取指定对象的详细属性 |
| `list_objects` | 列出场景中所有对象 |
| `create_object` | 创建基础几何体（立方体、球体、圆柱等） |
| `delete_object` | 删除指定对象 |
| `modify_object` | 修改对象的位置、旋转、缩放 |

### 4.2 建模与编辑
| 功能 | 描述 |
|------|------|
| `add_modifier` | 添加修改器（阵列、倒角、细分等） |
| `apply_modifier` | 应用修改器 |
| `edit_mode` | 进入编辑模式进行顶点/边/面操作 |
| `extrude` | 挤出面/边 |
| `bevel` | 倒角操作 |

### 4.3 材质与贴图
| 功能 | 描述 |
|------|------|
| `create_material` | 创建新材质 |
| `set_material_color` | 设置材质基础色 |
| `apply_material` | 将材质应用到对象 |
| `add_texture` | 添加纹理贴图 |
| `adjust_uv` | 调整 UV 映射 |

### 4.4 光照与渲染
| 功能 | 描述 |
|------|------|
| `add_light` | 添加灯光（点光、聚光、日光等） |
| `set_light_properties` | 设置灯光强度、颜色、角度 |
| `setup_camera` | 设置相机位置和视角 |
| `render_image` | 渲染当前场景 |
| `set_render_settings` | 配置渲染参数 |

### 4.5 资产库集成
| 功能 | 描述 |
|------|------|
| Poly Haven | 免费 3D 模型、纹理、HDRI 素材库 |
| Sketchfab | 搜索并下载 Sketchfab 模型 |
| Hyper3D Rodin | AI 生成 3D 模型 |
| Hunyuan3D | 腾讯混元 3D 生成 |

### 4.6 高级功能
| 功能 | 描述 |
|------|------|
| `execute_blender_code` | 执行任意 Blender Python 脚本 |
| `get_viewport_screenshot` | 获取视口截图 |
| `import_model` | 导入外部模型文件 (FBX, OBJ, GLB 等) |
| `export_model` | 导出模型文件 |

---

## 五、游戏项目场景示例

### 示例 1：创建外星人角色模型

**场景**: 为狙击游戏创建一个卡通风格的外星人目标

```
在 Blender 中创建一个卡通风格的外星人角色：
1. 创建一个椭球体作为身体（高约2米，绿色）
2. 添加一个大头，比例约为身体的 1/3
3. 添加两只大眼睛（黑色，有微弱发光）
4. 细长的四肢
5. 整体风格参考卡通外星人设计
6. 设置材质为半透明的绿色皮肤质感
```

### 示例 2：生成掩体和障碍物

**场景**: 快速生成 PVE 关卡中的掩体和障碍物

```
为狙击游戏创建一组掩体对象，用于关卡设计：
1. 创建一个混凝土矮墙（长3m，高1.2m，厚0.4m）
2. 创建一个木箱掩体（1m x 1m x 1m）
3. 创建一个金属油桶（高1.2m，直径0.6m）
4. 创建岩石堆（由3-4个不规则球体组合）
5. 每个对象都添加合适的材质
6. 将所有对象按类型分组排列
7. 导出为 FBX 格式，准备导入 Godot
```

### 示例 3：制作武器模型

**场景**: 创建狙击步枪的 3D 模型

```
创建一把未来风格的狙击步枪模型：
1. 长枪管（圆柱形，长约1.2m）
2. 瞄准镜（安装在枪身顶部，带透镜效果）
3. 枪身主体（棱角分明的科幻风格）
4. 握把和扳机
5. 能量电池（侧面，带蓝色发光效果）
6. 添加金属质感材质，主色调为深灰+蓝色点缀
7. 枪口添加散热片细节
```

### 示例 4：搭建战斗场景

**场景**: 使用 Poly Haven 资产快速搭建沙漠战斗场景

```
搭建一个沙漠狙击战斗场景：
1. 创建一个大型平地作为地面（50m x 50m）
2. 应用沙漠沙地纹理
3. 从 Poly Haven 下载并添加：
   - 几块岩石分布在场景中
   - 几株仙人掌和沙漠植物
   - 一个旧木箱作为掩体
4. 设置夕阳光照效果（暖色调，低角度）
5. 添加沙漠 HDRI 环境贴图
6. 放置相机在狙击位置（高处，俯视角度）
```

### 示例 5：批量生成破坏效果

**场景**: 为掩体创建不同破坏阶段的模型变体

```
为混凝土墙创建5个破坏阶段的模型变体：
1. 阶段1：完好状态
2. 阶段2：表面有裂纹和弹痕
3. 阶段3：一侧有缺口，露出内部钢筋
4. 阶段4：大面积破损，结构不稳定
5. 阶段5：完全坍塌，变成碎块堆
每个阶段都保存为单独的对象，命名为 wall_damage_01 到 wall_damage_05
```

---

## 六、Godot 工作流集成

### 从 Blender 到 Godot 的标准流程

```
Blender 建模 → 导出 GLB/FBX → Godot 导入 → 设置碰撞 → 配置材质
```

### 推荐导出设置

**格式**: glTF 2.0 (.glb) - 推荐，Godot 原生支持最佳

```
使用 AI 指令导出：
"将当前选中的对象导出为 glTF 格式，保存到项目的 assets/models/ 目录下，
包含材质和 UV，不导出灯光和相机"
```

### 命名规范建议

- 角色模型: `chr_<name>.glb` (如 `chr_alien_grunt.glb`)
- 武器模型: `wpn_<name>.glb` (如 `wpn_sniper_rifle.glb`)
- 掩体/环境: `env_<name>.glb` (如 `env_concrete_wall.glb`)
- 道具: `itm_<name>.glb` (如 `itm_ammo_box.glb`)

---

## 七、常见问题排查

### Q1: TRAE 中找不到 Blender MCP 工具

**可能原因**:
- MCP 配置未正确添加
- TRAE 未重启
- uv 路径未配置

**解决方案**:
1. 检查 `mcp.json` 配置是否正确
2. 完全重启 TRAE
3. 确保 `C:\Users\Admin\.local\bin` 在系统 PATH 中
4. 手动测试：在 CMD 中运行 `uvx blender-mcp --help`

### Q2: 连接 Blender 失败

**错误信息**: `Failed to connect to Blender: 由于目标计算机积极拒绝，无法连接`

**可能原因**:
- Blender 未启动
- Blender MCP 插件未启用
- 端口号不匹配

**解决方案**:
1. 打开 Blender
2. 确认已安装并启用 Blender MCP 插件
3. 在 3D 视图按 N 键，找到 BlenderMCP 面板
4. 点击 "Connect to Claude" 按钮
5. 确认端口号为 9876（或与配置一致）

### Q3: 操作执行缓慢或超时

**解决方案**:
1. 将复杂操作拆分为多个小步骤
2. 简化场景，减少对象数量
3. 避免一次操作太多对象
4. 使用低多边形模式进行快速迭代

### Q4: Python 代码执行安全

⚠️ **安全警告**: `execute_blender_code` 工具允许执行任意 Python 代码

**安全建议**:
- 执行代码前保存工作
- 不要运行来源不明的代码
- 重要文件定期备份

---

## 八、高效使用技巧

### 8.1 提示词最佳实践

**清晰明确**: 用简洁的语言描述需求，包含尺寸、位置、颜色等具体参数

**分步执行**: 复杂任务拆分为多个简单步骤，每步确认后再继续

**利用上下文**: 先让 AI 查看当前场景，再基于现有状态进行修改

### 8.2 常用快捷键

| Blender 操作 | 快捷键 |
|-------------|--------|
| 切换编辑模式 | Tab |
| 移动工具 | G |
| 旋转工具 | R |
| 缩放工具 | S |
| 框选 | B |
| 全选 | A |
| 取消选择 | Alt+A |
| 视图最大化选中 | Numpad . |

### 8.3 性能优化建议

1. **建模阶段使用低多边形**，最后再细分平滑
2. **合理使用实例化**，大量重复物体用实例而非复制
3. **定期清理无用数据**，删除未使用的材质和纹理
4. **使用集合 (Collection)** 组织场景对象

---

## 九、文件清单

```
游戏AIGC/
├── blender_mcp/
│   ├── mcp_config_template.json    # TRAE MCP 配置模板
│   └── install_blender_mcp.bat     # 一键安装配置脚本
├── blender_mcp_addon.py            # Blender 插件文件 (v1.5.4)
└── 本文档 (Blender_MCP_集成指南.md)
```

---

## 十、相关链接

- **BlenderMCP GitHub**: https://github.com/ahujasid/blender-mcp
- **Blender 官网**: https://www.blender.org/
- **MCP 协议**: https://modelcontextprotocol.io/
- **Poly Haven 素材库**: https://polyhaven.com/
- **Godot 官方文档**: https://docs.godotengine.org/

---

*最后更新: 2026-06-28*
*版本: BlenderMCP 1.5.4*
