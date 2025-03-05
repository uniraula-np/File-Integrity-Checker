Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "File Integrity - Hashcapture runner"
$form.Size = New-Object System.Drawing.Size(720, 600)
$form.StartPosition = "CenterScreen"
# Create a banner label
$bannerLabel = New-Object System.Windows.Forms.Label
$bannerLabel.Text = "Welcome to Files/Folder integrity checker and copying folder - Created by UtsabN"
$bannerLabel.AutoSize = $true
$bannerLabel.Location = New-Object System.Drawing.Point(20, 20)
$bannerLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($bannerLabel)
# Create output text box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 264)
$outputBox.Size = New-Object System.Drawing.Size(648, 240)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)
# Get the current folder path where the GUI script is running
$scriptFolder = $PSScriptRoot
# Function to run scripts and capture output
function Run-ScriptAndShowOutput {
   param(
		$scriptName,
		$display
	)
   $outputBox.AppendText("`r`n=== Running Script: $display ===`r`n")
   $scriptPath = Join-Path -Path $scriptFolder -ChildPath $scriptName
   try {
       # Capture output from the script
       $scriptOutput = & $scriptPath 2>&1 | Out-String
       # Display in output box
       $outputBox.AppendText("$scriptOutput`r`n")
   }
   catch {
       $outputBox.AppendText("ERROR: $_`r`n")
   }
   # Auto-scroll to bottom
   $outputBox.SelectionStart = $outputBox.Text.Length
   $outputBox.ScrollToCaret()
}
# Create buttons to run the scripts
#Button1
$button1 = New-Object System.Windows.Forms.Button
$button1.Text = "Run HashCompare"
$button1.Location = New-Object System.Drawing.Point(20, 60)
$button1.Size = New-Object System.Drawing.Size(150, 30)
$button1.Add_Click({ Run-ScriptAndShowOutput -scriptName "HashCompare.ps1" -display "Hash comparision of Folders" })
$form.Controls.Add($button1)
#Button 2
$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "Run HashFile"
$button2.Location = New-Object System.Drawing.Point(20, 110)
$button2.Size = New-Object System.Drawing.Size(150, 30)
$button2.Add_Click({ Run-ScriptAndShowOutput -scriptName "HashFile.ps1" -display "Hash creation of selected File/Files" })
$form.Controls.Add($button2)
#Button 3
$button3 = New-Object System.Windows.Forms.Button
$button3.Text = "Run HashFolder"
$button3.Location = New-Object System.Drawing.Point(20, 160)
$button3.Size = New-Object System.Drawing.Size(150, 30)
$button3.Add_Click({ Run-ScriptAndShowOutput -scriptName "HashFolder.ps1" -display "Hash creation of a Folder" })
$form.Controls.Add($button3)
#Button 4
$button4 = New-Object System.Windows.Forms.Button
$button4.Text = "ROBOCOPY files/folder"
$button4.Location = New-Object System.Drawing.Point(20, 210)
$button4.Size = New-Object System.Drawing.Size(150, 30)
$button4.Add_Click({ Run-ScriptAndShowOutput -scriptName "FileCopyAssistant.ps1" -display "Copying folder using ROBOCOPY" })
$form.Controls.Add($button4)
# Add clear button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear Output"
$clearButton.Location = New-Object System.Drawing.Point(515, 210)
$clearButton.Size = New-Object System.Drawing.Size(150, 30)
$clearButton.Add_Click({ $outputBox.Clear() })
$form.Controls.Add($clearButton)
# Show the form
$form.ShowDialog()
