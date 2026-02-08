# ============================================
### 《意识之道》智能文章创建脚本
### 作者：道祖
### 文件名：newpost.ps1
### 编程语言：PowerShell
### 功能：带折叠功能的时间轴
### 作者：道祖
### 版本：v1.01 
### 日期：2026-02-04 00：10
### 更新日期：2026-02-09 02：39
# ============================================



param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$category = "道祖之道",
    
    [Parameter(Mandatory=$false, Position=1)]
    [string]$title,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails
)

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

$defcategory=$category -eq "道祖之道"

# 获取分类文件夹路径
function Get-foundFolder {
    $foundFolders = $tree.Find($category)
    if ($foundFolders -and $foundFolders.Count -gt 0) {
        if ($foundFolders.Count -gt 1) {
            if ($ShowDetails) {
                Write-Host "⚠️  找到多个匹配的文件夹，使用第一个" -ForegroundColor Yellow
                $foundFolders | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
            }
            $foundFolder = $foundFolders[0]
        }
        else {
            $foundFolder = $foundFolders
        }
        return $foundFolder

    }
    else{
        Write-Host "❌ 未找到包含 '$category' 的分类文件夹" -ForegroundColor Red
    
        # 显示可用的分类映射
        if ($categoryMap.Count -gt 0) {
            Write-Host "`n📋 可用的分类映射:" -ForegroundColor Yellow
            
            # 按分组显示
            $groups = @{
                "道经卷" = $categoryMap.Keys | Where-Object { $_ -match "^道经卷|法则篇|道演篇" }
                "道境卷" = $categoryMap.Keys | Where-Object { $_ -match "^道境卷|道境之门|境界论述|实修根本|实修经|实修理术" }
                "实践方向" = $categoryMap.Keys | Where-Object { $_ -match "^实践方向|哲学之道|科学之道|技术之道|道祖之道" }
                "其他" = $categoryMap.Keys | Where-Object { $_ -notmatch "^道经卷|道境卷|实践方向" }
            }
            
            foreach ($groupKey in $groups.Keys) {
                if ($groups[$groupKey].Count -gt 0) {
                    Write-Host "`n  ${groupKey}:" -ForegroundColor Cyan
                    $groups[$groupKey] | Sort-Object | ForEach-Object {
                        Write-Host "    • $_ → $($categoryMap[$_])" -ForegroundColor DarkGray
                    }
                }
            }
        }
        
        # 显示顶层文件夹
        Write-Host "`n📁 可用的顶层文件夹:" -ForegroundColor Yellow
        
        # 添加GetSubfolders方法到$tree对象（如果不存在）
        if (-not ($tree | Get-Member -Name GetSubfolders -MemberType ScriptMethod)) {
            $tree | Add-Member -MemberType ScriptMethod -Name GetSubfolders -Value {
                param([string]$ParentPath)
                if (-not $ParentPath) {
                    return $this.AllFolders | Where-Object { $_ -notmatch "/" }
                }
                $this.AllFolders | Where-Object { $_ -like "$ParentPath/*" -and $_ -ne $ParentPath }
            }
        }
        
        $topLevelFolders = $tree.GetSubfolders("")
        if ($topLevelFolders) {
            $topLevelFolders | ForEach-Object { Write-Host "  • $_" -ForegroundColor Gray }
        }
        exit 0  
    }

}


# 获取文章信息，处理 Front-matter
function Get-PostInfo {
    # 处理文章标题
    # 若标题为空，则以日期为标题
    if ([string]::IsNullOrEmpty($title)) {
        $now = Get-Date
        $title = "$($now.Year)年$($now.Month)月$($now.Day)日$($now.Hour)时$($now.Minute)分"
        Write-Host "默认标题: $title" -ForegroundColor Yellow
    }

    if($defcategory){Write-Host "默认分类: $category" -ForegroundColor Yellow}
    
    if ($category -eq $title) {
        $posturl = "index"
    } else {
        # 使用时间戳作为URL的一部分，确保唯一性
        $timestamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
        $posturl = "$timestamp"
    }
    $PostTitle = $title

    # 获取创建文章的分类文件夹路径
    $foundFolder=Get-foundFolder

    # 构建分类字符串,除去根节点categonries
    $categories=$foundFolder
    $categories=$categories.Replace($($tree.GetSubfolders("")+"/"),"[")
    $categories=$categories.Replace("/",",")+"]"
    $categories="categories: $categories"

    #处理默认路径
    if($defcategory){
        $foundFolder="$foundFolder/$($now.Year)/$($now.Month)"
        Write-Host "默认路径: $foundFolder" -ForegroundColor Yellow
    }

    # 构建永久链接
    $permalink = Convert-PathToEnglish -RelativePath $foundFolder -CategoryMap $categoryMap
    $permalinkPath = "permalink: /$permalink/$posturl/"

    # 默认首页不显示，自定义字段
    $hide = "hide: ture"

    return $foundFolder,$PostTitle,$categories,$permalinkPath,$hide
}


# 文章模板处理
function Set-ProcScaffold {
    param(
        [string]$PostTitle,
        [string]$categories,
        [string]$permalinkPath,
        [string]$hide
    )

    # 不改变原有模板，创建新的模板进行处理
    $postTemplate = "post.md"
    $newTemplate = "newpost.md"
    $templatePath = Join-Path (Get-Location) "scaffolds\$postTemplate"
    $newTemplatePath = Join-Path (Get-Location) "scaffolds\$newTemplate"
    
    if (Test-Path $templatePath) {
        # 复制模板
        Copy-Item $templatePath $newTemplatePath -Force
        
        # 更新模板内容
        $templateContent = Get-Content $newTemplatePath

        # 替换title（如果模板中有占位符）
        if ($templateContent -match 'title:\s*{{ title }}') {
            $templateContent = $templateContent -replace 'title:\s*{{ title }}', "title: $PostTitle"
        }

        # 替换categories
        if ($templateContent -match 'categories:\s*.*') {
            $templateContent = $templateContent -replace 'categories:\s*.*', "$categories"
        } else {
            # 如果没有categories行，添加一个
            $templateContent = $templateContent -replace '---', "---`n$categories"
        }
        
        # 替换permalink
        if ($templateContent -match 'permalink:\s*.*') {
            $templateContent = $templateContent -replace 'permalink:\s*.*', "$permalinkPath"
        } else {
            # 如果没有permalink行，添加一个
            $templateContent = $templateContent -replace '---', "---`n$permalinkPath"
        }
        
        # 替换hide
        if ($templateContent -match 'hide:\s*.*') {
            $templateContent = $templateContent -replace 'hide:\s*.*', "$hide"
        } else {
            #如果没有hide行，添加一个
            $templateContent = $templateContent -replace '---', "---`n$hide"
        }

        Set-Content -Path $newTemplatePath -Value $templateContent -Encoding UTF8
        
        #code $newTemplatePath #查看模板文件

        if ($ShowDetails) {
            Write-Host "📄 更新模板内容:" -ForegroundColor Gray
            Write-Host "  permalink: $permalinkPath" -ForegroundColor DarkGray
            Write-Host "  categories: $categories" -ForegroundColor DarkGray
        }

        return $newTemplatePath
    }
    else{
        Write-Host "❌ 模板文件不存在: $templatePath" -ForegroundColor Red
        Write-Host "请确保存在 scaffolds\post.md 文件" -ForegroundColor Yellow
        exit 0
    }
}

# 创建新文章
function Set-NewPost{
    param(
        [string]$foundFolder,
        [string]$PostTitle
    )
    # 执行Hexo命令创建文章
    try {
        # 构建完整的文章路径
        $fullPostPath = Join-Path (Get-Location) "source/_posts" $foundFolder $PostTitle
        $fullPostPath = $fullPostPath.Replace("/", "\") + ".md"

        # 检查是否已存在
        if (Test-Path $fullPostPath) {
            Write-Host "⚠️  文件已存在: $fullPostPath" -ForegroundColor Yellow
            $overwrite = Read-Host "是否覆盖？(y/n)"
            if ($overwrite -ne 'y') {
                Write-Host "❌ 已取消创建" -ForegroundColor Red
                exit 0
            }
        }
        
        # 使用Hexo创建文章
        hexo new newpost --path "$foundFolder/$PostTitle" $PostTitle
        # 打开文章
        code "source/_posts/$foundFolder/$PostTitle.md"
        Write-Host "✅ 成功创建标题为'$PostTitle'的文章" -ForegroundColor Green
        Write-Host "📁 路径: source/_posts/$foundFolder/$PostTitle.md" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ 执行Hexo命令时出错: $_" -ForegroundColor Red
        # 手动创建文件的备用方案
        Write-Host "手动创建文件..." -ForegroundColor Yellow
    }
}



$foundFolder,$PostTitle,$categories,$permalinkPath,$hide=Get-PostInfo
$newTemplatePath=Set-ProcScaffold -PostTitle:($PostTitle) -categories:($categories) -permalinkPath:($permalinkPath) -hide:($hide)
Set-NewPost -foundFolder:($foundFolder) -PostTitle:($PostTitle)


# 清理
# 移除临时模板
if (Test-Path $newTemplatePath) {
    Remove-Item $newTemplatePath -Force
}
# 移除模块
Remove-Module CategoryMap, FolderTree, PathConverter -ErrorAction SilentlyContinue

Write-Host "`n✅ 脚本执行完成" -ForegroundColor Green