[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\..\apps\itextsharp.dll") | Out-Null
Add-Type -Path "$PSScriptRoot\..\apps\itextsharp.dll"


function ReadProperties {
  param($content)
  $AppProps = ConvertFrom-StringData (Get-Content $content -Raw)
  return $AppProps
}

function getPDFField {
  param($fieldname)
  $outvalue = "Field Not Found"
  for ($page = 1; $page -le $reader.NumberOfPages; $page++)
  {
    if ($page -eq 1) {
      #extract a page and split it into lines
      foreach ($PDFField in $PdfReader.AcroFields.Fields.Keys) {
        #Uncheck the below to get back all the fields
        #Write-Host $PDFField , ':', $PdfReader.AcroFields.getField($PDFField)

        if ($PDFField -eq $fieldname) {
          $outvalue = $PdfReader.AcroFields.GetField($PDFField)
        }
      }
    }
  }
  return $outvalue
}

$props = ReadProperties ("$PSScriptRoot\..\properties\PortalUsers.properties")

$PDFPath2785 = $props["PDFPath2785"]

$PdfReader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList "$PDFPath2785/Approved/mmiller_Ektropy SAAR_rev20191021-sign3.pdf"

$EDIPI = getPDFField ($props["PDFFieldEDIPI"])
$FullName= getPDFField ($props["PDFFieldName"])
$Lname=$FullName.split(" ,")[0]
$Fname=$FullName.split(" ")[1]
$Mname=$FullName.split(" ")[2]

Write-Host $fName,$Mname, $LName, '-', $EDIPI
$reader.Close()


