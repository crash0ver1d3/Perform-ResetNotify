# Perform-ResetNotify
 Incident Response tool to reset a user or user(s) password, and send a notification email to the manager listed in AD, as well as helpdesk, and any other parties. A second email is sent, to manager, and same audience, using Office Message Encryption, with the password for first logon.

Supply samaccountname, or a csv of samaccountnames.

. .\Perform-ResetNotify.ps1/n
<#Single User Mode#>/n
Perform-ResetNotify -UserId test.user21 -Comment "This comment must be in quotes. This will appear in the email body in bold letters"/n
<#Bulk Mode#>/n
Perform-ResetNotify -ImportFile ../data/AtRiskUsers.csv -Comment "This comment must be in quotes. This will appear in the email body in bold letters"
