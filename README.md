# lita-poll

Plugin that enables polling functionality for a lita bot.

## Installation

Add lita-poll to your Lita instance's Gemfile:

``` ruby
gem "lita-poll"
```

## Usage

Poll commands are prefixed with 'poll'.

Created topics are given a 3-hex id and stored in redis.

The following commands are available to all users:

* poll list - List existing polls
* poll make [topic] - Create a new poll on [topic]
* poll option [pollId] [option] - Add [option] to poll with [pollId]
* poll info [pollId] - Shows information on poll with [pollId]
* poll vote [pollId] [optNum] - Vote for [optNum] on poll with [pollId]
* poll tally [pollId] - Tally poll with [pollId]

The following commands are only available to members of the poll_admins group:

* poll clear - Clear existing polls
* poll complete [pollId] - End poll with [pollId]

## License

[MIT](http://opensource.org/licenses/MIT)
