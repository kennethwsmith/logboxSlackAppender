# logboxSlackAppender
LogBox Appender to send messages to Slack.

###Sample logBox declaration in Coldbox.cfc

```
logBox = {
	// Define Appenders
	appenders = {
		coldboxTracer = { class="coldbox.system.logging.appenders.ColdboxTracerAppender" },
		slackLog = {
		 class="appenders.SlackAppender",
		 properties =
			{
			 channel="XXX",
			 userToken="XXX"
			}
		}
	},
	// Root Logger
	root = { levelmax="INFO", appenders="coldboxTracer" },
	// Granular Categories
	categories = {
		"slack" = {appenders="slackLog"}
	}
};
```
## Example usage in coldbox handler
```
component extends="handlers.baseHandler" displayname="Foo" {
	property name="slackLogger" inject="logbox:logger:slack";

	public void function sendSlackMessage (event,rc,prc) {
		slackLogger.debug("*Blah*\n>blah\n>monkey");
		event.renderData(data="Sent Message");
	}
}
```