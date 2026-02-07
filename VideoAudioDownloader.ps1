Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# フォーム
$form = New-Object System.Windows.Forms.Form
$form.Text = "VideoAudioDownloader"
$form.Size = New-Object System.Drawing.Size(330,400)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 18)

# ラジオボタン用グループ
$groupMode = New-Object System.Windows.Forms.GroupBox
$groupMode.Text = "Mode"
$groupMode.Location = New-Object System.Drawing.Point(10,10)
$groupMode.Size = New-Object System.Drawing.Size(150,180)

$radioVideo = New-Object System.Windows.Forms.RadioButton
$radioVideo.Text = "video"
$radioVideo.Location = New-Object System.Drawing.Point(15,40)
$radioVideo.Checked = $true

$radioAudio = New-Object System.Windows.Forms.RadioButton
$radioAudio.Text = "audio"
$radioAudio.Location = New-Object System.Drawing.Point(15,80)

$radioBoth = New-Object System.Windows.Forms.RadioButton
$radioBoth.Text = "both"
$radioBoth.Location = New-Object System.Drawing.Point(15,120)

$groupMode.Controls.AddRange(@($radioVideo,$radioAudio,$radioBoth))

# フォーマット用グループ（最初は非表示）
$groupFormat = New-Object System.Windows.Forms.GroupBox
$groupFormat.Text = "Audio Format"
$groupFormat.Location = New-Object System.Drawing.Point(160,10)
$groupFormat.Size = New-Object System.Drawing.Size(150,180)
$groupFormat.Visible = $false

$radioMp3 = New-Object System.Windows.Forms.RadioButton
$radioMp3.Text = "mp3"
$radioMp3.Location = New-Object System.Drawing.Point(15,40)
$radioMp3.Checked = $true

$radioM4a = New-Object System.Windows.Forms.RadioButton
$radioM4a.Text = "m4a"
$radioM4a.Location = New-Object System.Drawing.Point(15,80)

$groupFormat.Controls.AddRange(@($radioMp3,$radioM4a))
$form.Controls.Add($groupFormat)


# filename ラベル
$labelFilename = New-Object System.Windows.Forms.Label
$labelFilename.Text = "filename"
$labelFilename.Location = New-Object System.Drawing.Point(15,200)
$labelFilename.AutoSize = $true

# テキストボックス
$textFilename = New-Object System.Windows.Forms.TextBox
$textFilename.Location = New-Object System.Drawing.Point(120,205)
$textFilename.Size = New-Object System.Drawing.Size(180,20)
$textFilename.Font = New-Object System.Drawing.Font("Segoe UI", 11)

# URL ラベル
$labelURL = New-Object System.Windows.Forms.Label
$labelURL.Text = "URL"
$labelURL.Location = New-Object System.Drawing.Point(15,240)
$labelURL.AutoSize = $true

# テキストボックス
$textURL = New-Object System.Windows.Forms.TextBox
$textURL.Location = New-Object System.Drawing.Point(120,245)
$textURL.Size = New-Object System.Drawing.Size(180,20)
$textURL.Font = New-Object System.Drawing.Font("Segoe UI", 11)

# OK ボタン
$btnOK = New-Object System.Windows.Forms.Button
$btnOK.Text = "OK"
$btnOK.Location = New-Object System.Drawing.Point(70,300)
$btnOK.Size = New-Object System.Drawing.Size(90,30)
$btnOK.Add_Click({
    if($textURL.Text -eq ""){
        [System.Windows.Forms.MessageBox]::Show("Please enter URL.")
        return
    }
    $groupMode.Enabled  = $false
    $groupFormat.Enabled = $false
    $textFilename.Enabled   = $false
    $textURL.Enabled    = $false
    $btnOK.Enabled      = $false
    $btnCancel.Enabled  = $false

    $URL = $textURL.Text
    $nameopt = @("-o","%(title)s.%(ext)s")
    if($textFilename.Text -ne ""){
        $nameopt = @("-o", "$($textFilename.Text).%(ext)s")
    }
    if ($radioVideo.Checked) { $mode = "video" }
    elseif ($radioAudio.Checked) { 
        $mode = "audio" 
        $Format = if ($radioMp3.Checked) { "mp3" } else { "m4a" }
    }
    else { 
        $mode = "both" 
        $Format = if ($radioMp3.Checked) { "mp3" } else { "m4a" }
    }

    switch ($mode) {
        "video" {
           .\yt-dlp.exe --js-runtimes node --extractor-args "youtube:player_client=android" -f "bv*[height<=1080]+ba/b" @nameopt --merge-output-format mp4 $URL
        }
        "audio" {
           .\yt-dlp.exe --js-runtimes node --extractor-args "youtube:player_client=android" -f "ba/b" -x --audio-format $Format --audio-quality 0 @nameopt $URL
       }
        "both" {
           .\yt-dlp.exe --js-runtimes node --extractor-args "youtube:player_client=android" -f "ba/b" -x --audio-format $Format --audio-quality 0 @nameopt $URL
           .\yt-dlp.exe --js-runtimes node --extractor-args "youtube:player_client=android" -f "bv*[height<=1080]+ba/b" @nameopt --merge-output-format mp4 $URL
        }
    }
    
    $groupMode.Enabled  = $true
    $groupFormat.Enabled = $true
    $textFilename.Enabled   = $true
    $textURL.Enabled    = $true
    $btnOK.Enabled      = $true
    $btnCancel.Enabled  = $true
    $textURL.Text = ""
    $textFilename.Text = ""
})

# Cancel ボタン
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Location = New-Object System.Drawing.Point(170,300)
$btnCancel.Size = New-Object System.Drawing.Size(90,30)
$btnCancel.Add_Click({ 
    $form.Close()
})

# フォームに追加
$form.Controls.AddRange(@(
    $groupMode,
    $groupFormat,
    $labelFilename,
    $textFilename,
    $labelURL,
    $textURL,
    $btnOK,
    $btnCancel
))

$radioVideo.Add_CheckedChanged({
    if ($radioVideo.Checked) {
        $groupFormat.Visible = $false
    }
})

$radioAudio.Add_CheckedChanged({
    if ($radioAudio.Checked) {
        $groupFormat.Visible = $true
    }
})

$radioBoth.Add_CheckedChanged({
    if ($radioBoth.Checked) {
        $groupFormat.Visible = $true
    }
})


# 表示
[void]$form.ShowDialog()
