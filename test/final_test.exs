defmodule FinalTest do
  use ExUnit.Case
  doctest Final
  doctest Server
  doctest Client

  # test "Register Users" do
  #   assert Final.main(["10", "5"]) == "hello"
  # end

  test "Register User Test" do
    :ets.new(:serverNode, [:set, :public, :named_table])
    {:ok,serverID} = Server.start_link()
    serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
    userName = "testUser1"
    assert Client.registerUser(serverPID, userName, self()) == :ok
    assert_receive({:userRegistered})
  end

  test "Send Tweet Test for a registered user" do
    numOfRequests = 5
    :ets.new(:serverNode, [:set, :public, :named_table])
    {:ok,serverID} = Server.start_link()
    serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
    userName = "testUser2"
    Client.registerUser(serverPID, userName, self())
    testTweet = Client.getRandomTweet()
    # output = "#{userName} tweeted: #{testTweet}"
    assert Client.sendTweets(serverPID, userName, self(), numOfRequests, testTweet) == :ok
    assert_receive({:userTweeted})
  end

end
