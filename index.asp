<!DOCTYPE html>
<html lang="en">
<head>
	<meta http-equiv="expires" content="-1" />
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<meta name="copyright" content="2013, Web Site Management" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge" >
	<title>Move It</title>
	<style type="text/css">
		body
		{
			padding: 50px 10px 10px 10px;
		}
		.template-page, .template-element, #cookie-data
		{
			display: none;
		}
	</style>
	<link rel="stylesheet" href="css/bootstrap.min.css" />
	<script type="text/javascript" src="js/jquery-1.8.3.min.js"></script>
	<script type="text/javascript" src="js/bootstrap.min.js"></script>
	<script type="text/javascript" src="js/jquery.cookie.js"></script>
	<script type="text/javascript" src="rqlconnector/Rqlconnector.js"></script>
	<script type="text/javascript">
		var LoginGuid = '<%= session("loginguid") %>';
		var SessionKey = '<%= session("sessionkey") %>';
		var RqlConnectorObj = new RqlConnector(LoginGuid, SessionKey);
		var CurrentPageGuid;
		var CurrentEditLinkGuid;
		var CurrentTargetPageGuid;
		var CurrentTargetEditLinkGuid;
	
		$(document).ready(function() {
			LoadCurrentPageGuid();
			
			LoadTargetPagesFromCookie();
			
			$('#target-pages').on('click', '.move-to-target-page', function(event){
				$('#target-page-dialog').modal('show');
				CurrentTargetPageGuid = $(this).attr('id');
				LoadStructuralElements(CurrentTargetPageGuid);
			});
			
			$('#target-page-dialog').on('click', '.move-to-target-element', function(event){
				CurrentTargetEditLinkGuid = $(this).attr('id');
				ConnectPage(CurrentTargetEditLinkGuid, CurrentPageGuid);
			});
		});
		
		function GetUrlVars(SourceUrl)
		{
			if(SourceUrl == undefined)
			{
				SourceUrl = window.location.href;
			}
			SourceUrl = new String(SourceUrl);
			var vars = [], hash;
			var hashes = SourceUrl.slice(SourceUrl.indexOf('?') + 1).split('&');
			for(var i = 0; i < hashes.length; i++)
			{
				hash = hashes[i].split('=');
				vars.push(hash[0]);
				vars[hash[0]] = hash[1];
			}
	
			return vars;
		}
		
		function GetSmartEditUrl()
		{
			var SmartEditURL = '';
			var objClipBoard = window.opener.document;
			if($(objClipBoard).find('iframe[name=Preview]').length > 0)
			{
				SmartEditURL = $(objClipBoard).find('iframe[name=Preview]').contents().get(0).location;
				SmartEditURL = new String(SmartEditURL);
			}
			
			return SmartEditURL;
		}
		
		function RefreshSmartEditUrl()
		{
			var SmartEditURL = GetSmartEditUrl();
			SmartEditURL = SmartEditURL.replace('ParentPageGUID=','ParentPageGUID=' + CurrentTargetPageGuid); 
			SmartEditURL = SmartEditURL.replace(CurrentEditLinkGuid,CurrentTargetEditLinkGuid);
			
			var objClipBoard = window.opener.document;
			if($(objClipBoard).find('iframe[name=Preview]').length > 0)
			{
				$(objClipBoard).find('iframe[name=Preview]').contents().get(0).location = SmartEditURL;
				//$(objClipBoard).find('iframe[name=Preview]').attr('src', SmartEditURL);
			}
			
			window.close();
		}
		
		function LoadCurrentPageGuid()
		{
			var SmartEditURL = GetSmartEditUrl();

			CurrentPageGuid = GetUrlVars(SmartEditURL)['EditPageGUID'];
			CurrentEditLinkGuid = GetUrlVars(SmartEditURL)['EditLinkGUID'];
		}

		function AddCurrentPageAsTargetPage()
		{
			LoadSimplePageInfo(CurrentPageGuid);
		}
		
		function AddTargetPage(PageGuid, PageId, PageHeadline)
		{
			if($('#cookie-data page[guid=' + PageGuid + ']').length != 0)
				return;
				
			$('#cookie-data').append('<page guid="' + PageGuid + '"/>');
			SaveTargetPagesToCookie();
		
			var TargetPageClone = $('.template-page').clone();
			$(TargetPageClone).removeClass('template-page');
			
			$(TargetPageClone).find('.close').attr('data-id', PageGuid);
			$(TargetPageClone).find('.move-to-target-page').attr('id', PageGuid);
			$(TargetPageClone).find('.page-id').text(PageId);
			$(TargetPageClone).find('.page-headline').text(PageHeadline);
			
			$('#target-pages').append($(TargetPageClone));
		}
		
		function AddTargetElement(ElementGuid, ElementName)
		{
			var TargetElementClone = $('.template-element').clone();
			$(TargetElementClone).removeClass('template-element');
			
			$(TargetElementClone).find('.move-to-target-element').attr('id', ElementGuid);
			$(TargetElementClone).find('.element-name').text(ElementName);
			
			$('#target-page-dialog .modal-body').append($(TargetElementClone));
		}
		
		function DeleteTargetPageFromCookie(DOM)
		{
			$('#cookie-data page[guid=' + $(DOM).attr('data-id') + ']').remove();
			
			SaveTargetPagesToCookie();
		}
		
		function SaveTargetPagesToCookie()
		{
			$.cookie('targetpages', $('#cookie-data').html());
		}
		
		function LoadTargetPagesFromCookie()
		{
			var TargetPages = $.cookie('targetpages');
			if(TargetPages != null)
			{
				
				TargetPages = '<pages>' + $.trim(TargetPages) + '</pages>';
				var TargetPagesDOM = $.parseXML(TargetPages);
				$(TargetPagesDOM).find('page').each(function(){
					LoadSimplePageInfo($(this).attr('guid'));
				});
			}
		}
		
		function LoadSimplePageInfo(PageGuid)
		{
			var strRQLXML = '<PAGE action="load" guid="' + PageGuid + '"/>';
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				AddTargetPage($(data).find('PAGE').attr('guid'), $(data).find('PAGE').attr('id'), $(data).find('PAGE').attr('headline'));
			});
		}
		
		function LoadStructuralElements(PageGuid)
		{
			var strRQLXML = '<PAGE guid="' + PageGuid + '" ><LINKS action="load"/></PAGE>';
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				$('#target-page-dialog .modal-body').empty();
				$(data).find('LINK').each(function(){
					if($(this).attr('islink') == '2')
					{
						AddTargetElement($(this).attr('guid'), $(this).attr('eltname'));
					}
				});
			});
		}
		
		function DisconnectPage(ConnectedElementGuid, PageGuid)
		{
			var strRQLXML = '';
			strRQLXML += '<LINK action="save" guid="' + ConnectedElementGuid + '">';
			strRQLXML += '<PAGES>';
			strRQLXML += '<PAGE deleted ="1" guid="' + PageGuid + '" />';
			strRQLXML += '</PAGES>';
			strRQLXML += '</LINK>';
				
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				// disconnected
				
				RefreshSmartEditUrl();
			});
		}
		
		function ConnectPage(ConnectedElementGuid, PageGuid)
		{
			$('#target-page-dialog .modal-body button').attr('disabled', 'disabled');
			
			var strRQLXML = '<CLIPBOARD action="AddPagesToLink" guid="' + ConnectedElementGuid + '" type="link"><ENTRY guid="' + PageGuid + '" type="page" /></CLIPBOARD>'
			
			RqlConnectorObj.SendRql(strRQLXML, false, function(data){
				// connected
				var ErrorText = $(data).find('ERROR').text();
				
				if(ErrorText != '')
				{
					$('#target-page-dialog .modal-body button').removeAttr('disabled');
					alert(ErrorText);
				}
				else
				{
					DisconnectPage(CurrentEditLinkGuid, PageGuid);
				}
			});
		}
	</script>
</head>
<body>
	<div class="navbar navbar-inverse navbar-fixed-top">
		<div class="navbar-inner">
			<div style="padding-left:15px;padding-right:15px;">
				<button class="btn btn-success" type="button" onclick="AddCurrentPageAsTargetPage()">Add Current Page as Target</button>
				<div class="pull-right">
					<button class="btn" type="button" onclick="window.close();">Close</button>
				</div>
			</div>
		</div>
	</div>
	<div id="target-page-dialog" class="modal hide fade" data-backdrop="static" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
		<div class="modal-header">
			<h3>Move Page To</h3>
		</div>
		<div class="modal-body">
		</div>
		<div class="modal-footer">
			<a href="#" class="btn" onclick="$('#target-page-dialog').modal('hide')">Close</a>
		</div>
	</div>
	<div id="target-pages">
		<div class="alert template-element">
			<button type="button" class="btn btn-success move-to-target-element">Move To</button>
			<span class="element-name"></span>
		</div>
		<div class="alert template-page">
			<button type="button" class="close" data-dismiss="alert" onclick="DeleteTargetPageFromCookie($(this))">&times;</button>
			<button type="button" class="btn btn-success move-to-target-page">Move To</button>
			[<span class="page-id"></span>] - <span class="page-headline"></span>
		</div>
		
	</div>
	<div id="cookie-data">
	</div>
</body>
</html>