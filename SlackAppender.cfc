component extends="coldbox.system.logging.AbstractAppender" output="false" hint="An appender that sends out a slack message"{

	public SlackAppender function init(required name, required struct properties="#structNew()#", required numeric levelMin=0, required numeric levelMax=4) hint="Constructor" output="false"{

		super.init(argumentCollection=arguments);
		if( NOT propertyExists("userToken") ){
			$throw(message="User Token is required",type="SlackAppender.PropertyNotFound");
		}
		if( NOT propertyExists("channel") ){
			$throw(message="Channel is required",type="SlackAppender.PropertyNotFound");
		}
		if( NOT propertyExists("appURI") ){
			setProperty("appURI","https://slack.com/api/");
		}
		if( NOT propertyExists("postAsUser") ){
			setProperty("postAsUser",true);
		}
		if( NOT propertyExists("useThread") ){
			setProperty("useThread",true);
		}
		if( NOT propertyExists("useSeverity") ){
			setProperty("useSeverity",true);
		}
		return this;
	}

	public void function logMessage(required any logEvent) hint="Write an entry into the logger."{

		var args = overrideProperties(arguments.logEvent);
		if (args.useSeverity) {
			args.messageText = buildSeverityMessage(arguments.logEvent.getSeverity()) & arguments.logEvent.getMessage();
		}
		else {
			args.messageText = arguments.logEvent.getMessage();
		}
		args.attachments = getAttachments(arguments.logEvent,args.useSeverity);
		try {
			if (!args.useThread) {
				var reply = postMessage( argumentCollection=args );
			}
			else {
				thread name="logSlackMessage#getTickCount()#" args=args {
					var reply = postMessage( argumentCollection=args );
				}	
			}
		}
		catch(any e) {
			$log("ERROR","Error sending message from appender #getName()#. #e.message# #e.detail# #e.stacktrace#");
		}
	}

	private any function postMessage(required array attachments, required string userToken, required string appURI, required string channel, required boolean postAsUser, required string messageText) {
		arguments.action = "chat.postMessage";
		return sendRequest(argumentCollection=arguments);	
	}

	private any function sendRequest(required string action, required array attachments, required string userToken, required string appURI, required string channel, required boolean postAsUser, required string messageText) {

		var httpService = new http();
			httpService.setURL(arguments.appURI&arguments.action);
			httpService.setMethod("POST");
			httpService.setTimeout(5);
			httpService.setUserAgent("LogBox Slack Appender");
			httpService.addParam(type="formfield",name="channel",value=arguments.channel);
			httpService.addParam(type="formfield",name="as_user",value=arguments.postAsUser);
			httpService.addParam(type="formfield",name="text",value=arguments.messageText);
			httpService.addParam(type="formfield",name="token",value=arguments.userToken);
			if ( structKeyExists(arguments,"attachments") )
				httpService.addParam(type="formfield",name="attachments",value=serializeJSON(arguments.attachments));
			
		var reply = httpService.send().getPrefix();

		return reply;
	}

	private string function buildSeverityMessage(required numeric severity) {
		var oSev = decodeSeverity(arguments.severity);
		return "#oSev.emoji# *#oSev.severityText#*: ";
	}

	private array function getAttachments(required any logEvent, required boolean useSeverity) {
		var extraInfo = arguments.logEvent.getExtraInfo();
		if (isStruct(extraInfo) && structKeyExists(extraInfo,"attachments")) {
			if (arguments.useSeverity) {
				return replaceColors(extraInfo.attachments,arguments.logEvent.getSeverity());
			}
			else {
				return extraInfo.attachments
			}
		}
		return [];
	}

	private array function replaceColors(required array attachments, required numeric severity) {
		var oSev = decodeSeverity(arguments.severity);
		for(var a in arguments.attachments) {
			if (StructKeyExists(a,"color")) {
				a.color = oSev.color;
			}
		}
		return arguments.attachments;
	}

	private struct function overrideProperties(required any logEvent) {
		var props = {
			userToken = getProperty('userToken'),
			channel = getProperty('channel'),
			appURI = getProperty('appURI'),
			postAsUser = getProperty('postAsUser'),
			useThread = getProperty('useThread'),
			useSeverity = getProperty('useSeverity')
		};
		var extraInfo = arguments.logEvent.getExtraInfo();
		if (isStruct(extraInfo) && structKeyExists(extraInfo,"overrideProperties")) {
			if( structKeyExists(extraInfo.overrideProperties,"userToken") )
				props.userToken = extraInfo.overrideProperties.userToken;
			if( structKeyExists(extraInfo.overrideProperties,"channel") )
				props.channel = extraInfo.overrideProperties.channel;
			if( structKeyExists(extraInfo.overrideProperties,"appURI") )
				props.appURI = extraInfo.overrideProperties.appURI;
			if( structKeyExists(extraInfo.overrideProperties,"postAsUser") )
				props.postAsUser = extraInfo.overrideProperties.postAsUser;
			if( structKeyExists(extraInfo.overrideProperties,"useThread") )
				props.useThread = extraInfo.overrideProperties.useThread;
			if( structKeyExists(extraInfo.overrideProperties,"useSeverity") )
				props.useSeverity = extraInfo.overrideProperties.useSeverity;
		}
		return props;
	}

	private struct function decodeSeverity(required numeric severity){
		var oSev = {};
		switch(arguments.severity){
			case 0:
				oSev.severityText = "Fatal";
				oSev.emoji = ":skull:";
				oSev.color = "##000000";
				break;
			case 1:
				oSev.severityText = "Error";
				oSev.emoji = ":bomb:";
				oSev.color = "##FF0000";
				break;
			case 2:
				oSev.severityText = "Warning";
				oSev.emoji = ":warning:";
				oSev.color = "##FF8C00";
				break;
			case 3:
				oSev.severityText = "Info";
				oSev.emoji = ":bulb:";
				oSev.color = "##228822";
				break;
			default:
				oSev.severityText = "Debug";
				oSev.emoji = ":beetle:";
				oSev.color = "##00BFFF";
		}

		return oSev;
	}

}