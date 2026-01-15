# 🚀 上传源代码到GitHub
Write-Host "📤 开始上传..." -ForegroundColor Cyan

# 1. 添加所有更改
git add .

# 2. 提交
$time = Get-Date -Format "HH:mm:ss"
git commit -m "更新: $time"

# 3. 推送
git push origin main

# 4. 完成
Write-Host "✅ 上传完成!" -ForegroundColor Green
Write-Host "仓库: https://github.com/DaoZu-Yishizhidao/yishizhidao" -ForegroundColor Gray
