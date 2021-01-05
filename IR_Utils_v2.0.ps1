##############################################################################
# Script: IR_Utils_v2.0.ps1
# Date: 2021.1.5
# Version: 2.0
# Author: Blake Regan @blake_r38
# Purpose: This serves as utilities/modules for the Perform-ResetNofify.ps1 script. 
# Legal: Script provided "AS IS" without warranties or guarantees of any
#        kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
##############################################################################


function eNotificationEmail($Manager, $Employee, $Comment){
  <#debug, send to engineer mailbox, or group, comment out the $smtpTo under production#>
    #$smtpTo = "youremailaddress"
    #$cc="coworkers_email_address"
 
  
  <#Production#>
  #comment out the $smtpTo variable below, to use the debug value above.
  $smtpTo = "$($Manager.Mail)"
  write-host $smtpTo
  $cc=("helpdeskmanager","helpdeskmanager","helpdeskmanager","distributionlist")
  
  $messageSubject = "Suspicious Account Activity"
  
  #email address used to send the email
  $smtpFrom ="yourSMTPaddress"
  #body of the email in http
  $smtpBody= " 
    <font face=""calibri""> 
    Dear $($Manager.GivenName),<br>
    <br>
    The Security Operations team has received an alert regarding your employee, $($Employee.Name). Unusual activity on the users account has prompted us to reset their account password.<br>
    We will send you a separate email with the new password. You should only give this new password to your employee in person or over the phone.<br> 
    The Global Service Desk has been copied on this email in case your employee calls them. <br>
    <br>
    <b>$Comment</b><br>
    <br>
    <p>Thanks, <br>  
    </P> 
    Security Operations <br>
    <br><br>
    <font color = ""#FF0000""> This is an unmonitored email account. Please do not reply to this email.<br>
    </font>" 
  $smtpServer = "FQDN_of_your_SMTPSERVER"

  Try{
      # attempt to send the error messages
      Send-MailMessage -From $smtpFrom -To $smtpTo -cc $cc -Subject  $messageSubject -Body $smtpBody -Priority High -SMTPserver $smtpServer -DeliveryNotificationOption onFailure -BodyAsHtml
      
  }
  catch{
      # catch all errors sending the messages and write to error file
      
      #the following line is the old error writing, adjusting to standard log location
      out-file -append -filepath ../log/Error.Log -inputobject $ErrorMessage
      $ErrorMessage = $_.Exception.Message
  }
}

function SendEncryptedCredentialsEmail($Manager, $Employee, $password){
  <#debug, send to engineer mailbox, or group, comment out the $smtpTo under production#>
  #$smtpTo = "youremailaddress"
  #$cc="coworkers_email_address"
  
  <#Production#>
  #comment out the $smtpTo variable below, to use the debug value above.
  $smtpTo = "$($Manager.Mail)"
  $cc=("helpdeskmanager1","helpdeskmanager2","helpdeskmanager3","distributionlist")
  <#NOTE: The brackets and the word [encrypt], are required for the email to be sent encrypted. Screenshot in repo.#> 
  $messageSubject = "notes [encrypt]"
  
  #email address used to send the email
  
  #body of the email in http
  $smtpBody= " 
    <font face=""calibri""> 
    Dear $($Manager.GivenName),<br>
    <br>
    The Security Operation team has received an alert regarding your employee, $($Employee.Name). Unusual activity on the users account has prompted us to reset their account password.<br>
    You should only give this new password to your employee in person or over the phone.<br> 
    The Global Service Desk has been copied on this email in case your employee calls them. <br>
    <br>
    $($Employee.SamAccountName)<br>
    $password<br>

    <p>Thanks, <br>  
    </P> 
    Security Operations <br>
    <br><br>
    <font color = ""#FF0000""> This is an unmonitored email account. Please do not reply to this email.<br>
    </font>" 
  $smtpServer = "FQDN_of_your_SMTPSERVER"

  Try{
      # attempt to send the error messages
      Send-MailMessage -From $smtpFrom -To $smtpTo -cc $cc -Subject  $messageSubject -Body $smtpBody -Priority High -SMTPserver $smtpServer -DeliveryNotificationOption onFailure -BodyAsHtml
      
  }
  catch{
      # catch all errors sending the messages and write to error file
      
      out-file -append -filepath ../log/Error.Log -inputobject $ErrorMessage
      $ErrorMessage = $_.Exception.Message
  }
}

function Directory_Log_Cleanup ($FileDir){

#timestamp cannot contain decimal in the format, as that will appear as a file name extension, and prevent export from being created
$timestamp=(Get-Date -UFormat "%Y%m%d_%H-%M-%S")


$ArchiveDestination=$FileDir+"$($timestamp)_archived"

#may do something time based in next version, leaving the sort object for that purpose
$files = Get-ChildItem $FileDir | Sort-Object lastwritetime 
$message = "Archive not created, unable to rotate logs"
if ($files.Count -gt 30)
  {
    Compress-Archive -Path $FileDir -DestinationPath $ArchiveDestination -Force

    if (Test-Path -type Leaf ($ArchiveDestination +".zip"))
    {
        foreach ($file in $files)

        {
            Remove-Item $($file.fullname) -Force
        }
    
    }
    else
    {
       write-host $message
       
    }


}
}
