# 📁 查看目录结构
Write-Host "《意识之道》博客项目结构" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor DarkGray

# 核心目录
Write-Host "📁 核心文件夹:" -ForegroundColor Green
Get-ChildItem -Directory | ForEach-Object {
    $count = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "  $($_.Name)/ ($count 个文件)" -ForegroundColor White
}

Write-Host "`n📄 配置文件:" -ForegroundColor Green
Get-ChildItem -File -Filter "*config*" | ForEach-Object {
    Write-Host "  $($_.Name)" -ForegroundColor Gray
}

Write-Host "`n🚀 可用脚本:" -ForegroundColor Green
Get-ChildItem -File -Filter "*.ps1" | ForEach-Object {
    Write-Host "  .\$($_.Name)" -ForegroundColor Yellow
}

Write-Host "`n📊 统计信息:" -ForegroundColor Cyan
$totalFiles = (Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
$totalSize = [math]::Round((Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Sum Length).Sum / 1MB, 2)
Write-Host "  总文件数: $totalFiles 个" -ForegroundColor Gray
Write-Host "  总大小: $totalSize MB" -ForegroundColor Gray
