# Git和Hexo状态检查
Write-Host "🔍 《意识之道》博客状态检查" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor DarkGray

Write-Host "
🌿 Git状态：" -ForegroundColor Yellow
git status

Write-Host "
🌐 远程连接：" -ForegroundColor Yellow
git remote -v

Write-Host "
📝 最近提交：" -ForegroundColor Yellow
git log --oneline -5

Write-Host "
📦 Hexo信息：" -ForegroundColor Yellow
hexo version

Write-Host "
📊 文章统计：" -ForegroundColor Yellow
\ = (Get-ChildItem "source/_posts" -Filter "*.md" | Measure-Object).Count
Write-Host "已创建文章: \ 篇" -ForegroundColor White
