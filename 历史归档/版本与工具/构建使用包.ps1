param()
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$packageRoot = Join-Path $projectRoot '历史归档/单文件版本'
$utf8Writer = [System.Text.UTF8Encoding]::new($false)
$null = New-Item -ItemType Directory -Path $packageRoot -Force
$coreFiles = @('助手指令/共用内容/核心指令.md','视觉表现资源/01-视觉表现激活地图.md','助手指令/共用内容/输出与信息保留.md')
$expandedFiles = @('助手指令/共用内容/核心指令.md','视觉表现资源/01-视觉表现激活地图.md','视觉表现资源/02-运动与物理表现机会.md','视觉表现资源/03-跨域关系与艺术发展.md','视觉表现资源/04-二维与风格转译.md','助手指令/共用内容/输出与信息保留.md')
$deepenedFiles = @($expandedFiles | Where-Object { $_ -ne '助手指令/共用内容/输出与信息保留.md' }) + @('视觉表现资源/05-同一事件的艺术变体.md','视觉表现资源/06-过程展开与关联发展.md','视觉表现资源/07-观察证据与视觉形式.md','视觉表现资源/08-日式二维的多种表现发展.md','助手指令/共用内容/输出与信息保留.md')
$packages = @(
    @{name='VDL-v0.5-基础版.md'; sources=$coreFiles; description='核心指令、广域激活地图与输出约定'},
    @{name='VDL-v0.5-扩展版.md'; sources=$expandedFiles; description='基础内容加运动物理、跨域关系、二维风格资源'},
    @{name='VDL-v0.5-深化版.md'; sources=$deepenedFiles; description='扩展内容加事件变体、过程发展、观察形式与日漫多样表现'}
)
$packageRecords = foreach ($package in $packages) {
    $header = "# Visual Direction Lab v0.5 单文件使用包`n`n$($package.description)。根据 v0.4 首轮实际测试优化关系成立条件、艺术选择与成稿表达。候选修订，不代表能力提升或视频效果已经验证。`n`n以下内容作为创作要求与可选构思资源使用。先运用自身知识；按当前任务选择资源入口，不全表执行、不设置效果配额。例子不是标准答案，允许库外创造。默认直接交付完整连续提示词，用户要求其他交付时随任务调整。`n`n"
    $sections = foreach ($source in $package.sources) { (Get-Content -LiteralPath (Join-Path $projectRoot $source) -Raw -Encoding UTF8).Trim() }
    $packageText = $header + ($sections -join "`n`n---`n`n") + "`n"
    $outputPath = Join-Path $packageRoot $package.name
    [System.IO.File]::WriteAllText($outputPath, $packageText, $utf8Writer)
    $sourceRecords = foreach ($source in $package.sources) {
        @{path=$source; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $source) -Algorithm SHA256).Hash.ToLowerInvariant()}
    }
    @{path=('历史归档/单文件版本/'+$package.name); description=$package.description; characters=$packageText.Length; sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant(); sources=@($sourceRecords)}
}
$manifest = @{version='0.5'; core_instruction_version='0.5'; status='candidate_revision_from_v0.4_pilot'; validation_at_build='no_v0.5_package_validation_at_build'; previous_version_primary_runs=16; independent_model_runs=0; video_runs=0; packages=@($packageRecords); loading='choose_one_package_or_use_modules'; historical_research='研究参考/'; historical_package_manifest='历史归档/单文件版本/历史/v0.3-使用包清单.json'; historical_package_manifests=@('历史归档/单文件版本/历史/v0.3-使用包清单.json','历史归档/单文件版本/历史/v0.4-使用包清单.json'); evaluation='创作案例与验证/'; source_of_truth='助手指令/共用内容/'}
[System.IO.File]::WriteAllText((Join-Path $packageRoot '使用包清单.json'), ($manifest | ConvertTo-Json -Depth 10), $utf8Writer)
$packageRecords | ForEach-Object { [pscustomobject]@{package=$_.path; characters=$_.characters; source_files=$_.sources.Count} } | ConvertTo-Json
