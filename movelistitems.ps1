####################################################################
#Copy/Replace items from one list to another list with Attachments between Sharepoint Sites
#Original Author:Deon van Zyl
#Date: 30 Nov 2016
####################################################################

#source = https://oldsite.com/Lists/3p_applicants
#destination = https://newsite.com/Lists/3P%20Capture

Remove-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue
Add-PSSnapin Microsoft.SharePoint.PowerShell -erroraction SilentlyContinue

	try
	{

   $srcListSiteUrl = "https://oldsite.com/"    
   $SourceListName = "3p_applicants"     
   $dstListSiteUrl = "https://newsite.com/"    
   # original list below
  # $DestinationListName = "3P Capture"     
	$DestinationListName = "3p_applicants"  
   $keyColumnInternalName = "3pReqNumber" 

	
	
	$sourceListWeb = Get-SPWeb -identity $srcListSiteUrl
	$sourceListUrl = $sourceListWeb.ServerRelativeUrl + "/lists/" + $SourceListName;
	
	$dstListWeb = Get-SPWeb -identity $dstListSiteUrl
	$destinationListUrl = $dstListWeb.ServerRelativeUrl + "/lists/" + $DestinationListName;
	
	#$SourceList = $sourceListWeb.GetList($sourceListUrl);
    $SourceList = $sourceListWeb.GetList( "https://oldsite.com/Lists/3p_applicants" )

	#$DestinationList = $dstListWeb.GetList($destinationListUrl);

    $DestinationList = $dstListWeb.GetList( "https://newsite.com/Lists/3p_applicants" )
	
	$sourceSPListItemCollection = $SourceList.GetItems(); 


	foreach($srcListItem in $sourceSPListItemCollection)
	{  
		
		#CAML query of the common column (generally the title column or any unique column)
		$keyValue = $srcListItem[$keyColumnInternalName]
		$camlQuery =
		 "<Where>
		   <Eq>
			<FieldRef Name=" + $keyColumnInternalName + " />
			  <Value Type='Text'>" + $keyValue + "</Value>
		   </Eq>
		 </Where>"
		$spQuery = new-object Microsoft.SharePoint.SPQuery
		$spQuery.Query = $camlQuery
		$spQuery.RowLimit = 1
		#check if the item is already present in destination list
		$destItemCollection = $DestinationList.GetItems($spQuery)

       #  Write-host "  Found $($srcListItem.Fields)" -foregroundcolor white
       # write-host ($srcListItem.Fields.List.Title)

      # write-host "  Found ($destItemCollection.Count)" -foregroundcolor white

		if($destItemCollection.Count -gt 0)
		{
			write-host "list item already exists, updating "
			foreach($dstListItem in $destItemCollection)
			{
				foreach($spField in $dstListItem.Fields) 
				{  
				  if ($spField.ReadOnlyField -ne $True -and  $spField.InternalName -ne "Attachments") 
				  {  
					 $dstListItem[$spField.InternalName] = $srcListItem[$spField.InternalName];  
				  }  
				} 
					
			  # Handle Attachments  
			  foreach($leafName in $srcListItem.Attachments) 
			  {  
			    $spFile = $SourceList.ParentWeb.GetFile($srcListItem.Attachments.UrlPrefix + $leafName)  
			    $dstListItem.Attachments.Add($leafName, $spFile.OpenBinary());  
			  } 
    		  $dstListItem.Update()
			  
			}
		}
		else
		{
			write-host "adding new item"

			$newSPListItem = $DestinationList.AddItem(); 
			
			foreach($spField in $srcListItem.Fields) 
			{  
			  if ($spField.ReadOnlyField -ne $True -and  $spField.InternalName -ne "Attachments") 
			  {  
				  $newSPListItem[$spField.InternalName] = $srcListItem[$spField.InternalName];  
			  }  
			}
			 # Handle Attachments
			foreach($leafName in $srcListItem.Attachments) 
			  {  
			    $spFile = $SourceList.ParentWeb.GetFile($srcListItem.Attachments.UrlPrefix + $leafName)  
			    $newSPListItem.Attachments.Add($leafName, $spFile.OpenBinary());  
			  } 			
			$newSPListItem.Update()
		}

	 
	}
		
	}
	catch
	{
		write-host $_.exception
			
	}
	finally
	{


            # Delete all items from Temp Table
            $ItemCount = $sourceSPListItemCollection.Count - 1
            for($IntIndex = $ItemCount; $IntIndex -gt -1; $IntIndex--)
            {
                    $sourceSPListItemCollection.Delete($IntIndex);
            }
            #end Delete All items 

		if($sourceListWeb -ne $null){$sourceListWeb.Dispose()}
		if($dstListWeb -ne $null){$dstListWeb.Dispose()}
		
	}