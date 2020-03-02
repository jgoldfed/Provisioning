
#Set the -c parameter. NOTE: This must be set to "confirm" the firing of the script
# From https://stackoverflow.com/questions/35271907/why-do-i-need-to-use-parametersetname-with-a-powershell-switch
param([switch]$c = $false)
$confirm = $c


#Set variables using the readProperties
. $PSScriptRoot\readProperties.ps1

$PDFPath2875 = $props["PDFPath2875"]
$PDFFieldEDIPI = $props["PDFFieldEDIPI"]
$PDFFieldTitle = $props["PDFFieldTitle"]
$PDFFieldAddress = $props["PDFFieldAddress"]
$PDFFieldEmail = $props["PDFFieldEmail"]
$PDFFieldPhone = $props["PDFFieldPhone"]
$PDFFieldOrganization = $props["PDFFieldOrganization"]

#Set date and datetime for logging purposes
$CurrDate = Get-Date -Format "yyyy-MM-dd"
$logFile = "PortletUsers" + $CurrDate + ".log"
$logFilePath = "$PSScriptRoot\..\logs\$logFile"
$spreadsheetFile = "PortletUsers" + $CurrDate + ".csv"
$spreadsheetFilePath = "$PSScriptRoot\..\output\$spreadsheetFile"




#Set PDF Reader and read fields
. $PSScriptRoot\parsePDF.ps1

#Set Log-Output function for logging
function Log-Output {
  param($Header,$strToPrint)
  #Ensure flag for confirm is set
  if (!$confirm) {
    $Header = "TEST | " + $Header.ToUpper()
  }
  else {
    $Header = $Header.ToUpper()
  }


  Write-Output "`r`n***** $Header *****" | Tee-Object -FilePath $logFilePath -Append
  if ($strToPrint) {
    Write-Output $strToPrint | Tee-Object -FilePath $logFilePath -Append
  }
}


function MoveToFolder {
  param($fldrstatus)
  Move-Item -Path "$PDFPath2875/Approved/$_" -Destination "$PDFPath2875/$fldrstatus/$_" -Force
  Log-Output "Status" "Moved file to $PDFPath2875/$fldrstatus folder"
}


function getCurrDateTime {
  $CurrDateTime = Get-Date -Format "yyyy-MM-dd'T'HH:mm:ss"
  return $CurrDateTime
}

function WritetoCSV {
  $CurrDateTime = Get-Date -Format "yyyy-MM-dd'T'HH:mm:ss"
  return $CurrDateTime
}




#Process each file in the approved folder
Get-ChildItem "$PDFPath2875/Approved" -Filter *.pdf | ForEach-Object {
  $PDFReader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList "$PDFPath2875/Approved/$_"
  #$edipi = getPDFField $PDFFieldEDIPI

  $jobtitle = getPDFField $PDFFieldTitle
  $email = getPDFField $PDFFieldEmail
  $phone = getPDFField $PDFFieldPhone
  $organization = getPDFField $PDFFieldOrganization

  $PDFField = printPDFFields
  $CurrDateTime = getCurrDateTime

  $successFlag = 0

  #****START OUTPUT****
  Log-Output "$_ Analysis Starting - $CurrDateTime"

  #****FORM 2875****
  Log-Output "Form 2875 Data" $PDFField


  #Get the Signature field from parsePDF. Parse them.
  $UserSignature = getPDFSignature
  $lname = $UserSignature.split('.')[0]
  $fname = $UserSignature.split('.')[1]
  $edipi = $UserSignature.split('.')[-1]

  #Close the PDF Reader
  $PDFReader.Close()

  #Detect failure if the fname is blank
  if ($fname.length -lt 1) {
    Log-Output "PDF Read Error" "Error found: EDI PI User Signature is not in the correct format. Please review."
    #Move-Item the file to Failed
    if ($confirm) {
      MoveToFolder "Failed"
    }
    $CurrDateTime = getCurrDateTime
    Log-Output "$_ Analysis Ending - $CurrDateTime"
    return
  }



  #Get the IAS value (in email format)
  . $PSScriptRoot\getIAS.ps1

  $IASId = getIAS $edipi
  $IASemail = getIAS_email $edipi
  #Check for error

  #****IAS RESPONSE****
  #Detect failure
  if ($IASemail -eq 'noaccount@example.com') {

    Log-Output "IAS Response" "Error found: Cannot find unique Id. Please confirm user exists in CAC system and that PDF form is complete."
    #Move-Item the file to Failed
    if ($confirm) {
      MoveToFolder "Failed"
    }
    $CurrDateTime = getCurrDateTime
    Log-Output "$_ Analysis Ending - $CurrDateTime"
    return
  }
  else {
    Log-Output "IAS Response" "Username assigned to $IASemail."
  }

  #Modify the user with required parameters
  . $PSScriptRoot\addModifyOdpUsers.ps1

  #****PORTAL REQUEST***
  $printBod = printBody $IASEmail $fname $lname $jobtitle $email $phone
  Log-Output "Portal Request" $printBod

  #Ensure -c switch is set
  if ($confirm) {
    $amOU = addModifyOdpUser $IASEmail $fname $lname $jobtitle $email $phone
    $amOUSC = $amOU.StatusCode
    $amOUDe = $amOU.StatusDescription

    $xml = [xml]$amOU.Content

    #****PORTAL RESPONSE***
    #if we find a response with //faultcode as part of the Xpath, this qualifies as an error
    if ($xml | Select-Xml –Xpath “//faultcode”) {

      Log-Output "Portal Response" "Error found: "
      $xml.ChildNodes.SelectNodes("//faultstring") | Select-Object -ExpandProperty "#text"
      #Move the file to Failed
      MoveToFolder "Failed"

    }
    else {
      Log-Output "Portal Response" "Successfully modified with the following attributes:"
      $xml.SelectNodes("descendant::node()") | Where-Object Value | ForEach-Object { @{ $_.ParentNode = $_.Value } } | Format-Table | Tee-Object -FilePath $logFilePath -Append
      MoveToFolder "Processed"
      $successFlag = 1
    }
    $CurrDateTime = getCurrDateTime



    #****WRITE TO CSV (SPREADSHEET)****
    #Create and populate the spreadshhetFile if it does not exist
    if ($successFlag -eq 1) {
      if (!(Test-Path $spreadsheetFilePath -PathType leaf))
      {
        Write-Output "LastName,FirstName,PrimaryEmail,PhoneNumber,Organization,IASID,GroupsRequested,PortalEmailAddress,DateModified" | Out-File $spreadsheetFilePath -Append
      }

      Write-Output "${lname},${fname},${email},${phone},${organization},${IASId}, ,${IASemail},${CurrDateTime}" | Out-File $spreadsheetFilePath -Append
      Log-Output "Added User information to CSV file"
    }
  }
  #****END OUTPUT****
  Log-Output "$_ Analysis Ending - $CurrDateTime"
}

