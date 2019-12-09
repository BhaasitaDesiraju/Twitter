defmodule Proj4Test do
  use ExUnit.Case
  doctest Proj4
  doctest Server
  doctest Client

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

    # test for query by mention
    test "Query by mention" do
      numOfRequests = 5
      numOfUsers = 10
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser9"
      Client.registerUser(serverPID, userName, self())
      mentionedUser = "@"<>userName
      assert Client.queryByMention(serverPID, userName, numOfUsers, self()) == {:ok, mentionedUser}
      assert mentionedUser == "@testUser9"
    end

    test "Query by mention of a non-registered user" do
      numOfRequests = 5
      numOfUsers = 10
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser10"
      err = try do
        Client.queryMention(serverPID, numOfUsers, self())
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
      userName = "testUser11"
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
        userName = "testUser12"
        Client.registerUser(serverPID, userName, self())
        testTweet = "This is DOS. #COP5615"
        assert Client.sendTweetsWithHashtags(serverPID, userName, self(), numOfRequests, testTweet) == :ok
        assert_receive({:userTweetedWithHashTags, tweet})
        assert tweet == testTweet
        assert Client.queryHashTag(serverPID, numOfUsers) == :ok
    end

    # test for query by subscribed to
    test "test query by subscribed to" do
      numOfRequests = 5
      numOfUsers = 10
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser13"
      subscribedUser = "subsUser"
      Client.registerUser(serverPID, subscribedUser, self())
      err = try do
        Client.getTweetsOfSubscribedTo(serverPID, userName, subscribedUser, self())
      rescue
        e in UserNotFoundError -> e
      end
      assert err.message == "User not found!"
    end

    test "test query for subscribed to for a registered user" do
      numOfRequests = 5
      numOfUsers = 10
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser14"
      Client.registerUser(serverPID, userName, self())
      subscribedUser = "subsUser"
      subUserPid = spawn fn -> subscribedUser end
      Client.registerUser(serverPID, subscribedUser, subUserPid)
      assert Client.getTweetsOfSubscribedTo(serverPID, userName, subscribedUser, self()) == {:ok, userName, subscribedUser}
    end

    # test for followers
    test "Test if followers are being added" do
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser15"
      Client.registerUser(serverPID, userName, self())
      followerName = "follower1"
      followerPID = spawn fn -> followerName end
      Client.registerUser(serverPID, followerName, followerPID)
      assert Client.addingFollowerCast(serverPID, userName, followerName, self()) == {:ok, followerName}
    end

    test "Test if followers is being added to an unregistered user" do
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser16"
      followerName = "follower2"
      followerPID = spawn fn -> followerName end
      Client.registerUser(serverPID, followerName, followerPID)
      err = try do
        Client.addingFollowerCast(serverPID, userName, followerName, self()) == {:ok, followerName}
      rescue
        e in UserNotFoundError -> e
      end
      assert err.message == "User not found!"
    end

    # test for following
    test "Test for getting followers from following list" do
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      followerList = []
      userName = "testUser17"
      Client.registerUser(serverPID, userName, self())
      followerName = "follower3"
      followerPID = spawn fn -> followerName end
      Client.registerUser(serverPID, followerName, followerPID)
      assert Client.addingFollowerCast(serverPID, userName, followerName, self()) == {:ok, followerName}
      assert Client.getFollowingList(serverPID, userName, self()) == followerList
    end

    test "Test for looking for an unregistered user to the following list" do
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser18"
      followerName = "follower4"
      followerPID = spawn fn -> followerName end
      Client.registerUser(serverPID, followerName, followerPID)
      err = try do
      assert Client.getFollowingList(serverPID, userName, self())
      rescue
        e in UserNotFoundError -> e
      end
      assert err.message == "User not found!"
    end

    # test to disconnect
    test "Test to disconnect a registered user" do
      numOfUsersToDisconnect = 5
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userToDisconnect = "testUser19"
      Client.registerUser(serverPID, userToDisconnect, self())
      assert_receive({:userRegistered, userToDisconnect})
      assert Client.disconnectUser(serverPID, userToDisconnect, numOfUsersToDisconnect, self()) == {:ok, userToDisconnect}
      assert userToDisconnect == "testUser19"
    end

    test "Test to disconnect an unregistered user" do
      numOfUsersToDisconnect = 5
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userToDisconnect = "testUser20"
      err = try do
        Client.disconnectUser(serverPID, userToDisconnect, numOfUsersToDisconnect, self())
      rescue
        e in UserNotFoundError -> e
      end
      assert err.message == "User not found!"
    end

    # tests to reconnect
    test "Test to reconnect a registered user" do
      numOfUsersToDisconnect = 5
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userToReconnect = "testUser21"
      Client.registerUser(serverPID, userToReconnect, self())
      assert_receive({:userRegistered, userToReconnect})
      assert Client.reconnectUser(serverPID, userToReconnect, self()) == {:ok, userToReconnect}
      assert userToReconnect == "testUser21"
    end

    test "Test to reconnect an unregistered user" do
      numOfUsersToDisconnect = 5
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userToReconnect = "testUser22"
      err = try do
        Client.reconnectUser(serverPID, userToReconnect, self())
      rescue
        e in UserNotFoundError -> e
      end
      assert err.message == "User not found!"
    end

    # test for live view
    test "Test to live view of a registered user" do
      numOfUsers = 10
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser23"
      Client.registerUser(serverPID, userName, self())
      assert_receive({:userRegistered, userToName})
      assert Client.retrieveUserLiveView(serverPID, userName, self(), numOfUsers) == {:ok, userName}
    end

    test "Test to display live view for an unregistered user" do
      numOfUsers = 10
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser24"
      err = try do
        Client.retrieveUserLiveView(serverPID, userName, self(), numOfUsers)
      rescue
        e in UserNotFoundError -> e
      end
      assert err.message == "User not found!"
    end

    # test for zipf
    test "Test for zipf for a registered user" do
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser25"
      Client.registerUser(serverPID, userName, self())
      assert_receive({:userRegistered, userToName})
      userFollowers = []
      follower1 = "follower1"
      follower1PID = spawn fn -> follower1 end
      Client.registerUser(serverPID, follower1, follower1PID)
      userFollowers ++ [follower1]
      follower2 = "follower2"
      follower2PID = spawn fn -> follower2 end
      Client.registerUser(serverPID, follower2, follower2PID)
      userFollowers ++ [follower2]
      follower3 = "follower3"
      follower3PID = spawn fn -> follower3 end
      Client.registerUser(serverPID, follower3, follower3PID)
      userFollowers ++ [follower3]
      assert Client.addZipfFollowers(userName, serverPID, userFollowers, self()) == {:ok, userName, userFollowers}
    end

    test "Test for zipf of an unregistered user" do
      :ets.new(:serverNode, [:set, :public, :named_table])
      {:ok,serverID} = Server.start_link()
      serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
      userName = "testUser26"
      userFollowers = []
      follower1 = "follower1"
      follower1PID = spawn fn -> follower1 end
      Client.registerUser(serverPID, follower1, follower1PID)
      userFollowers ++ [follower1]
      follower2 = "follower2"
      follower2PID = spawn fn -> follower2 end
      Client.registerUser(serverPID, follower2, follower2PID)
      userFollowers ++ [follower2]
      follower3 = "follower3"
      follower3PID = spawn fn -> follower3 end
      Client.registerUser(serverPID, follower3, follower3PID)
      userFollowers ++ [follower3]
      err = try do
        Client.addZipfFollowers(userName, serverPID, userFollowers, self())
      rescue
        e in UserNotFoundError -> e
      end
      assert err.message == "User not found!"
    end

    end
