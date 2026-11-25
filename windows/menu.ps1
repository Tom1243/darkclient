$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
$stateDir = Join-Path $env:LOCALAPPDATA 'OpenDarkEden'
[void](New-Item -ItemType Directory -Force $stateDir)
$settings = Join-Path $stateDir 'client.txt'
$compose = Join-Path $PSScriptRoot 'server\standalone\compose.yaml'
function Stack([string[]]$Arguments) {
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Install and start Docker Desktop with Linux containers to host a world.' }
    & docker compose -f $compose @Arguments
    if ($LASTEXITCODE) { throw 'Docker failed. See the accompanying console for details.' }
}
function Address {
    $ip = $address.Text.Trim()
    $parsed = $null
    if ($ip -notmatch '^(\d{1,3}\.){3}\d{1,3}$' -or ![Net.IPAddress]::TryParse($ip,[ref]$parsed)) { throw 'Enter a valid IPv4 address.' }
    return $ip
}
function LaunchGame {
    $ip = Address
    $dir = if (Test-Path $settings) { Get-Content -LiteralPath $settings -Raw }
    if (!$dir -or !(Test-Path -LiteralPath (Join-Path $dir 'fengshen.exe'))) {
        $pick = New-Object Windows.Forms.OpenFileDialog
        $pick.Title = 'Select fengshen.exe from your extracted DARKEDEN game folder'
        $pick.Filter = 'Dark Eden client|fengshen.exe'
        if ($pick.ShowDialog() -ne 'OK') { return }
        $dir = Split-Path $pick.FileName
        [IO.File]::WriteAllText($settings,$dir)
    }
    $file = Join-Path $dir 'Data\Info\GameClient.inf'
    $enc = [Text.Encoding]::GetEncoding(28591)
    $original = [IO.File]::ReadAllText($file,$enc)
    $key = '(?im)^(\s*LoginServerAddress\d*\s*[:=]\s*)[^\s#;]+'
    if ($original -notmatch $key) { throw 'This GameClient.inf has no recognized LoginServerAddress setting.' }
    $updated = [regex]::Replace($original,$key,('${1}'+$ip))
    $updated = [regex]::Replace($updated,'(?im)^(\s*LoginServerPort\s*[:=]\s*)\d+','${1}9999')
    $updated = [regex]::Replace($updated,'(?im)^(\s*LoginServerPortNum\s*[:=]\s*)\d+','${1}1')
    if ($updated -cne $original) {
        if (!(Test-Path "$file.original")) { Copy-Item -LiteralPath $file -Destination "$file.original" }
        [IO.File]::WriteAllText($file,$updated,$enc)
    }
    # Use the client's own launcher script so this path behaves exactly like
    # double-clicking window.bat (which can set up launch details for this build).
    $batch = Join-Path $dir 'window.bat'
    if (Test-Path -LiteralPath $batch) {
        Start-Process -FilePath $env:ComSpec -WorkingDirectory $dir -WindowStyle Hidden -ArgumentList '/d','/c','window.bat'
    } else {
        Start-Process -FilePath (Join-Path $dir 'fengshen.exe') -WorkingDirectory $dir -ArgumentList '0000000001'
    }
}
$form = New-Object Windows.Forms.Form
$form.Text = 'Dark Eden'
$form.ClientSize = New-Object Drawing.Size(420,360)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
function Label($text,$y) {
    $label = New-Object Windows.Forms.Label
    $label.Text = $text
    $label.SetBounds(20,$y,382,22)
    $form.Controls.Add($label)
}
function Button($text,$x,$y,$width,$action) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $text
    $b.SetBounds($x,$y,$width,34)
    $b.Tag = $action
    $b.Add_Click({ param($sender,$event)
        try { $action = $sender.Tag; & $action } catch { [void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'Dark Eden') }
    })
    $form.Controls.Add($b)
}
Label 'Server IPv4 address (use 127.0.0.1 for solo play)' 20
$address = New-Object Windows.Forms.TextBox
$address.SetBounds(20,45,380,28)
$address.Text = '127.0.0.1'
$form.Controls.Add($address)
Button 'Play / join world' 20 85 380 { LaunchGame }
Label 'Host a world on this PC' 144
Button 'Start server' 20 170 185 {
    $env:DARKEDEN_IP = Address
    $env:DARKEDEN_BIND = if ($env:DARKEDEN_IP -eq '127.0.0.1') { '127.0.0.1' } else { '0.0.0.0' }
    Stack @('up','-d','--wait')
    [void][Windows.Forms.MessageBox]::Show('World ready. Create a player, then choose Play.','Dark Eden')
}
Button 'Stop server' 215 170 185 { Stack @('down') }
Button 'Create player' 20 215 380 {
    $name = $player.Text
    $pass = $secret.Text
    if ($name -cnotmatch '^[a-zA-Z0-9]{4,10}$' -or $pass -cnotmatch '^[a-zA-Z0-9]{6,10}$') { throw 'Use 4-10 letters or digits for the ID and 6-10 for the password.' }
    @($name,$pass) | docker compose -f $compose exec -T odk-mysql bash /opt/darkeden-admin add-player
    if ($LASTEXITCODE) { throw 'Could not create player. Check the server is running and choose an unused ID.' }
    $secret.Clear()
    [void][Windows.Forms.MessageBox]::Show('Player created.','Dark Eden')
}
Label 'Player ID                                   Game password' 263
$player = New-Object Windows.Forms.TextBox
$secret = New-Object Windows.Forms.TextBox
$player.SetBounds(20,286,185,28)
$secret.SetBounds(215,286,185,28)
$secret.UseSystemPasswordChar = $true
$form.Controls.AddRange(@($player,$secret))
[void]$form.ShowDialog()
