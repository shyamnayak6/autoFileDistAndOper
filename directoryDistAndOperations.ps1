
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
Write-Host 'properties file path' $scriptPath

$file_content = Get-Content $scriptPath"\config.properties"
$file_content = $file_content -join [Environment]::NewLine

$configuration = ConvertFrom-StringData($file_content)
#$Credentials=Get-Credential

$Username = Read-Host "Enter Username"
$Password = Read-Host "Enter Password" -AsSecureString

#$Credentials.UserName = $configuration.'User_Name'
Write-Host $Credentials.Username
#$Credentials.Password = $configuration.'Password'
Write-Host $Credentials.Password

$sourcePath=$configuration.'sourcePath'
$destPath=$configuration.'destPath'

$Machine_Names = $configuration.'Machine_Name'
$Machine_Namelist = $Machine_Names.split(",");
#$Credentials.Password = ConvertTo-SecureString $Credentials.Password -AsPlainText -Force
#$cred= New-Object System.Management.Automation.PSCredential ($Credentials.Username, $Credentials.Password)

$cred= New-Object System.Management.Automation.PSCredential ($Username, $Password)

foreach($Machine_Name in $Machine_Namelist){ 



$session= New-PSSession -ComputerName $Machine_Name -Credential $cred
#WriteAuditLog -Persona $Machine_Name -Activity " Connection Established to the $Machine_Name" -user $Credentials.Username -Application "Monitoring"



 $taskscriptContent ={
  param([Object] $sourcePath,[string] $destPath)



if (Test-Path $destPath) {
 # Determine the new name: the name of the input dir followed by "_" and a date string.
 # Note the use of a single interpolated string ("...") with 2 embedded subexpressions, 
 # $(...)
 $newName="$(Split-Path -Leaf $destPath)_backup_$((Get-Date).ToString('MM-dd-yyyy-HH-mm-ss'))"
 Rename-Item -Path $destPath -newName $newName -Force

 }
 if(!(Test-Path -Path $destPath )){
    New-Item -ItemType directory -Path $destPath
    Write-Host "New  historic logs folder created"
}

 

}


 $taskscriptContent1 ={
  param([String] $Machine_Name,[string] $destPath)

 $dir2= $destPath+"\Test_Scripts"

 $name=$Machine_Name.ToCharArray()
Write-Host $name
$csv_extn="_M"+$name.Get($name.Count-2)+$name.Get($name.Count-1)
Write-Host $csv_extn

Get-ChildItem -path $dir2 -Directory | 
foreach {
Write-Host $_.FullName
#Set-Location $_.FullName;
$dir2=$_.FullName


Get-ChildItem $dir2 -Recurse -Include *.csv | ForEach-Object{

$oldname = $_.BaseName 
#Write-Host $oldname
$newname=$oldname.Replace($csv_extn,"")
Write-Host $newname
    $newFileName=$_.Name.Replace($oldname,$newname) 
    Write-Host $newFileName
   # Rename-Item $oldname $newFileName
    Rename-Item -Path $dir2\$oldname".csv" -NewName $dir2\$newFileName

}
}

}

invoke-command -session $session -scriptblock $taskscriptContent  -ArgumentList  $sourcePath, $destPath
Copy-Item $sourcePath"\*" -Destination $destPath  -ToSession $session -Recurse -Force
invoke-command -session $session -scriptblock $taskscriptContent1  -ArgumentList  $Machine_Name, $destPath
Remove-PSSession -Session $session
 }
