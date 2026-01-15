# deploy-check.ps1
# 部署前检查脚本

param(
    [switch]$Fix = $false
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Hexo Butterfly 部署前检查" -ForegroundColor Cyan
Write-Host "=========================================="

function Check-And-Fix {
    param($CheckName, $CheckScript, $FixScript)
    
    Write-Host "`n🔍 检查: $CheckName" -ForegroundColor White
    
    try {
        & $CheckScript
        Write-Host "✅ 通过" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ 失败: $_" -ForegroundColor Red
        
        if ($Fix -and $FixScript) {
            Write-Host "🛠️  尝试修复..." -ForegroundColor Yellow
            try {
                & $FixScript
                Write-Host "✅ 修复成功" -ForegroundColor Green
                return $true
            } catch {
                Write-Host "❌ 修复失败: $_" -ForegroundColor Red
                return $false
            }
        }
        return $false
    }
}

# 1. 检查Node.js版本
Check-And-Fix "Node.js版本" {
    $nodeVersion = node --version
    if ($nodeVersion -notmatch "^v(18|20)\.") {
        throw "需要Node.js 18或20，当前版本: $nodeVersion"
    }
} {
    Write-Host "请从 https://nodejs.org/ 安装Node.js 18或20" -ForegroundColor Yellow
}

# 2. 检查Hexo版本
Check-And-Fix "Hexo版本" {
    $hexoVersion = hexo version
    if ($hexoVersion -notmatch "hexo:\s*(\d+)") {
        throw "无法获取Hexo版本"
    }
} {
    Write-Host "运行: npm install -g hexo-cli" -ForegroundColor Yellow
}

# 3. 检查依赖安装
Check-And-Fix "依赖包" {
    if (-not (Test-Path "node_modules")) {
        throw "node_modules目录不存在"
    }
    
    # 检查关键依赖
    $required = @("hexo", "hexo-theme-butterfly", "hexo-renderer-marked")
    foreach ($pkg in $required) {
        if (-not (Test-Path "node_modules/$pkg")) {
            throw "缺少依赖: $pkg"
        }
    }
} {
    Write-Host "运行: npm install --legacy-peer-deps" -ForegroundColor Yellow
    npm install --legacy-peer-deps
}

# 4. 检查配置文件
Check-And-Fix "配置文件" {
    $requiredFiles = @("_config.yml", "_config.butterfly.yml")
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            throw "缺少配置文件: $file"
        }
        
        # 验证YAML格式
        $content = Get-Content $file -Raw
        try {
            $null = ConvertFrom-Yaml $content
        } catch {
            throw "$file 包含无效的YAML格式: $_"
        }
    }
} {
    # 创建基础配置文件
    if (-not (Test-Path "_config.yml")) {
        Write-Host "创建基础 _config.yml..." -ForegroundColor Yellow
        Copy-Item "_config.example.yml" "_config.yml" -ErrorAction Stop
    }
}

# 5. 检查主题文件
Check-And-Fix "主题文件" {
    $theme = (Select-String -Path "_config.yml" -Pattern "^theme:\s*(.+)$").Matches.Groups[1].Value
    if (-not $theme) {
        throw "无法从_config.yml获取主题配置"
    }
    
    if (-not (Test-Path "themes/$theme")) {
        throw "主题目录不存在: themes/$theme"
    }
    
    # 检查主题配置文件
    if (-not (Test-Path "themes/$theme/_config.yml") -and -not (Test-Path "_config.butterfly.yml")) {
        throw "缺少主题配置文件"
    }
} {
    # 创建主题配置
    if (Test-Path "themes/butterfly/_config.yml") {
        Write-Host "复制主题配置文件..." -ForegroundColor Yellow
        Copy-Item "themes/butterfly/_config.yml" "_config.butterfly.yml"
    }
}

# 6. 检查源文件
Check-And-Fix "源文件" {
    if (-not (Test-Path "source/_posts")) {
        throw "文章目录不存在: source/_posts"
    }
    
    # 检查是否有文章
    $posts = Get-ChildItem "source/_posts" -Filter "*.md" -Recurse
    if ($posts.Count -eq 0) {
        Write-Host "⚠️  警告: 没有找到文章" -ForegroundColor Yellow
    }
} {
    # 创建示例文章
    Write-Host "创建示例文章..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "source/_posts" -Force | Out-Null
    @"
---
title: 欢迎来到《意识之道》
date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
tags: [欢迎, 介绍]
categories: 公告
---

# 欢迎！

这是您的第一篇文章。编辑此文件开始您的创作之旅。
"@ | Out-File "source/_posts/welcome.md" -Encoding UTF8
}

# 7. 测试构建
Check-And-Fix "构建测试" {
    Write-Host "清理旧构建..." -ForegroundColor Gray
    hexo clean | Out-Null
    
    Write-Host "生成静态文件..." -ForegroundColor Gray
    $output = hexo g 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "构建失败:`n$output"
    }
    
    # 检查输出目录
    if (-not (Test-Path "public/index.html")) {
        throw "生成失败: 没有找到index.html"
    }
    
    $fileCount = (Get-ChildItem "public" -Recurse -File).Count
    $size = [math]::Round(((Get-ChildItem "public" -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 2)
    
    Write-Host "📊 构建统计:" -ForegroundColor White
    Write-Host "   文件数量: $fileCount 个" -ForegroundColor Gray
    Write-Host "   总大小: $size MB" -ForegroundColor Gray
    
} {
    Write-Host "请检查错误信息并修复问题" -ForegroundColor Yellow
}

# 8. 检查自定义文件
Check-And-Fix "自定义文件" {
    $customFiles = @(
        "source/_data/butterfly.yml",
        "source/css/custom.css",
        "scripts/injects"
    )
    
    foreach ($file in $customFiles) {
        if (Test-Path $file) {
            Write-Host "   ✅ 找到: $file" -ForegroundColor Gray
        } else {
            Write-Host "   ⚠️  未找到: $file" -ForegroundColor Yellow
        }
    }
    
    return $true
} {
    # 创建必要的自定义文件
    if (-not (Test-Path "source/_data")) {
        New-Item -ItemType Directory -Path "source/_data" -Force | Out-Null
    }
    
    if (-not (Test-Path "source/_data/butterfly.yml")) {
        Write-Host "创建示例配置..." -ForegroundColor Yellow
        Copy-Item "_config.butterfly.yml" "source/_data/butterfly.yml" -ErrorAction SilentlyContinue
    }
}

Write-Host "`n=========================================="
Write-Host "🎉 检查完成！" -ForegroundColor Green

if (-not $Fix) {
    Write-Host "`n提示: 使用 -Fix 参数自动修复问题" -ForegroundColor Cyan
    Write-Host "示例: .\deploy-check.ps1 -Fix" -ForegroundColor Gray
}

Write-Host "`n下一步:"
Write-Host "1. 运行 'npm run dev' 启动开发服务器" -ForegroundColor White
Write-Host "2. 访问 http://localhost:4000 预览" -ForegroundColor White
Write-Host "3. 运行 'hexo deploy' 部署到生产环境" -ForegroundColor White