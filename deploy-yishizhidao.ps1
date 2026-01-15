# deploy-yishizhidao-advanced.ps1
# Hexo + Butterfly 主题专用部署脚本
$ErrorActionPreference = "Stop"

# ================ 配置区 ================
$CONFIG = @{
    # 站点信息
    SiteName    = "《意识之道》思想实验场"
    SiteUrl     = "https://yishizhidao.cn"
    
    # Git配置
    RepoPath    = Get-Location
    Branch      = "main"
    Remote      = "origin"
    
    # 部署配置（根据实际部署方式选择）
    DeployType  = "pages"  # pages: GitHub Pages | server: 服务器 | static: 静态文件
    
    # GitHub Pages配置
    GitHubPagesBranch = "gh-pages"
    GitHubRepo        = "yourusername/yishizhidao"
    
    # 服务器Webhook配置
    WebhookUrl  = "https://yishizhidao.cn/webhook/deploy"
    WebhookSecret = ""  # Webhook密钥（如果有）
    
    # 构建配置
    BuildConfig = "_config.yml"  # 主配置文件
    ThemeConfig = "_config.butterfly.yml"  # 主题配置
    
    # 备份配置
    BackupDir   = "backups"
    KeepBackups = 5
    
    # 性能监控
    EnableMonitoring = $true
    CheckUrls = @(
        "https://yishizhidao.cn",
        "https://yishizhidao.cn/feed.xml",
        "https://yishizhidao.cn/sitemap.xml"
    )
}

# ================ 核心函数 ================
function Write-Header {
    param([string]$Title)
    $emoji = switch -Regex ($Title) {
        "检查|验证" { "🔍" }
        "构建|生成" { "🔨" }
        "部署|发布" { "🚀" }
        "备份|恢复" { "💾" }
        "清理|优化" { "🧹" }
        "完成|成功" { "🎉" }
        "测试|监控" { "🧪" }
        default { "📋" }
    }
    Write-Host "`n" -NoNewline
    Write-Host "="*60 -ForegroundColor Cyan
    Write-Host "  $emoji  $Title" -ForegroundColor Yellow
    Write-Host "="*60 -ForegroundColor Cyan
    Write-Host "`n" -NoNewline
}

function Write-Success {
    param([string]$Message)
    Write-Host "[✓] $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "[✗] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[i] $Message" -ForegroundColor Cyan
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[!] $Message" -ForegroundColor Yellow
}

function Show-Spinner {
    param(
        [string]$Message,
        [scriptblock]$ScriptBlock,
        [int]$Timeout = 60
    )
    
    $frames = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    $job = Start-Job -ScriptBlock $ScriptBlock
    
    Write-Host "$message [" -NoNewline -ForegroundColor Cyan
    
    $startTime = Get-Date
    while ($job.State -eq "Running") {
        $elapsed = (Get-Date) - $startTime
        if ($elapsed.TotalSeconds -gt $Timeout) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Write-Host "]" -NoNewline -ForegroundColor Cyan
            Write-Host " 超时" -ForegroundColor Red
            return $null
        }
        
        $frame = $frames[(Get-Date).Millisecond % $frames.Length]
        Write-Host $frame -NoNewline -ForegroundColor Cyan
        Write-Host -NoNewline "`b"  # 退格
        Start-Sleep -Milliseconds 100
    }
    
    Write-Host "✓]" -NoNewline -ForegroundColor Green
    $result = Receive-Job $job -AutoRemoveJob -Wait
    
    # 检查退出码
    if ($job.ChildJobs[0].ExitCode -ne 0) {
        Write-Host " 失败" -ForegroundColor Red
        throw $result
    }
    
    Write-Host " 完成" -ForegroundColor Green
    return $result
}

# ================ 部署步骤 ================
function Test-Environment {
    Write-Header "环境检查"
    
    $checks = @(
        @{ Name = "Git"; Command = "git --version" },
        @{ Name = "Node.js"; Command = "node --version" },
        @{ Name = "Hexo"; Command = "hexo version" },
        @{ Name = "NPM"; Command = "npm --version" }
    )
    
    foreach ($check in $checks) {
        try {
            $result = Invoke-Expression $check.Command 2>&1
            if ($LASTEXITCODE -eq 0 -or -not $result.ToString().Contains("error")) {
                Write-Success "$($check.Name): $($result | Select-Object -First 1)"
            } else {
                throw $result
            }
        } catch {
            Write-Error "$($check.Name): 未安装或配置错误"
            if ($check.Name -in @("Hexo", "Node.js")) {
                throw "必需环境缺失"
            }
        }
    }
    
    # 检查主题
    if (-not (Test-Path "themes/butterfly")) {
        Write-Warning "Butterfly主题未安装"
        $choice = Read-Host "是否安装Butterfly主题？(y/n)"
        if ($choice -eq 'y') {
            npm install hexo-theme-butterfly --save
            Write-Success "Butterfly主题安装完成"
        }
    }
}

function Backup-BeforeDeploy {
    Write-Header "部署前备份"
    
    $backupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $backupPath = Join-Path $CONFIG.BackupDir $backupName
    
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    $filesToBackup = @(
        "_config.yml",
        "_config.butterfly.yml",
        "source/_data/butterfly.yml",
        "source/css/custom.css",
        "scripts/injects"
    )
    
    $count = 0
    foreach ($file in $filesToBackup) {
        if (Test-Path $file) {
            $dest = Join-Path $backupPath $file
            $parent = Split-Path $dest -Parent
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            
            if (Test-Path $file -PathType Container) {
                Copy-Item -Path $file -Destination $parent -Recurse -Force
            } else {
                Copy-Item -Path $file -Destination $dest -Force
            }
            $count++
        }
    }
    
    # 备份当前构建状态
    if (Test-Path "public") {
        $publicBackup = Join-Path $backupPath "public-snapshot"
        Copy-Item -Path "public" -Destination $publicBackup -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # 生成备份报告
    $backupInfo = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        backupName = $backupName
        filesBackedUp = $count
        gitCommit = if (git rev-parse --short HEAD 2>$null) { git rev-parse --short HEAD } else { "N/A" }
        hexoVersion = (hexo version 2>$null | Select-String "hexo:").ToString().Split(":")[1].Trim()
    } | ConvertTo-Json
    
    $backupInfo | Out-File "$backupPath/backup-info.json" -Encoding UTF8
    
    Write-Success "备份完成: $count 个文件已备份到 $backupPath"
    
    # 清理旧备份
    $backups = Get-ChildItem $CONFIG.BackupDir -Directory | Sort-Object CreationTime -Descending
    if ($backups.Count -gt $CONFIG.KeepBackups) {
        $oldBackups = $backups | Select-Object -Skip $CONFIG.KeepBackups
        $oldBackups | ForEach-Object {
            Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-Info "已清理 $($oldBackups.Count) 个旧备份"
    }
}

function Build-HexoSite {
    Write-Header "构建Hexo网站"
    
    # 1. 清理
    Write-Info "清理旧构建文件..."
    $result = Show-Spinner "执行 hexo clean" {
        hexo clean
    }
    
    # 2. 生成
    Write-Info "生成静态文件..."
    $buildStart = Get-Date
    $result = Show-Spinner "执行 hexo generate" {
        if ($CONFIG.EnableMonitoring) {
            # 启用详细日志
            hexo generate --debug
        } else {
            hexo generate
        }
    }
    $buildTime = (Get-Date) - $buildStart
    
    # 3. 验证构建结果
    Write-Info "验证构建结果..."
    $requiredFiles = @(
        "public/index.html",
        "public/css/style.css",
        "public/js/script.js"
    )
    
    $missingFiles = @()
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Warning "缺少文件: $($missingFiles -join ', ')"
    } else {
        Write-Success "构建验证通过"
    }
    
    # 4. 统计信息
    if (Test-Path "public") {
        $files = Get-ChildItem "public" -Recurse -File
        $totalSize = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 2)
        
        Write-Host "`n📊 构建统计:" -ForegroundColor Cyan
        Write-Host "  文件数量: $($files.Count) 个" -ForegroundColor Gray
        Write-Host "  总大小: $totalSize MB" -ForegroundColor Gray
        Write-Host "  构建时间: $($buildTime.TotalSeconds.ToString('0.0')) 秒" -ForegroundColor Gray
    }
    
    # 5. 检查构建问题
    Write-Info "扫描常见问题..."
    
    # 检查图片加载
    $htmlFiles = Get-ChildItem "public" -Recurse -Filter "*.html"
    foreach ($html in $htmlFiles) {
        $content = Get-Content $html.FullName -Raw
        if ($content -match 'src="(?!https?://|//)') {
            Write-Warning "发现可能错误的图片路径: $($html.Name)"
        }
    }
}

function Deploy-ToGitHubPages {
    Write-Header "部署到 GitHub Pages"
    
    $deployDir = ".deploy_git"
    
    # 1. 准备部署目录
    if (Test-Path $deployDir) {
        Remove-Item $deployDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Info "初始化部署仓库..."
    git init $deployDir
    Set-Location $deployDir
    
    # 2. 配置Git
    git config user.name "GitHub Actions"
    git config user.email "action@github.com"
    git remote add origin "https://github.com/$($CONFIG.GitHubRepo).git"
    
    # 3. 切换分支
    git checkout --orphan $CONFIG.GitHubPagesBranch
    
    # 4. 复制文件
    Set-Location ".."
    Get-ChildItem "public" -Recurse | Copy-Item -Destination "$deployDir/" -Recurse -Force
    Set-Location $deployDir
    
    # 5. 提交
    Write-Info "提交更改..."
    git add -A
    $commitMsg = "Deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $(git log -1 --pretty=format:'%s' 2>$null)"
    git commit -m $commitMsg
    
    # 6. 推送
    Write-Info "推送到 GitHub..."
    $result = Show-Spinner "推送 $($CONFIG.GitHubPagesBranch) 分支" {
        git push -f origin $CONFIG.GitHubPagesBranch 2>&1
    }
    
    Set-Location ".."
    Write-Success "GitHub Pages 部署完成"
    
    # 7. 提供访问链接
    Write-Host "`n🌐 访问链接:" -ForegroundColor Cyan
    $pagesUrl = "https://$($CONFIG.GitHubRepo.Split('/')[0]).github.io/$($CONFIG.GitHubRepo.Split('/')[1])"
    Write-Host "  GitHub Pages: $pagesUrl" -ForegroundColor White
    if ($CONFIG.GitHubRepo -match "\.github\.io$") {
        Write-Host "  自定义域名: $($CONFIG.SiteUrl)" -ForegroundColor White
    }
}

function Trigger-Webhook {
    Write-Header "触发服务器部署"
    
    try {
        $body = @{
            ref = "refs/heads/$($CONFIG.Branch)"
            repository = @{
                name = Split-Path $CONFIG.RepoPath -Leaf
                url = "https://github.com/$($CONFIG.GitHubRepo)"
            }
            commits = @(
                @{
                    id = git rev-parse --short HEAD
                    message = git log -1 --pretty=format:"%s"
                    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                }
            )
        } | ConvertTo-Json
        
        $headers = @{}
        if (-not [string]::IsNullOrEmpty($CONFIG.WebhookSecret)) {
            $signature = [System.Text.Encoding]::UTF8.GetBytes($CONFIG.WebhookSecret)
            $hmac = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList $signature
            $hash = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($body))
            $signature = [Convert]::ToBase64String($hash)
            $headers."X-Hub-Signature-256" = "sha256=$signature"
        }
        
        Write-Info "发送Webhook请求..."
        $response = Invoke-RestMethod -Uri $CONFIG.WebhookUrl -Method Post `
            -Body $body -ContentType "application/json" `
            -Headers $headers -TimeoutSec 10
        
        Write-Success "Webhook触发成功: $($response.message ?? 'OK')"
        
    } catch {
        Write-Warning "Webhook触发失败: $_"
        Write-Info "请手动触发服务器部署"
    }
}

function Test-Deployment {
    Write-Header "部署后测试"
    
    if (-not $CONFIG.EnableMonitoring) {
        Write-Info "监控功能已禁用"
        return
    }
    
    $results = @()
    foreach ($url in $CONFIG.CheckUrls) {
        try {
            Write-Host "测试 $url ..." -NoNewline
            $start = Get-Date
            $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10
            $elapsed = (Get-Date) - $start
            
            if ($response.StatusCode -eq 200) {
                Write-Host " ✓ " -NoNewline -ForegroundColor Green
                Write-Host "$($elapsed.TotalMilliseconds.ToString('0'))ms" -ForegroundColor Gray
                $results += @{ Url = $url; Status = "Success"; Time = $elapsed }
            } else {
                Write-Host " ✗ " -NoNewline -ForegroundColor Red
                Write-Host "HTTP $($response.StatusCode)" -ForegroundColor Red
                $results += @{ Url = $url; Status = "Failed"; Time = $elapsed }
            }
        } catch {
            Write-Host " ✗ " -NoNewline -ForegroundColor Red
            Write-Host "连接失败" -ForegroundColor Red
            $results += @{ Url = $url; Status = "Failed"; Time = $null }
        }
    }
    
    # 生成测试报告
    $successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
    if ($successCount -eq $CONFIG.CheckUrls.Count) {
        Write-Success "所有测试通过！网站运行正常"
    } else {
        Write-Warning "$successCount/$($CONFIG.CheckUrls.Count) 个测试通过"
    }
}

function Show-Summary {
    Write-Header "部署摘要"
    
    $summary = @{
        "站点名称" = $CONFIG.SiteName
        "部署时间" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "部署方式" = $CONFIG.DeployType
        "Git提交" = git rev-parse --short HEAD
        "构建大小" = if (Test-Path "public") { 
            "$([math]::Round((Get-ChildItem "public" -Recurse -File | Measure-Object Length -Sum).Sum / 1MB, 2)) MB" 
        } else { "N/A" }
        "主题版本" = (npm list hexo-theme-butterfly --depth=0 2>$null | Select-String "hexo-theme-butterfly")?.ToString().Split("@")[1] ?? "N/A"
    }
    
    foreach ($item in $summary.GetEnumerator()) {
        Write-Host "  $($item.Key):" -NoNewline -ForegroundColor Cyan
        Write-Host " $($item.Value)" -ForegroundColor White
    }
    
    Write-Host "`n🔗 重要链接:" -ForegroundColor Yellow
    Write-Host "  网站首页: $($CONFIG.SiteUrl)" -ForegroundColor White
    Write-Host "  RSS订阅: $($CONFIG.SiteUrl)/feed.xml" -ForegroundColor Gray
    Write-Host "  站点地图: $($CONFIG.SiteUrl)/sitemap.xml" -ForegroundColor Gray
    
    if ($CONFIG.DeployType -eq "pages") {
        $repoUrl = "https://github.com/$($CONFIG.GitHubRepo)"
        Write-Host "  GitHub仓库: $repoUrl" -ForegroundColor Gray
        Write-Host "  GitHub Pages: $repoUrl/settings/pages" -ForegroundColor Gray
    }
}

function Interactive-Menu {
    :menu while ($true) {
        Write-Host "`n" -NoNewline
        Write-Host "="*50 -ForegroundColor Cyan
        Write-Host "  🎯 《意识之道》部署控制台" -ForegroundColor Yellow
        Write-Host "="*50 -ForegroundColor Cyan
        Write-Host "`n请选择操作:" -ForegroundColor White
        
        $options = @(
            @{ Key = "1"; Text = "🔍 完整部署流程"; Color = "Green" },
            @{ Key = "2"; Text = "🧪 仅构建测试"; Color = "Cyan" },
            @{ Key = "3"; Text = "💾 创建备份"; Color = "Yellow" },
            @{ Key = "4"; Text = "🧹 清理构建缓存"; Color = "Magenta" },
            @{ Key = "5"; Text = "📊 查看站点统计"; Color = "Blue" },
            @{ Key = "6"; Text = "⚙️  修改部署配置"; Color = "Gray" },
            @{ Key = "q"; Text = "🚪 退出"; Color = "Red" }
        )
        
        foreach ($opt in $options) {
            Write-Host "  $($opt.Key). " -NoNewline -ForegroundColor $opt.Color
            Write-Host $opt.Text -ForegroundColor White
        }
        
        Write-Host "`n" -NoNewline
        $choice = Read-Host "请输入选项"
        
        switch ($choice) {
            "1" { 
                Invoke-FullDeployment
                Pause
                continue menu
            }
            "2" { 
                Build-HexoSite
                Pause
                continue menu
            }
            "3" { 
                Backup-BeforeDeploy
                Pause
                continue menu
            }
            "4" { 
                hexo clean
                if (Test-Path ".deploy_git") { Remove-Item ".deploy_git" -Recurse -Force }
                if (Test-Path "db.json") { Remove-Item "db.json" -Force }
                Write-Success "清理完成"
                Pause
                continue menu
            }
            "5" { 
                if (Test-Path "public") {
                    $files = Get-ChildItem "public" -Recurse -File
                    $size = [math]::Round(($files | Measure-Object Length -Sum).Sum / 1MB, 2)
                    
                    $htmlFiles = $files | Where-Object { $_.Extension -eq ".html" }
                    $imageFiles = $files | Where-Object { $_.Extension -match "\.(jpg|png|gif|svg|webp)$" }
                    
                    Write-Host "`n📊 站点统计:" -ForegroundColor Cyan
                    Write-Host "  总文件数: $($files.Count)" -ForegroundColor Gray
                    Write-Host "  总大小: $size MB" -ForegroundColor Gray
                    Write-Host "  HTML页面: $($htmlFiles.Count)" -ForegroundColor Gray
                    Write-Host "  图片文件: $($imageFiles.Count)" -ForegroundColor Gray
                }
                Pause
                continue menu
            }
            "6" { 
                Write-Host "`n当前配置:" -ForegroundColor Yellow
                $CONFIG.GetEnumerator() | Where-Object { $_.Key -notmatch "Secret|Key" } | ForEach-Object {
                    Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Gray
                }
                Pause
                continue menu
            }
            "q" { 
                Write-Host "`n感谢使用！" -ForegroundColor Green
                exit 0
            }
            default {
                Write-Warning "无效选项"
                continue menu
            }
        }
    }
}

function Invoke-FullDeployment {
    try {
        Write-Header "开始完整部署流程"
        
        # 1. 环境检查
        Test-Environment
        
        # 2. 备份
        Backup-BeforeDeploy
        
        # 3. Git提交（如果源码需要部署）
        if ($CONFIG.DeployType -eq "source") {
            Write-Header "提交源码更改"
            git add .
            $commitMsg = Read-Host "输入提交信息（留空使用自动生成）"
            if ([string]::IsNullOrWhiteSpace($commitMsg)) {
                $commitMsg = "更新: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            }
            git commit -m $commitMsg
            git push origin $CONFIG.Branch
            Write-Success "源码提交完成"
        }
        
        # 4. 构建
        Build-HexoSite
        
        # 5. 部署
        switch ($CONFIG.DeployType) {
            "pages" {
                Deploy-ToGitHubPages
            }
            "server" {
                Trigger-Webhook
            }
            "static" {
                Write-Info "静态文件已生成在 public/ 目录"
                Write-Info "请手动上传到您的服务器"
            }
        }
        
        # 6. 测试
        if ($CONFIG.EnableMonitoring) {
            Test-Deployment
        }
        
        # 7. 摘要
        Show-Summary
        
        Write-Success "🎉 部署流程全部完成！"
        
    } catch {
        Write-Error "部署失败: $_"
        Write-Host "`n建议操作:"
        Write-Host "1. 检查错误信息" -ForegroundColor Gray
        Write-Host "2. 运行 'hexo clean && hexo g' 手动构建" -ForegroundColor Gray
        Write-Host "3. 查看 logs/ 目录下的日志文件" -ForegroundColor Gray
        throw
    }
}

# ================ 主程序 ================
try {
    # 显示欢迎信息
    Write-Host "`n"
    Write-Host "  🧠 《意识之道》自动化部署系统" -ForegroundColor Magenta
    Write-Host "  " + ("="*45) -ForegroundColor DarkGray
    Write-Host "  版本: 2.0.0 | 时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host "  目录: $(Get-Location)" -ForegroundColor Gray
    Write-Host "`n" -NoNewline
    
    # 检查是否在Hexo目录中
    if (-not (Test-Path "_config.yml") -or -not (Test-Path "scaffolds")) {
        Write-Warning "当前目录可能不是Hexo项目根目录"
        $confirm = Read-Host "是否继续？(y/n)"
        if ($confirm -ne 'y') {
            exit 0
        }
    }
    
    # 进入交互菜单
    Interactive-Menu
    
} catch {
    Write-Error "脚本执行失败: $_"
    Write-Host "`n按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}