param([string]$TrialName='DeepSeek-v0.4-首轮')
$ErrorActionPreference='Stop'
$projectRoot=[System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$trialRoot=[System.IO.Path]::GetFullPath((Join-Path (Join-Path $PSScriptRoot '实际试验') $TrialName))
if (-not $trialRoot.StartsWith([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '实际试验'))+[System.IO.Path]::DirectorySeparatorChar)) { throw '试验名称超出目录' }
if (Test-Path -LiteralPath $trialRoot) { throw '试验目录已存在，不覆盖冻结材料' }
$encoding=[System.Text.UTF8Encoding]::new($false)
function Save-Text([string]$path,[string]$value) { [System.IO.File]::WriteAllText($path,$value,$encoding) }
function Save-Json([string]$path,$value) { Save-Text $path ($value | ConvertTo-Json -Depth 12) }
$null=New-Item -ItemType Directory -Path (Join-Path $trialRoot '请求') -Force
$null=New-Item -ItemType Directory -Path (Join-Path $trialRoot '冻结材料') -Force
$null=New-Item -ItemType Directory -Path (Join-Path $trialRoot '原始输出') -Force
$null=New-Item -ItemType Directory -Path (Join-Path $trialRoot '评审') -Force
$conditions=@(
    @{id='B0';source=$null},
    @{id='A0';source='助手指令/共用内容/核心指令.md'},
    @{id='A2';source='历史归档/单文件版本/VDL-v0.4-扩展版.md'},
    @{id='A3';source='历史归档/单文件版本/VDL-v0.4-深化版.md'}
)
$scenes=@(
    @{id='D31';kind='public_development';request='5 秒，日式二维少女奔跑、急停、回头；单镜头，脚部接触可见。'},
    @{id='D38';kind='public_development';request='6 秒，纯线条与色块动画，一个形状逐渐显现；没有人物与剧情。'},
    @{id='N51';kind='new_concrete_scene_not_strict_blind';request='8 秒日式二维，两人共同抬一块长木板通过狭窄门口，固定全景单镜头。'},
    @{id='N52';kind='new_concrete_scene_not_strict_blind';request='6 秒日式二维，一串悬挂的钥匙被手拨动，手离开后钥匙逐渐安定；固定近景单镜头。'}
)
$contract='只交付一份可独立理解的连续视频提示词，300–500 个中文字符，不展示方案列表或分析。遇到要求冲突可以简短说明。'
$materials=@{}
$materialRecords=foreach ($condition in $conditions) {
    if ($condition.source) {
        $sourcePath=Join-Path $projectRoot $condition.source
        $frozenName=$condition.id+'.md'
        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path (Join-Path $trialRoot '冻结材料') $frozenName)
        $materials[$condition.id]=Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
        @{condition=$condition.id;original_source=$condition.source;frozen_file=('冻结材料/'+$frozenName);sha256=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant();characters=$materials[$condition.id].Length}
    }
}
$records=[System.Collections.Generic.List[object]]::new()
$number=0
foreach ($scene in $scenes) {
    foreach ($condition in $conditions) {
        $number++
        $requestId='P{0:D3}' -f $number
        $prompt="你是一位视觉艺术与动画创作助手。`n`n创作要求：`n$($scene.request)`n`n交付要求：`n$contract"
        if ($condition.source) { $prompt+="`n`n创作指令与可选构思资源（只按相关性使用，不是输出模板）：`n$($materials[$condition.id].Trim())" }
        $requestFile='请求/'+$requestId+'.md'
        Save-Text (Join-Path $trialRoot $requestFile) $prompt
        Save-Json (Join-Path $trialRoot ('请求/'+$requestId+'.json')) @{request_id=$requestId;messages=@(@{role='user';content=$prompt});status='prepared_not_executed'}
        $records.Add([pscustomobject]@{request_id=$requestId;scene=$scene.id;scene_kind=$scene.kind;condition=$condition.id;replicate=1;request_file=$requestFile;sha256=(Get-FileHash -LiteralPath (Join-Path $trialRoot $requestFile) -Algorithm SHA256).Hash.ToLowerInvariant();characters=$prompt.Length;status='prepared_not_executed'})
    }
}
$random=[System.Random]::new(20261010)
$order=@($records.ToArray())
for ($position=$order.Count-1;$position -gt 0;$position--) {
    $other=$random.Next($position+1);$swap=$order[$position];$order[$position]=$order[$other];$order[$other]=$swap
}
$sequence=for ($position=0;$position -lt $order.Count;$position++) {
    @{order=$position+1;request_id=$order[$position].request_id;review_id=('R{0:D3}' -f ($position+1));request_file=$order[$position].request_file;status='not_started'}
}
Save-Json (Join-Path $trialRoot '管理清单.json') @{trial_version='0.4-pilot-1';trial_name=$TrialName;created_at=[DateTimeOffset]::Now.ToString('o');request_count=$records.Count;replicates=1;randomization_seed=20261010;scenes=$scenes;conditions=$conditions;output_contract=$contract;materials=@($materialRecords);requests=@($records.ToArray());limitations=@('pilot_not_statistical_evidence','new_cases_are_public_at_execution','web_model_exact_backend_unknown','different_input_lengths')}
Save-Json (Join-Path $trialRoot '运行顺序.json') @($sequence)
Save-Json (Join-Path $trialRoot '运行状态.json') @{status='prepared_waiting_for_execution';completed_requests=0;submitted_requests=0;failed_requests=0;video_runs=0;platform='DeepSeek web';model_display_name=$null;backend_model_version=$null;thinking_mode=$null;search_mode=$null;context='one_new_conversation_per_request';notes=@()}
Save-Text (Join-Path $trialRoot 'README.md') "# DeepSeek v0.4 首轮试验`n`n16 个冻结请求：4 场景 × 4 条件 × 1 次。两类公开开发场景与两个新具体场景；不是严格盲测。所有请求目前未执行，实际数量以运行状态和原始输出记录为准。`n`n每个请求在独立新会话执行，同一模式、不联网搜索、不提供评审答案。保存原始可见回答和会话地址，完成后制作仅含评审编号与回答的评审材料。管理清单中的条件映射不提供给评审侧。首轮用于找明显问题，后续再重复和扩展。`n"
[pscustomobject]@{trial_directory=$trialRoot;requests=$records.Count;executed=0;frozen_materials=@($materialRecords).Count}|ConvertTo-Json
