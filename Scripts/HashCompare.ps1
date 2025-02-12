###This is used to compare the hash value of two folders and save results in csv format. This uses SHA256 algorithm.
Add-Type -AssemblyName System.Windows.Forms
Write-output "You are currently running Hash Comparison script of two folders"
#Input Parameters
#Enter the work folder path to create CSV files
# Open folder browser dialog
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select a folder to save scanned output"
$null = $FolderBrowser.ShowDialog()
$WorkFolder = $FolderBrowser.SelectedPath
# Check if a folder was selected
if (-not $WorkFolder) {
   Write-output "No folder selected. Exiting script."
   exit
}
Write-Output "Your current workfolder is $WorkFolder "


# Get the location of Source folder or the original location path.
# Open folder browser dialog
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select a source folder location"
$null = $FolderBrowser.ShowDialog()
$sourceFolder = $FolderBrowser.SelectedPath
# Check if a folder was selected
if (-not $sourceFolder) {
   Write-output "No folder selected. Exiting script."
   exit
}

# Get the location of Destination Folder where files are copied.
# Open folder browser dialog
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select a destination folder location"
$null = $FolderBrowser.ShowDialog()
$destFolder = $FolderBrowser.SelectedPath
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

