@echo off
title Blender MCP 安装配置脚本
echo ========================================
echo   Blender MCP 集成安装配置脚本
echo ========================================
echo.

REM 检查 uv 是否安装
echo [1/4] 检查 uv 包管理器...
where uv >nul 2>nul
if %errorlevel% equ 0 (
    echo ✓ uv 已安装
) else (
    echo ✗ uv 未安装，正在安装...
    powershell -Command "irm https://astral.sh/uv/install.ps1 | iex"
    echo ✓ uv 安装完成
)
echo.

REM 安装 blender-mcp 包
echo [2/4] 安装 blender-mcp Python 包...
set Path=%USERPROFILE%\.local\bin;%Path%
uvx blender-mcp --help >nul 2>&1
echo ✓ blender-mcp 包已准备就绪
echo.

REM 配置 TRAE MCP
echo [3/4] 配置 TRAE MCP 服务器...
set MCP_CONFIG=%APPDATA%\TRAE SOLO CN\User\mcp.json
echo 配置文件路径: %MCP_CONFIG%
echo.

REM 检查配置文件是否存在
if exist "%MCP_CONFIG%" (
    echo 找到现有配置文件
    findstr /c:"blender" "%MCP_CONFIG%" >nul
    if %errorlevel% equ 0 (
        echo ✓ Blender MCP 已在配置中
    ) else (
        echo 正在添加 Blender MCP 配置...
        powershell -Command "$config = Get-Content '%MCP_CONFIG%' | ConvertFrom-Json; $blenderServer = @{ command = 'cmd'; args = @('/c', 'set Path=%USERPROFILE%\.local\bin;%Path% && uvx blender-mcp'); env = @{ BLENDER_HOST = 'localhost'; BLENDER_PORT = '9876'; DISABLE_TELEMETRY = 'true' } }; $config.mcpServers | Add-Member -MemberType NoteProperty -Name 'blender' -Value $blenderServer -Force; $config | ConvertTo-Json -Depth 10 | Set-Content '%MCP_CONFIG%' -Encoding UTF8"
        echo ✓ Blender MCP 配置已添加
    )
) else (
    echo 创建新的配置文件...
    mkdir "%APPDATA%\TRAE SOLO CN\User" 2>nul
    copy "%~dp0mcp_config_template.json" "%MCP_CONFIG%"
    echo ✓ 配置文件已创建
)
echo.

REM Blender 插件安装提示
echo [4/4] Blender 插件安装提示
echo.
echo ⚠️  请手动完成以下步骤:
echo.
echo 1. 下载并安装 Blender (https://www.blender.org/download/)
echo 2. 打开 Blender，进入 Edit → Preferences → Add-ons
echo 3. 点击 "Install..."，选择 blender_mcp\blender_mcp_addon.py
echo 4. 勾选 "Interface: Blender MCP" 启用插件
echo 5. 在 3D 视图按 N 键打开侧边栏，切换到 BlenderMCP 标签
echo 6. 点击 "Connect to Claude" 启动服务器
echo.
echo 7. 重启 TRAE 使 MCP 配置生效
echo.
echo ========================================
echo   安装脚本执行完成
echo ========================================
pause
