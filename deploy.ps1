# Hexo博客一键部署脚本
Write-Host "🚀 《意识之道》博客部署流程" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor DarkGray

# 步骤1: 生成静态文件
Write-Host "
📦 生成静态文件..." -ForegroundColor Yellow
hexo clean
hexo g

# 步骤2: 部署到GitHub Pages
Write-Host "
🌐 部署到GitHub Pages..." -ForegroundColor Yellow
hexo d

# 步骤3: 备份源代码
Write-Host "
💾 备份源代码到GitHub..." -ForegroundColor Yellow
\ = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git add .
\ = git status --porcelain
if (\) {
    git commit -m "博客更新: \"
    git push origin main
    Write-Host "✅ 源代码已备份" -ForegroundColor Green
} else {
    Write-Host "ℹ️  没有需要提交的更改" -ForegroundColor Cyan
}

# 步骤4: 显示信息
Write-Host "
📊 部署完成！" -ForegroundColor Green
Write-Host "博客地址: https://daozu-yishizhidao.github.io/yishizhidao/" -ForegroundColor White
Write-Host "部署时间: \" -ForegroundColor White
