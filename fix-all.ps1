# ====================================================
# 《意识之道》博客部署问题终极修复脚本
# ====================================================

Write-Host "🔧 博客部署问题修复工具" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray

# 步骤1: 修复脚本文件
Write-Host "`n📝 步骤1: 修复脚本文件..." -ForegroundColor Yellow
$scripts = @("deploy.ps1", "check-status.ps1")
foreach ($script in $scripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        # 修复错误的变量转义
        $fixedContent = $content -replace '\\\$', '$'
        if ($content -ne $fixedContent) {
            $fixedContent | Out-File $script -Encoding UTF8
            Write-Host "✅ 已修复: $script" -ForegroundColor Green
        } else {
            Write-Host "✅ 无需修复: $script" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️  文件不存在: $script" -ForegroundColor Yellow
    }
}

# 步骤2: 安装部署插件
Write-Host "`n📦 步骤2: 检查部署插件..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules\hexo-deployer-git")) {
    Write-Host "正在安装 hexo-deployer-git..." -ForegroundColor Gray
    npm install hexo-deployer-git --save
    Write-Host "✅ hexo-deployer-git 安装完成" -ForegroundColor Green
} else {
    Write-Host "✅ hexo-deployer-git 已安装" -ForegroundColor Green
}

# 步骤3: 修复Git配置
Write-Host "`n🔧 步骤3: 修复Git配置..." -ForegroundColor Yellow
git config --global core.autocrlf true
git config --global core.safecrlf warn
Write-Host "✅ Git行尾配置已修复" -ForegroundColor Green

# 步骤4: 测试修复结果
Write-Host "`n🧪 步骤4: 测试修复结果..." -ForegroundColor Yellow

# 测试脚本语法
Write-Host "`n测试 deploy.ps1 语法..." -ForegroundColor Gray
try {
    $scriptBlock = [ScriptBlock]::Create((Get-Content "deploy.ps1" -Raw))
    Write-Host "✅ deploy.ps1 语法正确" -ForegroundColor Green
} catch {
    Write-Host "❌ deploy.ps1 语法错误: $_" -ForegroundColor Red
}

Write-Host "`n✅ 修复完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "现在可以运行: .\deploy.ps1" -ForegroundColor White
