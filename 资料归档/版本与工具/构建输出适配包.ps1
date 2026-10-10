param()
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$packages = @(
    @{model='Anima'; output='助手指令/Anima.md'; adapter='助手指令/共用内容/输出适配/Anima-生图.md'; instruction='本包默认交付 Anima 静态图片提示词，采用该适配的 Positive / Negative 组织；这项任务与格式选择优先于通用核心中的默认视频交付。视频任务改用相应视频适配，不能声称 Anima 生成动画。'},
    @{model='MiniMax-H3'; output='助手指令/MiniMax-H3.md'; adapter='助手指令/共用内容/输出适配/MiniMax-H3-视频.md'; instruction='本包默认交付 MiniMax-H3 视频提示词，按实际任务选择基础或全参考字段；特定格式优先于通用核心的自然段默认交付。静态图片生成需另选生图适配。'}
)
$utf8Writer = [System.Text.UTF8Encoding]::new($false)
$packageRecords = foreach ($package in $packages) {
$sources = @('资料归档/单文件版本/VDL-v0.5-基础版.md')
$sources += '视觉表现资源/10-艺术风格与审美方向发展.md'
if ($package.model -eq 'Anima') { $sources += '视觉表现资源/09-画面深度与静态表现发展.md' }
$sources += $package.adapter
$output = $package.output
$outputFolder = Split-Path -Parent (Join-Path $projectRoot $output)
[System.IO.Directory]::CreateDirectory($outputFolder) | Out-Null
$sections = foreach ($source in $sources) {
    $sourcePath = Join-Path $projectRoot $source
    $sourceFolder = Split-Path -Parent $sourcePath
    $sourceText = (Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8).Trim()
    [regex]::Replace($sourceText, '\]\(([^)]+)\)', [System.Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $target = $match.Groups[1].Value
        if ($target -match '^(https?:|app:|codex:|#)') { return $match.Value }
        $parts = $target -split '#',2
        $absolute = [System.IO.Path]::GetFullPath((Join-Path $sourceFolder $parts[0]))
        $relative = [System.IO.Path]::GetRelativePath($outputFolder, $absolute).Replace('\','/')
        if ($parts.Count -gt 1) { $relative += '#'+$parts[1] }
        return ']('+$relative+')'
    })
}
$resourceNote = if ($package.model -eq 'Anima') { '含艺术风格与静态表现资源，各 v0.1；新增资源尚未对照或生成验证。' } else { '含艺术风格资源 v0.1，新增资源尚未对照或生成验证。' }
$body = "# Visual Direction Lab：$($package.model) 使用版`n`n创作核心 v0.5，输出适配 v0.3.1，官方资料核对 2026-10-10。$resourceNote$($package.instruction) 模型提示词主体默认英文，说明用用户语言，台词与画面文字保持原文；用户明确指定其他语言时遵从。艺术母版保持模型无关，概念、分镜等任务按用户要求交付。本包未进行图片或视频生成验证。`n`n" + ($sections -join "`n`n---`n`n") + "`n"
[System.IO.File]::WriteAllText((Join-Path $projectRoot $output), $body, $utf8Writer)
$sourceRecords = foreach ($source in $sources) { @{path=$source; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $source) -Algorithm SHA256).Hash.ToLowerInvariant()} }
@{model=$package.model; path=$output; characters=$body.Length; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $output) -Algorithm SHA256).Hash.ToLowerInvariant(); sources=@($sourceRecords)}
}
$manifest = @{version='0.3.1'; core_instruction_version='0.5'; status='separate_model_packages_not_generation_validated'; verified_date='2026-10-10'; image_model='Anima'; video_model='MiniMax-H3'; image_runs=0; video_runs=0; packages=@($packageRecords)}
[System.IO.File]::WriteAllText((Join-Path $projectRoot '资料归档/单文件版本/输出适配包清单.json'), ($manifest | ConvertTo-Json -Depth 10), $utf8Writer)
$packageRecords | ForEach-Object { [pscustomobject]@{model=$_.model; package=$_.path; characters=$_.characters; source_files=$_.sources.Count} } | ConvertTo-Json
