param()
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$issues = [Collections.Generic.List[string]]::new()
# 历史试验正文保持原样，旧引用不作为当前导航检查；输入与回答另做哈希核验。
$markdownFiles = @(Get-ChildItem -LiteralPath $projectRoot -Filter '*.md' -Recurse -File | Where-Object { $_.FullName -notmatch '[\\/](\.git|创作输出|冻结材料|请求|原始输出)[\\/]' })
foreach ($file in $markdownFiles) {
    $body = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($body.Contains([char]0xfffd)) { $issues.Add('编码替换字符：'+$file.FullName) }
    foreach ($match in [regex]::Matches($body, '\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim().Trim('<','>')
        if ($target -match '^(https?:|app:|codex:|#)') { continue }
        $target = ($target -split '#',2)[0]
        if ($target -and -not (Test-Path -LiteralPath (Join-Path $file.DirectoryName $target))) { $issues.Add('失效链接：'+$file.FullName+' -> '+$target) }
    }
}
$jsonFiles = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot '项目记录') -Filter '*.json' -Recurse -File)
foreach ($file in $jsonFiles) {
    try { $null = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { $issues.Add('无效 JSON：'+$file.FullName) }
}
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot '输出适配包清单.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($package in $manifest.packages) {
    foreach ($record in @($package) + @($package.sources)) {
        $path = Join-Path $projectRoot $record.path
        if (-not (Test-Path -LiteralPath $path)) { $issues.Add('缺少使用版来源：'+$record.path); continue }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $record.sha256) { $issues.Add('使用版需重建或核对：'+$record.path) }
    }
}
$runtimeRoot = Join-Path $projectRoot '创作系统'
$runtimeFiles = @(Get-ChildItem -LiteralPath $runtimeRoot -Filter '*.md' -Recurse -File)
foreach ($oldDirectory in @('助手指令','视觉表现资源','人类视觉语言库','参考资料')) {
    if (Test-Path -LiteralPath (Join-Path $projectRoot $oldDirectory)) { $issues.Add('旧运行目录仍存在：'+$oldDirectory) }
}
if ($manifest.packages.Count -ne 1 -or $manifest.entry -ne '创作系统/入口.md') { $issues.Add('运行入口或导出未统一') }
$modules = @(Get-ChildItem -LiteralPath (Join-Path $runtimeRoot '能力'),(Join-Path $runtimeRoot '任务') -Filter '*.md' -File)
foreach ($module in $modules) {
    $moduleBody = Get-Content -LiteralPath $module.FullName -Raw -Encoding UTF8
    foreach ($field in @('层级','何时读取','解决什么','何时深入','何时停止')) {
        if (-not $moduleBody.Contains('**'+$field+'**')) { $issues.Add('模块缺少调用说明：'+$module.Name+' / '+$field) }
    }
}
# 检查统一入口能沿正文链接到达每份运行材料，防止迁移留下孤立文件。
$visited = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$queue = [Collections.Generic.Queue[string]]::new()
$queue.Enqueue((Join-Path $runtimeRoot '入口.md'))
while ($queue.Count -gt 0) {
    $current = $queue.Dequeue()
    if (-not $visited.Add($current) -or -not (Test-Path -LiteralPath $current)) { continue }
    $body = [IO.File]::ReadAllText($current)
    foreach ($match in [regex]::Matches($body,'\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value
        if ($target -match '^(https?:|app:|codex:|#)') { continue }
        $relative = ($target -split '#',2)[0]
        $absolute = [IO.Path]::GetFullPath((Join-Path (Split-Path $current -Parent) $relative))
        if ($absolute.StartsWith($runtimeRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -and $absolute.EndsWith('.md')) { $queue.Enqueue($absolute) }
    }
}
foreach ($file in $runtimeFiles) {
    if (-not $visited.Contains($file.FullName)) { $issues.Add('入口无法到达运行材料：'+$file.FullName) }
}
foreach ($package in $manifest.packages) {
    $sourcePaths = @($package.sources | ForEach-Object { $_.path })
    if ($sourcePaths[0] -ne '创作系统/入口.md') { $issues.Add('导出没有统一入口') }
    if (@($sourcePaths | Select-Object -Unique).Count -ne $sourcePaths.Count) { $issues.Add('导出重复来源') }
    if ($sourcePaths.Count -ne $runtimeFiles.Count) { $issues.Add('导出未覆盖完整运行目录') }
    foreach ($file in $runtimeFiles) {
        $relative = [IO.Path]::GetRelativePath($projectRoot,$file.FullName).Replace('\','/')
        if ($relative -notin $sourcePaths) { $issues.Add('运行材料未进入导出：'+$relative) }
    }
    $archive = [IO.Compression.ZipFile]::OpenRead((Join-Path $projectRoot $package.path))
    try {
        if ($archive.Entries.Count -ne $sourcePaths.Count+1 -or -not $archive.GetEntry('导出说明.md')) { $issues.Add('导出包条目不完整') }
        foreach ($source in $package.sources) {
            $entry = $archive.GetEntry($source.path)
            if (-not $entry) { $issues.Add('导出缺少正文：'+$source.path); continue }
            $stream = $entry.Open()
            $hasher = [Security.Cryptography.SHA256]::Create()
            try { $hash = [Convert]::ToHexString($hasher.ComputeHash($stream)).ToLowerInvariant() }
            finally { $stream.Dispose(); $hasher.Dispose() }
            if ($hash -ne $source.sha256) { $issues.Add('导出正文与来源不一致：'+$source.path) }
        }
    } finally { $archive.Dispose() }
}
$developmentIds = [System.Collections.Generic.List[string]]::new()
foreach ($file in $modules) {
    $resourceText = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($match in [regex]::Matches($resourceText, '(?m)^## (S-V\d+|P-D\d+|J-V\d+)\b|(?m)^\| (O-F\d+) \|')) {
        $resourceId = $match.Groups[1].Value + $match.Groups[2].Value
        $developmentIds.Add($resourceId)
    }
}

foreach ($group in @($developmentIds | Group-Object)) {
    if ($group.Count -gt 1) { $issues.Add('深化资源编号重复：'+$group.Name) }
}
$actualModelRuns = 0
$visualLanguageRoot = Join-Path $projectRoot '创作系统/材料/关系'
$relationIds = [Collections.Generic.List[string]]::new()
$relationFields = @('日常入口','成立条件','可见过程','观察与表达','变体与边界','依据与验证')
$experienceIndex = Get-Content -LiteralPath (Join-Path $visualLanguageRoot '索引.md') -Raw -Encoding UTF8
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $visualLanguageRoot '条目') -Filter '*.md' -File)) {
    $relationText = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    foreach ($entry in [regex]::Matches($relationText, '(?ms)^## (VL-[A-Z]\d+) ([^\r\n]+)\r?\n(.*?)(?=^## |\z)')) {
        $id = $entry.Groups[1].Value
        $relationIds.Add($id)
        foreach ($field in $relationFields) {
            if (-not $entry.Groups[3].Value.Contains('**'+$field+'**')) { $issues.Add('视觉关系缺少字段：'+$id+' / '+$field) }
        }
        if (-not $experienceIndex.Contains($id)) { $issues.Add('视觉关系未进入日常索引：'+$id) }
    }
}
if ($relationIds.Count -eq 0) { $issues.Add('人类视觉语言库缺少关系条目') }
foreach ($group in @($relationIds | Group-Object)) {
    if ($group.Count -gt 1) { $issues.Add('视觉关系编号重复：'+$group.Name) }
}
foreach ($match in [regex]::Matches($experienceIndex, '\bVL-[A-Z]\d+\b')) {
    if (-not $relationIds.Contains($match.Value)) { $issues.Add('日常索引引用不存在的视觉关系：'+$match.Value) }
}
$excludedModelRuns = 0
$actualTrialRoot = Join-Path $projectRoot '项目记录/创作案例与验证/实际试验'
if (Test-Path -LiteralPath $actualTrialRoot) {
    foreach ($trial in @(Get-ChildItem -LiteralPath $actualTrialRoot -Directory)) {
        $trialManifestPath = Join-Path $trial.FullName '管理清单.json'
        if (-not (Test-Path -LiteralPath $trialManifestPath)) { continue }
        $trialManifest = Get-Content -LiteralPath $trialManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($frozenMaterial in $trialManifest.materials) {
            if ((Get-FileHash -LiteralPath (Join-Path $trial.FullName $frozenMaterial.frozen_file) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $frozenMaterial.sha256) { $issues.Add('实际试验冻结材料变化：'+$frozenMaterial.condition) }
        }
        foreach ($frozenRequest in $trialManifest.requests) {
            $requestBody = (Get-Content -LiteralPath (Join-Path $trial.FullName ('请求/'+$frozenRequest.request_id+'.json')) -Raw -Encoding UTF8 | ConvertFrom-Json).messages[0].content
            $requestHash = [System.Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($requestBody))).ToLowerInvariant()
            if ($requestHash -ne $frozenRequest.sha256) { $issues.Add('实际试验冻结请求变化：'+$frozenRequest.request_id) }
        }
        $trialRecords = @(Get-ChildItem -LiteralPath (Join-Path $trial.FullName '原始输出') -Filter '*.json' -File | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json })
        foreach ($response in $trialRecords) {
            if ((Get-FileHash -LiteralPath (Join-Path $trial.FullName $response.response_file) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $response.response_sha256) { $issues.Add('实际回答变化：'+$response.response_file) }
            if ($response.eligible_for_primary -ne $false) { $actualModelRuns++ } else { $excludedModelRuns++ }
        }
        $trialState = Get-Content -LiteralPath (Join-Path $trial.FullName '运行状态.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($trialState.completed_requests -ne @($trialRecords | Where-Object {$_.eligible_for_primary -ne $false}).Count) { $issues.Add('实际试验计数不一致：'+$trial.Name) }
    }
}
foreach ($recordFile in @(Get-ChildItem -LiteralPath (Join-Path $projectRoot '项目记录/创作案例与验证') -Filter '记录清单.json' -Recurse -File)) {
    $observation = Get-Content -LiteralPath $recordFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($record in $observation.files) {
        $path = Join-Path $recordFile.DirectoryName $record.path
        if (-not (Test-Path -LiteralPath $path)) { $issues.Add('成图观察缺少存档：'+$record.path); continue }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $record.sha256) { $issues.Add('成图观察存档变化：'+$recordFile.Directory.Name+'/'+$record.path) }
    }
}
if ($issues.Count) { $issues | ForEach-Object { Write-Output $_ }; throw ('发现 '+$issues.Count+' 项结构问题') }
[pscustomobject]@{status='passed_current_links_packages_and_saved_trial_integrity_only'; markdown_files=$markdownFiles.Count; json_files=$jsonFiles.Count; current_packages=$manifest.packages.Count; independent_model_runs=$actualModelRuns; excluded_model_runs=$excludedModelRuns; video_runs=0} | ConvertTo-Json
