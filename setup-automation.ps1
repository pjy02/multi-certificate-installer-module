# GitHub Actions 自动化发布设置脚本
# 使用方法：在PowerShell中运行 .\setup-automation.ps1

param(
    [string]$Version = "v1.0.0",
    [switch]$Force = $false
)

Write-Host "🚀 开始设置GitHub Actions自动化发布系统" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow

# 检查是否在git仓库中
if (-not (Test-Path ".git")) {
    Write-Host "❌ 错误：当前目录不是git仓库" -ForegroundColor Red
    Write-Host "请先初始化git仓库：git init" -ForegroundColor Yellow
    exit 1
}

# 检查GitHub CLI是否安装
try {
    $ghVersion = gh --version
    Write-Host "✅ 检测到GitHub CLI: $ghVersion" -ForegroundColor Green
    $ghAvailable = $true
} catch {
    Write-Host "⚠️  警告：未检测到GitHub CLI" -ForegroundColor Yellow
    Write-Host "建议安装GitHub CLI以获得更好的体验" -ForegroundColor Yellow
    Write-Host "下载地址：https://cli.github.com/" -ForegroundColor Cyan
    $ghAvailable = $false
}

# 检查工作流文件
$workflowDir = ".github\workflows"
if (-not (Test-Path $workflowDir)) {
    Write-Host "❌ 错误：未找到工作流目录" -ForegroundColor Red
    Write-Host "请确保.github/workflows目录存在" -ForegroundColor Yellow
    exit 1
}

$basicWorkflow = Join-Path $workflowDir "release.yml"
$advancedWorkflow = Join-Path $workflowDir "release-advanced.yml"

if (-not (Test-Path $basicWorkflow)) {
    Write-Host "❌ 错误：未找到基础版工作流文件" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $advancedWorkflow)) {
    Write-Host "❌ 错误：未找到高级版工作流文件" -ForegroundColor Red
    exit 1
}

Write-Host "✅ 工作流文件检查通过" -ForegroundColor Green

# 检查module.prop文件
if (-not (Test-Path "module.prop")) {
    Write-Host "❌ 错误：未找到module.prop文件" -ForegroundColor Red
    exit 1
}

# 读取当前版本
$modulePropContent = Get-Content "module.prop"
$currentVersion = ($modulePropContent | Where-Object { $_ -match "^version=" }) -replace "^version=", ""
$currentVersionCode = ($modulePropContent | Where-Object { $_ -match "^versionCode=" }) -replace "^versionCode=", ""

Write-Host "📋 当前版本信息：" -ForegroundColor Cyan
Write-Host "   版本号: $currentVersion" -ForegroundColor White
Write-Host "   版本代码: $currentVersionCode" -ForegroundColor White

# 更新module.prop
Write-Host "🔄 更新module.prop文件" -ForegroundColor Cyan

try {
    $newVersionCode = [int]$currentVersionCode + 1
    $content = Get-Content "module.prop"
    $newContent = $content | ForEach-Object {
        if ($_ -match "^version=") {
            "version=$Version"
        } elseif ($_ -match "^versionCode=") {
            "versionCode=$newVersionCode"
        } else {
            $_
        }
    }
    $newContent | Set-Content "module.prop"
    Write-Host "✅ module.prop更新成功" -ForegroundColor Green
    Write-Host "   新版本号: $Version" -ForegroundColor White
    Write-Host "   新版本代码: $newVersionCode" -ForegroundColor White
    
    # 提交更改
    Write-Host "📤 提交版本更新" -ForegroundColor Cyan
    git add module.prop
    git commit -m "Bump version to $Version"
    Write-Host "✅ 版本更新已提交" -ForegroundColor Green
} catch {
    Write-Host "❌ module.prop更新失败" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    exit 1
}

# 检查是否有未提交的更改
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️  检测到未提交的更改：" -ForegroundColor Yellow
    Write-Host $gitStatus -ForegroundColor White
    
    if (-not $Force) {
        $response = Read-Host "是否继续？(y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Host "❌ 操作已取消" -ForegroundColor Red
            exit 1
        }
    }
}

# 创建版本标签
Write-Host "🏷️  创建版本标签: $Version" -ForegroundColor Cyan

try {
    git tag $Version
    Write-Host "✅ 标签创建成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 标签创建失败" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    exit 1
}

# 推送标签
Write-Host "📤 推送标签到远程仓库" -ForegroundColor Cyan

try {
    git push origin $Version
    Write-Host "✅ 标签推送成功" -ForegroundColor Green
} catch {
    Write-Host "❌ 标签推送失败" -ForegroundColor Red
    Write-Host $_ -ForegroundColor Red
    exit 1
}

Write-Host "" -ForegroundColor White
Write-Host "🎉 自动化发布设置完成！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Yellow
Write-Host "📝 后续步骤：" -ForegroundColor Cyan
Write-Host "   1. 访问GitHub仓库的Actions页面" -ForegroundColor White
Write-Host "   2. 查看工作流执行状态" -ForegroundColor White
Write-Host "   3. 等待自动发布完成" -ForegroundColor White
Write-Host "   4. 在Releases页面验证发布结果" -ForegroundColor White
Write-Host "" -ForegroundColor White
Write-Host "🔗 有用的链接：" -ForegroundColor Cyan
if ($ghAvailable) {
    try {
        $repoUrl = git remote get-url origin
        $repoName = $repoUrl -replace '.*github.com[:/](.*?)(\.git)?$', '$1'
        Write-Host "   - GitHub Actions: https://github.com/$repoName/actions" -ForegroundColor White
        Write-Host "   - Releases: https://github.com/$repoName/releases" -ForegroundColor White
    } catch {
        Write-Host "   - GitHub Actions: [仓库URL]/actions" -ForegroundColor White
        Write-Host "   - Releases: [仓库URL]/releases" -ForegroundColor White
    }
} else {
    Write-Host "   - GitHub Actions: [仓库URL]/actions" -ForegroundColor White
    Write-Host "   - Releases: [仓库URL]/releases" -ForegroundColor White
}
Write-Host "" -ForegroundColor White
Write-Host "📚 更多信息请参考：.github/AUTOMATION.md" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "⚠️  重要提示：" -ForegroundColor Yellow
Write-Host "   如果GitHub Actions因权限问题失败，请：" -ForegroundColor White
Write-Host "   1. 检查仓库设置 > Actions > General" -ForegroundColor White
Write-Host "   2. 确保'Workflow permissions'设置为'Read and write permissions'" -ForegroundColor White
Write-Host "   3. 或者使用简化版工作流'release-simple.yml'" -ForegroundColor White

# 询问是否要查看工作流状态
$response = Read-Host "是否现在查看工作流状态？(y/N)"
if ($response -eq "y" -or $response -eq "Y") {
    try {
        $repoUrl = git remote get-url origin
        $repoName = $repoUrl -replace '.*github.com[:/](.*?)(\.git)?$', '$1'
        Start-Process "https://github.com/$repoName/actions"
    } catch {
        Write-Host "❌ 无法打开浏览器，请手动访问GitHub Actions页面" -ForegroundColor Red
    }
}

Write-Host "✨ 设置完成！" -ForegroundColor Green