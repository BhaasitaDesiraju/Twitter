defmodule FinalTest do
use ExUnit.Case
doctest Final
doctest Server
doctest Client

# test "Debug" do
#   Final.main(["10", "5"]) == "hello"
# end

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
  err = try do
     Client.sendTweets(serverPID, userName, self(), numOfRequests, testTweet)
  rescue
    e in UserNotFoundError -> e
  end
  assert err.message == "User not found!"
end


test "Send Tweet with hashtag to a registered user" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser5"
  Client.registerUser(serverPID, userName, self())
  testTweet = Client.getTweetsWithHashtags()
  assert Client.sendTweetsWithHashtags(serverPID, userName, self(), numOfRequests, testTweet) == :ok
  assert_receive({:userTweetedWithHashTags, tweet})
  assert tweet == testTweet
end

test "A user that's not registered tries to send a tweet with hashtag" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser6"
  testTweet = Client.getTweetsWithHashtags()
  err = try do
     Client.sendTweetsWithHashtags(serverPID, userName, self(), numOfRequests, testTweet)
  rescue
    e in UserNotFoundError -> e
  end
  assert err.message == "User not found!"
end


test "Send Tweet with mention to a registered user" do
  numOfRequests = 5
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser7"
  mentionedUser = "randomUser1"
  mentionedUserPID = spawn fn -> mentionedUser end
  Client.registerUser(serverPID, userName, self())
  Client.registerUser(serverPID, mentionedUser, mentionedUserPID)
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
  userName = "testUser8"
  mentionedUser = "randomUser2"
  Client.registerUser(serverPID, mentionedUser, self())
  testTweet = Client.getRandomTweet()
  err = try do
    Client.sendTweetsWithMention(serverPID, userName, self(), numOfRequests, testTweet, mentionedUser)
  rescue
    e in UserNotFoundError -> e
  end
  assert err.message == "User not found!"
end

# test for retweet
test "Retweet by a registered user" do
  numOfRequests = 5
  numOfUsers = 10
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName1 = "tweetTestUser"
  user1Pid = spawn fn -> userName1 end
  Client.registerUser(serverPID, userName1, user1Pid)
  userName2 = "retweetTestUser"
  user2Pid = spawn fn -> userName2 end
  Client.registerUser(serverPID, userName2, user2Pid)
  testTweet = Client.getRandomTweet()
  assert Client.sendTweets(serverPID, userName1, user1Pid, numOfRequests, testTweet) == :ok
  assert Client.sendReTweetCast(serverPID, userName2, testTweet, userName1, user1Pid) == :ok
end

# test to delete
test "delete random users that are not registered" do
  numOfUsers = 10
  usersToDelete = round(Float.ceil(0.1 * numOfUsers))
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  err = try do
    Client.deleteUsers(usersToDelete, serverPID, numOfUsers)
  rescue
    e in UserNotFoundError -> e
  end
  assert err.message == "User not found!"
end

# test to disconnect -1

# test to reconnect - 1

# test for query by mention
test "Query by mention" do
  numOfRequests = 5
  numOfUsers = 10
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser10"
  Client.registerUser(serverPID, userName, self())
  assert Client.queryByMention(serverPID, userName, numOfUsers) == :ok
end

test "Query by mention of a non-registered user" do
  numOfRequests = 5
  numOfUsers = 10
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser11"
  err = try do
    Client.queryMention(serverPID, numOfUsers)
  rescue
    e in UserNotFoundError -> e
  end
  assert err.message == "User not found!"
end

# test for query by hashtag
test "Query by hashtag" do
  numOfRequests = 5
  numOfUsers = 10
  :ets.new(:serverNode, [:set, :public, :named_table])
  {:ok,serverID} = Server.start_link()
  serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
  userName = "testUser12"
  Client.registerUser(serverPID, userName, self())
  testTweet = Client.getTweetsWithHashtags()
  assert Client.sendTweetsWithHashtags(serverPID, userName, self(), numOfRequests, testTweet) == :ok
  assert_receive({:userTweetedWithHashTags, tweet})
  assert tweet == testTweet
  assert Client.queryHashTag(serverPID, numOfUsers) == :ok
end

test "Query with hashtag for a random tweet" do
    numOfRequests = 5
    numOfUsers = 10
    :ets.new(:serverNode, [:set, :public, :named_table])
    {:ok,serverID} = Server.start_link()
    serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
    userName = "testUser13"
    Client.registerUser(serverPID, userName, self())
    testTweet = "This is DOS. #COP5615"
    assert Client.sendTweetsWithHashtags(serverPID, userName, self(), numOfRequests, testTweet) == :ok
    assert_receive({:userTweetedWithHashTags, tweet})
    assert tweet == testTweet
    assert Client.queryHashTag(serverPID, numOfUsers) == :ok
end

# test for query by subscto - 2
# test "test query by subscribed to" do

# end

# test for followers - 2

# test for following - 2

# test for live view - 1



end
