function RqlConnector(LoginGuid, SessionKey) {
  this.LoginGuid = LoginGuid;
  this.SessionKey = SessionKey;
  this.DCOM = 'DCOM';
  this.DCOMUrl = 'rqlaction.asp';
  this.WebService11 = 'WebService11';
  this.WebService11Url = '/CMS/WebService/RqlWebService.svc';
  this.RqlConnectionType = '';
  this.InitializeConnectionType();
}

RqlConnector.prototype.SetConnectionType =function (ConnectionType)
{
	this.RqlConnectionType = ConnectionType;
}

RqlConnector.prototype.GetConnectionType =function ()
{
	return this.RqlConnectionType;
}

RqlConnector.prototype.InitializeConnectionType =function ()
{
	if(this.GetConnectionType() == '')
	{
		if(this.TestConnection(this.WebService11Url))
		{
			this.SetConnectionType(this.WebService11);
		}else{
			this.SetConnectionType(this.DCOM);
		}
	}
}

RqlConnector.prototype.SendRql = function(InnerRQL, IsText, CallbackFunc)
{
	switch(this.GetConnectionType())
	{
		case this.DCOM:
			this.SendRqlCOM(InnerRQL, IsText, CallbackFunc);
			break;
		case this.WebService11:
			this.SendRqlWebService(InnerRQL, IsText, CallbackFunc);
			break;
	}
}

RqlConnector.prototype.SendRqlWebService = function(InnerRQL, IsText, CallbackFunc)
{
	var SOAPMessage = '';
	SOAPMessage += '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">';
	SOAPMessage += '<s:Body><q1:Execute xmlns:q1="http://tempuri.org/RDCMSXMLServer/message/"><sParamA>' + this.padRQLXML(InnerRQL, IsText) + '</sParamA><sErrorA></sErrorA><sResultInfoA></sResultInfoA></q1:Execute></s:Body>';
	SOAPMessage += '</s:Envelope>';
	
	$.ajax({
		type: 'POST',
		url: this.WebService11Url,
		data: SOAPMessage,
		contentType: 'text/xml; charset=utf-8',
		dataType: 'xml',
		beforeSend: function(xhr) {
			xhr.setRequestHeader('SOAPAction', 'http://tempuri.org/RDCMSXMLServer/action/XmlServer.Execute');
		},
		success: function (data) {
			var RetRql = $(data).find('Result').text();
			var RetRqlError = $(data).find('sErrorA').text();
			
			if(IsText)
			{
				data = RetRql;
			}
			else
			{
				RetRql = '<RQL>' + $.trim(RetRql) + '<ERROR>' + RetRqlError + '</ERROR>' + '</RQL>';
				data = $.parseXML(RetRql);
			}

			CallbackFunc(data);
		},
		error: function (message) {
			//alert(message);
			CallbackFunc(message);
		}
	});
}

RqlConnector.prototype.SendRqlCOM = function(InnerRQL, IsText, CallbackFunc)
{
	var Rql = this.padRQLXML(InnerRQL, IsText);
	$.post(this.DCOMUrl, { rqlxml: Rql },
	function(data){
		data = $('<div/>').append(data);
		CallbackFunc(data);
	});
}

RqlConnector.prototype.padRQLXML =function (InnerRQL, IsText)
{
	var Rql = '<IODATA loginguid="' + this.LoginGuid + '" sessionkey="' + this.SessionKey + '"';
	if(IsText)
	{
		Rql += ' format="1"';
	}
	
	Rql += '>' + InnerRQL + '</IODATA>';
	
	if(this.GetConnectionType(this.WebService11) == this.WebService11)
	{
			Rql = '<![CDATA[' + Rql + ']]>';
	}
		
	return Rql;
}

RqlConnector.prototype.TestConnection =function (Url)
{
  var http = new XMLHttpRequest();
  http.open('HEAD', Url, false);
  http.send();
  return http.status!=404;
}