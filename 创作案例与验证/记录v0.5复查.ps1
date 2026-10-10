param([Parameter(Mandatory)][string]$RequestId,[Parameter(Mandatory)][string]$ConversationUrl)
$ErrorActionPreference='Stop'
$trialRoot=Join-Path $PSScriptRoot '实际试验/DeepSeek-v0.5-定向复查'
$manifest=Get-Content -LiteralPath (Join-Path $trialRoot '管理清单.json') -Raw -Encoding UTF8|ConvertFrom-Json
$request=@($manifest.requests|Where-Object request_id -eq $RequestId)
if($request.Count -ne 1){throw '请求编号无效'}
$outputPath=Join-Path $trialRoot ('原始输出/'+$RequestId+'.md')
$metadataPath=Join-Path $trialRoot ('原始输出/'+$RequestId+'.json')
if(Test-Path -LiteralPath $metadataPath){throw '回答已登记，不覆盖'}
$answer=(Get-Content -LiteralPath $outputPath -Raw -Encoding UTF8).TrimEnd("`r","`n")
$record=@{request_id=$RequestId;status='completed_visible_answer_captured';eligible_for_primary=$true;conversation_url=$ConversationUrl;captured_at=[DateTimeOffset]::Now.ToString('o');platform='DeepSeek web';backend_model_version=$null;thinking_mode=$true;search_mode=$false;loading_mode='inline_text';request_sha256=$request[0].sha256;response_file=('原始输出/'+$RequestId+'.md');response_sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant();answer_characters=$answer.Length;reasoning_saved=$false;observation_note='输入原文逐字核对；仅核心指令，不加载构思资源或输出约定文档'}
$encoding=[System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($metadataPath,($record|ConvertTo-Json -Depth 10),$encoding)
$records=@(Get-ChildItem -LiteralPath (Join-Path $trialRoot '原始输出') -Filter '*.json' -File)
$state=@{status=$(if($records.Count -eq 4){'completed_targeted_outputs_captured'}else{'running'});completed_requests=$records.Count;excluded_responses=0;video_runs=0;platform='DeepSeek web';backend_model_version=$null;thinking_mode=$true;search_mode=$false;scope='core_only_not_resource_or_package_validation';notes=@('历史参照，不是同期随机对照','每场景仅一次','由开发者知条件审查')}
[System.IO.File]::WriteAllText((Join-Path $trialRoot '运行状态.json'),($state|ConvertTo-Json -Depth 10),$encoding)
[pscustomobject]@{request_id=$RequestId;completed=$records.Count;characters=$answer.Length}|ConvertTo-Json
