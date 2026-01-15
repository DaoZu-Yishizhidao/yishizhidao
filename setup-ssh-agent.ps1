# setup-ssh-agent.ps1
Write-Host "🔑 配置SSH免密登录" -ForegroundColor Cyan
Write-Host "═" * 40 -ForegroundColor DarkGray

# 方法1: 尝试通过服务启动
try {
    Write-Host "尝试通过服务启动 ssh-agent..." -ForegroundColor Yellow
    Set-Service ssh-agent -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service ssh-agent -ErrorAction Stop
    Write-Host "✅ 服务方式启动成功" -ForegroundColor Green
} catch {
    Write-Host "⚠️  服务方式失败，尝试进程方式..." -ForegroundColor Yellow
    
    # 方法2: 进程方式
    try {
        # 查找或启动ssh-agent进程
        $agentProcess = Get-Process ssh-agent -ErrorAction SilentlyContinue
        if (-not $agentProcess) {
            $agentProcess = Start-Process ssh-agent -WindowStyle Hidden -PassThru
            Start-Sleep -Seconds 2
        }
        
        # 设置环境变量
        $env:SSH_AUTH_SOCK = "$env:TEMP\ssh-agent.sock"
        
        Write-Host "✅ 进程方式启动成功 (PID: $($agentProcess.Id))" -ForegroundColor Green
    } catch {
        Write-Host "❌ 两种方式都失败了" -ForegroundColor Red
        exit 1
    }
}

# 添加SSH密钥
Write-Host "`n🔐 添加SSH密钥..." -ForegroundColor Yellow
try {
    ssh-add ~/.ssh/id_ed25519
    Write-Host "✅ SSH密钥已添加到代理" -ForegroundColor Green
} catch {
    Write-Host "⚠️  添加密钥失败，可能需要手动输入密码" -ForegroundColor Yellow
    ssh-add ~/.ssh/id_ed25519  # 再试一次，这次会显示输入提示
}

# 测试连接
Write-Host "`n🔗 测试GitHub连接..." -ForegroundColor Yellow
ssh -T git@github.com

Write-Host "`n💡 配置完成！" -ForegroundColor Green
Write-Host "现在尝试运行: .\upload.ps1" -ForegroundColor White