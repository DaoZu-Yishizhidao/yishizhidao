# ====================================================
# Git 全局配置增强脚本
# 版本: 2.0
# 作者: 《意识之道》技术团队
# 描述: 为Windows开发者配置现代化、高效的Git环境
# ====================================================

# 脚本元信息
$ScriptName = "Git全局配置增强脚本"
$Version = "2.0"
$Author = "DaoZu (@yishizhidao.cn)"

# 彩色输出函数
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Text,
        [Parameter(Mandatory=$false)]
        [string]$Color = "White",
        [Parameter(Mandatory=$false)]
        [string]$Symbol = "•"
    )
    Write-Host "$Symbol " -NoNewline -ForegroundColor $Color
    Write-Host $Text -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput -Text $Message -Color "Green" -Symbol "✓"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput -Text $Message -Color "Cyan" -Symbol "ℹ"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput -Text $Message -Color "Yellow" -Symbol "⚠"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput -Text $Message -Color "Red" -Symbol "✗"
}

function Write-Step {
    param([int]$Step, [int]$Total, [string]$Message)
    $percentage = [math]::Round(($Step/$Total)*100, 0)
    Write-Host "`n[$Step/$Total | ${percentage}%] " -NoNewline -ForegroundColor Magenta
    Write-Host "$Message" -ForegroundColor White
    Write-Host ("─" * 60) -ForegroundColor DarkGray
}

# 艺术字横幅
function Show-Banner {
    Clear-Host
    Write-Host @"

  ╔══════════════════════════════════════════════════════════╗
  ║                                                          ║
  ║   ██████╗ ██╗████████╗ ██████╗ ██╗   ██╗██████╗         ║
  ║   ██╔════╝ ██║╚══██╔══╝██╔═══██╗██║   ██║██╔══██╗        ║
  ║   ██║  ███╗██║   ██║   ██║   ██║██║   ██║██████╔╝        ║
  ║   ██║   ██║██║   ██║   ██║   ██║██║   ██║██╔══██╗        ║
  ║   ╚██████╔╝██║   ██║   ╚██████╔╝╚██████╔╝██████╔╝        ║
  ║    ╚═════╝ ╚═╝   ╚═╝    ╚═════╝  ╚═════╝ ╚═════╝         ║
  ║                                                          ║
  ║         全局配置增强工具 v$Version - 现代化Git工作流           ║
  ║                                                          ║
  ╚══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan
}

# 检查前置条件
function Test-Prerequisites {
    Write-Step -Step 1 -Total 12 -Message "检查系统环境"
    
    # 检查PowerShell版本
    $psVersion = $PSVersionTable.PSVersion.Major
    if ($psVersion -lt 5) {
        Write-Error "需要PowerShell 5.0或更高版本 (当前: v$psVersion)"
        return $false
    }
    Write-Success "PowerShell版本: v$psVersion"
    
    # 检查Git是否安装
    try {
        $gitVersion = (git --version 2>$null).Split()[2]
        if (-not $gitVersion) {
            Write-Error "Git未安装或不在PATH中"
            Write-Info "请从 https://git-scm.com/download/win 下载安装"
            return $false
        }
        Write-Success "Git版本: $gitVersion"
    } catch {
        Write-Error "无法检测Git版本: $_"
        return $false
    }
    
    # 检查管理员权限
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Warning "未以管理员身份运行，某些功能可能受限"
    } else {
        Write-Success "管理员权限: 已获取"
    }
    
    return $true
}

# 配置用户信息
function Set-GitUserInfo {
    Write-Step -Step 2 -Total 12 -Message "配置用户身份信息"
    
    # 尝试从现有配置获取
    $currentName = git config --global user.name
    $currentEmail = git config --global user.email
    
    if ($currentName -and $currentEmail) {
        Write-Info "当前配置: $currentName <$currentEmail>"
        $choice = Read-Host "是否更新? (y/N)"
        if ($choice -notmatch '^[Yy]') {
            Write-Success "保持现有用户配置"
            return @{name=$currentName; email=$currentEmail}
        }
    }
    
    # 获取新配置
    Write-Host "`n请设置Git全局用户信息:" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────" -ForegroundColor DarkGray
    
    $defaultName = "DaoZu"
    $defaultEmail = "dao@yishizhidao.cn"
    
    $name = Read-Host "用户名 [$defaultName]"
    if ([string]::IsNullOrWhiteSpace($name)) { $name = $defaultName }
    
    $email = Read-Host "邮箱 [$defaultEmail]"
    if ([string]::IsNullOrWhiteSpace($email)) { $email = $defaultEmail }
    
    # 设置配置
    git config --global user.name "$name"
    git config --global user.email "$email"
    
    Write-Success "用户信息已设置: $name <$email>"
    return @{name=$name; email=$email}
}

# 配置核心设置
function Set-GitCoreSettings {
    Write-Step -Step 3 -Total 12 -Message "配置核心Git设置"
    
    # 默认分支名 (现代化)
    git config --global init.defaultBranch main
    Write-Success "默认初始分支: main"
    
    # 行尾处理 (跨平台协作关键)
    git config --global core.autocrlf input  # 提交时转换为LF，检出时不转换
    git config --global core.safecrlf warn   # 提交混合行尾时警告
    Write-Success "行尾标准化: autocrlf=input, safecrlf=warn"
    
    # 长路径支持 (Windows专用)
    git config --global core.longpaths true
    Write-Success "长路径支持: 已启用"
    
    # 文件系统缓存 (性能优化)
    git config --global core.fscache true
    git config --global core.preloadindex true
    Write-Success "文件系统缓存: 已优化"
    
    # 非ASCII路径支持
    git config --global core.quotePath false
    Write-Success "非ASCII路径支持: 已优化"
    
    # 压缩级别
    git config --global core.compression 9
    Write-Success "压缩级别: 9 (最高)"
}

# 配置凭证管理
function Set-GitCredentialManager {
    Write-Step -Step 4 -Total 12 -Message "配置凭证管理"
    
    # 检测当前凭证助手
    $currentHelper = git config --global credential.helper
    if ($currentHelper) {
        Write-Info "当前凭证助手: $currentHelper"
    }
    
    # Windows: 使用最新凭证管理器
    git config --global credential.helper manager-core
    Write-Success "凭证管理器: Windows Credential Manager Core"
    
    # 配置超时时间
    git config --global credential.helper 'manager-core --timeout=3600'
    Write-Success "凭证缓存超时: 3600秒"
    
    # 安全性配置
    git config --global credential.validate true
    Write-Success "凭证验证: 已启用"
}

# 配置推送和拉取行为
function Set-GitPushPullSettings {
    Write-Step -Step 5 -Total 12 -Message "配置推送与拉取行为"
    
    # 推送配置
    git config --global push.default current
    git config --global push.autoSetupRemote true
    Write-Success "推送配置: 当前分支, 自动设置远程跟踪"
    
    # 拉取配置 (推荐变基方式)
    git config --global pull.rebase merges
    git config --global rebase.autoStash true
    Write-Success "拉取配置: rebase=merges, 自动储藏更改"
    
    # 并行获取 (性能优化)
    git config --global fetch.parallel 4
    Write-Success "并行获取线程数: 4"
    
    # 修剪过时的远程分支
    git config --global fetch.prune true
    Write-Success "获取时自动修剪: 已启用"
}

# 配置颜色主题
function Set-GitColorTheme {
    Write-Step -Step 6 -Total 12 -Message "配置颜色与主题"
    
    # 基础颜色配置
    git config --global color.ui auto
    Write-Success "颜色UI: auto"
    
    # 各组件颜色
    git config --global color.status auto
    git config --global color.branch auto
    git config --global color.diff auto
    git config --global color.interactive auto
    git config --global color.grep auto
    Write-Success "所有Git组件颜色: 已启用"
    
    # 状态颜色定制
    git config --global color.status.added "green bold"
    git config --global color.status.changed "yellow bold"
    git config --global color.status.untracked "red bold"
    Write-Success "状态颜色: 已定制"
    
    # 分支颜色定制
    git config --global color.branch.current "green reverse"
    git config --global color.branch.local "green"
    git config --global color.branch.remote "yellow"
    Write-Success "分支颜色: 已定制"
}

# 配置高效别名
function Set-GitAliases {
    Write-Step -Step 7 -Total 12 -Message "配置高效Git别名"
    
    # 基础别名 (与原脚本兼容)
    $baseAliases = @{
        # 常用命令简写
        "co" = "checkout"
        "br" = "branch"
        "ci" = "commit"
        "st" = "status"
        "df" = "diff"
        "lg" = "log --graph --pretty=format:'%C(bold yellow)%h%C(reset) -%C(bold red)%d%C(reset) %s %C(bold green)(%cr) %C(bold blue)<%an>%C(reset)' --abbrev-commit"
        "lga" = "log --graph --all --pretty=format:'%C(bold yellow)%h%C(reset) -%C(bold red)%d%C(reset) %s %C(bold green)(%cr) %C(bold blue)<%an>%C(reset)' --abbrev-commit"
        
        # 撤销操作
        "unstage" = "restore --staged --"
        "uncommit" = "reset --soft HEAD~1"
        "undo" = "!git reset HEAD~1 --mixed"
        
        # 提交相关
        "amend" = "commit --amend --no-edit"
        "amend!" = "commit --amend"
        
        # 推送拉取
        "ps" = "push"
        "pl" = "pull"
        "plr" = "pull --rebase"
        
        # 分支操作
        "nb" = "!git checkout -b"
        "bclean" = "!git branch --merged main | Where-Object { $_ -notmatch '^\*|main' } | ForEach-Object { git branch -d $_ }"
    }
    
    # 高级别名
    $advancedAliases = @{
        # 工作流快捷方式
        "save" = "!git add -A && git commit -m"
        "wip" = "!git add -A && git commit -m 'WIP: $(date)'"
        "done" = "!git add -A && git commit -m 'DONE: $(date)'"
        
        # 查看历史
        "hist" = "log --pretty=format:'%C(yellow)%h %C(blue)%ad %C(green)%an%C(reset)%n%s%n' --date=short --all"
        "filelog" = "log -u"
        "ls" = "log --pretty=format:'%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]' --decorate"
        
        # 差异查看
        "dc" = "diff --cached"
        "dw" = "diff --word-diff"
        "dr" = "diff @~..@"
        
        # 统计信息
        "stats" = "shortlog -sn --no-merges"
        "count" = "rev-list --count HEAD"
        
        # 清理操作
        "clean-branches" = "!git branch --merged | grep -v '\*' | grep -v 'main' | xargs -n 1 git branch -d"
        "sweep" = "!git fetch --prune && git branch -vv | grep ': gone]' | awk '{print \$1}' | xargs git branch -d"
        
        # 子模块
        "sup" = "submodule update --init --recursive"
        "spr" = "!git pull --recurse-submodules && git submodule update --init --recursive"
        
        # Hexo博客专用
        "blog-deploy" = "!hexo clean && hexo generate --deploy"
        "blog-update" = "!git add . && git commit -m 'Blog update: $(date)' && git push origin main"
    }
    
    # 设置别名
    $allAliases = $baseAliases + $advancedAliases
    $aliasCount = 0
    
    foreach ($alias in $allAliases.Keys) {
        git config --global "alias.$alias" $allAliases[$alias]
        $aliasCount++
    }
    
    Write-Success "已配置 $aliasCount 个别名"
    Write-Info "查看所有别名: git alias-list (已自动添加)"
    
    # 添加别名查看命令
    git config --global "alias.alias-list" "!git config --global --list | findstr alias"
}

# 配置全局忽略文件
function Set-GlobalGitignore {
    Write-Step -Step 8 -Total 12 -Message "配置全局.gitignore文件"
    
    $gitignorePath = "$env:USERPROFILE\.gitignore_global"
    
    # 检查文件是否存在
    if (Test-Path $gitignorePath) {
        $backupPath = "$gitignorePath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $gitignorePath $backupPath -Force
        Write-Info "已备份现有文件: $backupPath"
    }
    
    # 创建全局忽略文件内容
    $gitignoreContent = @"
# ============================================
# 全局 Git 忽略规则
# 适用于所有 Git 仓库
# ============================================

# ---------- 操作系统文件 ----------
.DS_Store
Thumbs.db
desktop.ini
*.lnk

# ---------- 编辑器/IDE文件 ----------
# VS Code
.vscode/
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json

# IntelliJ IDEA
.idea/
*.iml
*.iws
*.ipr

# Vim/Neovim
*.swp
*.swo
*~
[._]*.s[a-w][a-z]
[._]s[a-w][a-z]
*.un~
Session.vim
.netrwhist

# ---------- 运行时/依赖文件 ----------
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.pnpm-debug.log*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/

# ---------- 环境变量文件 ----------
.env
.env.local
.env.*.local

# ---------- 日志文件 ----------
*.log
logs/

# ---------- 构建输出 ----------
dist/
build/
.out/
.next/
.nuxt/
.output/

# ---------- 包管理器 ----------
package-lock.json
yarn.lock
pnpm-lock.yaml

# ---------- 操作系统临时文件 ----------
*.tmp
*.temp
*.cache
.cache/

# ---------- 测试覆盖率 ----------
coverage/
.nyc_output/

# ---------- 杂项 ----------
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
"@

    # 写入文件
    $gitignoreContent | Out-File -FilePath $gitignorePath -Encoding UTF8
    git config --global core.excludesfile $gitignorePath
    
    Write-Success "全局.gitignore文件已创建: $gitignorePath"
    Write-Info "包含 $(($gitignoreContent -split "`n").Count) 条忽略规则"
}

# 配置提交信息模板
function Set-CommitTemplate {
    Write-Step -Step 9 -Total 12 -Message "配置提交信息模板"
    
    $templatePath = "$env:USERPROFILE\.gittemplate.txt"
    
    $templateContent = @"
# ============================================
# Git 提交信息模板
# 请遵循 Conventional Commits 规范
# ============================================

# <类型>[可选 范围]: <简短描述>
# 
# [详细描述，说明更改的原因和方式]
# 
# [可选脚注，如关联的问题编号]
# 
# --------------------------------
# 类型说明:
#   feat:     新功能
#   fix:      修复Bug
#   docs:     文档更新
#   style:    代码格式调整，不影响功能
#   refactor: 代码重构，不添加功能也不修复Bug
#   perf:     性能优化
#   test:     测试相关
#   chore:    构建过程或辅助工具的变动
#   ci:       CI/CD配置变更
#   revert:   回滚提交
# 
# 范围说明:
#   可选的模块或文件范围，如: feat(blog): 
# 
# 示例:
#   feat(blog): 添加文章评论功能
#   fix(auth): 修复登录状态丢失问题
#   docs: 更新API使用文档
# 
# ============================================

# 请在上方输入提交信息，删除所有注释行
"@

    $templateContent | Out-File -FilePath $templatePath -Encoding UTF8
    git config --global commit.template $templatePath
    
    # 配置提交信息编辑器（可选）
    git config --global core.editor "code --wait"
    
    Write-Success "提交模板已创建: $templatePath"
    Write-Info "提交时使用: git commit 或 git ci"
}

# 配置差异和合并工具
function Set-DiffMergeTools {
    Write-Step -Step 10 -Total 12 -Message "配置差异与合并工具"
    
    # 检查VSCode是否安装
    $vscodePath = "code"
    try {
        $null = Get-Command $vscodePath -ErrorAction Stop
        $vscodeAvailable = $true
    } catch {
        $vscodeAvailable = $false
    }
    
    if ($vscodeAvailable) {
        # 配置VSCode作为差异工具
        git config --global diff.tool vscode
        git config --global difftool.vscode.cmd "code --wait --diff `$LOCAL `$REMOTE"
        
        # 配置VSCode作为合并工具
        git config --global merge.tool vscode
        git config --global mergetool.vscode.cmd "code --wait `$MERGED"
        
        Write-Success "差异/合并工具: Visual Studio Code"
        Write-Info "使用: git difftool / git mergetool"
    } else {
        Write-Warning "未找到VSCode，跳过差异工具配置"
        Write-Info "可手动配置: git config --global diff.tool [toolname]"
    }
    
    # 配置差异显示方式
    git config --global diff.algorithm histogram
    git config --global diff.indentHeuristic true
    git config --global diff.renameLimit 999999
    
    Write-Success "差异算法: histogram (改进的差异检测)"
}

# 配置Git钩子模板
function Set-GitHooksTemplate {
    Write-Step -Step 11 -Total 12 -Message "配置Git钩子模板"
    
    $hooksTemplateDir = "$env:USERPROFILE\.git-hooks-template"
    
    # 创建目录
    if (-not (Test-Path $hooksTemplateDir)) {
        New-Item -ItemType Directory -Path $hooksTemplateDir -Force | Out-Null
    }
    
    # 设置模板目录
    git config --global init.templatedir $hooksTemplateDir
    
    # 创建示例钩子
    $preCommitHook = @"
#!/bin/sh
# Git预提交钩子示例
# 检查代码风格和测试

echo "🔍 运行预提交检查..."

# 运行测试
# npm test

# 检查代码风格
# npm run lint

echo "✅ 预提交检查完成"
"@

    $preCommitHook | Out-File -FilePath "$hooksTemplateDir\hooks\pre-commit" -Encoding UTF8
    
    Write-Success "Git钩子模板目录: $hooksTemplateDir"
    Write-Info "新仓库将自动包含这些钩子"
}

# 配置高级特性
function Set-AdvancedFeatures {
    Write-Step -Step 12 -Total 12 -Message "配置高级特性"
    
    # 大文件存储 (Git LFS) 配置
    git config --global filter.lfs.required true
    git config --global filter.lfs.clean "git-lfs clean -- %f"
    git config --global filter.lfs.smudge "git-lfs smudge -- %f"
    git config --global filter.lfs.process "git-lfs filter-process"
    Write-Success "Git LFS配置: 已准备"
    
    # GPG签名配置 (可选)
    $enableSigning = Read-Host "是否启用提交签名? (y/N)"
    if ($enableSigning -match '^[Yy]') {
        git config --global commit.gpgsign true
        git config --global tag.gpgsign true
        Write-Success "提交签名: 已启用"
        Write-Info "请确保已设置GPG密钥: git config --global user.signingkey [YOUR_KEY_ID]"
    }
    
    # 协议优化
    git config --global protocol.version 2
    Write-Success "Git协议版本: 2 (性能优化)"
    
    # 重写配置 (安全)
    git config --global receive.fsckObjects true
    git config --global transfer.fsckObjects true
    Write-Success "对象完整性检查: 已启用"
}

# 验证配置
function Test-GitConfiguration {
    Write-Host "`n🔍 验证Git配置" -ForegroundColor Magenta
    Write-Host ("─" * 60) -ForegroundColor DarkGray
    
    $tests = @(
        @{Name="用户信息"; Command="git config --global user.name"; Expect=".*"},
        @{Name="邮箱地址"; Command="git config --global user.email"; Expect=".*@.*"},
        @{Name="默认分支"; Command="git config --global init.defaultBranch"; Expect="main"},
        @{Name="凭证助手"; Command="git config --global credential.helper"; Expect=".*"},
        @{Name="颜色输出"; Command="git config --global color.ui"; Expect="auto"}
    )
    
    $passed = 0
    foreach ($test in $tests) {
        try {
            $result = Invoke-Expression $test.Command 2>$null
            if ($result -match $test.Expect) {
                Write-Success "$($test.Name): $result"
                $passed++
            } else {
                Write-Warning "$($test.Name): 未正确配置"
            }
        } catch {
            Write-Warning "$($test.Name): 检测失败"
        }
    }
    
    # 测试别名
    try {
        $aliases = git config --global --list | Select-String "alias\." | Measure-Object
        Write-Success "配置别名数: $($aliases.Count)"
        $passed++
    } catch {
        Write-Warning "别名检测失败"
    }
    
    Write-Host "`n📊 配置验证完成: $passed/$($tests.Count+1) 项通过" -ForegroundColor Cyan
}

# 显示配置摘要
function Show-Summary {
    Write-Host "`n📋 Git配置摘要" -ForegroundColor Magenta
    Write-Host ("═" * 70) -ForegroundColor DarkGray
    
    $summary = @{
        "基本信息" = @(
            "用户: $(git config --global user.name)",
            "邮箱: $(git config --global user.email)",
            "默认分支: $(git config --global init.defaultBranch)"
        )
        "核心配置" = @(
            "凭证管理: $(git config --global credential.helper)",
            "行尾处理: $(git config --global core.autocrlf)",
            "长路径支持: $(git config --global core.longpaths)"
        )
        "别名统计" = @(
            "已配置别名: $(git config --global --list | Select-String 'alias\.' | Measure-Object).Count 个"
        )
        "文件配置" = @(
            "全局忽略: $env:USERPROFILE\.gitignore_global",
            "提交模板: $env:USERPROFILE\.gittemplate.txt"
        )
    }
    
    foreach ($category in $summary.Keys) {
        Write-Host "`n$category" -ForegroundColor Yellow
        Write-Host ("─" * 40) -ForegroundColor DarkGray
        foreach ($item in $summary[$category]) {
            Write-Host "  $item" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n🎯 推荐命令" -ForegroundColor Yellow
    Write-Host ("─" * 40) -ForegroundColor DarkGray
    Write-Host "  git st                        查看状态" -ForegroundColor Gray
    Write-Host "  git lg                        图形化日志" -ForegroundColor Gray
    Write-Host "  git save \"消息\"              快速保存更改" -ForegroundColor Gray
    Write-Host "  git bclean                    清理已合并分支" -ForegroundColor Gray
    Write-Host "  git alias-list                查看所有别名" -ForegroundColor Gray
}

# 保存配置文件备份
function Backup-Configuration {
    $backupDir = "$env:USERPROFILE\git-config-backup"
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    # 导出当前配置
    git config --global --list | Out-File "$backupDir\git-config-$timestamp.txt" -Encoding UTF8
    
    # 备份.gitconfig文件
    $gitconfigPath = "$env:USERPROFILE\.gitconfig"
    if (Test-Path $gitconfigPath) {
        Copy-Item $gitconfigPath "$backupDir\.gitconfig-$timestamp.backup" -Force
    }
    
    Write-Info "配置备份已保存到: $backupDir"
}

# 主函数
function Main {
    # 显示横幅
    Show-Banner
    
    Write-Host "脚本信息: $ScriptName v$Version" -ForegroundColor White
    Write-Host "作者: $Author" -ForegroundColor White
    Write-Host ("═" * 70) -ForegroundColor DarkGray
    Write-Host "`n"
    
    # 确认执行
    Write-Warning "此脚本将修改您的Git全局配置"
    $confirm = Read-Host "是否继续? (Y/n)"
    if ($confirm -match '^[Nn]') {
        Write-Info "脚本执行已取消"
        exit 0
    }
    
    # 检查前置条件
    if (-not (Test-Prerequisites)) {
        Write-Error "前置条件检查失败，脚本终止"
        exit 1
    }
    
    # 备份现有配置
    Backup-Configuration
    
    try {
        # 执行配置步骤
        $userInfo = Set-GitUserInfo
        Set-GitCoreSettings
        Set-GitCredentialManager
        Set-GitPushPullSettings
        Set-GitColorTheme
        Set-GitAliases
        Set-GlobalGitignore
        Set-CommitTemplate
        Set-DiffMergeTools
        Set-GitHooksTemplate
        Set-AdvancedFeatures
        
        # 验证配置
        Test-GitConfiguration
        
        # 显示摘要
        Show-Summary
        
        Write-Host "`n🎉 Git全局配置增强完成！" -ForegroundColor Green
        Write-Host ("═" * 70) -ForegroundColor DarkGray
        
        # 最后提示
        Write-Host "`n💡 提示：" -ForegroundColor Cyan
        Write-Host "1. 重启终端使配置生效" -ForegroundColor Gray
        Write-Host "2. 手动编辑配置: git config --global --edit" -ForegroundColor Gray
        Write-Host "3. 查看所有配置: git config --global --list" -ForegroundColor Gray
        Write-Host "4. 备份目录: $env:USERPROFILE\git-config-backup" -ForegroundColor Gray
        
        # 生成快速参考卡片
        Write-Host "`n📖 快速参考卡片已保存到桌面" -ForegroundColor Yellow
        $cheatSheetPath = "$env:USERPROFILE\Desktop\Git-配置参考.md"
        @"
# Git 配置快速参考

## 用户信息
- 姓名: $(git config --global user.name)
- 邮箱: $(git config --global user.email)

## 常用命令别名
- \`git st\` - 查看状态
- \`git lg\` - 图形化日志
- \`git save \"消息\"\` - 快速提交所有更改
- \`git amend\` - 修补上次提交
- \`git unstage\` - 取消暂存文件
- \`git bclean\` - 清理已合并分支

## 重要文件位置
- 全局配置: \`$env:USERPROFILE\.gitconfig\`
- 忽略文件: \`$env:USERPROFILE\.gitignore_global\`
- 提交模板: \`$env:USERPROFILE\.gittemplate.txt\`
- 备份目录: \`$env:USERPROFILE\git-config-backup\`

## 常用工作流
1. \`git nb feature-name\` - 创建新分支
2. \`git save \"feat: 添加新功能\"\` - 提交更改
3. \`git ps\` - 推送到远程
4. \`git plr\` - 变基式拉取更新

配置时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@ | Out-File -FilePath $cheatSheetPath -Encoding UTF8
        
    } catch {
        Write-Error "脚本执行出错: $_"
        Write-Error "错误发生在: $($_.InvocationInfo.ScriptLineNumber)"
        exit 1
    }
}

# 脚本入口点
if ($MyInvocation.InvocationName -ne '.') {
    Main
} else {
    Write-Warning "请使用点号源加载脚本: .\$($MyInvocation.MyCommand.Name)"
}