
# 实验性脚本
# 导入模块
$modulesDir = "./psm-modules"
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

# 1. 加载分类映射
$categoryMap = Get-CategoryMap -Silent:(!$ShowDetails)
if ($categoryMap.Count -eq 0) {
    Write-Host "❌ 无法加载分类映射" -ForegroundColor Red
    exit 1
}

# 2. 扫描目录结构
$tree = Get-FolderTree -RootPath "source/_posts" -Silent:(!$ShowDetails)
if (-not $tree) {
    Write-Host "❌ 无法扫描目录结构" -ForegroundColor Red
    exit 1
}

$foundFolders = $tree.Find("实践方向")
$cat="实践方向"
$count =0
$folder=$foundFolders[0]
Write-Host "📁 发现文件夹: $folder" -ForegroundColor Cyan
$filespath=Join-Path (Get-Location) "source\_posts\$folder"
$files = Get-ChildItem -Path $filespath -Filter "*.md" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    Write-Host "🔍 处理文件: $($file.FullName)" -ForegroundColor Yellow
    if ($content -match '\s*\') {
        #$content = $content -replace '(?m)^\s*-\s*实践方向', "  - 道行卷"
        Write-Host "ture" -ForegroundColor Yellow
    }
    }else{
        Write-Host "false:$($file.FullName)" -ForegroundColor Yellow
    }

    #Set-Content -Path $file.FullName -Value $content -Encoding UTF8
}

Write-Host "✅ 处理完成，共处理文件: $count" -ForegroundColor Green