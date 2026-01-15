# Complete-Git-Setup.ps1
Write-Host "🚀 开始配置《意识之道》博客Git工作流" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor DarkGray

# 1. 检查Git状态
Write-Host "`n📊 当前Git状态：" -ForegroundColor Yellow
git status

# 2. 创建初始提交
Write-Host "`n💾 创建首次提交..." -ForegroundColor Yellow
git add .
git commit -m "初始提交: 重建Hexo+Butterfly博客

🎯 包含功能：
- Hexo v$(hexo version | Select-String -Pattern "\d+\.\d+\.\d+" | ForEach-Object { $_.Matches.Value })
- Butterfly主题
- KaTeX数学公式支持
- 完整的项目结构

📅 提交时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"

Write-Host "✅ 首次提交完成" -ForegroundColor Green

# 3. 连接GitHub远程仓库
Write-Host "`n🌐 连接GitHub远程仓库..." -ForegroundColor Yellow
$remoteUrl = "https://github.com/DaoZu-Yishizhidao/yishizhidao.git"

# 移除可能存在的旧远程配置
git remote remove origin 2>$null

# 添加新的远程仓库
git remote add origin $remoteUrl

# 验证远程仓库
Write-Host "`n🔗 远程仓库配置：" -ForegroundColor Cyan
git remote -v

Write-Host "✅ 远程仓库连接成功" -ForegroundColor Green

# 4. 推送代码到GitHub
Write-Host "`n🚀 推送代码到GitHub..." -ForegroundColor Yellow
Write-Host "仓库地址: $remoteUrl" -ForegroundColor White

# 设置上游分支并推送
try {
    git push -u origin main
    Write-Host "✅ 代码推送成功！" -ForegroundColor Green
} catch {
    Write-Host "❌ 推送失败，尝试强制推送..." -ForegroundColor Red
    $choice = Read-Host "远程仓库可能已有内容。是否强制推送（覆盖远程）？(y/N)"
    
    if ($choice -match '^[Yy]') {
        git push -u origin main --force
        Write-Host "⚠️  已强制推送，远程内容已被覆盖" -ForegroundColor Yellow
    } else {
        Write-Host "❌ 推送已取消" -ForegroundColor Red
        exit 1
    }
}

# 5. 验证推送结果
Write-Host "`n🔍 验证推送结果..." -ForegroundColor Cyan
Write-Host "=" * 40 -ForegroundColor DarkGray

# 检查本地分支信息
Write-Host "`n🌿 本地分支状态：" -ForegroundColor Yellow
git branch -vv

# 检查远程分支信息
Write-Host "`n☁️  远程分支状态：" -ForegroundColor Yellow
git ls-remote --heads origin

# 6. 配置Hexo部署
Write-Host "`n⚙️  配置Hexo部署设置..." -ForegroundColor Yellow

# 备份原有配置
if (Test-Path "_config.yml") {
    Copy-Item "_config.yml" "_config.yml.backup" -Force
}

# 读取并更新部署配置
$configContent = Get-Content "_config.yml" -Raw

# 添加或更新部署配置
if ($configContent -notmatch "deploy:") {
    $configContent += @"

# Deployment
## Docs: https://hexo.io/docs/one-command-deployment
deploy:
  type: git
  repo: https://github.com/DaoZu-Yishizhidao/yishizhidao.git
  branch: gh-pages
  message: "博客更新: {{ now('YYYY-MM-DD HH:mm:ss') }}"
"@
} else {
    # 如果已有部署配置，则更新它
    $configContent = $configContent -replace "(?s)deploy:.*?(?=\n\w+:|$)", @"
deploy:
  type: git
  repo: https://github.com/DaoZu-Yishizhidao/yishizhidao.git
  branch: gh-pages
  message: "博客更新: {{ now('YYYY-MM-DD HH:mm:ss') }}"
"@
}

$configContent | Out-File "_config.yml" -Encoding UTF8

Write-Host "✅ Hexo部署配置已更新" -ForegroundColor Green

# 7. 创建便捷工作流脚本
Write-Host "`n📝 创建工作流脚本..." -ForegroundColor Yellow

# 7.1 一键部署脚本
@"
# Hexo博客一键部署脚本
Write-Host "🚀 《意识之道》博客部署流程" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor DarkGray

# 步骤1: 生成静态文件
Write-Host "`n📦 生成静态文件..." -ForegroundColor Yellow
hexo clean
hexo g

# 步骤2: 部署到GitHub Pages
Write-Host "`n🌐 部署到GitHub Pages..." -ForegroundColor Yellow
hexo d

# 步骤3: 备份源代码
Write-Host "`n💾 备份源代码到GitHub..." -ForegroundColor Yellow
\$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git add .
\$status = git status --porcelain
if (\$status) {
    git commit -m "博客更新: \$timestamp"
    git push origin main
    Write-Host "✅ 源代码已备份" -ForegroundColor Green
} else {
    Write-Host "ℹ️  没有需要提交的更改" -ForegroundColor Cyan
}

# 步骤4: 显示信息
Write-Host "`n📊 部署完成！" -ForegroundColor Green
Write-Host "博客地址: https://daozu-yishizhidao.github.io/yishizhidao/" -ForegroundColor White
Write-Host "部署时间: \$timestamp" -ForegroundColor White
"@ | Out-File -FilePath "deploy.ps1" -Encoding UTF8

# 7.2 快速检查脚本
@"
# Git和Hexo状态检查
Write-Host "🔍 《意识之道》博客状态检查" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor DarkGray

Write-Host "`n🌿 Git状态：" -ForegroundColor Yellow
git status

Write-Host "`n🌐 远程连接：" -ForegroundColor Yellow
git remote -v

Write-Host "`n📝 最近提交：" -ForegroundColor Yellow
git log --oneline -5

Write-Host "`n📦 Hexo信息：" -ForegroundColor Yellow
hexo version

Write-Host "`n📊 文章统计：" -ForegroundColor Yellow
\$postCount = (Get-ChildItem "source/_posts" -Filter "*.md" | Measure-Object).Count
Write-Host "已创建文章: \$postCount 篇" -ForegroundColor White
"@ | Out-File -FilePath "check-status.ps1" -Encoding UTF8

Write-Host "✅ 工作流脚本创建完成" -ForegroundColor Green

# 8. 更新.gitignore（如果需要）
Write-Host "`n📁 更新.gitignore文件..." -ForegroundColor Yellow

$gitignoreContent = @"
# Hexo生成文件
public/
.deploy_git/
db.json

# 依赖目录
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# 备份文件
backups/
*.backup

# 编辑器文件
.vscode/
.idea/
*.swp
*.swo

# 环境变量
.env
.env.local

# 操作系统文件
.DS_Store
Thumbs.db
desktop.ini

# Butterfly主题缓存
.sass-cache/
*.css.map
"@

$gitignoreContent | Out-File ".gitignore" -Encoding UTF8

# 重新提交.gitignore
git add .gitignore
git commit -m "更新: 完善.gitignore配置" 2>$null

# 9. 显示完成信息
Write-Host "`n🎉 《意识之道》博客Git工作流配置完成！" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor DarkGray

@"

📋 配置摘要：
✅ Git仓库已初始化并提交
✅ 远程仓库已连接: https://github.com/DaoZu-Yishizhidao/yishizhidao
✅ Hexo部署配置已更新
✅ 工作流脚本已创建

🚀 可用命令：
1. 生成并部署: .\deploy.ps1
2. 状态检查: .\check-status.ps1
3. 创建新文章: hexo new post "标题"
4. 本地预览: hexo s
5. Git推送: git push

🔗 重要链接：
博客地址: https://daozu-yishizhidao.github.io/yishizhidao/
源码仓库: https://github.com/DaoZu-Yishizhidao/yishizhidao
GitHub Pages设置: https://github.com/DaoZu-Yishizhidao/yishizhidao/settings/pages

💡 下一步操作：
1. 在GitHub仓库设置中启用GitHub Pages（选择gh-pages分支）
2. 创建第一篇测试文章: hexo new post "数学公式测试"
3. 运行 .\deploy.ps1 部署到GitHub

🕐 完成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@ | Write-Host -ForegroundColor White

# 10. 可选：立即测试部署
$testDeploy = Read-Host "`n是否立即测试部署？(Y/n)"
if ($testDeploy -notmatch '^[Nn]') {
    Write-Host "`n🧪 开始测试部署..." -ForegroundColor Cyan
    .\deploy.ps1
}