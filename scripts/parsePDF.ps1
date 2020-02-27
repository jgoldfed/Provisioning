[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\..\apps\itextsharp.dll") | Out-Null
Add-Type -Path "$PSScriptRoot\..\apps\itextsharp.dll"

. $PSScriptRoot\readProperties.ps1
. $PSScriptRoot\getIAS.ps1
. $PSScriptRoot\AddModifyOdpUsers.ps1

function getPDFField {
  param($fieldname)
  $outvalue = "Field Not Found"
  for ($page = 1; $page -le $PDFReader.NumberOfPages; $page++)
  {
    if ($page -eq 1) {
      #extract a page and split it into lines
      foreach ($PDFField in $PdfReader.AcroFields.Fields.Keys) {
        #Uncheck the below to get back all the fields
        #Write-Host $PDFField , ':', $PdfReader.AcroFields.getField($PDFField)

        if ($PDFField -eq $fieldname) {
          $outvalue = $PDFReader.AcroFields.GetField($PDFField)
        }
      }
    }
  }
  return $outvalue
}

function getPDFSignature {
  $outvalue = "Field Not Found"
  for ($page = 1; $page -le $PDFReader.NumberOfPages; $page++)
  {
    if ($page -eq 1) {
      $names = $PdfReader.AcroFields.getSignatureNames()

      $name = $names[0]
      $pk = $PdfReader.AcroFields.VerifySignature($name)
      return $pk.signname
    }
  }
}

$PDFPath2785 = $props["PDFPath2785"]
$PDFFieldEDIPI = $props["PDFFieldEDIPI"]
$PDFFieldTitle = $props["PDFFieldTitle"]
$PDFFieldAddress = $props["PDFFieldAddress"]

#$PDFReader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList  "$PDFPath2785/Approved/Ektropy SAAR_rev20191021_Ramya0221.pdf" #mmiller_Ektropy SAAR_rev20191021-sign3.pdf"
$PDFReader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList  "$PDFPath2785/Approved/mmiller_Ektropy SAAR_rev20191021-sign3.pdf"
$edipi = getPDFField $PDFFieldEDIPI
$jobtitle = getPDFField $PDFFieldTitle


$UserSignature = getPDFSignature
$lname = $UserSignature.split('.')[0]
$fname = $UserSignature.split('.')[1]
$mname = $UserSignature.split('.')[2]
#$EDIPI=$UserSignature.split('.')[-1]


$PDFReader.Close()
#Write-Host $LName,$Fname,$MName,$EDIPI

$IASemail = getIAS_email $edipi

$amOU = addModifyOdpUser $IASEmail $fname $lname $jobtitle

$xml = [xml] $amOU.Content     
$xml.SelectNodes("descendant::node()") | ? Value | % { @{$_.ParentNode = $_.Value}  }

