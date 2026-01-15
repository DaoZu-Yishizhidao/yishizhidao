# view.ps1 - 增强版
Write-Host "《意识之道》博客 - 项目状态" -ForegroundColor Cyan
Write-Host "═" * 50 -ForegroundColor DarkGray

# 显示 Git 状态
Write-Host "`n🌿 Git 状态:" -ForegroundColor Yellow
git status --short

# 显示最近提交
Write-Host "`n📝 最近提交:" -ForegroundColor Yellow
git log --oneline -5

# 显示文件统计
Write-Host "`n📊 项目统计:" -ForegroundColor Yellow
Write-Host "文章: $(@(Get-ChildItem 'source/_posts/*.md' -ErrorAction SilentlyContinue).Count) 篇" -ForegroundColor White
Write-Host "最后更新: $(git log -1 --format='%cd' --date=format:'%Y-%m-%d %H:%M')" -ForegroundColor White