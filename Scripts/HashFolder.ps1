#This script will generate the hash of entire contents of a folder
Add-Type -AssemblyName System.Windows.Forms
Write-Output "You are currently running Hash extraction (SHA256 Algorithm) of all contents of a selected folder"
# Get the location of Source folder
# Open folder browser dialog
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select a folder to extract hash file"
$null = $FolderBrowser.ShowDialog()
$sourceFolder = $FolderBrowser.SelectedPath
# Check if a folder was selected
if (-not $sourceFolder) {
   Write-Output "No folder selected. Exiting script."
   exit
}
Write-Output "You have selected '$sourceFolder' Folder to extract hashes."
# Location to export a csv file
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select a location to save exported hashed data"
$null = $FolderBrowser.ShowDialog()
$WorkFolder = $FolderBrowser.SelectedPath
# Check if a folder was selected
if (-not $WorkFolder) {
   Write-Output "No folder selected. Exiting script."
   exit
}

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

