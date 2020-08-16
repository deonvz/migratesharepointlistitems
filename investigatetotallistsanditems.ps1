Add-PSSnapin Microsoft.SharePoint.PowerShell –erroraction SilentlyContinue

$ListsInfo = @{}
$TotalItems = 0
$SiteCollection = Get-SPSite "https://someoldsite.com/"
ForEach ($Site in $SiteCollection.AllWebs)
{
    ForEach ($List in $Site.Lists)
    {
        $ListsInfo.Add($Site.Url + " - " + $List.Title, $List.ItemCount)
        $TotalItems += $List.ItemCount
    }
}
$ListsInfo.GetEnumerator() | sort name | Format-Table -Autosize
Write-Host "Total number of Lists: " $ListsInfo.Count
Write-Host "Total number of ListItems: " $TotalItems