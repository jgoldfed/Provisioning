# Create a web service proxy and attach the user certificate to it
$pwd = "niku123PMAT"
$securepwd = $pwd | ConvertTo-SecureString -asPlainText -Force

$certificate = Import-PfxCertificate -FilePath "C:\Users\JarrettGoldfedder\Documents\Jarrett\PowerShell\Provisioning\scripts\SATLAPPMATAP01.med.ds.osd.mil.pfx" -CertStoreLocation Cert:\CurrentUser\My -Password $securepwd

$Body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:uas="http://uas.ias.com/">
   <soapenv:Header/>
   <soapenv:Body>
      <uas:getIASID>
         <id>1510135616</id>
         <idType>E</idType>
         <returnIdType>U</returnIdType>
      </uas:getIASID>
   </soapenv:Body>
</soapenv:Envelope>'
$request = Invoke-WebRequest -Uri "https://cacpt.csd.disa.mil:443/ECRSWebServices/uas?wsdl" -Headers (@{SOAPAction='Read'}) -Method Post -Body $Body -ContentType text/xml  -Certificate $certificate 

$pattern = ".*<id>(.*)</id>.*"
$id = [regex]::match($request.Content, $pattern).Groups[1].Value
$id + '@example.com'