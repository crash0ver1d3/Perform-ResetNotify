##############################################################################
# Script: Perform-ResetNotify.ps1
# Date: 2021.1.5
# Version: 1.5
# Author: Blake Regan @crash0ver1d3
# Purpose: This script will take a samaccountname, or list of samaccountnames, and reset the password and send two emails./n
# One email is cleartext sent to manager, and helpdesk, other staff. The second email gets sent encrypted, with Office Message Encryption./n
# As this script is written, the encrpytion piece does require Microsoft Exchange, and a transport rule created that matches a regex in email email subject, to apply OME./n
# This is accomplished by creating a transport rule that detects '\[encrypt]\' and applies OME./n
# Check the read me for reference screenshot for the transport rule.
# Legal: Script provided "AS IS" without warranties or guarantees of any
#        kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
##############################################################################


$ver="1.5"

Import-Module ActiveDirectory
Import-Module .\IR_Utils_v2.0.ps1

#check for presence of log location, if not create it#>
$LogLocation=$(get-item -Path "..\").fullname + "\log"
if (!(Test-Path -PathType Container $LogLocation))
{
    New-Item -ItemType Container $LogLocation -Force

}

#check for presence of log location, if not create it#>
$DataLocation=$(get-item -Path "..\").fullname + "\data"
if (!(Test-Path -PathType Container $DataLocation))
{
    New-Item -ItemType Container $DataLocation -Force

}


<#Main Function#>
function Perform-ResetNotify ($UserID,$ImportFile,$Confirm,$Comment)
{
#timestamp cannot contain decimal in the format, as that will appear as a file name extension, and prevent export from being created
$d2= (Get-Date -Format g)
$timestamp=(Get-Date -UFormat "%Y%m%d_%H-%M-%S")
$ActionReport=(get-item -Path "..\").fullname + "\log\ActionReport.$timestamp.csv"
New-Item $ActionReport -ItemType File 
Add-Content $ActionReport -Value "ScriptVer,Date,SamAccountName,Email,Manager,Comment"

#dc=contoso,dc=redmond,dc=local
$root = [ADSI]"LDAP://RootDSE"
#$DOMAIN = $root.Get("rootDomainNamingContext")
$DOMAIN = $root.defaultNamingContext

$ImportFullpath=(Get-Item $ImportFile)

    if (!($ImportFile -eq $null))
    {
        
        if ($ImportFile -notlike "*.csv")
        {
            write-host "The ImportFile parameter only supports csv files. You must supply a csv file or use the UserID parameter with a single ID"
            
        }
        if ($ImportFile -like "*.csv")
        {
            write-host "CSV file detected, continuing with bulk reset"
            $UserIDS=(import-csv -Path $ImportFullpath.FullName)
            $bulkmode=$true
            
        }

    }
    <#Confirm if userID exsits, If not error out.#>
    if (!($UserID -eq $null))
    {
        
        try {Get-ADUser -Identity $UserID ;write-host "The UserID that you supplied exists, continuing.";$singlemode=$true}
        catch {"The User ID you supplied $($UserID) does not match an account in $DOMAIN. Please check your input, and run script again."; Start-sleep -Seconds 1}   
     }


<#random password generation. Struggling with having this as a function and returning values#>
Add-Type -AssemblyName 'System.Web'
$minLength = 16 ## characters
$maxLength = 20 ## characters
$length = Get-Random -Minimum $minLength -Maximum $maxLength
$nonAlphaChars = 3
$password = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)
$secPw = ConvertTo-SecureString -String $password -AsPlainText -Force

<#Create Employee Object, for single user with properties#>
if ($singlemode)
{
    $Employee=Get-ADUser -Identity $UserID -Properties Name, DisplayName, Mail,Manager,Samaccountname,GivenName | select -Property Name, DisplayName, Mail,Manager,Samaccountname,GivenName

    <#Create Manager Object#>
    $Manager=Get-aduser -Identity $Employee.Manager -Properties Name, DisplayName, Mail,Manager,GivenName | select -Property Name, DisplayName, Mail,Manager, GivenName

    <#Send cleartext notification email to Manager and Service Desk#>
    eNotificationEmail $Manager $Employee $Comment

    <#Send Encrypted Email to Manager and Service Desk, with credentials#>
    SendEncryptedCredentialsEmail $Manager $Employee $password

    #Reset account password with random creds, and set account to change password at next logon#>
    Set-ADAccountPassword -Identity $Employee.Samaccountname -NewPassword $secPw -Confirm:$false
    Set-Aduser -identity $Employee.SamAccountname -ChangePasswordAtLogon $true -Confirm:$false
    
    <#Make log entry in ActionReport, using processed values.#>
    Add-Content $ActionReport "$ver,$d2,$($Employee.SamAccountName),$($Employee.Mail),$Comment"
    <#Null out password values#>

    $password=$null
    $secPw=$null
}

<# Create array of users, and gather properties#>
if ($bulkmode)
{
    foreach ($User_ID in $UserIDS)
    {

    $Employee=Get-ADUser -Identity $User_ID.SamAccountName -Properties Name, DisplayName, Mail,Manager,Samaccountname,GivenName | select -Property Name, DisplayName, Mail,Manager,Samaccountname,GivenName

    <#Create Manager Object#>
    $Manager=Get-aduser -Identity $Employee.Manager -Properties Name, DisplayName, Mail,Manager,GivenName | select -Property Name, DisplayName, Mail,Manager, GivenName

    <#Send cleartext notification email to Manager and Service Desk#>
    eNotificationEmail $Manager $Employee $Comment

    <#Send Encrypted Email to Manager and Service Desk, with credentials#>
    SendEncryptedCredentialsEmail $Manager $Employee $password

    #Reset account password with random creds, and set account to change password at next logon#>
    Set-ADAccountPassword -Identity $Employee.Samaccountname -NewPassword $secPw -Confirm:$false
    Set-Aduser -identity $Employee.SamAccountname -ChangePasswordAtLogon $true -Confirm:$false

    <#Make log entry in ActionReport, using processed values.#>
    Add-Content $ActionReport "$ver,$d2,$($Employee.SamAccountName),$($Employee.Mail),$Comment"

    <#Null out password values#>
    $password=$null
    $secPw=$null   
 }
}
<#This function will zip up log files, and name with a datstamp once a pre-defined count has been satisfied. Default is 30 days.#>
Directory_Log_Cleanup $LogLocation
}


