require "spec_helper"

describe Lita::Handlers::PollHandler, lita_handler: true do
  ph = Lita::Handlers::PollHandler
  topics = ['Topic1', 'Topic2']
  options = ['Option1', 'Option2', 'Option3']
  topic1Id = Poll.new(topics.first).id

  let(:poll_admin) do
    user = Lita::User.create(1, name: "Poll Admin")
    Lita::Authorization.new(registry.config).add_user_to_group!(user, :poll_admins)
    user
  end
  let(:poll_user1) { Lita::User.create(2, name: "Poll User1") }
  let(:poll_user2) { Lita::User.create(3, name: "Poll User2") }

  it { is_expected.to route_command("poll list").to(:list) }
  topics.each { |topic|
    poll = Poll.new(topic)
    it { is_expected.to route_command("poll make "+topic).to(:make) }
    it { is_expected.to route_command("poll option "+poll.id+" Option 1").to(:option) }
    it { is_expected.to route_command("poll info "+poll.id).to(:info) }
    it { is_expected.to route_command("poll vote "+poll.id+" 1").to(:vote) }
    it { is_expected.to route_command("poll tally "+poll.id).to(:tally) }
    it { is_expected.not_to route_command("poll complete "+poll.id).to(:complete) }
    it { is_expected.to route_command("poll complete "+poll.id).with_authorization_for(:poll_admins).to(:complete) }

  }
  it { is_expected.to route_command("poll clear").with_authorization_for(:poll_admins).to(:clear) }
  it { is_expected.not_to route_command("poll clear").to(:clear) }

  describe "polling for users" do
    it "no polls" do
      send_command('poll list', as: poll_user1)
      expect(replies.last).to eq(ph::translate("replies.list.no_polls"))
    end

    it "invalid poll" do
      dummy_topic = 'Dummy'
      dummy_poll = Poll.new(dummy_topic)
      send_command('poll option '+dummy_poll.id+' DummyOption', as: poll_user1)
      send_command('poll vote '+dummy_poll.id+' 1', as: poll_user1)
      send_command('poll info '+dummy_poll.id, as: poll_user1)
      send_command('poll tally '+dummy_poll.id, as: poll_user1)
      replies.each { |reply|
        expect(reply).to eq(ph::translate("replies.general.poll_not_found", id: dummy_poll.id))
      }
    end

    it "make and use polls" do
      # make
      topics.each { |topic|
        poll = Poll.new(topic)
        send_command('poll make '+topic, as: poll_user1)
        success = ph::translate("replies.make.success", poll_id: poll.id, poll_topic: poll.topic)
        expect(replies.last).to eq(success)
      }
      # list
      send_command('poll list', as: poll_user2)
      list_reply = replies.last(topics.length+1)
      expect(list_reply.first).to eq(ph::translate("replies.list.header"))
      topics.each { |topic, reply|
        poll = Poll.new(topic)
        success = ph::translate("replies.list.poll", poll_id: poll.id, poll_topic: poll.topic)
        expect(list_reply.drop(1)).to include(success)
      }
      # add options
      options.each { |option|
        topic = topics.first
        poll = Poll.new(topic)
        send_command('poll option '+poll.id+' '+option, as: poll_user1)
        success = ph::translate("replies.option.success", option: option, poll_id: poll.id)
        expect(replies.last).to eq(success)
      }
      # check poll info
      send_command('poll info '+topic1Id, as: poll_user2)
      sleep(2)
      info_reply = replies.last(options.length+1)
      expect(info_reply.first).to eq(ph::translate("replies.info.header", poll_topic: topics.first))
      options.zip(info_reply.drop(1)).each_with_index.each { |pair, idx|
        option = pair.first
        reply = pair.last
        success = ph::translate("replies.info.option", idx: idx+1, option: option)
        expect(reply).to eq(success)
      }
      # voting and tallying
      send_command('poll vote '+topic1Id+' 1', as: poll_user1)
      expect(replies.last).to eq(ph::translate("replies.vote.success", option: options[0]))
      send_command('poll vote '+topic1Id+' 2', as: poll_user2)
      expect(replies.last).to eq(ph::translate("replies.vote.success", option: options[1]))
      send_command('poll tally '+topic1Id, as: poll_user2)
      sleep(2)
      tally_reply = replies.last(options.length+1)
      expect(tally_reply[0]).to eq(ph::translate("replies.tally.header"))
      expect(tally_reply[1]).to eq(ph::translate("replies.tally.option", option: options[0], votes: 1))
      expect(tally_reply[2]).to eq(ph::translate("replies.tally.option", option: options[1], votes: 1))
      expect(tally_reply[3]).to eq(ph::translate("replies.tally.option", option: options[2], votes: 0))
      # change vote
      send_command('poll vote '+topic1Id+' 3', as: poll_user1)
      expect(replies.last).to eq(ph::translate("replies.vote.success", option: options[2]))
      send_command('poll tally '+topic1Id, as: poll_user2)
      sleep(2)
      tally_reply = replies.last(options.length+1)
      expect(tally_reply[0]).to eq(ph::translate("replies.tally.header"))
      expect(tally_reply[1]).to eq(ph::translate("replies.tally.option", option: options[0], votes: 0))
      expect(tally_reply[2]).to eq(ph::translate("replies.tally.option", option: options[1], votes: 1))
      expect(tally_reply[3]).to eq(ph::translate("replies.tally.option", option: options[2], votes: 1))
      # voting for non-existent options
      send_command('poll vote '+topic1Id+' 4', as: poll_user1)
      expect(replies.last).to eq(ph::translate("replies.vote.not_found"))
    end
  end

  describe "poll administration" do
    it "complete poll" do
      topics.each { |topic|
        poll = Poll.new(topic)
        send_command('poll make '+topic, as: poll_user1)
      }
      send_command('poll complete '+topic1Id, as: poll_admin)
      expect(replies.last).to eq(ph::translate("replies.complete.success"))
      send_command('poll list', as: poll_user1)
      sleep(2)
      list_reply = replies.last(topics.length)
      expect(list_reply.first).to eq(ph::translate("replies.list.header"))
    end

    it "clear polls" do
      topics.each { |topic|
        poll = Poll.new(topic)
        send_command('poll make '+topic, as: poll_user1)
      }
      send_command('poll clear', as: poll_admin)
      expect(replies.last).to eq(ph::translate("replies.clear.success"))
      send_command('poll list', as: poll_user1)
      expect(replies.last).to eq(ph::translate("replies.list.no_polls"))
    end
  end

end
