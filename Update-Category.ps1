# ============================================
# 《意识之道》分类批量更新脚本（增强版）
# 作者：道祖
# 版本：v2
# 日期：2026-04-18
# 功能：利用文件夹扫描与路径转换模块，批量更新文章分类
# ============================================

param(
    [Parameter(Mandatory = $true, HelpMessage = "需要被替换的旧分类名（中文或英文别名）")]
    [string]$OldCategory,

    [Parameter(Mandatory = $true, HelpMessage = "替换后的新分类名（中文或英文别名）")]
    [string]$NewCategory,

    [Parameter(HelpMessage = "文章存放的根目录（相对于脚本目录或绝对路径）")]
    [string]$TargetDir = "source/_posts",

    [switch]$DryRun = $false,   # 预览模式，不实际修改文件
    [switch]$Silent = $false,   # 静默模式，减少输出
    [switch]$Force = $false     # 强制更新，即使新分类不在映射表中
)

# 脚本目录



# 导入模块
$modulesDir = "./psm-modules"
$rootDir = Split-Path -Parent $modulesDir
$modules = @(
    "$modulesDir\CategoryMap.psm1",
    "$modulesDir\FolderTree.psm1", 
    "$modulesDir\PathConverter.psm1"
)
foreach ($module in $modules) {
    if (Test-Path $module) {
        try {
            Import-Module $module -Force -ErrorAction Stop
            if ($ShowDetails) {
                Write-Host "✅ 导入模块: $(Split-Path $module -Leaf)" -ForegroundColor Green
            }
        }
        catch {
            Write-Host "❌ 无法导入模块 $module : $_" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "❌ 模块文件不存在: $module" -ForegroundColor Red
        Write-Host "请确保以下模块文件存在:" -ForegroundColor Yellow
        $modules | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
        exit 1
    }
}

# 构建目标目录绝对路径
if (-not [System.IO.Path]::IsPathRooted($TargetDir)) {
    $TargetDir = Join-Path $rootDir $TargetDir
}
if (-not (Test-Path $TargetDir)) {
    Write-Host "❌ 目录不存在: $TargetDir" -ForegroundColor Red
    exit 1
}

# 加载分类映射
$categoryMap = Get-CategoryMap -Silent:$Silent
if (-not $categoryMap) {
    Write-Host "⚠️ 未找到分类映射，将仅进行纯文本替换。" -ForegroundColor Yellow
}

# 辅助函数：获取中文名（如果传入的是英文别名，则通过映射表反向查找）
function Get-ChineseName {
    param([string]$Name)
    if (-not $categoryMap) { return $Name }
    
    # 如果本身是中文且存在于映射键中，直接返回
    if ($categoryMap.ContainsKey($Name)) { return $Name }
    
    # 如果是英文别名，反向查找中文
    $chinese = $categoryMap.Keys | Where-Object { $categoryMap[$_] -eq $Name }
    if ($chinese) { return $chinese }
    
    return $Name
}

# 验证分类是否有效（存在于映射表中）
function Test-CategoryValid {
    param([string]$Category)
    if (-not $categoryMap -or $Force) { return $true }
    
    # 检查中文名或英文别名
    return ($categoryMap.ContainsKey($Category) -or $categoryMap.Values -contains $Category)
}

# 获取所有 Markdown 文件（利用文件夹扫描模块的思想，但直接使用 Get-ChildItem 更简单）
Write-Host "🔍 扫描目录: $TargetDir" -ForegroundColor Cyan
$files = Get-ChildItem -Path $TargetDir -Filter "*.md" -Recurse
$total = $files.Count
Write-Host "📄 找到 $total 个 Markdown 文件" -ForegroundColor Gray

if ($total -eq 0) {
    Write-Host "⚠️ 没有找到任何 .md 文件，退出。" -ForegroundColor Yellow
    exit
}

# 确认操作
$oldChinese = Get-ChineseName -Name $OldCategory
$newChinese = Get-ChineseName -Name $NewCategory
Write-Host "🔄 准备将分类 [$OldCategory] → [$NewCategory]" -ForegroundColor Yellow
if ($oldChinese -ne $OldCategory) {
    Write-Host "   中文原名: $oldChinese" -ForegroundColor DarkGray
}
if ($newChinese -ne $NewCategory) {
    Write-Host "   中文新名: $newChinese" -ForegroundColor DarkGray
}

if (-not $Force -and $categoryMap) {
    if (-not (Test-CategoryValid -Category $OldCategory)) {
        Write-Host "❌ 旧分类 [$OldCategory] 不在映射表中，使用 -Force 可强制替换。" -ForegroundColor Red
        exit 1
    }
    if (-not (Test-CategoryValid -Category $NewCategory)) {
        Write-Host "❌ 新分类 [$NewCategory] 不在映射表中，使用 -Force 可强制替换。" -ForegroundColor Red
        exit 1
    }
}

if ($DryRun) {
    Write-Host "⚠️  预览模式：不会实际修改文件" -ForegroundColor Magenta
}

$updated = 0
$skipped = 0
$errors = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if (-not $content) {
        Write-Host "⚠️ 无法读取文件: $($file.Name)" -ForegroundColor DarkYellow
        $errors++
        continue
    }

    $modified = $false
    $newContent = $content

    # 解析 Front-matter
    if ($content -match '(?s)^---\s*\n(.*?)\n---\s*\n(.*)') {
        $frontMatter = $matches[1]
        $body = $matches[2]
        $lines = $frontMatter -split "`n"
        $newLines = @()
        $inCategories = $false

        foreach ($line in $lines) {
            # 检测 categories 行
            if ($line -match '^categories:') {
                $inCategories = $true
                # 单行数组：categories: [A, B, C]
                if ($line -match '^categories:\s*\[(.*)\]') {
                    $cats = $matches[1] -split ',' | ForEach-Object { $_.Trim() }
                    $newCats = @()
                    foreach ($c in $cats) {
                        if ($c -eq $OldCategory -or $c -eq $oldChinese) {
                            $newCats += $NewCategory
                            $modified = $true
                        } else {
                            $newCats += $c
                        }
                    }
                    $newLine = "categories: [" + ($newCats -join ", ") + "]"
                    $newLines += $newLine
                    $inCategories = $false
                }
                # 单行字符串：categories: A
                elseif ($line -match '^categories:\s*([^\s\[].*)$') {
                    $cat = $matches[1].Trim()
                    if ($cat -eq $OldCategory -or $cat -eq $oldChinese) {
                        $newLine = "categories: $NewCategory"
                        $modified = $true
                    } else {
                        $newLine = $line
                    }
                    $newLines += $newLine
                    $inCategories = $false
                }
                # 多行数组开始：categories:
                else {
                    $newLines += $line
                }
            }
            elseif ($inCategories) {
                # 多行数组项：  - CategoryName
                if ($line -match '^\s*-\s*(.+)$') {
                    $cat = $matches[1].Trim()
                    if ($cat -eq $OldCategory -or $cat -eq $oldChinese) {
                        $newLine = $line -replace [regex]::Escape($cat), $NewCategory
                        $modified = $true
                    } else {
                        $newLine = $line
                    }
                    $newLines += $newLine
                }
                else {
                    # 结束分类区域
                    $inCategories = $false
                    $newLines += $line
                }
            }
            else {
                $newLines += $line
            }
        }

        if ($modified) {
            $newFrontMatter = $newLines -join "`n"
            $newContent = "---`n$newFrontMatter`n---`n$body"
        }
    }
    else {
        if (-not $Silent) {
            Write-Host "⚠️ 未找到 Front-matter: $($file.Name)" -ForegroundColor DarkYellow
        }
        $skipped++
        continue
    }

    if ($modified) {
        if (-not $DryRun) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
        }
        Write-Host "✏️  已更新: $($file.FullName)" -ForegroundColor Green
        $updated++
    }
    else {
        if (-not $Silent) {
            Write-Host "⏭️  无需更新: $($file.Name)" -ForegroundColor Gray
        }
        $skipped++
    }
}

# 输出统计
Write-Host "`n📊 处理完成：" -ForegroundColor Cyan
Write-Host "   总文件数: $total" -ForegroundColor White
Write-Host "   已更新: $updated" -ForegroundColor Green
Write-Host "   跳过: $skipped" -ForegroundColor Gray
Write-Host "   错误: $errors" -ForegroundColor Red
if ($DryRun) {
    Write-Host "🔍 这是预览模式，未实际修改任何文件。去掉 -DryRun 参数以执行真实替换。" -ForegroundColor Magenta
}