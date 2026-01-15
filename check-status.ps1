# ====================================================
# Git和Hexo状态检查脚本
# ====================================================

Write-Host "🔍 《意识之道》博客状态检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor DarkGray

Write-Host "`n🌿 Git状态：" -ForegroundColor Yellow
git status

Write-Host "`n🌐 远程连接：" -ForegroundColor Yellow
git remote -v

Write-Host "`n📝 最近提交：" -ForegroundColor Yellow
git log --oneline -5

Write-Host "`n📦 Hexo信息：" -ForegroundColor Yellow
hexo version

Write-Host "`n📊 文章统计：" -ForegroundColor Yellow
$postCount = (Get-ChildItem "source/_posts" -Filter "*.md" | Measure-Object).Count
Write-Host "已创建文章: $postCount 篇" -ForegroundColor White

Write-Host "`n🔗 插件检查：" -ForegroundColor Yellow
$deployerInstalled = Test-Path "node_modules\hexo-deployer-git"
if ($deployerInstalled) {
    Write-Host "✅ hexo-deployer-git: 已安装" -ForegroundColor Green
} else {
    Write-Host "❌ hexo-deployer-git: 未安装" -ForegroundColor Red
    Write-Host "   运行: npm install hexo-deployer-git --save" -ForegroundColor Yellow
}

Write-Host "`n✅ 状态检查完成" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor DarkGray
