# ====================================================
# Hexo博客一键部署脚本（修正版）
# ====================================================

Write-Host "🚀 《意识之道》博客部署流程" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray

# 检查必要插件
Write-Host "`n🔍 检查部署插件..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules\hexo-deployer-git")) {
    Write-Host "❌ 未找到部署插件，正在安装..." -ForegroundColor Red
    npm install hexo-deployer-git --save
}

# 步骤1: 生成静态文件
Write-Host "`n📦 生成静态文件..." -ForegroundColor Yellow
try {
    hexo clean
    hexo g
    Write-Host "✅ 静态文件生成成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 生成静态文件失败: $_" -ForegroundColor Red
    exit 1
}

# 步骤2: 部署到GitHub Pages
Write-Host "`n🌐 部署到GitHub Pages..." -ForegroundColor Yellow
try {
    hexo d
    Write-Host "✅ GitHub Pages部署完成" -ForegroundColor Green
} catch {
    Write-Host "❌ GitHub Pages部署失败: $_" -ForegroundColor Red
    Write-Host "提示: 请检查_config.yml中的deploy配置" -ForegroundColor Yellow
}

# 步骤3: 备份源代码到GitHub
Write-Host "`n💾 备份源代码到GitHub..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    # 添加所有更改
    git add .
    
    # 检查是否有更改
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        # 有更改，提交并推送
        git commit -m "博客更新: $timestamp"
        git push origin main
        Write-Host "✅ 源代码已备份到GitHub" -ForegroundColor Green
    } else {
        Write-Host "ℹ️  没有需要提交的更改" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️  源代码备份失败: $_" -ForegroundColor Yellow
}

# 步骤4: 显示信息
Write-Host "`n📊 部署完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor DarkGray
Write-Host "博客地址: https://daozu-yishizhidao.github.io/yishizhidao/" -ForegroundColor White
Write-Host "源码仓库: https://github.com/DaoZu-Yishizhidao/yishizhidao" -ForegroundColor White
Write-Host "部署时间: $timestamp" -ForegroundColor White
Write-Host "========================================" -ForegroundColor DarkGray

# 步骤5: 提示GitHub Pages设置
Write-Host "`n💡 提示: 首次部署后需要设置GitHub Pages" -ForegroundColor Yellow
Write-Host "1. 访问: https://github.com/DaoZu-Yishizhidao/yishizhidao/settings/pages" -ForegroundColor Gray
Write-Host "2. 分支选择: 'gh-pages'" -ForegroundColor Gray
Write-Host "3. 目录选择: '/(root)'" -ForegroundColor Gray
