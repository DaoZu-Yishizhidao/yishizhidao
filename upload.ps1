# ============================================
# 《意识之道》博客 - 智能上传脚本 (增强版)
# 功能：安全地将源代码同步到 GitHub 仓库
# ============================================

Write-Host "🚀 《意识之道》博客 - 源代码同步" -ForegroundColor Cyan
Write-Host "═" * 50 -ForegroundColor DarkGray

# 检查是否在 Git 仓库中
try {
    git rev-parse --git-dir 2>$null | Out-Null
} catch {
    Write-Host "❌ 错误：当前目录不是 Git 仓库！" -ForegroundColor Red
    Write-Host "   请在 Hexo 博客根目录运行此脚本。" -ForegroundColor Yellow
    exit 1
}

# 1. 检查是否有未提交的更改
Write-Host "`n📊 检查工作区状态..." -ForegroundColor Yellow
$status = git status --porcelain

if (-not $status) {
    Write-Host "ℹ️  工作区干净，没有需要提交的更改。" -ForegroundColor Cyan
    $choice = Read-Host "是否继续推送最新提交到远程？(Y/n)"
    if ($choice -match '^[Nn]') {
        Write-Host "⏹️  操作已取消。" -ForegroundColor Gray
        exit 0
    }
} else {
    Write-Host "📝 发现 $(@($status).Count) 个文件变动，准备提交..." -ForegroundColor Green
}

# 2. 添加所有更改
try {
    Write-Host "`n🔄 添加文件到暂存区..." -ForegroundColor Yellow
    git add .
    Write-Host "✅ 文件已添加" -ForegroundColor Green
} catch {
    Write-Host "❌ 添加文件失败: $_" -ForegroundColor Red
    exit 1
}

# 3. 提交更改
try {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMessage = "博客更新: $timestamp"
    
    Write-Host "`n💾 创建提交 [$timestamp]..." -ForegroundColor Yellow
    git commit -m $commitMessage
    
    Write-Host "✅ 提交成功: $commitMessage" -ForegroundColor Green
} catch {
    # 提交可能失败（例如没有实际更改）
    Write-Host "⚠️  提交步骤跳过: $_" -ForegroundColor Yellow
}

# 4. 尝试拉取远程更新（避免冲突）
Write-Host "`n🌐 同步远程更新..." -ForegroundColor Yellow
try {
    git pull origin main --rebase --autostash
    Write-Host "✅ 远程更新已同步" -ForegroundColor Green
} catch {
    Write-Host "⚠️  拉取远程更新失败，可能原因：" -ForegroundColor Yellow
    Write-Host "   - 网络连接问题" -ForegroundColor Gray
    Write-Host "   - 存在需要手动解决的冲突" -ForegroundColor Gray
    Write-Host "   尝试直接推送..." -ForegroundColor Gray
}

# 5. 推送到远程仓库
try {
    Write-Host "`n🚀 推送到 GitHub 仓库..." -ForegroundColor Yellow
    git push origin main
    
    Write-Host "`n🎉 同步完成！" -ForegroundColor Green
    Write-Host "═" * 40 -ForegroundColor DarkGray
    Write-Host "📦 提交哈希: $(git rev-parse --short HEAD)" -ForegroundColor White
    Write-Host "🕐 同步时间: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor White
    Write-Host "🌐 仓库地址: https://github.com/DaoZu-Yishizhidao/yishizhidao" -ForegroundColor White
    
    # 显示最近提交
    Write-Host "`n📄 最近提交记录:" -ForegroundColor Cyan
    git log --oneline -3
} catch {
    Write-Host "`n❌ 推送失败！" -ForegroundColor Red
    Write-Host "═" * 40 -ForegroundColor DarkGray
    Write-Host "错误详情: $_" -ForegroundColor Yellow
    
    Write-Host "`n🔧 建议的解决方案:" -ForegroundColor Cyan
    Write-Host "1. 检查网络连接" -ForegroundColor Gray
    Write-Host "2. 运行: git status 查看当前状态" -ForegroundColor Gray
    Write-Host "3. 如果有冲突，先解决冲突后再运行此脚本" -ForegroundColor Gray
    Write-Host "4. 如需强制推送: git push origin main --force" -ForegroundColor Gray
    
    exit 1
}

# 6. 最终状态检查
Write-Host "`n✅ 所有操作完成！" -ForegroundColor Green
Write-Host "═" * 50 -ForegroundColor DarkGray
Write-Host "💡 提示: 运行 .\view.ps1 查看最新目录结构" -ForegroundColor Cyan