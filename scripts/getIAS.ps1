# Create a web service proxy and attach the user certificate to it

. $PSScriptRoot\readProperties.ps1

$IASCertFileName = $props["IASCertFileName"]
$IASCertPassword = $props["IASCertPassword"]
$IASWebService = $props["IASWebService"] + '?wsdl'

$CertPath = "$PSScriptRoot\$IASCertFileName"
$securepwd = $IASCertPassword | ConvertTo-SecureString -AsPlainText -Force

$certificate = Import-PfxCertificate -FilePath $CertPath -CertStoreLocation Cert:\CurrentUser\My -Password $securepwd

function getIAS {
  param($edipi)
  $Body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:uas="http://uas.ias.com/">
   <soapenv:Header/>
   <soapenv:Body>
      <uas:getIASID>
         <id>' + ${edipi} + '</id>
         <idType>E</idType>
         <returnIdType>U</returnIdType>
      </uas:getIASID>
   </soapenv:Body>
</soapenv:Envelope>'
  $request = Invoke-WebRequest -Uri $IASWebService -Headers (@{ SOAPAction = 'Read' }) -Method Post -Body $Body -ContentType text/xml -Certificate $certificate

  $pattern = ".*<id>(.*)</id>.*"
  $uid = [regex]::match($request.Content,$pattern).Groups[1].Value
  return $uid
}

function getIAS_email {
  param($edipi)
  $uid = getIAS $edipi
  return $uid + '@example.com'
}
