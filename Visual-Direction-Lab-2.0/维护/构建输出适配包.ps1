param()
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sources = @('发布包/VDL-v0.5-基础版.md','模型使用/输出适配/README.md','模型使用/输出适配/Anima-生图.md','模型使用/输出适配/MiniMax-H3-视频.md')
$output = '发布包/VDL-v0.5-Anima-H3-使用版.md'
$outputFolder = Split-Path -Parent (Join-Path $projectRoot $output)
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
$body = "# Visual Direction Lab：Anima / MiniMax-H3 使用版`n`n创作核心 v0.5，输出适配 v0.1，官方资料核对 2026-10-10。生图默认 Anima，视频默认 MiniMax-H3；后面的特定格式补充通用输出约定。艺术母版保持模型无关。本包未进行图片或视频生成验证。`n`n" + ($sections -join "`n`n---`n`n") + "`n"
$utf8Writer = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Join-Path $projectRoot $output), $body, $utf8Writer)
$sourceRecords = foreach ($source in $sources) { @{path=$source; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $source) -Algorithm SHA256).Hash.ToLowerInvariant()} }
$manifest = @{version='0.1'; core_instruction_version='0.5'; status='official_guidance_adaptation_not_generation_validated'; verified_date='2026-10-10'; image_model='Anima'; video_model='MiniMax-H3'; image_runs=0; video_runs=0; packages=@(@{path=$output; characters=$body.Length; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $output) -Algorithm SHA256).Hash.ToLowerInvariant(); sources=@($sourceRecords)})}
[System.IO.File]::WriteAllText((Join-Path $projectRoot '发布包/输出适配包清单.json'), ($manifest | ConvertTo-Json -Depth 10), $utf8Writer)
[pscustomobject]@{package=$output; characters=$body.Length; source_files=$sources.Count} | ConvertTo-Json
