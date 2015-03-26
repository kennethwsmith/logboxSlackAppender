# logboxSlackAppender
LogBox Appender to send messages to Slack.

## Property description
* userToken (required) - Token of the User for Slack
* channel (required) - channel name or ID
* appURI - URI of slack API
* postAsUser - whether to post as anonymous bot, or as the user from token
* useThread - whether to thread the http request
* useSeverity - whether to include emoji and colors based off logBox severity

## Example logBox declaration in Coldbox.cfc
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
## Simple usage in a handler
```
component extends="handlers.baseHandler" displayname="Foo" {
	property name="slackLogger" inject="logbox:logger:slack";

	public void function sendSlackMessage (event,rc,prc) {
		slackLogger.debug("Some Debug Data");
		event.renderData(data="Sent Message");
	}
}
```
## Usage with overriding properties
Create an `extraInfo` struct with an `overrideProperties` struct that overrides the default properties
```
component extends="handlers.baseHandler" displayname="Foo" {
	property name="slackLogger" inject="logbox:logger:slack";
	var extraInfo = {
		overrideProperties = { //optional
			channel = "customChannel", //Dont use the channel that was defined when the logger was setup, use this one.
			postAsUser = false //Post as anonymous bot, not the user
		}
	}
	public void function sendSlackMessage (event,rc,prc) {
		slackLogger.info("Some informative info",extraInfo);
		event.renderData(data="Sent Message");
	}
}
```
## Usage with attachments
Create an `extraInfo` struct with an `attachments` array defined by slack here: https://api.slack.com/docs/attachments

```
component extends="handlers.baseHandler" displayname="Foo" {
	property name="slackLogger" inject="logbox:logger:slack";
	var extraInfo = {
		attachments =  [
			{
			"fallback": "Required plain-text summary of the attachment.",
			"color": "##36a64f",
			"pretext": "Optional text that appears above the attachment block",
			"author_name": "Bobby Tables",
			"author_link": "http://flickr.com",
			"author_icon": "http://png-2.findicons.com/files/icons/1609/ose_png/256/warning.png",
			"title": "Slack API Documentation",
			"title_link": "https://api.slack.com/",
			"text": "Optional text that appears within the attachment",
			"fields": [
				{
					"title": "Text",
					"value": "Foo",
					"short": true
				},
				{
					"title": "Stuff",
					"value": "Bar",
					"short": true
				}
			],
			"image_url": "http://my-website.com/path/to/image.jpg"
			}
		]
	}
	public void function sendSlackMessage (event,rc,prc) {
		slackLogger.warn("Some warning info",extraInfo);
		event.renderData(data="Sent Message");
	}
}
```