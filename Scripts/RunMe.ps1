Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "File Integrity - Hashcapture runner"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
# Create a banner label
$bannerLabel = New-Object System.Windows.Forms.Label
$bannerLabel.Text = "Welcome to Files/Folder integrity checker - Created by UtsabN"
$bannerLabel.AutoSize = $true
$bannerLabel.Location = New-Object System.Drawing.Point(20, 20)
$bannerLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($bannerLabel)
# Create output text box
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 220)
$outputBox.Size = New-Object System.Drawing.Size(540, 200)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)
# Get the current folder path where the GUI script is running
$scriptFolder = $PSScriptRoot
# Function to run scripts and capture output
function Run-ScriptAndShowOutput {
   param($scriptName)
   $outputBox.AppendText("`r`n=== Running $scriptName ===`r`n")
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
$button1 = New-Object System.Windows.Forms.Button
$button1.Text = "Run HashCompare"
$button1.Location = New-Object System.Drawing.Point(20, 80)
$button1.Size = New-Object System.Drawing.Size(150, 30)
$button1.Add_Click({ Run-ScriptAndShowOutput -scriptName "HashCompare.ps1" })
$form.Controls.Add($button1)
$button2 = New-Object System.Windows.Forms.Button
$button2.Text = "Run HashFile"
$button2.Location = New-Object System.Drawing.Point(20, 130)
$button2.Size = New-Object System.Drawing.Size(150, 30)
$button2.Add_Click({ Run-ScriptAndShowOutput -scriptName "HashFile.ps1" })
$form.Controls.Add($button2)
$button3 = New-Object System.Windows.Forms.Button
$button3.Text = "Run HashFolder"
$button3.Location = New-Object System.Drawing.Point(20, 180)
$button3.Size = New-Object System.Drawing.Size(150, 30)
$button3.Add_Click({ Run-ScriptAndShowOutput -scriptName "HashFolder.ps1" })
$form.Controls.Add($button3)
# Add clear button
$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear Output"
$clearButton.Location = New-Object System.Drawing.Point(400, 180)
$clearButton.Size = New-Object System.Drawing.Size(150, 30)
$clearButton.Add_Click({ $outputBox.Clear() })
$form.Controls.Add($clearButton)
# Show the form
$form.ShowDialog()