# Hexo极简部署脚本
Write-Host "🚀 快速部署《意识之道》博客" -ForegroundColor Cyan
hexo clean
hexo g
hexo d
Write-Host "✅ 部署完成!" -ForegroundColor Green
