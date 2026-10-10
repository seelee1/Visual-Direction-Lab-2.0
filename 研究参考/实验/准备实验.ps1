param([string]$OutputDirectory = (Join-Path $PSScriptRoot '准备输出'))
$ErrorActionPreference = 'Stop'
$utf8Encoding = [System.Text.UTF8Encoding]::new($false)
function Write-Utf8File([string]$filePath, [string]$fileText) {
    [System.IO.File]::WriteAllText($filePath, $fileText, $utf8Encoding)
}
function Get-TextHash([string]$value) {
    $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
    try { return ([System.BitConverter]::ToString($hashAlgorithm.ComputeHash($utf8Encoding.GetBytes($value)))).Replace('-', '').ToLowerInvariant() }
    finally { $hashAlgorithm.Dispose() }
}
$configPath = Join-Path $PSScriptRoot '实验配置.json'
$configText = Get-Content -LiteralPath $configPath -Raw -Encoding utf8
$config = $configText | ConvertFrom-Json
$requestDir = Join-Path $OutputDirectory '生成请求'
$null = New-Item -ItemType Directory -Path $requestDir -Force
$records = [System.Collections.Generic.List[object]]::new()
$serial = 0
foreach ($scene in $config.scenes) {
    $packetText = [string]$config.packets.($scene.packet)
    foreach ($condition in $config.conditions) {
        $materialText = ''
        if ($condition.material -eq 'relevant') { $materialText = $packetText }
        if ($condition.material -eq 'distractor') {
            $materialText = [string]$config.distractor_seed_text
            while ($materialText.Length -lt $packetText.Length) { $materialText += [string]$config.distractor_seed_text }
            $materialText = $materialText.Substring(0, $packetText.Length)
        }
        for ($repeatIndex = 1; $repeatIndex -le $config.replicates; $repeatIndex++) {
            $serial++
            $requestId = 'Q{0:D3}' -f $serial
            $userText = "创作要求：`n$($scene.request)`n`n交付要求：`n$($config.output_contract)"
            if ($condition.activation) { $userText += "`n`n创作要求补充：`n$($condition.activation)" }
            if ($materialText) { $userText += "`n`n参考资料（用于知识参考，不是输出模板）：`n$materialText" }
            $messages = @(@{role='system'; content=$config.base_system}, @{role='user'; content=$userText})
            $requestJson = @{messages=$messages} | ConvertTo-Json -Depth 6
            $requestPath = Join-Path $requestDir ($requestId + '.json')
            Write-Utf8File $requestPath $requestJson
            Write-Utf8File (Join-Path $requestDir ($requestId + '.md')) ("系统要求：`n$($config.base_system)`n`n$userText")
            $records.Add([pscustomobject]@{request_id=$requestId; scene=$scene.id; condition=$condition.id; replicate=$repeatIndex; sha256=(Get-TextHash $requestJson); material_characters=$materialText.Length; input_characters=($userText.Length+$config.base_system.Length); status='prepared_not_executed'; request_file=('生成请求/'+$requestId+'.json')})
        }
    }
}
$randomGenerator = [System.Random]::new([int]$config.randomization_seed)
$randomizedRecords = @($records.ToArray())
for ($position = $randomizedRecords.Length - 1; $position -gt 0; $position--) {
    $otherPosition = $randomGenerator.Next($position + 1)
    $temporaryRecord = $randomizedRecords[$position]
    $randomizedRecords[$position] = $randomizedRecords[$otherPosition]
    $randomizedRecords[$otherPosition] = $temporaryRecord
}
$orderedRecords = for ($position = 0; $position -lt $randomizedRecords.Length; $position++) {
    [pscustomobject]@{order=($position+1); request_id=$randomizedRecords[$position].request_id; request_file=$randomizedRecords[$position].request_file}
}
Write-Utf8File (Join-Path $OutputDirectory '准备清单.json') ($records.ToArray() | ConvertTo-Json -Depth 6)
Write-Utf8File (Join-Path $OutputDirectory '运行顺序.json') ($orderedRecords | ConvertTo-Json -Depth 6)
$frozenInputs = foreach ($frozenName in @('实验配置.json','探针与评审.md','运行记录模板.json')) {
    [pscustomobject]@{file=$frozenName; sha256=(Get-FileHash -LiteralPath (Join-Path $PSScriptRoot $frozenName) -Algorithm SHA256).Hash.ToLowerInvariant()}
}
Write-Utf8File (Join-Path $OutputDirectory '冻结登记.json') (@{version=$config.version; status='prepared_not_executed'; generated_at=[DateTimeOffset]::Now.ToString('o'); randomization_seed=$config.randomization_seed; request_count=$records.Count; inputs=$frozenInputs} | ConvertTo-Json -Depth 6)
[pscustomobject]@{prepared_requests=$records.Count; scenes=$config.scenes.Count; conditions=$config.conditions.Count; replicates=$config.replicates; executed_runs=0; output_directory=[System.IO.Path]::GetFullPath($OutputDirectory)} | ConvertTo-Json
