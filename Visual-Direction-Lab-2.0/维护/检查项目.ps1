param()
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$issues = [System.Collections.Generic.List[string]]::new()
$markdownFiles = @(Get-ChildItem -LiteralPath $projectRoot -Filter '*.md' -Recurse -File)
foreach ($file in $markdownFiles) {
    $fileText = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($fileText.Contains([char]0xfffd)) { $issues.Add('编码替换字符：'+$file.FullName) }
    foreach ($match in [regex]::Matches($fileText, '\]\(([^)]+)\)')) {
        $target = $match.Groups[1].Value.Trim().Trim('<','>')
        if ($target -match '^(https?:|app:|codex:|#)') { continue }
        $target = ($target -split '#',2)[0]
        if (-not $target) { continue }
        $resolvedTarget = [System.IO.Path]::GetFullPath((Join-Path $file.DirectoryName $target))
        if (-not (Test-Path -LiteralPath $resolvedTarget)) { $issues.Add('失效链接：'+$file.FullName+' -> '+$target) }
    }
}
$jsonFiles = @(Get-ChildItem -LiteralPath $projectRoot -Filter '*.json' -Recurse -File)
foreach ($file in $jsonFiles) {
    try { $null = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { $issues.Add('无效 JSON：'+$file.FullName) }
}
$experimentRoot = Join-Path $projectRoot '研究资料/实验'
$freeze = Get-Content -LiteralPath (Join-Path $experimentRoot '准备输出/冻结登记.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($inputRecord in $freeze.inputs) {
    $actual = (Get-FileHash -LiteralPath (Join-Path $experimentRoot $inputRecord.file) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $inputRecord.sha256) { $issues.Add('旧冻结输入变化：'+$inputRecord.file) }
}
$oldRequests = @(Get-ChildItem -LiteralPath (Join-Path $experimentRoot '准备输出/生成请求') -Filter '*.json' -File)
if ($oldRequests.Count -ne $freeze.request_count) { $issues.Add('旧请求数量变化') }
$requestManifest = Get-Content -LiteralPath (Join-Path $experimentRoot '准备输出/准备清单.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($record in $requestManifest) {
    $requestPath = Join-Path (Join-Path $experimentRoot '准备输出') $record.request_file
    $requestText = Get-Content -LiteralPath $requestPath -Raw -Encoding UTF8
    $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
    try { $requestHash = ([System.BitConverter]::ToString($hashAlgorithm.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($requestText)))).Replace('-','').ToLowerInvariant() }
    finally { $hashAlgorithm.Dispose() }
    if ($requestHash -ne $record.sha256) { $issues.Add('旧请求变化：'+$record.request_id) }
}
$manifest = Get-Content -LiteralPath (Join-Path $projectRoot '发布包/使用包清单.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($package in $manifest.packages) {
    if ((Get-FileHash -LiteralPath (Join-Path $projectRoot $package.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $package.sha256) { $issues.Add('发布包变化：'+$package.path) }
    foreach ($source in $package.sources) {
        if ((Get-FileHash -LiteralPath (Join-Path $projectRoot $source.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $source.sha256) { $issues.Add('发布包需重建：'+$source.path) }
    }
}
$historicalPackageCount = 0
$historicalManifestPaths = @(@($manifest.historical_package_manifest) + @($manifest.historical_package_manifests) | Where-Object { $_ } | Select-Object -Unique)
foreach ($historyPath in $historicalManifestPaths) {
    $historicalManifest = Get-Content -LiteralPath (Join-Path $projectRoot $historyPath) -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($package in $historicalManifest.packages) {
        if ((Get-FileHash -LiteralPath (Join-Path $projectRoot $package.path) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $package.sha256) { $issues.Add('历史使用包变化：'+$package.path) }
        $historicalPackageCount++
    }
}
$publicCaseCount = 0
$caseConfigs = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot '评估') -Filter '*公开场景.json' -File)
foreach ($configFile in $caseConfigs) {
    $caseConfig = Get-Content -LiteralPath $configFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $publicCaseCount += $caseConfig.scenes.Count
    foreach ($condition in $caseConfig.conditions) {
        if ($condition.material -and -not (Test-Path -LiteralPath (Join-Path $configFile.DirectoryName $condition.material))) { $issues.Add('评估材料路径失效：'+$configFile.Name+'/'+$condition.id) }
    }
}
$developmentIds = [System.Collections.Generic.List[string]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $projectRoot '模型使用/构思资源') -Filter '*.md' -File)) {
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
$excludedModelRuns = 0
$actualTrialRoot = Join-Path $projectRoot '评估/实际试验'
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
if ($issues.Count) { $issues | ForEach-Object { Write-Output $_ }; throw ('发现 '+$issues.Count+' 项结构问题') }
[pscustomobject]@{status='passed_document_structure_and_saved_trial_integrity_only'; markdown_files=$markdownFiles.Count; json_files=$jsonFiles.Count; old_frozen_inputs=$freeze.inputs.Count; unchanged_old_requests=$oldRequests.Count; packages=$manifest.packages.Count; unchanged_historical_packages=$historicalPackageCount; development_entries=$developmentIds.Count; public_cases=$publicCaseCount; independent_model_runs=$actualModelRuns; excluded_model_runs=$excludedModelRuns; video_runs=0} | ConvertTo-Json
