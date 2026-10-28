param()
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$utf8 = [Text.UTF8Encoding]::new($false)
$systemRoot = Join-Path $projectRoot '创作系统'
$output = '导出/视觉助手.zip'
$outputPath = Join-Path $projectRoot $output
[void][IO.Directory]::CreateDirectory((Split-Path $outputPath -Parent))
$sources = @('创作系统/入口.md') + @(Get-ChildItem -LiteralPath $systemRoot -Recurse -File | Sort-Object FullName | ForEach-Object {
    [IO.Path]::GetRelativePath($projectRoot,$_.FullName).Replace('\','/')
} | Where-Object { $_ -ne '创作系统/入口.md' })
# 导出只封装同一棵运行目录，不维护按模型分叉的助手正文。
$tempPath = $outputPath + '.tmp'
$archive = $null
try {
    $archive = [IO.Compression.ZipFile]::Open($tempPath,[IO.Compression.ZipArchiveMode]::Create)
    foreach ($source in $sources) {
        $entry = $archive.CreateEntry($source,[IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTimeOffset]::new(2000,1,1,0,0,0,[TimeSpan]::Zero)
        $stream = $entry.Open()
        try { $bytes = [IO.File]::ReadAllBytes((Join-Path $projectRoot $source)); $stream.Write($bytes,0,$bytes.Length) }
        finally { $stream.Dispose() }
    }
    $entry = $archive.CreateEntry('导出说明.md')
    $entry.LastWriteTime = [DateTimeOffset]::new(2000,1,1,0,0,0,[TimeSpan]::Zero)
    $writer = [IO.StreamWriter]::new($entry.Open(),$utf8)
    try {
        $writer.WriteLine('# 视觉助手')
        $writer.WriteLine('')
        $writer.WriteLine('统一读取“创作系统/入口.md”。这是源项目运行目录的原样打包，没有按模型划分的助手版本。')
        $writer.WriteLine('项目记录中的历史试验与维护工具没有打包。正文指向项目记录的链接属于源项目证据，不能在本包中声称已访问；外部网页也需要实际取得。')
    } finally { $writer.Dispose() }
} finally { if ($archive) { $archive.Dispose() } }
Move-Item -LiteralPath $tempPath -Destination $outputPath -Force
$sourceRecords = foreach ($source in $sources) {
    [ordered]@{path=$source; sha256=(Get-FileHash -LiteralPath (Join-Path $projectRoot $source) -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$package = [ordered]@{model='统一创作系统'; path=$output; sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant(); sources=@($sourceRecords)}
$manifest = [ordered]@{
    version='0.8.0'; core_instruction_version='0.8'; entry='创作系统/入口.md'
    status='unified_structure_not_agent_routing_or_generation_validated'
    adapter_verified_dates=[ordered]@{Anima='2026-10-10'; 'MiniMax-H3'='2026-10-10'; 'GPT-Image'='2026-10-26'}
    image_runs=0; gpt_image_runs=0; video_runs=0; packages=@($package)
}
$json = ($manifest | ConvertTo-Json -Depth 10).Replace([string][char]13,'') + [char]10
[IO.File]::WriteAllText((Join-Path $PSScriptRoot '输出适配包清单.json'),$json,$utf8)
[pscustomobject]@{package=$output; source_files=$sources.Count; bytes=(Get-Item -LiteralPath $outputPath).Length} | ConvertTo-Json
