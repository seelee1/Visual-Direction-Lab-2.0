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
$developmentIds = [System.Collections.Generic.List[string]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $projectRoot '视觉表现资源') -Filter '*.md' -File)) {
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
$visualLanguageRoot = Join-Path $projectRoot '人类视觉语言库'
$relationIds = [Collections.Generic.List[string]]::new()
$relationFields = @('日常入口','成立条件','可见过程','观察与表达','变体与边界','依据与验证')
$experienceIndex = Get-Content -LiteralPath (Join-Path $visualLanguageRoot '日常经验索引.md') -Raw -Encoding UTF8
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $visualLanguageRoot '关系条目') -Filter '*.md' -File)) {
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
