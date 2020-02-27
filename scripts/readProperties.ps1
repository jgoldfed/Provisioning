function ReadProperties {
  param($content)
  $AppProps = ConvertFrom-StringData (Get-Content $content -Raw)
  return $AppProps
}

$props = ReadProperties ("$PSScriptRoot\..\properties\PortalUsers.properties")
