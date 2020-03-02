# Create a web service proxy and attach the user certificate to it

. $PSScriptRoot\readProperties.ps1


$PortalWebService = $props["PortalWebService"]
$PortalUser = $props["PortalUser"]
$PortalPass = $props["PortalPass"] | ConvertTo-SecureString -AsPlainText -Force
$PortalTenant = $props["PortalTenant"]
$PortalAppInstance = $props["PortalAppInstance"]

$cred = New-Object System.Management.Automation.PSCredential ($PortalUser,$PortalPass)

function createBody {
  param($uidemail,$fname,$lname,$jobtitle,$email,$phone)
  $strBody = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:http.service.odp.ondemand.ca.com" xmlns:odum="http://odum.service.odp.ondemand.ca.com">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:addModifyUserRequest>
         <odum:user>
            <odum:emailAddress>' + $uidemail + '</odum:emailAddress>
            <odum:tenantName>' + $PortalTenant + '</odum:tenantName>
            <odum:active>true</odum:active>
            <odum:additionalEmailAddresses>
               <urn:item>
                  <odum:emailAddress>' + $email +'</odum:emailAddress>
                  <odum:emailAddressType>E-mail</odum:emailAddressType>
                  <odum:primary>true</odum:primary>
               </urn:item>
            </odum:additionalEmailAddresses>
            <odum:appInstances>
            <item>' + $PortalAppInstance + '</item>
            </odum:appInstances>
            <odum:firstName>' + $fname + '</odum:firstName>
            <odum:jobTitle>' + $jobtitle + '</odum:jobTitle>
            <odum:languageId>en_US</odum:languageId>
            <odum:lastName>' + $lname + '</odum:lastName>
            <odum:lockout>false</odum:lockout>
            <odum:phones>
               <urn:item>
                  <odum:number>' + $phone + '</odum:number>
                  <odum:phoneType>Business</odum:phoneType>
                  <odum:primary>true</odum:primary>
               </urn:item>
            </odum:phones>
            <odum:timezone>UTC</odum:timezone>
         </odum:user>
      </urn:addModifyUserRequest>
   </soapenv:Body>
</soapenv:Envelope>'
  return $strBody
}

function addModifyOdpUser {
  param($uidemail,$fname,$lname,$jobtitle,$email,$phone)
  $Body = createBody $uidemail $fname $lname $jobtitle $email $phone

  $portalrequest = Invoke-WebRequest -Uri $PortalWebService -Headers (@{ SOAPAction = 'Read' }) -Method Post -Body $Body -ContentType text/xml -Credential $cred

  if ($portalrequest.StatusCode -eq "200") {
    return $portalrequest
  }
  else {
    return "There was an error." + $portalrequest.StatusCode + ' was returned.'
  }
}

function printBody {
  param($uidemail,$fname,$lname,$jobtitle)
  $Body = createBody $uidemail $fname $lname $jobtitle $email $phone
  return $Body
}
