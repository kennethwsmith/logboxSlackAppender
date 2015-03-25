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
		if( NOT propertyExists("threadPost") ){
			setProperty("threadPost",true);
		}
		return this;
	}

	public void function logMessage(required any logEvent) hint="Write an entry into the logger."{

		if (!getProperty('threadPost')) {
			postMessage( channel=getProperty('channel'), messageText=arguments.logEvent.getMessage() );
		}
		else {
			thread name=reReplace(createUUID(),'\W','','all') loge=arguments.logEvent channel=getProperty("channel") {
				try {
					postMessage( channel=channel, messageText=loge.getMessage() );
				}
				catch(any e) {
					$log("ERROR","Error sending message from appender #getName()#. #e.message# #e.detail# #e.stacktrace#");
				}
			};
		}

	}

	private string function getSeverity(required numeric severity){
		switch(arguments.severity){
			case 0:
				var eventType = "FATAL";
				break;
			case 1:
				var eventType = "ERROR";
				break;
			case 2:
				var eventType = "WARN";
				break;
			case 3:
				var eventType = "INFO";
				break;
			default:
				var eventType = "DEBUG";
		}

		return eventType;
	}

	private string function buildMessage(required string channel, required string action, boolean as_user = true, required string messageText){

		var buffer="";
		buffer = buffer & getProperty("appURI");
		buffer = buffer & arguments.action;
		buffer = buffer & "?channel=#arguments.channel#";
		buffer = buffer & "&as_user=#arguments.as_user.toString()#";
		buffer = buffer & "&text=#arguments.messageText#";
		buffer = buffer & "&token=#getProperty('userToken')#";
		return buffer;
	}

	private any function postMessage(required string channel, required string messageText) {

		arguments.action = "chat.postMessage";
		arguments.as_user = getProperty("postAsUser");
		var appURL = buildMessage(argumentCollection=arguments);

		return sendRequest(appURL);	
	}

	private any function sendRequest(required string appURL) {

		var httpService = new http();
			httpService.setURL(arguments.appURL);
			httpService.setMethod("GET");
			httpService.setTimeout(5);
			httpService.setUserAgent("LogBox Slack Appender");

		return httpService.send().getPrefix();
	}

}