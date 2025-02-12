<##Get the hash of a file only using multiple algorithm and save file in csv.

It generates multiple cryptographic hashes for files and exports to CSV
.DESCRIPTION
This enhanced version includes:
- Support for 8 different hash algorithms
- Detailed error logging
- Progress reporting
- File metadata
- Flexible input/output options
.EXAMPLE
Get-FileHashesAdvanced -Path "C:\Files\*" -Output "FileChecksums.csv"
#>
Add-Type -AssemblyName System.Windows.Forms
#Requires -Version 5.1
Write-Output "You are currently running Hash extraction of selected file/files"
# Open file browser dialog to select the file/files
#############
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.Title = "Select 1 or Multiple Files"
#$FileBrowser.InitialDirectory = [Environment]::GetFolderPath('MyDocuments') #Use this if require to autoselect MyDocuments directory.
$FileBrowser.Filter = "All Files (*.*)|*.*"
$FileBrowser.Multiselect = $true
if ($FileBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
   $selectedFiles = $FileBrowser.FileNames
   foreach ($file in $selectedFiles) {
       $outputBox.AppendText("Selected File: $file`r`n")
   }
}
$FilePath = $FileBrowser.FileNames

## Check if a file was selected
if (-not $FilePath) {
   Write-Output "No file selected. Exiting script."
   exit
}
## Output the selected file path
# Location to export a csv file
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = "Select a location of folder for hash file generation"
$null = $FolderBrowser.ShowDialog()
$WorkFolder = $FolderBrowser.SelectedPath
# Check if a folder was selected
if (-not $WorkFolder) {
   Write-Output "No folder selected. Exiting script."
   exit
}

$OutputHashPath = $WorkFolder + "\file_hashes.csv"
#check existence of file_hashes csv file and clear it  
	if(Test-Path $OutputHashPath) {
		"" | Set-Content -Path $OutputHashPath 
	} else {
		Write-Output "Creating new file_hashes.CSV file in location $OutputHashPath "
	}


function Get-FileHashesAdvanced {
   [CmdletBinding()]
   param(
       [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
       [Alias("FullName")]
       [string[]]$Path,
       [string]$Output = "FileHashes.csv",
       [ValidateSet('MD5','SHA1','SHA256','SHA384','SHA512','RIPEMD160','MACTripleDES','SHA3_256')]
       [string[]]$Algorithms = @('MD5','SHA1','SHA256','SHA384','SHA512')
   )
   begin {
       # Initialize hash algorithms
       $hashProviders = @{
           MD5         = [System.Security.Cryptography.MD5]::Create()
           SHA1        = [System.Security.Cryptography.SHA1]::Create()
           SHA256      = [System.Security.Cryptography.SHA256]::Create()
           SHA384      = [System.Security.Cryptography.SHA384]::Create()
           SHA512      = [System.Security.Cryptography.SHA512]::Create()
           RIPEMD160   = [System.Security.Cryptography.RIPEMD160]::Create()
           MACTripleDES= [System.Security.Cryptography.MACTripleDES]::new()
           SHA3_256    = if ($PSVersionTable.PSVersion -ge [version]'7.0') {
                           [System.Security.Cryptography.SHA3_256]::Create()
                         }
       }
       $files = @()
       $processedCount = 0
       $startTime = Get-Date
	   
   }
   process {
       foreach ($item in $Path) {
           try {
               $resolvedPaths = Resolve-Path $item -ErrorAction Stop | Where-Object { -not $_.Provider.IsContainer }
               foreach ($filePath in $resolvedPaths.Path) {
                   $file = Get-Item -LiteralPath $filePath -ErrorAction Stop
                   $fileData = [ordered]@{
                       FileName       = $file.Name
                       FilePath       = $file.FullName
                       FileSize       = $file.Length
                       Created        = $file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
                       Modified       = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                       Attributes     = $file.Attributes
                   }
                   # Calculate hashes
                   $stream = $null
                   try {
                       $stream = [System.IO.File]::OpenRead($file.FullName)
                       foreach ($algorithm in $Algorithms) {
                           if (-not $hashProviders.ContainsKey($algorithm)) {
                               $fileData[$algorithm] = "Algorithm not available"
                               continue
                           }
                           try {
                               $hash = $hashProviders[$algorithm].ComputeHash($stream)
                               $fileData[$algorithm] = [BitConverter]::ToString($hash).Replace("-", "")
                               $stream.Position = 0  # Reset stream for next algorithm
                           }
                           catch {
                               $fileData[$algorithm] = "Error: $($_.Exception.Message)"
                           }
                       }
                   }
                   finally {
                       if ($stream) { $stream.Dispose() }
                   }
                   $files += [PSCustomObject]$fileData
                   $processedCount++
                   # Progress reporting
                   Write-Progress -Activity "Processing Files" `
                       -Status "$processedCount files processed" `
                       -PercentComplete (($processedCount / $Path.Count) * 100)
               }
           }
           catch {
               Write-Warning "Error processing path '$item': $_"
           }
       }
   }
   end {
       # Cleanup hash providers
       $hashProviders.Values | ForEach-Object { if ($_ -is [IDisposable]) { $_.Dispose() } }
       if ($files.Count -gt 0) {
           # Export to CSV
           $files | Export-Csv -Path $Output -NoTypeInformation -Encoding UTF8
           # Generate report
           $endTime = Get-Date
           $totalTime = $endTime - $startTime
           Write-Output @"
           === Processing Summary ===
           Total files processed: $($files.Count)
           Start time: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))
           End time:   $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))
           Total time: $($totalTime.ToString('hh\:mm\:ss'))
           Output saved to: $((Resolve-Path $Output).Path)
"@
       }
       else {
           Write-Warning "No valid files processed"
       }
   }
}
# Example usage:
Get-FileHashesAdvanced -Path $FilePath -Output $OutputHashPath -Algorithms MD5,SHA256,SHA3_256

