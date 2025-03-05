Add-Type -AssemblyName System.Windows.Forms
# Show initial confirmation dialog
$msgBoxResult = [System.Windows.Forms.MessageBox]::Show(
   "Please Note: for any network drive ensure it is authenticated and the path is accessible for copying files.",
   "Confirmation",
   [System.Windows.Forms.MessageBoxButtons]::OKCancel
)
if ($msgBoxResult -ne "OK") {
   Write-Output "Operation cancelled by user."
   exit
}

Write-Output "You are currently running Robocopy to copy file from Source to Destination folder"
# Get paths from user input
function Get-FolderPath {
	   param(
       [string]$DisplayText       
   )
   $form = New-Object System.Windows.Forms.Form
   $form.Text = "Select a path for " + $DisplayText
   $form.Size = New-Object System.Drawing.Size(450,200)
   $form.StartPosition = "CenterScreen"
   $form.FormBorderStyle = "FixedDialog"
   $form.MaximizeBox = $false
   $form.MinimizeBox = $false
   # Label
   $label = New-Object System.Windows.Forms.Label
   $label.Location = New-Object System.Drawing.Point(10,20)
   $label.Size = New-Object System.Drawing.Size(400,20)
   $label.Text = "Select or enter " + $DisplayText + " path:"
   $form.Controls.Add($label)
   # TextBox for path input
   $textBox = New-Object System.Windows.Forms.TextBox
   $textBox.Location = New-Object System.Drawing.Point(10,40)
   $textBox.Size = New-Object System.Drawing.Size(300,20)
   $form.Controls.Add($textBox)
   # Browse button
   $browseButton = New-Object System.Windows.Forms.Button
   $browseButton.Location = New-Object System.Drawing.Point(320,38)
   $browseButton.Size = New-Object System.Drawing.Size(75,23)
   $browseButton.Text = "Browse"
   $browseButton.Add_Click({
       $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
       $folderBrowser.Description = $DisplayText
       if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
           $textBox.Text = $folderBrowser.SelectedPath
       }
   })
   $form.Controls.Add($browseButton)
   # Submit button
   $submitButton = New-Object System.Windows.Forms.Button
   $submitButton.Location = New-Object System.Drawing.Point(120,80)
   $submitButton.Size = New-Object System.Drawing.Size(75,23)
   $submitButton.Text = "Submit"
   $submitButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
   $form.AcceptButton = $submitButton
   $form.Controls.Add($submitButton)
   # Cancel button
   $cancelButton = New-Object System.Windows.Forms.Button
   $cancelButton.Location = New-Object System.Drawing.Point(220,80)
   $cancelButton.Size = New-Object System.Drawing.Size(75,23)
   $cancelButton.Text = "Cancel"
   $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
   $form.CancelButton = $cancelButton
   $form.Controls.Add($cancelButton)
   $form.Topmost = $true
   $result = $form.ShowDialog()
   if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
       return $textBox.Text
   }
   else {
       return $null
   }
}

$source = Get-FolderPath -DisplayText "Source Folder"
if ($source) {
   Write-Output "Selected source path: $source"
   # Add your logic here to use the selected path
}
else {
   Write-Output "No Path selected. Operation is cancelled."
   exit
}
$destination = Get-FolderPath -DisplayText "Destination Folder"
if ($destination) {
   Write-Output "Selected destination path: $destination"
   # Add your logic here to use the selected path
}
else {
   Write-Output "No Path selected. Operation is cancelled."
   exit
}
# Create log file path with timestamp
$logFile = Join-Path $env:TEMP "RobocopyLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
# Robocopy parameters with console output
$robocopyArgs = @(
   "`"$source`"",
   "`"$destination`"",
   "/E",         # Copy subdirectories (including empty ones)
   "/COPY:DAT",  # Copy Data, Attributes, Timestamps
   "/R:3",       # Retry 3 times on failed copies
   "/W:5",       # Wait 5 seconds between retries
   "/MT:16",     # Multi-threaded (16 threads)
   "/V",         # Verbose output
   "/TEE",       # Output to console AND log file
   "/FP",        # Show full paths
   "/LOG:`"$logFile`""  # Log file path
)
# Execute Robocopy with real-time output
try {
   Write-Output "`nStarting file copy with Robocopy...`n"
   # Run Robocopy directly to show real-time output
& robocopy @robocopyArgs
   Write-Output "`nCopy operation completed!"
   Write-Output "Log file created at: $logFile"
}
catch {
   [System.Windows.Forms.MessageBox]::Show("Error occurred during copy operation!", "Error", "OKCancel", "Error") | Out-Null
   Write-Output "Error: $_"
}

Start-Process notepad $logFile

<# Optional: Open log file after completion
$openLog = [System.Windows.Forms.MessageBox]::Show(
   "Would you like to view the log file?",
   "Log File",
   [System.Windows.Forms.MessageBoxButtons]::YesNo
)
if ($openLog -eq "Yes") {
   Start-Process notepad $logFile
}#>