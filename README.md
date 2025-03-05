# File-Integrity-Checker
To check the file/files integrity and copying folder using ROBOCOPY from source to destination path.

This PowerShell script is created by Utsab N. for checking the files integrity.
Created on Jan, 2025

Main idea is to ensure the file integrity is maintained during the file or contents of a folder transfer process. Whenever any files are copied from one location to other it is necessary to check the file integration and compare if the hashes matches. This scripts helps in capturing the hashes of all files in original location and compares to destination location (after files are transferred) with the hash value to verify the file is transferred without any alteration. 

For example - when uploading a files to different drive or location, when you have your multiple copy of your personal folder and unsure if any changes to any files are made - use this tool to identify using the hashfolder comparison.

Also, there are 2 other script where in some cases we only need to capture the hash of all files located to a folder or specifically to selected files. This then can be shared to recipient team who when downloaded files can verify the hash and ensure the file/files integrity is maintained.

There is additional script to copy entire contents of a folder using ROBOCOPY and extracting log output to see any errors during the file transfer.

How to use the Script?

	1. In this folder locate the file "IntegrityChecker" and run as admin to avoid any restriction.
	2. This will open the GUI for the file integrity checker.
	3. There are 3 different script related to file integrity check and 1 additional script to copy folder using ROBOCOPY: 
		a.) Compare the hash value of source and destination folder after the file transfer is complete. This uses SHA256 Algorithm to generate Hashes.
		b.) Generate a hash value of entire content of a folder and save it in csv format for future use to verify or share to recipient. This also uses SHA256 Algorithm to generate hash value of all content of a folder.
		c.) Generate a hash value of selected file/files and save it in csv format for future use to verify or share to recipient end. This extracts, MD5 and SHA values.
  		d.) Using ROBOCOPY inbuilt windows feature to copy folder from one location other and extract the log of file transfer process.
	4. All the out put are displayed in the Output box of the PowerShell GUI
	5. Once done- simply close the file.
