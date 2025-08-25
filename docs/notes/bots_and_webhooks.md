# Bots and Webhooks

## telegram-bot

- to send messages on telegram channel using telegram-api, with bot-account


**flow**

- create bot using `bot_father`, and save the access_token
    - edit bot's permission to give it ability to interact with `channels`

- create a new private-channel

- add new_bot as `admin` in new_channel 
    - try adding using mobile-phone, if unable to do from web
- remove `excess permissions`, keep only related to `post_message` 

- send message to channel using bot-api by providing `channel_id` in query param or as json_payload

>  always prefix channel_id with `-100`

```sh linenums="1"

$tele_base="https://api.telegram.org/bot<YOUR_BOT_TOKEN>"

curl -s -XPOST "$tele_base/sendMessage\
     -H "content-type:application/json"\
     -d '{"chat_id":"-1003051237226", "text":"text to private channel"}' | jq
```


**refer**

- <https://core.telegram.org/bots/tutorial>
- <https://core.telegram.org/bots/api#sendmessage>

## discord-webhook


**flow**

- create new channel, and then click on edit-channel
- click on integration and then click webhooks
- click `new-webhook` and copy the url



**refer**

- <https://discord.com/developers/docs/resources/webhook#execute-webhook>