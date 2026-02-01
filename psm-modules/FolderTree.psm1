# 文件夹扫描模块
# 功能：扫描指定目录并返回文件夹树结构

# 扫描指定目录并创建文件夹树对象
function Get-FolderTree {
    [CmdletBinding()]
    param(
        [string]$RootPath = "source/_posts",
        [switch]$Silent = $false
    )
    
    # 确保根路径存在
    if (-not (Test-Path $RootPath)) {
        Write-Error "根路径不存在: $RootPath"
        return $null
    }
    
    # 获取根目录的完整路径
    $rootFullPath = (Get-Item $RootPath).FullName
    if (-not $rootFullPath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $rootFullPath += [System.IO.Path]::DirectorySeparatorChar
    }
    
    Write-Verbose "扫描目录: $rootFullPath"
    
    # 扫描所有文件夹
    $allFolders = @()
    
    try {
        $folders = Get-ChildItem -Path $rootFullPath -Directory -Recurse -ErrorAction Stop
        
        foreach ($folder in $folders) {
            $folderFullPath = $folder.FullName
            
            # 计算相对路径
            $relativePath = [System.IO.Path]::GetRelativePath($rootFullPath, $folderFullPath)
            
            # 替换路径分隔符为斜杠（如果相对路径为空，则是根目录本身）
            if ($relativePath -ne ".") {
                $relativePath = $relativePath.Replace("\", "/")
                $allFolders += $relativePath
            }
        }
        
        Write-Verbose "找到 $($allFolders.Count) 个文件夹"
        
        # 创建文件夹树对象
        $treeObject = [PSCustomObject]@{
            AllFolders = $allFolders
            RootPath = $RootPath
            RootFullPath = $rootFullPath
        }
        
        # 添加方法
        $treeObject | Add-Member -MemberType ScriptMethod -Name Exists -Value {
            param([string]$RelativePath)
            $this.AllFolders -contains $RelativePath
        }
        
        $treeObject | Add-Member -MemberType ScriptMethod -Name Find -Value {
            param([string]$Pattern)
            $this.AllFolders | Where-Object { $_ -like "*$Pattern*" }
        }
        
        $treeObject | Add-Member -MemberType ScriptMethod -Name GetSubfolders -Value {
            param([string]$ParentPath)
            if (-not $ParentPath) {
                return $this.AllFolders | Where-Object { $_ -notmatch "/" }
            }
            $this.AllFolders | Where-Object { $_ -like "$ParentPath/*" -and $_ -ne $ParentPath }
        }
        
        return $treeObject
    }
    catch {
        Write-Error "扫描目录时出错: $_"
        return $null
    }
}

# 获取文件夹树并显示统计信息
function Show-FolderTree {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$RootPath = "source/_posts",
        
        [switch]$ShowSample = $false,
        [int]$SampleCount = 5
    )
    
    $tree = Get-FolderTree -RootPath $RootPath
    
    if ($tree) {
        Write-Host "📁 扫描目录: $($tree.RootFullPath)" -ForegroundColor Gray
        Write-Host "📊 找到 $($tree.AllFolders.Count) 个文件夹" -ForegroundColor Green
        
        if ($ShowSample -and $tree.AllFolders.Count -gt 0) {
            Write-Host "📋 示例文件夹 ($SampleCount 个):" -ForegroundColor Gray
            $tree.AllFolders | Select-Object -First $SampleCount | ForEach-Object {
                Write-Host "  • $_" -ForegroundColor DarkGray
            }
            
            if ($tree.AllFolders.Count -gt $SampleCount) {
                Write-Host "  ... 还有 $($tree.AllFolders.Count - $SampleCount) 个" -ForegroundColor DarkGray
            }
        }
        
        return $tree
    }
    
    return $null
}

# 导出模块函数
Export-ModuleMember -Function `
    Get-FolderTree,
    Show-FolderTree