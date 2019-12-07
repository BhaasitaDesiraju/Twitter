defmodule FinalTest do
use ExUnit.Case
doctest Final
doctest Server
doctest Client

test "Debug" do
  Final.main(["10", "5"]) == "hello"
end

test "Register User Test" do
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverPID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser1"
  assert Client.registerUser(serverPID, userName, self()) == :ok
  assert_receive({:userRegistered, user})
  assert user == userName
end

test "Send Tweet for a registered user" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser2"
  Client.registerUser(serverPID, userName, self())
  testTweet = Client.getRandomTweet()
  # output = "#{userName} tweeted: #{testTweet}"
  assert Client.sendTweets(serverPID, userName, self(), numOfRequests, testTweet) == :ok
  assert_receive({:userTweeted, tweet})
  assert tweet == testTweet
end

test "Checking if the tweet is being sent correctly" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser3"
  Client.registerUser(serverPID, userName, self())
  randomTweet = "abcdhsfjhs"
  testTweet = Client.getRandomTweet()
  assert Client.sendTweets(serverPID, userName, self(), numOfRequests, testTweet) == :ok
  assert_receive({:userTweeted, tweet})
  refute tweet == randomTweet
  assert tweet == testTweet
end

test "Send Tweet for an user that is not registered" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser4"
  testTweet = Client.getRandomTweet()
  # output = "#{userName} tweeted: #{testTweet}"
  assert Client.sendTweets(serverPID, userName, self(), numOfRequests, testTweet) == :ok
  assert_receive({:userTweeted, tweet})
  refute tweet == testTweet
end


test "Send Tweet with hashtag to a registered user" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser5"
  Client.registerUser(serverPID, userName, self())
  testTweet = Client.getRandomTweet()
  assert Client.sendTweetsWithHashtags(serverPID, userName, self(), numOfRequests, testTweet) == :ok
  assert_receive({:userTweetedWithHashTags, tweet})
  assert tweet == testTweet
end

test "Send Tweet with mention to a registered user" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser6"
  mentionedUser = "testUser2"
  Client.registerUser(serverPID, userName, self())
  testTweet = Client.getRandomTweet()
  assert Client.sendTweetsWithMention(serverPID, userName, self(), numOfRequests, testTweet, mentionedUser) == :ok
  assert_receive({:userTweetedWithMentions, tweet})
  assert tweet == testTweet
end

test "Send Tweet with mention to a user that is not registered" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser6"
  mentionedUser = "testUser2"
  Client.registerUser(serverPID, userName, self())
  testTweet = Client.getRandomTweet()
  assert Client.sendTweetsWithMention(serverPID, userName, self(), numOfRequests, testTweet, mentionedUser) == :ok
  assert_receive({:userTweetedWithMentions, tweet})
  assert tweet == testTweet
end

end
