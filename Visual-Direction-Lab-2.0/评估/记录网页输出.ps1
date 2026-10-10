param([Parameter(Mandatory)][string]$RequestId,[Parameter(Mandatory)][string]$ConversationUrl,[string]$LoadingMode='inline_text',[string]$ObservationNote='',[bool]$SearchMode=$false,[bool]$EligibleForPrimary=$true,[string]$AttemptSuffix='')
$ErrorActionPreference='Stop'
$trialRoot=Join-Path $PSScriptRoot '实际试验/DeepSeek-v0.4-首轮'
$manifest=Get-Content -LiteralPath (Join-Path $trialRoot '管理清单.json') -Raw -Encoding UTF8|ConvertFrom-Json
$request=@($manifest.requests|Where-Object request_id -eq $RequestId)
if ($request.Count -ne 1) { throw '请求编号无效' }
$outputPath=Join-Path $trialRoot ('原始输出/'+$RequestId+$AttemptSuffix+'.md')
$metadataPath=Join-Path $trialRoot ('原始输出/'+$RequestId+$AttemptSuffix+'.json')
if (Test-Path -LiteralPath $metadataPath) { throw '输出已登记，不覆盖' }
$answer=(Get-Content -LiteralPath $outputPath -Raw -Encoding UTF8).TrimEnd("`r","`n")
$record=@{request_id=$RequestId;status='completed_visible_answer_captured';eligible_for_primary=$EligibleForPrimary;attempt_suffix=$AttemptSuffix;conversation_url=$ConversationUrl;captured_at=[DateTimeOffset]::Now.ToString('o');platform='DeepSeek web';backend_model_version=$null;model_display='全新模型上线（页面未显示可核验版本）';thinking_mode=$true;search_mode=$SearchMode;loading_mode=$LoadingMode;request_sha256=$request[0].sha256;response_file=('原始输出/'+$RequestId+$AttemptSuffix+'.md');response_sha256=(Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant();answer_characters=$answer.Length;reasoning_saved=$false;observation_note=$ObservationNote}
$encoding=[System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($metadataPath,($record|ConvertTo-Json -Depth 10),$encoding)
$allRecords=@(Get-ChildItem -LiteralPath (Join-Path $trialRoot '原始输出') -Filter '*.json' -File|ForEach-Object {Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8|ConvertFrom-Json})
$validRecords=@($allRecords|Where-Object {$_.eligible_for_primary -ne $false})
$state=@{status=$(if($validRecords.Count -eq $manifest.request_count){'completed_pilot_outputs_captured'}else{'running'});completed_requests=$validRecords.Count;completed_responses_including_excluded=$allRecords.Count;submitted_requests=$allRecords.Count;excluded_responses=($allRecords.Count-$validRecords.Count);failed_requests=0;video_runs=0;platform='DeepSeek web';model_display_name=$record.model_display;backend_model_version=$null;thinking_mode=$true;search_mode=$false;context='one_new_conversation_per_request';notes=@('后台模型版本未公开','仅保存最终可见回答，不保存思考展开文本','新会话发送前检查并统一模式','submitted_requests计数仅统计已有最终采集记录，不表示实时在途请求')}
[System.IO.File]::WriteAllText((Join-Path $trialRoot '运行状态.json'),($state|ConvertTo-Json -Depth 10),$encoding)
$sequence=Get-Content -LiteralPath (Join-Path $trialRoot '运行顺序.json') -Raw -Encoding UTF8|ConvertFrom-Json
foreach($item in $sequence){if($item.request_id -eq $RequestId -and $EligibleForPrimary){$item.status='completed'}}
[System.IO.File]::WriteAllText((Join-Path $trialRoot '运行顺序.json'),($sequence|ConvertTo-Json -Depth 10),$encoding)
[pscustomobject]@{request_id=$RequestId;completed_primary=$validRecords.Count;completed_including_excluded=$allRecords.Count;characters=$answer.Length;url=$ConversationUrl}|ConvertTo-Json
