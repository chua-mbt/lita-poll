require "json"
require "lita/handlers/poll"

module Lita
  module Handlers
    class PollHandler < Handler
      route /^poll list$/, :list, help: {
        t("help.list.usage") => t("help.list.description")
      }
      def list(response)
        ids = redis.keys('*')
        if ids.empty?
          response.reply(t("replies.list.no_polls"))
        else
          response.reply(t("replies.list.header"))
          redis.keys('*').each do |id|
            poll = Poll.json_create(JSON.parse(redis.get(id)))
            response.reply(t("replies.list.poll", poll_id: poll.id, poll_topic: poll.topic))
          end
        end
      end

      route /^poll clear$/, :clear, help: {
        t("help.clear.usage") => t("help.clear.description")
      }, restrict_to: "poll_admins"
      def clear(response)
        redis.flushdb
        response.reply(t("replies.clear.success"))
      end

      route /^poll make (.+)$/, :make, help: {
        t("help.make.usage") => t("help.make.description")
      }
      def make(response)
        made = Poll.new(response.matches.pop[0])
        redis.set(made.id, made.to_json)
        response.reply(t("replies.make.success", poll_id: made.id, poll_topic: made.topic))
      end

      route Regexp.new("^poll option #{Poll::ID_REGEXP} (.+)$"), :option, help: {
        t("help.option.usage") => t("help.option.description")
      }
      def option(response)
        args = response.matches.pop
        id = args[0]
        poll = redis.get(id)
        option = args[1]
        if poll.nil?
          response.reply(t("replies.general.poll_not_found", id: id))
        else
          poll = Poll.json_create(JSON.parse(poll))
          poll.set_option(option)
          redis.set(poll.id, poll.to_json)
          response.reply(t("replies.option.success", option: option, poll_id: poll.id))
        end
      end

      route Regexp.new("poll info #{Poll::ID_REGEXP}$"), :info, help: {
        t("help.info.usage") => t("help.info.description")
      }
      def info(response)
        args = response.matches.pop
        id = args[0]
        poll = redis.get(id)
        if poll.nil?
          response.reply(t("replies.general.poll_not_found", id: id))
        else
          poll = Poll.json_create(JSON.parse(poll))
          idx = 0
          response.reply(t("replies.info.header", poll_topic: poll.topic))
          every(0.5) do |timer|
            if idx >= poll.options.length
              timer.stop
            else
              option = poll.options[idx]
              idx += 1
              response.reply(t("replies.info.option", idx: idx, option: option))
            end
          end
        end
      end

      route Regexp.new("^poll vote #{Poll::ID_REGEXP} (\\d+)$"), :vote, help: {
        t("help.vote.usage") => t("help.vote.description")
      }
      def vote(response)
        args = response.matches.pop
        id = args[0]
        optNum = args[1].to_i
        poll = redis.get(id)
        if poll.nil?
          response.reply(t("replies.general.poll_not_found", id: id))
        else
          poll = Poll.json_create(JSON.parse(poll))
          if poll.valid_vote?(optNum)
            poll.vote(response.user, optNum)
            redis.set(poll.id, poll.to_json)
            response.reply_privately(t(
              "replies.vote.success", option: poll.options[optNum-1]
            ))
          else
            response.reply_privately(t("replies.vote.not_found"))
          end
        end
      end

      route Regexp.new("^poll tally #{Poll::ID_REGEXP}$"), :tally, help: {
        t("help.tally.usage") => t("help.tally.description")
      }
      def tally(response)
        args = response.matches.pop
        id = args[0]
        poll = redis.get(id)
        if poll.nil?
          response.reply(t("replies.general.poll_not_found", id: id))
        else
          tally = []
          poll = Poll.json_create(JSON.parse(poll))
          poll.votes.each do |user, vote|
            vote = vote-1
            tally[vote] = tally[vote] ? tally[vote]+1 : 1
          end

          idx = 0
          response.reply(t("replies.tally.header"))
          every(0.5) do |timer|
            if idx >= poll.options.length
              timer.stop
            else
              option = poll.options[idx]
              response.reply(t(
                "replies.tally.option", option: option, votes: tally[idx] ? tally[idx] : 0
              ))
              idx += 1
            end
          end
        end
      end

      route Regexp.new("^poll complete #{Poll::ID_REGEXP}$"), :complete, help: {
        t("help.complete.usage") => t("help.complete.description")
      }, restrict_to: "poll_admins"
      def complete(response)
        redis.del(response.matches.pop[0])
        response.reply(t("replies.complete.success"))
      end
    end

    Lita.register_handler(PollHandler)
  end
end
