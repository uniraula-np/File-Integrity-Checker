#This script will generate the hash of entire contents of a folder
Add-Type -AssemblyName System.Windows.Forms
Write-Output "You are currently running Hash extraction (SHA256 Algorithm) of all contents of a selected folder"
# Get the location of Source folder
# Open folder browser dialog
##########
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

#Get the location to save the output csv
$WorkFolder = Get-FolderPath -DisplayText "to Save Exported hashed data in csv format"
# Check if a folder was selected
if (-not $WorkFolder) {
   Write-Output "No folder selected. Exiting script."
   exit
}
##########

# Open folder browser dialog
$sourceFolder = Get-FolderPath -DisplayText "Source Folder to generate hashed data"
# Check if a folder was selected
if (-not $sourceFolder) {
   Write-Output "No folder selected. Exiting script."
   exit
}
Write-Output "You have selected '$sourceFolder' Folder to extract hashes."

$sourceHashPath = $WorkFolder + "\hashes_output.csv"
#check existence of hashes_output csv file and clear it  
	if(Test-Path $sourceHashPath) {
		"" | Set-Content -Path $sourceHashPath 
		#Write-Output "hashes1.CSV file already found and cleared the previous content."
	} else {
		Write-Output "Creating new hashes_output.CSV file in location $sourceHashPath "
	}

# Function to create hash inventory for a folder
function Get-FolderHash {
   param(
       [string]$FolderPath,
       [string]$OutputCSVPath
   )
   $files = Get-ChildItem -Path $FolderPath -File -Recurse
   $totalFiles = $files.Count
   Write-Output "Total number of files in the given Folder: $totalFiles "
   $counter = 0
   $fileData = foreach ($file in $files) {
       $counter++
       $progress = [math]::Round(($counter / $totalFiles) * 100, 2)
       Write-Progress -Activity "Hashing files" -Status "$progress% Complete" `
           -PercentComplete $progress -CurrentOperation $file.FullName
       $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash
       [PSCustomObject]@{
           FullPath      = $file.FullName
           RelativePath  = $file.FullName.Substring($FolderPath.TrimEnd('\').Length + 1)
           Name          = $file.Name
           Size          = $file.Length
           LastModified  = $file.LastWriteTime
           Hash          = $hash
       }
   }
   $fileData | Export-Csv -Path $OutputCSVPath -NoTypeInformation -Encoding UTF8
   Write-Output "Hash inventory saved to: $OutputCSVPath"
}
# Generate hash inventories
Get-FolderHash -FolderPath $sourceFolder -OutputCSVPath $sourceHashPath

