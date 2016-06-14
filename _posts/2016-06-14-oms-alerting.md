---
layout: post
title: OMS Webhook Alerting
comments: true
categories: OMS
---
Today i started experimenting with the webhooks alert feature inside Operations Management Suite.

This is awesome, as it allows me to send alert data into my preferred system using webhooks.

We are using slack for internal communications and so this is a sensible and support place to send the relevant alert information.  I have setup a channel named #alerts which is where i stream in various alerts.

After enabling the webhook in the OMS alert setup page, you can either send the default json payload, or create your own custom payload.

Slack accepts specifically formatted json payloads, so in this case, i will need to tick the checkbox "Include custom JSON payload" so that i can format it in a way that slack is happy with.

Before that though, i need to know what OMS actually sends in its default payload so that i can look through the available fields and use them to compose my own.

To do this i can use a resource like [RequestBin](http://requestb.in) to send my test payload to.  To do so, I create a "Request Bin" and copy the url provided into the OMS Webhook URL field, and send off a test hook.

Refresh the RequestBin page and it will show you the request as well as the request body.

Copy this into a resource like [Json Parser Online](http://json.parser.online.fr/) and it will prettify it and make it more readable.  Now you can see the full request with all the fields that OMS sent.

Below are the results from my test.

```json
{
"WorkspaceId":"{GUID}",
"AlertRuleName":"An account failed to log on : BAD PASSWORD",
"SearchQuery":"Type=SecurityEvent EventID=4625 e4625_SubStatus_CF=0xc0000064",
"AlertThresholdOperator":"gt",
"AlertThresholdValue":5,
"SearchIntervalStartTimeUtc":"2016-06-14T04:02:25.000Z",
"SearchIntervalEndtimeUtc":"2016-06-14T04:07:25.014Z",
"ResultCount":"1 results",
"SearchIntervalInSeconds":"300",
"LinkToResults":"https://{GUID}.portal.mms.microsoft.com/#Workspace/search/index?_timeInterval.intervalEnd=2016-06-14T04:07:25.014Z&_timeInterval.intervalDuration=300&q=Type=SecurityEvent EventID=4625 e4625_SubStatus_CF=0xc0000064",
"Description":""
}
```

Now i can use these fields to build my own request.  To use a field in the payload you must prefix the field name with a `#` symbol. eg `#fieldname`

I am no JSON guru, so i used Slacks [Message Builder](https://api.slack.com/docs/formatting/builder) along with some examples of a slack json payload i found here [MS Technet](https://blogs.technet.microsoft.com/msoms/2016/03/30/introducing-webhook-support-for-oms-alerts/)

My finished payload looks like this.

```json
{
  "text":"#alertrulename with #searchresultcount. This exceeds the threshold of #thresholdvalue in #searchinterval seconds.",
  "attachments":[
    {
    "title":"Details",
    "fields":[
      {
      "title":"SearchIntervalStartTimeUtc",
      "value":"#searchintervalstarttimeutc"
      },
      {
      "title":"SearchIntervalEndtimeUtc",
      "value":"#searchintervalendtimeutc"
      },
      {
      "title":"SearchResultCount",
      "value":"#searchresultcount"
      },
      {
      "title":"SearchQuery",
      "value":"#searchquery"
      }
      ]
    }
  ]
}
```

I then copy this into my OMS custom JSON payload field, and i am all set!.

To make this all work yourself, you will need a slack account, and first create the webhook url in slack.

Use this site to get more information about [Slack Webhooks](https://api.slack.com/incoming-webhooks)

Use this site to create yourself a [Slack Webhook](https://slack.com/apps/manage/custom-integrations)

Gotchas:  One problem i came across was some of the values that the fields returned, and also some of the fields themselves did not expand its values, eg the field was not supported/recognised.  I will reach out to an OMS Engineer to see if they are able to answer these issues and post results back here if any.

#### Issues / Notes
1. All fields MUST be in lowercase to expand.
2. Field "#resultcount" is not recognised, "#searchresultcount" must be used instead.
3. Field "#alertthresholdvalue" is not recognised, "#thresholdvalue" must be used instead.

Here is the end result of an alert in OMS being sent to my slack channel using a custom JSON payload.

![OMS-bad-password-alert](/img/oms-bad-password.png)
