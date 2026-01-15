# 创建Hexo本地开发指南
# Hexo本地开发环境指南
Write-Host "📚 Hexo本地开发环境配置" -ForegroundColor Yellow
Write-Host "=========================================="

# 检查Hexo安装
try {
    $hexoVersion = hexo --version
    Write-Host "✅ Hexo已安装: $hexoVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Hexo未安装" -ForegroundColor Red
    Write-Host "请运行: npm install -g hexo-cli" -ForegroundColor White
    exit 1
}

# 项目结构说明
Write-Host "`n📁 项目结构说明：" -ForegroundColor Cyan
Write-Host "=========================================="
Write-Host "_config.yml     - Hexo主配置文件" -ForegroundColor White
Write-Host "source/         - 文章和页面目录" -ForegroundColor White
Write-Host "  _posts/       - 所有文章" -ForegroundColor White
Write-Host "  _drafts/      - 草稿文章" -ForegroundColor White
Write-Host "themes/         - 主题目录" -ForegroundColor White
Write-Host "public/         - 生成的静态文件" -ForegroundColor White
Write-Host "scaffolds/      - 文章模板" -ForegroundColor White

# 常用命令
Write-Host "`n🚀 常用Hexo命令：" -ForegroundColor Cyan
Write-Host "=========================================="
$commands = @{
    "新建文章" = "hexo new '文章标题'"
    "本地预览" = "hexo server"
    "生成静态文件" = "hexo generate"
    "清理缓存" = "hexo clean"
    "部署到Git" = "hexo deploy"
    "草稿模式" = "hexo server --draft"
}

foreach ($desc in $commands.Keys) {
    Write-Host "  $desc" -ForegroundColor Green -NoNewline
    Write-Host ": $($commands[$desc])" -ForegroundColor Gray
}

# 创建示例文章
Write-Host "`n📝 创建示例文章：" -ForegroundColor Cyan
Write-Host "=========================================="
$exampleContent = @"
---
title: 欢迎来到《意识之道》
date: 2026-01-15 03:44:50
tags: [欢迎, 介绍]
categories: 道经
mathjax: true
---
# 欢迎来到《意识之道》思想实验场

> 道可道，非常道。名可名，非常名。

这是您的第一篇文章。从这里开始您的思想探索之旅。

## 写作说明

1. 使用Markdown语法
2. 支持数学公式和图表
3. 自动部署到 https://yishizhidao.cn

## 快速开始

**定义 0.1.1（空集记号）**
$$
\varnothing := {}
$$
**定义 0.1.2（后继函数）**
对于任意集合 $x$，定义其后继为：
$$
x^+ := x \cup {x}
$$
**定义 0.1.3（冯·诺依曼自然数）**
递归定义：
$$
0 := \varnothing
$$
$$
1 := 0^+ = {\varnothing}
$$
$$
2 := 1^+ = {\varnothing, {\varnothing}}
$$
$$
3 := 2^+ = {\varnothing, {\varnothing}, {\varnothing, {\varnothing}}}
$$
一般地：
$$
n+1 := n^+ = n \cup {n}
$$

# 新建文章
hexo new "文章标题"

# 本地预览
hexo server

# 部署到网站
./deploy-yishizhidao.ps1
欢迎加入这个开源的思想实验！
"@
$examplePath = ".\source_posts\欢迎来到《意识之道》.md"
New-Item -Path $examplePath -ItemType File -Force -Value $exampleContent | Out-Null
Write-Host "✅ 示例文章已创建: $examplePath" -ForegroundColor Green
