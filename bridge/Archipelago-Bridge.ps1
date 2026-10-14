# Project Zomboid Archipelago prototype bridge. No Python or pip required.
# Outgoing WebSocket only; reads APCheckTracker_room.txt and APCheckTracker_locations.txt.
$ErrorActionPreference = 'Stop'
$luaDir = Join-Path $env:USERPROFILE 'Zomboid\Lua'
$configPath = Join-Path $luaDir 'APCheckTracker_room.txt'
$checksPath = Join-Path $luaDir 'APCheckTracker_locations.txt'
$rewardPath = Join-Path $luaDir 'APCheckTracker_rewards.txt'
$heartbeatPath = Join-Path $luaDir 'APCheckTracker_live.txt'
$sessionPath = Join-Path $luaDir 'APCheckTracker_session.txt'
$profilePath = Join-Path $luaDir 'APCheckTracker_profile.txt'
Write-Host 'Zomboid Archipelago Windows bridge v1.6 (three playstyles, server-verified seed)' 
Write-Host 'Configure server and slot in Project Zomboid with F10, then save.'
while (-not (Test-Path $configPath)) { Write-Host 'Waiting for F10 room settings...'; Start-Sleep 3 }
$lines = @(Get-Content -LiteralPath $configPath -Encoding UTF8)
if ($lines.Count -lt 3 -or $lines[0] -ne 'APROOM_V1') { throw 'Invalid room settings; open F10 and save again.' }
$server = $lines[1].Trim(); $slot = $lines[2].Trim(); $password = if ($lines.Count -gt 3) { $lines[3] } else { '' }; $seedRef = if ($lines.Count -gt 4) { $lines[4].Trim() } else { '' }
if ($server -notmatch '^wss?://') { $server = 'wss://' + $server }
$uri = [Uri]$server
# The server's actual seed identity is used after Connected; do not trust F10's legacy seed reference.
$runKey = ''
$rewardHeader = ''
$goalId = 0
$goalName = ''
$activePlaystyle = ''
$roomSeedName = ''
# A heartbeat proves that the bridge is currently connected, not just that an old snapshot exists.
function Write-Heartbeat {
    $stamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    [IO.File]::WriteAllText($heartbeatPath, ('APLIVE_V1|' + $runKey + '|' + $stamp), [Text.UTF8Encoding]::new($false))
}
# Invalidate stale live status immediately on bridge startup.
[IO.File]::WriteAllText($heartbeatPath, '', [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($sessionPath, '', [Text.UTF8Encoding]::new($false))
if ($uri.Scheme -ne 'wss' -and $uri.Host -notin @('localhost','127.0.0.1')) { throw 'Use wss:// for remote rooms (encrypted connection).' }
$validSet = [System.Collections.Generic.HashSet[int]]::new()
$mapping = @{
    '200001'=@('Base.TinnedBeans',24)
    '200002'=@('Base.Bandage',20)
    '200003'=@('Base.Axe',2)
    '200004'=@('Base.Bullets9mmBox',6)
    '200005'=@('Base.NailsBox',30)
    '200006'=@('Base.PetrolCan',2)
    '200008'=@('Base.ShotgunShellsBox',6)
    '200009'=@('Base.Shotgun',1)
    '200010'=@('Base.Generator',1)
    '200011'=@('Base.PropaneTank',2)
    '200012'=@('Base.Jack',1)
    '200013'=@('Base.HuntingRifle',1)
    '200014'=@('Base.Pills',8)
    '200015'=@('Base.SheetMetal',30)
    '200016'=@('Base.Saw',1)
    '200017'=@('Base.Hammer',3)
    '200018'=@('Base.NailsBox',30)
    '200019'=@('Base.Plank',60)
    '200020'=@('Base.Woodglue',8)
    '200021'=@('Base.ElectronicsScrap',40)
    '200022'=@('Base.Screwdriver',4)
    '200023'=@('Base.WeldingMask',2)
    '200024'=@('Base.WeldingRods',12)
    '200025'=@('Base.BroccoliSeed',20)
    '200026'=@('Base.Shovel',2)
    '200027'=@('Base.FishingRod',2)
    '200028'=@('Base.TinnedSoup',24)
    '200029'=@('Base.Coffee2',8)
    '200030'=@('Base.FirstAidKit',3)
    '200031'=@('Base.Disinfectant',8)
    '200032'=@('Base.WalkieTalkie4',3)
    '200033'=@('Base.LugWrench',2)
    '200034'=@('Base.Sledgehammer',1)
    '200035'=@('Base.Battery',16)
    '200036'=@('Base.WateringCan',3)
    '200037'=@('Base.Pot',4)
    '200038'=@('Base.Machete',2)
    '200039'=@('Base.Pillow',6)
    '200040'=@('Base.Axe',3)
}

function Escape-JsonString([string]$value) {
    if ($null -eq $value) { return '' }
    $builder = [System.Text.StringBuilder]::new()
    foreach ($ch in $value.ToCharArray()) {
        $n = [int]$ch
        if ($n -eq 34) { [void]$builder.Append('\"') }
        elseif ($n -eq 92) { [void]$builder.Append('\\') }
        elseif ($n -lt 32) { [void]$builder.Append(('\u{0:x4}' -f $n)) }
        else { [void]$builder.Append($ch) }
    }
    return $builder.ToString()
}
function Send-Packet($ws, $packet) {
    $command = [string]$packet['cmd']
    Write-Host ("Preparing packet: " + $command) -ForegroundColor DarkCyan
    # Construct the small set of supported AP commands directly.
    # Avoid ConvertTo-Json on nested PowerShell hashtables (hang in previous build).
    switch ($command) {
        'Connect' {
            $n = Escape-JsonString ([string]$packet['name'])
            $p = Escape-JsonString ([string]$packet['password'])
            $json = '[{"cmd":"Connect","game":"Project Zomboid","name":"' + $n + '","password":"' + $p + '","uuid":"pz-b42-ps-bridge","version":{"major":0,"minor":6,"build":8,"class":"Version"},"items_handling":7,"tags":[]}]'
        }
        'Sync' { $json = '[{"cmd":"Sync"}]' }
        'StatusUpdate' { $json = '[{"cmd":"StatusUpdate","status":30}]' }
        'LocationChecks' {
            $ids = @($packet['locations'] | ForEach-Object { [string][int]$_ }) -join ','
            $json = '[{"cmd":"LocationChecks","locations":[' + $ids + ']}]'
        }
        default { throw "Unsupported packet command: $command" }
    }
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    Write-Host ("Sending packet: " + $command + " (" + $bytes.Length + " bytes)") -ForegroundColor Cyan
    $segment = [ArraySegment[byte]]::new($bytes)
    $cts = [Threading.CancellationTokenSource]::new()
    $cts.CancelAfter(5000)
    try {
        $task = $ws.SendAsync($segment,[Net.WebSockets.WebSocketMessageType]::Text,$true,$cts.Token)
        $deadline = [DateTime]::UtcNow.AddSeconds(6)
        while (-not $task.IsCompleted -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 50 }
        if (-not $task.IsCompleted) { throw 'WebSocket send timed out after 6 seconds' }
        $task.GetAwaiter().GetResult() | Out-Null
        Write-Host 'Packet sent successfully.' -ForegroundColor Green
    } finally { $cts.Dispose() }
}

function Read-Checks {
    $set = [System.Collections.Generic.HashSet[int]]::new()
    if (-not (Test-Path $checksPath)) { return ,$set }
    $lines = @(Get-Content -LiteralPath $checksPath -Encoding UTF8 -ErrorAction SilentlyContinue)
    if ($lines.Count -lt 2 -or $lines[0] -ne ('APCHECKS_V2|' + $activePlaystyle)) { return ,$set }
    foreach ($line in $lines[1..($lines.Count-1)]) {
        $num = 0
        if ([int]::TryParse($line,[ref]$num) -and $validSet.Contains($num)) { [void]$set.Add($num) }
    }
    return ,$set
}
function Save-Rewards($received) {
    $out = [Collections.Generic.List[string]]::new()
    $out.Add($rewardHeader)
    foreach ($index in @($received.Keys | Sort-Object {[int]$_})) {
        $entry = $received[$index]
        if ($mapping.ContainsKey([string]$entry.item)) {
            $r = $mapping[[string]$entry.item]
            $remaining = [int]$r[1]
            $part = 0
            while ($remaining -gt 0) {
                $part++
                $quantity = [Math]::Min(10, $remaining)
                # Keep unique claim IDs for individual portions of one AP item.
                $claimId = ([long]$index * 100) + $part
                $out.Add("$claimId|$($r[0])|$quantity|$($entry.player)")
                $remaining -= $quantity
            }
        }
    }
    $tmp = "$rewardPath.tmp"
    [IO.File]::WriteAllLines($tmp,$out,[Text.UTF8Encoding]::new($false))
    Move-Item -Force -LiteralPath $tmp -Destination $rewardPath
}
while ($true) {
    $ws = [Net.WebSockets.ClientWebSocket]::new()
    try {
        Write-Host "Connecting to $server as $slot ..."
        [void]$ws.ConnectAsync($uri,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
        Write-Host 'WebSocket connected; waiting for Archipelago RoomInfo...' -ForegroundColor Cyan
        $connected=$false
        $remote=[System.Collections.Generic.HashSet[int]]::new()
        $sent=[System.Collections.Generic.HashSet[int]]::new()
        $received=@{}
        $goalSent=$false
        $buffer=New-Object byte[] 262144
        $segment=[ArraySegment[byte]]::new($buffer)
        $pending=$ws.ReceiveAsync($segment,[Threading.CancellationToken]::None)
        $handshakeStart=[DateTime]::UtcNow
        $chunks=[Collections.Generic.List[byte]]::new()
        while ($ws.State -eq [Net.WebSockets.WebSocketState]::Open) {
            if (-not $connected -and ([DateTime]::UtcNow - $handshakeStart).TotalSeconds -gt 15) { throw 'No Archipelago login confirmation within 15 seconds. Verify room is running and server URL/protocol is correct.' }
            if ($pending.Wait(250)) {
                $result=$pending.GetAwaiter().GetResult()
                if ($result.MessageType -eq [Net.WebSockets.WebSocketMessageType]::Close) { throw 'Server closed the connection' }
                for ($i=0; $i -lt $result.Count; $i++) { $chunks.Add($buffer[$i]) }
                if ($result.EndOfMessage) {
                    $raw=[Text.Encoding]::UTF8.GetString($chunks.ToArray()); $chunks.Clear()
                    Write-Host ('Server message: ' + $raw.Substring(0,[Math]::Min(400,$raw.Length)))
                    Write-Host 'Parsing server response...' -ForegroundColor DarkCyan
                    $packets=ConvertFrom-Json -InputObject $raw
                    foreach ($packet in @($packets)) {
                        switch ($packet.cmd) {
                            'RoomInfo' {
                                $roomSeedName = [string]$packet.seed_name
                                Write-Host 'RoomInfo received; sending slot login...' -ForegroundColor Cyan
                                Send-Packet $ws @{cmd='Connect';game='Project Zomboid';name=$slot;password=$password;uuid='pz-b42-ps-bridge';version=@{major=0;minor=6;build=8;class='Version'};items_handling=7;tags=@()}
                                Write-Host 'Login packet submitted; waiting for Connected or ConnectionRefused...' -ForegroundColor Cyan
                            }
                            'Connected' {
                                # Slot_data was written by THIS APWorld while generating the seed.
                                # Reject stale rooms or installing the wrong profile's Lua mod.
                                $data = $packet.slot_data
                                if ($null -eq $data -or [int]$data.bridge_version -lt 3) {
                                    throw 'This room uses an older APWorld. Install v1.6 .apworld and generate a NEW multiworld.'
                                }
                                $activePlaystyle = [string]$data.playstyle
                                if ($activePlaystyle -notin @('base_building','local_exploration','road_trip')) {
                                    throw "Unknown generated playstyle: $activePlaystyle"
                                }
                                if (-not (Test-Path $profilePath)) {
                                    throw 'Start Zomboid with the matching v1.6 mod and wait for F8 before starting the bridge.'
                                }
                                $profileLines = @(Get-Content -LiteralPath $profilePath -Encoding UTF8)
                                if ($profileLines.Count -lt 2 -or $profileLines[0] -ne 'APSTYLE_V1' -or $profileLines[1].Trim() -ne $activePlaystyle) {
                                    throw "Wrong Project Zomboid mod loaded. Multiworld requires '$activePlaystyle'; install that playstyle's mod folder."
                                }
                                $validSet.Clear()
                                foreach ($id in @($data.location_ids)) { [void]$validSet.Add([int]$id) }
                                if ($validSet.Count -ne [int]$data.check_count) { throw 'Invalid slot location list in generated multiworld.' }
                                $goalId = [int]$data.goal_location_id
                                if (-not $validSet.Contains($goalId)) { throw 'Victory location is missing from the generated checks.' }
                                $goalName = $activePlaystyle
                                if ([string]::IsNullOrWhiteSpace($roomSeedName)) { throw 'Archipelago did not provide a seed identity.' }
                                $runKey = $server.ToLowerInvariant() + '|' + $slot.ToLowerInvariant() + '|' + $roomSeedName + '|' + [string]$packet.team + '|' + [string]$packet.slot
                                $rewardHeader = 'APREWARDS_V3|' + $runKey
                                $connected=$true; $remote.Clear(); $sent.Clear()
                                # Publish the verified room BEFORE making the reward stash live.
                                [IO.File]::WriteAllLines($sessionPath, [string[]]@('APSESSION_V1',$server,$slot,$runKey), [Text.UTF8Encoding]::new($false))
                                $received=@{}; Save-Rewards $received
                                Write-Heartbeat
                                foreach ($id in @($packet.checked_locations)) { [void]$remote.Add([int]$id) }
                                Send-Packet $ws @{cmd='Sync'}
                                Write-Host "Connected! Playstyle: $activePlaystyle, $($validSet.Count) checks, goal ID: $goalId, seed: $roomSeedName" -ForegroundColor Green
                            }
                            'ConnectionRefused' { throw "Connection refused: $($packet.errors -join ', ')" }
                            'ReceivedItems' {
                                $idx=[int]$packet.index
                                foreach ($item in @($packet.items)) {
                                    $received[[string]$idx]=@{item=[int]$item.item;player=[string]$item.player}
                                    $idx++
                                }
                                Save-Rewards $received
                                Write-Host "Received $($received.Count) item entries. Open F9 in Zomboid."
                            }
                            'RoomUpdate' {
                                foreach ($id in @($packet.checked_locations)) { [void]$remote.Add([int]$id) }
                            }
                        }
                    }
                }
                $pending=$ws.ReceiveAsync($segment,[Threading.CancellationToken]::None)
            }
            if ($connected) {
                Write-Heartbeat
                $checks=Read-Checks
                if (-not $goalSent -and $checks.Contains($goalId) -and $remote.Contains($goalId)) {
                    Send-Packet $ws @{cmd='StatusUpdate';status=30}
                    $goalSent=$true
                    Write-Host "VICTORY ($goalName)! Goal completion sent to Archipelago." -ForegroundColor Green
                }
                $new=[Collections.Generic.List[int]]::new()
                foreach ($id in $checks) {
                    if ($validSet.Contains($id) -and -not $remote.Contains($id) -and -not $sent.Contains($id)) { $new.Add($id) }
                }
                if ($new.Count -gt 0) {
                    Send-Packet $ws @{cmd='LocationChecks';locations=@($new.ToArray())}
                    foreach ($id in $new) { [void]$sent.Add($id) }
                    Write-Host "Sent $($new.Count) checks"
                }
            }
        }
    } catch { Write-Warning ($_.Exception.ToString()) }
    finally {
        [IO.File]::WriteAllText($heartbeatPath, '', [Text.UTF8Encoding]::new($false))
        $ws.Dispose()
    }
    Write-Host 'Retrying in 5 seconds (Ctrl+C to stop)...'
    Start-Sleep 5
}
