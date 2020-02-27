[System.Reflection.Assembly]::LoadFrom("$PSScriptRoot\..\apps\itextsharp.dll") | Out-Null
Add-Type -Path "$PSScriptRoot\..\apps\itextsharp.dll"


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

function printPDFFields {
  for ($page = 1; $page -le $PDFReader.NumberOfPages; $page++)
  {
    if ($page -eq 1) {
      #extract a page and split it into lines
      foreach ($PDFField in $PdfReader.AcroFields.Fields.Keys) {
        #Uncheck the below to get back all the fields
        $strOutput = $strOutput + $PDFField + '| [' + $PdfReader.AcroFields.GetField($PDFField) + "]`r`n"

      }
    }
  }
  return $strOutput
}
