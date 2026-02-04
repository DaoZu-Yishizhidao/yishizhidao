param(
    [Parameter(Mandatory=$true)]
    [string]$category,
    [string]$title,
    [switch]$ShowDetails = $false
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

$postName=$title
if($category -eq $title){
    $posturl="index"
}
else{
    $posturl=[DateTimeOffset]::Now.ToUnixTimeMilliseconds()
}


$categoryMap = Get-CategoryMap -Silent:(!$ShowDetails)
$tree = Show-FolderTree -RootPath "source/_posts" -Silent:(!$ShowDetails)
$foundFolders = $tree.Find($category)

if ($foundFolders.Count -gt 1) {
    $foundFolders = $($foundFolders[0])
}

if ($foundFolders -and $foundFolders.Count -gt 0) {

   # $categories=$foundFolders
   # $categories=$categories.Replace($tree.GetSubfolders("")+"/","[")
   # $categories=$categories.Replace("/",",")+"]"
    $folderParts = $foundFolders -split '/'
    $categoriesArray = @()
     $folderParts   
    # 为每个层级创建分类,除去根节点categonries
    for ($i = 1; $i -lt $folderParts.Count; $i++) {
        $path = $folderParts[0..$i] -join '/'
        if ($categoryMap.ContainsKey($folderParts[$i])) {
            $categoriesArray += $categoryMap[$folderParts[$i]]
        } else {
            $categoriesArray += $folderParts[$i]
        }
    }
    
    # 构建分类字符串
    $categories = "[$($foundFolders -join ',')]"

    $categories
    $permalink=Convert-PathsToEnglish -Paths $foundFolders -CategoryMap $CategoryMap
    
    $post="post.md"
    $newpost="newpost.md"
    $postPath="$PWD\scaffolds\$post"
    $newpostPath="$PWD\scaffolds\$newpost"
    if(Test-Path $postPath){
        Copy-Item $postPath $newpostPath
        (Get-Content $newpostPath) -replace "permalink:", "permalink: $permalink/$posturl/" | Set-Content $newpostPath
        (Get-Content $newpostPath) -replace "categories:", "categories: $categories" | Set-Content $newpostPath

       # hexo new newpost --path "$foundFolders/$title" $title
        Write-Host "✅成功创建标题为'$title'的文章，路径为：$foundFolders/$title"
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












# 移除模块（清理）
Remove-Module CategoryMap, FolderTree, PathConverter -ErrorAction SilentlyContinue