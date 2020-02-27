
#Set variables using the readProperties
. $PSScriptRoot\readProperties.ps1

$PDFPath2785 = $props["PDFPath2785"]
$PDFFieldEDIPI = $props["PDFFieldEDIPI"]
$PDFFieldTitle = $props["PDFFieldTitle"]
$PDFFieldAddress = $props["PDFFieldAddress"]

#Set date and datetime for logging purposes
$CurrDate = Get-Date -Format "yyyy-MM-dd"
$outputFile = "PortletUsers" + $CurrDate + ".log"
$outputFilePath = "$PSScriptRoot\..\logs\$outputFile"

#Set PDF Reader and read fields
. $PSScriptRoot\parsePDF.ps1

#Set Log-Output function for logging
function Log-Output {
  param($Header,$strToPrint)
  $Header = $Header.ToUpper()
  Write-Output "`r`n***** $Header *****" | Tee-Object -FilePath $outputFilePath -Append
  if ($strToPrint) {
    Write-Output $strToPrint | Tee-Object -FilePath $outputFilePath -Append
  }
}


function MoveToFolder {
  param($fldrstatus)
  Move-Item -Path "$PDFPath2785/Approved/$_" -Destination "$PDFPath2785/$fldrstatus/$_" -Force
  Log-Output "Status" "Moved file to $PDFPath2785/$fldrstatus folder"
}


function getCurrDateTime {
  $CurrDateTime = Get-Date -Format "yyyy-MM-dd'T'HH:mm:ss"
  return $CurrDateTime
}

#Get each of the files in the Approved folder and process each one
Get-ChildItem "$PDFPath2785/Approved" -Filter *.pdf |
ForEach-Object {
  $PDFReader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList "$PDFPath2785/Approved/$_"
  $edipi = getPDFField $PDFFieldEDIPI
  $jobtitle = getPDFField $PDFFieldTitle
  $PDFField = printPDFFields
  $CurrDateTime = getCurrDateTime
  Log-Output "$_ Analysis Starting - $CurrDateTime"
  Log-Output "Form 2785 Data" $PDFField


  #Get the Signature field from parsePDF. Parse them.
  $UserSignature = getPDFSignature
  $lname = $UserSignature.split('.')[0]
  $fname = $UserSignature.split('.')[1]
  $mname = $UserSignature.split('.')[2]
  #$EDIPI=$UserSignature.split('.')[-1]

  #Close the PDF Reader
  $PDFReader.Close()


  #Get the IAS value (in email format)
  . $PSScriptRoot\getIAS.ps1

  $IASemail = getIAS_email $edipi
  #Check for error


  if ($IASemail -eq 'noaccount@example.com') {

    Log-Output "IAS Response" "Error found: Cannot find unique Id. Please confirm user exists in CAC system and that PDF form is complete."
    #Move-Item the file to Failed
    MoveToFolder "Failed"
    $CurrDateTime = getCurrDateTime
    Log-Output "$_ Analysis Ending - $CurrDateTime"
    return
  }
  else {
    Log-Output "IAS Response" "Username assigned to $IASemail."
  }

  #Modify the user with required parameters
  . $PSScriptRoot\addModifyOdpUsers.ps1

  $printBod = printBody $IASEmail $fname $lname $jobtitle


  $amOU = addModifyOdpUser $IASEmail $fname $lname $jobtitle
  $amOUSC = $amOU.StatusCode
  $amOUDe = $amOU.StatusDescription

  $xml = [xml]$amOU.Content
  if ($xml | Select-Xml –Xpath “//faultcode”) {

    Log-Output "Portal Response" "Error found: "
    $xml.ChildNodes.SelectNodes("//faultstring") | Select-Object -ExpandProperty "#text"
    #Move the file to Failed
    MoveToFolder "Failed"

  }
  else {
    Log-Output "Portal Response" "Successfully modified with the following attributes:"
    $xml.SelectNodes("descendant::node()") | Where-Object Value | ForEach-Object { @{ $_.ParentNode = $_.Value } } | Format-Table | Tee-Object -FilePath $outputFilePath -Append
    MoveToFolder "Processed"
  }
  $CurrDateTime = getCurrDateTime
  Log-Output "$_ Analysis Ending - $CurrDateTime"
}

