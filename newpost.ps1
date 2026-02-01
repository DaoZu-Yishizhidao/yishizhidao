# 《意识之道》智能文章创建脚本 - 模块化版本
param(
    [Parameter(Mandatory=$true)]
    [string]$category,
    [switch]$ShowDetails = $false,
    [switch]$ListAll = $false,
    [switch]$ListCategories = $false
)

Write-Host "📝 《意识之道》智能文章创建" -ForegroundColor Cyan
Write-Host "═" * 50 -ForegroundColor DarkGray

# 创建 psm-modules 目录（如果不存在）
$modulesDir = "./psm-modules"
if (-not (Test-Path $modulesDir)) {
    Write-Host "📁 创建模块目录: $modulesDir" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null
}

# 导入模块
$modules = @(
    "$modulesDir\CategoryMap.psm1",
    "$modulesDir\FolderTree.psm1", 
    "$modulesDir\PathConverter.psm1"
)

foreach ($module in $modules) {
    if (Test-Path $module) {
        try {
            Import-Module $module -Force -ErrorAction Stop
            Write-Verbose "导入模块: $module"
        }
        catch {
            Write-Error "无法导入模块 $module : $_"
            exit 1
        }
    }
    else {
        Write-Error "模块文件不存在: $module"
        Write-Host "请确保以下模块文件存在:" -ForegroundColor Red
        $modules | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
        exit 1
    }
}

# 处理特殊参数
if ($ListCategories) {
    Write-Host "📋 分类映射管理系统" -ForegroundColor Cyan
    Write-Host "═" * 50 -ForegroundColor DarkGray
    
    $categoryMap = Get-CategoryMap
    Show-AvailableCategoryMaps -CategoryMap $categoryMap
    exit 0
}

if ($ListAll) {
    Write-Host "📁 目录结构扫描" -ForegroundColor Cyan
    Write-Host "═" * 50 -ForegroundColor DarkGray
    
    $tree = Show-FolderTree -RootPath "source/_posts" -ShowSample -SampleCount 20
    exit 0
}

# 主逻辑：查找并转换文件夹路径

# 1. 加载分类映射
if($ShowDetails){
    Write-Host "🔍 加载分类映射..." -ForegroundColor Gray
}

$categoryMap = Get-CategoryMap -Silent:(!$ShowDetails)

if ($categoryMap.Count -eq 0) {
    Write-Host "❌ 无法加载分类映射，请检查配置文件" -ForegroundColor Red
    exit 1
}

# 2. 扫描目录结构
if($ShowDetails){
    Write-Host "🔍 扫描文章目录..." -ForegroundColor Gray
}
$tree = Show-FolderTree -RootPath "source/_posts"

if (-not $tree) {
    Write-Host "❌ 无法扫描目录结构" -ForegroundColor Red
    exit 1
}

# 3. 搜索文件夹
if($ShowDetails){
    Write-Host "🔍 搜索文件夹: '$category'" -ForegroundColor Gray
}
$foundFolders = $tree.Find($category)

if ($foundFolders -and $foundFolders.Count -gt 0) {
    if($ShowDetails){
        Write-Host "✅ 找到 $($foundFolders.Count) 个匹配的文件夹" -ForegroundColor Green
    }
    
    # 显示转换结果
    Show-PathConversion -Paths $foundFolders -CategoryMap $categoryMap
    
    # 如果有多个匹配，建议使用第一个
    if ($foundFolders.Count -gt 1) {
        Write-Host "`n💡 建议: 使用第一个匹配的文件夹" -ForegroundColor Yellow
        Write-Host "  路径: $($foundFolders[0])" -ForegroundColor Cyan
        
        # 询问用户选择
        Write-Host "`n❓ 是否使用第一个路径？(Y/N)" -ForegroundColor Yellow -NoNewline
        $choice = Read-Host " "
        
        if ($choice -in @('Y', 'y', '')) {
            $selectedPath = $foundFolders[0]
            $convertedPath = Convert-PathToEnglish -RelativePath $selectedPath -CategoryMap $categoryMap
            
            Write-Host "`n🎯 选择的路径:" -ForegroundColor Green
            Write-Host "  中文: $selectedPath" -ForegroundColor Gray
            Write-Host "  英文: $convertedPath" -ForegroundColor Cyan
        }
    }
}
else {
    Write-Host "❌ 未找到包含 '$category' 的文件夹" -ForegroundColor Red
    
    # 显示可用的分类映射
    Write-Host "`n📋 可用的分类映射:" -ForegroundColor Yellow
    Show-AvailableCategoryMaps -CategoryMap $categoryMap
    
    # 显示顶层文件夹
    Write-Host "`n📁 可用的顶层文件夹:" -ForegroundColor Yellow
    $topLevelFolders = $tree.GetSubfolders("")
    $topLevelFolders | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
}

Write-Host "`n💡 使用帮助:" -ForegroundColor DarkGray
Write-Host "  .\newpost.ps1 -category '技术'" -ForegroundColor DarkGray
Write-Host "  .\newpost.ps1 -category 'CICD'" -ForegroundColor DarkGray
Write-Host "  .\newpost.ps1 -ListCategories      # 显示所有分类映射" -ForegroundColor DarkGray
Write-Host "  .\newpost.ps1 -ListAll             # 显示所有文件夹" -ForegroundColor DarkGray

# 移除模块（清理）
Remove-Module CategoryMap, FolderTree, PathConverter -ErrorAction SilentlyContinue