# ============================================
# 《意识之道》博客 - 智能上传脚本 (SSH优化版)
# 特点：只需一次密码输入，全程复用SSH认证
# ============================================

Write-Host "🚀 《意识之道》博客 - 源代码同步" -ForegroundColor Cyan
Write-Host "═" * 50 -ForegroundColor DarkGray

# 函数：检查并管理SSH代理
function Initialize-SSHAgent {
    Write-Host "`n🔑 初始化SSH认证..." -ForegroundColor Yellow
    
    # 1. 检查是否已有SSH代理在运行
    $agentProcess = Get-Process ssh-agent -ErrorAction SilentlyContinue
    $agentRunning = $false
    
    if ($agentProcess) {
        Write-Host "✅ 检测到SSH代理进程 (PID: $($agentProcess.Id))" -ForegroundColor Green
        $agentRunning = $true
    }
    
    # 2. 检查密钥是否已加载
    $keysLoaded = $false
    try {
        $keyList = ssh-add -l 2>$null
        if ($keyList -and $keyList -notmatch "The agent has no identities") {
            Write-Host "✅ SSH密钥已加载" -ForegroundColor Green
            $keysLoaded = $true
        }
    } catch { }
    
    # 3. 如果密钥未加载，尝试加载
    if (-not $keysLoaded) {
        Write-Host "🔄 准备加载SSH密钥..." -ForegroundColor Yellow
        Write-Host "   请在提示时输入一次SSH密钥密码，后续操作将自动使用。" -ForegroundColor Gray
        
        try {
            # 启动ssh-agent（如果未运行）
            if (-not $agentRunning) {
                Write-Host "   启动SSH代理..." -ForegroundColor Gray
                Start-Process ssh-agent -WindowStyle Hidden
                Start-Sleep -Seconds 2
            }
            
            # 添加SSH密钥（这里会提示输入密码）
            ssh-add ~/.ssh/id_ed25519
            
            # 验证密钥已加载
            $verify = ssh-add -l 2>$null
            if ($verify -and $verify -notmatch "The agent has no identities") {
                Write-Host "✅ SSH密钥加载成功！" -ForegroundColor Green
                $keysLoaded = $true
            } else {
                Write-Host "❌ 密钥加载失败" -ForegroundColor Red
                return $false
            }
        } catch {
            Write-Host "❌ 密钥加载过程出错: $_" -ForegroundColor Red
            return $false
        }
    }
    
    return $keysLoaded
}

# 函数：执行Git命令并处理可能的密码提示
function Invoke-GitCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "`n🔄 $Description..." -ForegroundColor Yellow
    
    try {
        # 执行Git命令
        $output = Invoke-Expression "git $Command" 2>&1
        
        # 检查是否有错误
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 完成" -ForegroundColor Green
            if ($output -and $output -notmatch "^\s*$") {
                # 只显示非空且有意义的输出
                $output | ForEach-Object { 
                    if ($_ -notmatch "Enter passphrase" -and $_ -notmatch "^\s*$") {
                        Write-Host "   $_" -ForegroundColor Gray 
                    }
                }
            }
            return $true
        } else {
            # 检查是否是密码相关错误
            if ($output -match "Enter passphrase" -or $output -match "Permission denied") {
                Write-Host "❌ SSH认证失败，请确保密钥已正确加载" -ForegroundColor Red
            } else {
                Write-Host "❌ Git命令失败: $output" -ForegroundColor Red
            }
            return $false
        }
    } catch {
        Write-Host "❌ 执行出错: $_" -ForegroundColor Red
        return $false
    }
}

# 主流程开始
try {
    # 1. 初始化SSH代理（只需一次密码输入）
    if (-not (Initialize-SSHAgent)) {
        Write-Host "`n⚠️  SSH认证初始化失败，将尝试直接执行（可能需要多次输入密码）" -ForegroundColor Yellow
        Write-Host "   按任意键继续..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    } else {
        Write-Host "✅ SSH认证已准备就绪，后续操作无需再次输入密码" -ForegroundColor Green
    }
    
    # 2. 检查Git状态
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
        $fileCount = @($status).Count
        Write-Host "📝 发现 $fileCount 个文件变动，准备提交..." -ForegroundColor Green
    }
    
    # 3. 添加所有更改
    if (-not (Invoke-GitCommand "add ." "添加文件到暂存区")) {
        exit 1
    }
    
    # 4. 提交更改
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMessage = "博客更新: $timestamp"
    
    if (-not (Invoke-GitCommand "commit -m `"$commitMessage`"" "创建提交 [$timestamp]")) {
        Write-Host "⚠️  提交可能失败或无更改可提交，继续尝试同步..." -ForegroundColor Yellow
    }
    
    # 5. 同步远程更新（使用--rebase避免合并提交）
    Write-Host "`n🌐 同步远程更新..." -ForegroundColor Yellow
    Write-Host "   此步骤将检查远程是否有更新，并自动合并..." -ForegroundColor Gray
    
    $pullSuccess = $true
    try {
        # 先获取远程信息但不合并
        git fetch origin
        
        # 检查是否有远程更新
        $localCommit = git rev-parse HEAD
        $remoteCommit = git rev-parse origin/main
        
        if ($localCommit -ne $remoteCommit) {
            Write-Host "   检测到远程有更新，正在合并..." -ForegroundColor Gray
            if (-not (Invoke-GitCommand "pull origin main --rebase --autostash" "合并远程更新")) {
                Write-Host "⚠️  合并失败，可能存在冲突" -ForegroundColor Yellow
                Write-Host "   跳过合并，尝试直接推送..." -ForegroundColor Gray
                $pullSuccess = $false
            }
        } else {
            Write-Host "✅ 本地已是最新版本" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  同步远程更新时出错: $_" -ForegroundColor Yellow
        Write-Host "   跳过同步，尝试直接推送..." -ForegroundColor Gray
        $pullSuccess = $false
    }
    
    # 6. 推送到远程仓库
    if (-not (Invoke-GitCommand "push origin main" "推送到 GitHub 仓库")) {
        Write-Host "`n❌ 推送失败！" -ForegroundColor Red
        Write-Host "═" * 40 -ForegroundColor DarkGray
        
        Write-Host "🔧 建议的解决方案:" -ForegroundColor Cyan
        Write-Host "1. 检查网络连接" -ForegroundColor Gray
        Write-Host "2. 运行: git status 查看当前状态" -ForegroundColor Gray
        Write-Host "3. 如需强制推送，手动运行: git push origin main --force" -ForegroundColor Gray
        
        exit 1
    }
    
    # 7. 显示成功信息
    Write-Host "`n🎉 同步完成！" -ForegroundColor Green
    Write-Host "═" * 40 -ForegroundColor DarkGray
    Write-Host "📦 提交哈希: $(git rev-parse --short HEAD)" -ForegroundColor White
    Write-Host "📅 提交时间: $timestamp" -ForegroundColor White
    Write-Host "📝 提交信息: $commitMessage" -ForegroundColor White
    Write-Host "🌐 仓库地址: https://github.com/DaoZu-Yishizhidao/yishizhidao" -ForegroundColor White
    
    # 显示最近提交
    Write-Host "`n📄 最近提交记录:" -ForegroundColor Cyan
    git log --oneline -3
    
} catch {
    Write-Host "`n❌ 脚本执行过程中发生错误: $_" -ForegroundColor Red
    exit 1
}

# 8. 最终提示
Write-Host "`n✅ 所有操作完成！" -ForegroundColor Green
Write-Host "═" * 50 -ForegroundColor DarkGray
Write-Host "💡 提示: 运行 .\view.ps1 查看最新目录结构" -ForegroundColor Cyan
Write-Host "🔑 SSH会话保持中，下次运行脚本可能无需输入密码" -ForegroundColor Gray