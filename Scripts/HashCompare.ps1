###This is used to compare the hash value of two folders and save results in csv format. This uses SHA256 algorithm.
Add-Type -AssemblyName System.Windows.Forms
Write-output "You are currently running Hash Comparison script of two folders"
#Input Parameters
#Enter the work folder path to create CSV files
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
$WorkFolder = Get-FolderPath -DisplayText "Saving Scanned Output"
##########
# Check if a folder was selected
if (-not $WorkFolder) {
   Write-output "No folder selected. Exiting script."
   exit
}
Write-Output "Your current workfolder is $WorkFolder "


# Get the location of Source folder or the original location path.
$sourceFolder = Get-FolderPath -DisplayText "Source Folder"
# Check if a folder was selected
if (-not $sourceFolder) {
   Write-output "No folder selected. Exiting script."
   exit
}

# Get the location of Destination Folder where files are copied.
$destFolder = Get-FolderPath -DisplayText "Destination Folder"
# Check if a folder was selected
if (-not $destFolder) {
   Write-output "No folder selected. Exiting script."
   exit
}

$sourceHashPath = $WorkFolder + "\hashes1.csv"
$destHashPath = $WorkFolder + "\hashes2.csv"
$comparisonResultsPath = $WorkFolder + "\comparison_results.csv"

#check existence of hashes1 csv file and clear it  
	if(Test-Path $sourceHashPath) {
		"" | Set-Content -Path $sourceHashPath 
		#Write-Output "hashes1.CSV file already found and cleared the previous content."
	} else {
		Write-Output "Creating new hashes1.CSV file in location $sourceHashPath "
	}
#check existence of hashes2 csv file and clear it
	if(Test-Path $destHashPath) {
		"" | Set-Content -Path $destHashPath 
		#Write-Output "hashes2.CSV file already found and cleared the previous content."
	} else {
		Write-Output "Creating new hashes2.CSV file in location $destHashPath "
	}

#Check the existence of the comparison results csv file
if(Test-Path $comparisonResultsPath) {
	"" | Set-Content -Path $comparisonResultsPath
}	

# Function to create hash inventory for a folder
function Get-FolderHash {
   param(
       [string]$FolderPath,
       [string]$OutputCSVPath
   )
   $files = Get-ChildItem -Path $FolderPath -File -Recurse
   $totalFiles = $files.Count
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
   Write-output "Hash inventory saved to: $OutputCSVPath"
}
# Generate hash inventories
Get-FolderHash -FolderPath $sourceFolder -OutputCSVPath $sourceHashPath
Get-FolderHash -FolderPath $destFolder -OutputCSVPath $destHashPath
# Import hash data
$sourceHashes = Import-Csv $sourceHashPath
$destHashes = Import-Csv $destHashPath
# Create comparison hashtables
$sourceTable = @{}
$sourceHashes | ForEach-Object { $sourceTable[$_.RelativePath] = $_ }
$destTable = @{}
$destHashes | ForEach-Object { $destTable[$_.RelativePath] = $_ }
# Compare files
$comparisonResults = @()
# Check for modified/missing files in destination
foreach ($key in $sourceTable.Keys) {
   $sourceFile = $sourceTable[$key]
   if (-not $destTable.ContainsKey($key)) {
       $comparisonResults += [PSCustomObject]@{
           RelativePath  = $key
           Status        = "Missing in Destination"
           SourceHash    = $sourceFile.Hash
           DestHash      = $null
           SourceSize    = $sourceFile.Size
           DestSize      = $null
           LastModified  = $sourceFile.LastModified
       }
   }
   else {
       $destFile = $destTable[$key]
       if ($sourceFile.Hash -ne $destFile.Hash) {
           $comparisonResults += [PSCustomObject]@{
               RelativePath  = $key
               Status        = "Hash Mismatch"
               SourceHash    = $sourceFile.Hash
               DestHash      = $destFile.Hash
               SourceSize    = $sourceFile.Size
               DestSize      = $destFile.Size
               LastModified  = $destFile.LastModified
           }
       }
       $destTable.Remove($key)
   }
}
# Check for extra files in destination
foreach ($key in $destTable.Keys) {
   $destFile = $destTable[$key]
   $comparisonResults += [PSCustomObject]@{
       RelativePath  = $key
       Status        = "Extra in Destination"
       SourceHash    = $null
       DestHash      = $destFile.Hash
       SourceSize    = $null
       DestSize      = $destFile.Size
       LastModified  = $destFile.LastModified
   }
}
# Export comparison results
$comparisonResults | Export-Csv -Path $comparisonResultsPath -NoTypeInformation -Encoding UTF8
Write-output "Comparison results saved to: $comparisonResultsPath"
# Display summary
Write-output "`nComparison Summary:"
$comparisonResults | Group-Object Status | Format-Table Count, Name -AutoSize
$check = $comparisonResults | Group-Object Status
if (-not $check) {
   Write-output "----------> Integrity is maintained and no action required !!!  <----------"
}

