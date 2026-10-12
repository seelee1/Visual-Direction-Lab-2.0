param()
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$packages = @(
    @{model='通用创作'; output='助手指令/使用版本/通用创作.md'; adapter=$null; instruction='本包从艺术设计出发，不绑定生成模型或提示词输出。没有交付要求时，用用户语言直接给出具体完整的视觉设计；角色、场景、插画、动画、分镜、漫画与系列按创作意图发展。最后按用户需求选择交付形式；需要特定模型提示词时另提供对应输出适配。'},
    @{model='Anima'; output='助手指令/使用版本/Anima.md'; adapter='助手指令/输出适配/Anima-生图.md'; instruction='本包供已明确设置 Anima 生成用途的会话使用。先形成艺术设计，交付 Anima 提示词时采用 Positive / Negative 组织；用户要求概念、分镜或其他设计时仍按任务交付。视频生成任务需另选相应适配，不能声称 Anima 生成动画。'},
    @{model='MiniMax-H3'; output='助手指令/使用版本/MiniMax-H3.md'; adapter='助手指令/输出适配/MiniMax-H3-视频.md'; instruction='本包供已明确设置 MiniMax-H3 生成用途的会话使用。先形成艺术设计，交付 H3 提示词时按实际参考职责选择基础或全参考字段；用户要求概念、分镜或其他设计时仍按任务交付。静态图片生成需另选生图适配。'}
)
$utf8Writer = [System.Text.UTF8Encoding]::new($false)
$packageRecords = foreach ($package in $packages) {
$sources = @('助手指令/核心指令.md', '视觉表现资源/01-视觉表现激活地图.md', '助手指令/创作规范/交付与信息保留.md')
$sources += '视觉表现资源/10-艺术风格与审美方向发展.md'
if ($package.model -eq 'Anima') { $sources += '视觉表现资源/09-画面深度与静态表现发展.md' }
if ($package.adapter) { $sources += $package.adapter }
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
$resourceNote = if ($package.model -eq 'Anima') { '含艺术风格与静态表现资源，各 v0.1。' } else { '含艺术风格资源 v0.1。' }
$packageNote = if ($package.adapter) { '创作核心 v0.5，输出适配 v0.3.1，官方资料核对 2026-10-10。模型提示词主体默认英文，说明用用户语言，台词与画面文字保持原文；用户明确指定其他语言时遵从。' } else { '创作核心 v0.5；不含模型适配。没有输出要求也可直接使用，格式与语言按用户任务决定。' }
$body = "# Visual Direction Lab：$($package.model) 使用版`n`n$packageNote$resourceNote$($package.instruction) 艺术设计保持模型无关，完整表达选定作品；资源按需要调用，不要求每次展示流程。`n`n" + ($sections -join "`n`n---`n`n") + "`n"
[System.IO.File]::WriteAllText((Join-Path $projectRoot $output), $body, $utf8Writer)
$sourceRecords = foreach ($source in $sources) { @{path=$source; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $source) -Algorithm SHA256).Hash.ToLowerInvariant()} }
@{model=$package.model; path=$output; characters=$body.Length; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $output) -Algorithm SHA256).Hash.ToLowerInvariant(); sources=@($sourceRecords)}
}
$manifest = @{version='0.3.1'; core_instruction_version='0.5'; status='design_first_with_optional_model_packages_not_generation_validated'; verified_date='2026-10-10'; generic_package='助手指令/使用版本/通用创作.md'; image_model='Anima'; video_model='MiniMax-H3'; image_runs=0; video_runs=0; packages=@($packageRecords)}
[System.IO.File]::WriteAllText((Join-Path $projectRoot '项目记录/单文件版本/输出适配包清单.json'), ($manifest | ConvertTo-Json -Depth 10), $utf8Writer)
$packageRecords | ForEach-Object { [pscustomobject]@{model=$_.model; package=$_.path; characters=$_.characters; source_files=$_.sources.Count} } | ConvertTo-Json
