Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===== Script Directory =====
# EXE化対応: 複数の方法でスクリプト/EXEのディレクトリを取得
if ($MyInvocation.MyCommand.Path) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($PSScriptRoot) {
    $scriptDir = $PSScriptRoot
} else {
    # EXE化された場合
    $scriptDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
$ytdlpPath = Join-Path $scriptDir "yt-dlp.exe"

# yt-dlpが見つからない場合のチェック
if (-not (Test-Path $ytdlpPath)) {
    [System.Windows.Forms.MessageBox]::Show("yt-dlp.exe not found in: $scriptDir", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

# ===== Form =====
$form = New-Object System.Windows.Forms.Form
$form.Text = "VideoAudioDownloader"
$form.Size = New-Object System.Drawing.Size(360, 450)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 12)

# ===== Mode Group =====
$groupMode = New-Object System.Windows.Forms.GroupBox
$groupMode.Text = "Mode"
$groupMode.Location = New-Object System.Drawing.Point(10, 10)
$groupMode.Size = New-Object System.Drawing.Size(320, 80)

$radioVideo = New-Object System.Windows.Forms.RadioButton
$radioVideo.Text = "video"
$radioVideo.Size = New-Object System.Drawing.Size(80, 25)
$radioVideo.Location = New-Object System.Drawing.Point(20, 30)
$radioVideo.Checked = $true

$radioAudio = New-Object System.Windows.Forms.RadioButton
$radioAudio.Text = "audio"
$radioAudio.Size = New-Object System.Drawing.Size(80, 25)
$radioAudio.Location = New-Object System.Drawing.Point(120, 30)

$radioBoth = New-Object System.Windows.Forms.RadioButton
$radioBoth.Text = "both"
$radioBoth.Size = New-Object System.Drawing.Size(80, 25)
$radioBoth.Location = New-Object System.Drawing.Point(220, 30)

$groupMode.Controls.AddRange(@($radioVideo, $radioAudio, $radioBoth))
$form.Controls.Add($groupMode)

# ===== Audio Format Group =====
$groupFormat = New-Object System.Windows.Forms.GroupBox
$groupFormat.Text = "Audio Format"
$groupFormat.Location = New-Object System.Drawing.Point(10, 100)
$groupFormat.Size = New-Object System.Drawing.Size(320, 60)
$groupFormat.Enabled = $false

$radioMp3 = New-Object System.Windows.Forms.RadioButton
$radioMp3.Text = "mp3"
$radioMp3.Size = New-Object System.Drawing.Size(80, 25)
$radioMp3.Location = New-Object System.Drawing.Point(20, 25)
$radioMp3.Checked = $true

$radioM4a = New-Object System.Windows.Forms.RadioButton
$radioM4a.Text = "m4a"
$radioM4a.Size = New-Object System.Drawing.Size(80, 25)
$radioM4a.Location = New-Object System.Drawing.Point(120, 25)

$groupFormat.Controls.AddRange(@($radioMp3, $radioM4a))
$form.Controls.Add($groupFormat)

# audio 選択時のみ有効化
$radioAudio.Add_CheckedChanged({ $groupFormat.Enabled = $true })
$radioVideo.Add_CheckedChanged({ $groupFormat.Enabled = $false })
$radioBoth.Add_CheckedChanged({ $groupFormat.Enabled = $true})

# ===== Filename =====
$labelFilename = New-Object System.Windows.Forms.Label
$labelFilename.Text = "Filename"
$labelFilename.AutoSize = $true
$labelFilename.Location = New-Object System.Drawing.Point(10, 180)
$form.Controls.Add($labelFilename)

$textFilename = New-Object System.Windows.Forms.TextBox
$textFilename.Location = New-Object System.Drawing.Point(100, 175)
$textFilename.Size = New-Object System.Drawing.Size(230, 30)
$form.Controls.Add($textFilename)

# ===== URL =====
$labelURL = New-Object System.Windows.Forms.Label
$labelURL.Text = "URL"
$labelURL.AutoSize = $true
$labelURL.Location = New-Object System.Drawing.Point(10, 220)
$form.Controls.Add($labelURL)

$textURL = New-Object System.Windows.Forms.TextBox
$textURL.Location = New-Object System.Drawing.Point(100, 215)
$textURL.Size = New-Object System.Drawing.Size(230, 30)
$form.Controls.Add($textURL)

# ===== Show Console Checkbox =====
$chkShowConsole = New-Object System.Windows.Forms.CheckBox
$chkShowConsole.Text = "Show Console"
$chkShowConsole.Location = New-Object System.Drawing.Point(10, 255)
$chkShowConsole.Size = New-Object System.Drawing.Size(150, 25)
$chkShowConsole.Checked = $false
$form.Controls.Add($chkShowConsole)

# ===== ProgressBar =====
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(10, 285)
$progress.Size = New-Object System.Drawing.Size(320, 20)
$progress.Style = 'Marquee'
$progress.Visible = $false
$form.Controls.Add($progress)

# ===== Buttons =====
$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "OK"
$btnOK.Location = New-Object System.Drawing.Point(70, 320)
$btnOK.Size = New-Object System.Drawing.Size(90, 30)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Location = New-Object System.Drawing.Point(200, 320)
$btnCancel.Size = New-Object System.Drawing.Size(90, 30)

$form.Controls.AddRange(@($btnOK, $btnCancel))

# ===== Process and Timer =====
$script:downloadProcess = $null

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 500

$timer.Add_Tick({
    if ($null -ne $script:downloadProcess -and $script:downloadProcess.HasExited) {
        $timer.Stop()
        
        # バッチファイルを削除
        $batchFile = Join-Path $scriptDir "temp_download.bat"
        if (Test-Path $batchFile) {
            Remove-Item $batchFile -Force
        }
        
        $progress.Visible = $false
        $btnOK.Enabled = $true
        $groupMode.Enabled = $true
        $groupFormat.Enabled = $radioAudio.Checked -or $radioBoth.Checked
        $textFilename.Enabled = $true
        $textURL.Enabled = $true
        $textURL.Text = ""
        $textFilename.Text = ""
        $script:downloadProcess = $null
        [System.Windows.Forms.MessageBox]::Show("Download completed!")
    }
})

# ===== OK Click =====
$btnOK.Add_Click({
    if ($textURL.Text -eq "") {
        [System.Windows.Forms.MessageBox]::Show("Please enter URL.")
        return
    }

    $btnOK.Enabled = $false
    $groupMode.Enabled = $false
    $groupFormat.Enabled = $false
    $textFilename.Enabled = $false
    $textURL.Enabled = $false
    $progress.Visible = $true

    $Mode = if ($radioVideo.Checked) { "video" } elseif ($radioAudio.Checked) { "audio" } else { "both" }
    $Format = if ($radioMp3.Checked) { "mp3" } else { "m4a" }
    $URL = $textURL.Text

    if ($textFilename.Text -ne "") {
        $NameOpt = "-o `"$($textFilename.Text).%(ext)s`""
    } else {
        $NameOpt = "-o `"%(title)s.%(ext)s`""
    }

    $baseArgs = "--js-runtimes node --extractor-args `"youtube:player_client=android`""

    switch ($Mode) {
        "video" {
            $arguments = "$baseArgs -f `"bv*[height<=1080]+ba/b`" $NameOpt --merge-output-format mp4 `"$URL`""
        }
        "audio" {
            $arguments = "$baseArgs -f `"ba/b`" -x --audio-format $Format --audio-quality 0 $NameOpt `"$URL`""
        }
        "both" {
            # For "both", we run audio first, then video. Use a batch script.
            # バッチファイルでは % を %% にエスケープする必要がある
            $NameOptBat = $NameOpt -replace '%', '%%'
            $audioArgs = "$baseArgs -f `"ba/b`" -x --audio-format $Format --audio-quality 0 $NameOptBat `"$URL`""
            $videoArgs = "$baseArgs -f `"bv*[height<=1080]+ba/b`" $NameOptBat --merge-output-format mp4 `"$URL`""
            $batchContent = "@echo off`r`nchcp 65001 >nul`r`n`"$ytdlpPath`" $audioArgs`r`n`"$ytdlpPath`" $videoArgs"
            $batchFile = Join-Path $scriptDir "temp_download.bat"
            Set-Content -Path $batchFile -Value $batchContent -Encoding UTF8
            $winStyle = if ($chkShowConsole.Checked) { "Normal" } else { "Hidden" }
            $script:downloadProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFile`"" -WorkingDirectory $scriptDir -PassThru -WindowStyle $winStyle
            $timer.Start()
            return
        }
    }

    $winStyle = if ($chkShowConsole.Checked) { "Normal" } else { "Hidden" }
    $script:downloadProcess = Start-Process -FilePath $ytdlpPath -ArgumentList $arguments -WorkingDirectory $scriptDir -PassThru -WindowStyle $winStyle
    $timer.Start()
})

# ===== Cancel Click =====
$btnCancel.Add_Click({ 
    if ($null -ne $script:downloadProcess) {
        $script:downloadProcess.Kill()
        $script:downloadProcess = $null
        $timer.Stop()
        
        # バッチファイルを削除
        $batchFile = Join-Path $scriptDir "temp_download.bat"
        if (Test-Path $batchFile) {
            Remove-Item $batchFile -Force
        }
        
        $progress.Visible = $false
        $btnOK.Enabled = $true
        $groupMode.Enabled = $true
        $groupFormat.Enabled = $radioAudio.Checked -or $radioBoth.Checked
        $textFilename.Enabled = $true
        $textURL.Enabled = $true
    }
    else{
        $form.Close()
    } })

# ===== Show Form =====
[void]$form.ShowDialog()
