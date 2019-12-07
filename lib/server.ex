defmodule Server do
    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, :ok)
    end

    @impl true
    def init(:ok) do
        IO.puts "Server Started"
        :ets.insert(:serverNode,{"Server",self()})
        #create a Table to store list of users
        createUserRegister()
        #create a Table to store list of all tweets
        createTweetsRegister()
        #create a Table to store list of all tweets containing hashtags 
        createHashtagsRegister()
        #create a Table to store list of all tweets containing mentions 
        createMentionsRegister()
        #create a Table to store list of all the users a user is following
        createFollowingRegister()
        #create a Table to store list of all the followers of a user
        createFollowersRegister()
        #create a table for backup of deleted users
        createDeletedUsersRegister()
        state = ""
        {:ok, state}
    end

    def createUserRegister() do
        :ets.new(:userRegister, [:set, :public, :named_table])
    end

    def createTweetsRegister() do
        :ets.new(:tweetsRegister, [:set, :public, :named_table])
    end

    def createHashtagsRegister() do
        :ets.new(:hashtagsRegister, [:set, :public, :named_table])
    end

    def createMentionsRegister() do
        :ets.new(:mentionsRegister, [:set, :public, :named_table])
    end

    def createFollowingRegister() do
        :ets.new(:followingRegister, [:set, :public, :named_table])
    end

    def createFollowersRegister() do
        :ets.new(:followersRegister, [:set, :public, :named_table])
    end

    def createDeletedUsersRegister() do
        :ets.new(:deletedUsers, [:set, :public, :named_table])
    end

    @impl true
    def handle_cast({:registerUser,userName,userPID}, state) do
        :ets.insert(:userRegister, {userName, userPID})
        :ets.insert(:tweetsRegister, {userName, userPID, 0, []})
        :ets.insert(:hashtagsRegister, {userName, userPID, 0, []})
        :ets.insert(:mentionsRegister, {userName, userPID, 0, []})
        :ets.insert(:followingRegister, {userName, []})
        # if :ets.lookup(:followersRegister, userName) == [] do
        :ets.insert(:followersRegister, {userName, []})
        :ets.insert(:deletedUsers, {userName, 0})
        # end
        send(userPID, {:userRegistered})
        {:noreply, state}
    end

    @impl true
    def handle_cast({:userTweet, userName, userPID, tweetLimit, tweets}, state) do
        existingTweets = elem(Enum.at(:ets.lookup(:tweetsRegister,userName),0),3)
        # IO.inspect(existingTweets)
        updatedTweets = existingTweets ++ [tweets]
        tweetLimit = tweetLimit + 1
        :ets.insert(:tweetsRegister, {userName, userPID, tweetLimit, updatedTweets})
        IO.inspect("#{userName} tweeted: #{tweets}")
        send(userPID, {:userTweeted})
        {:noreply, state}
    end

    @impl true
    def handle_cast({:userTweetWithHashtags, userName, userPID, tweetLimit, tweets}, state) do
        existingTweets = elem(Enum.at(:ets.lookup(:hashtagsRegister,userName),0),3)
        # IO.inspect(existingTweets)
        updatedTweets = existingTweets ++ [tweets]
        tweetLimit = tweetLimit + 1
        :ets.insert(:hashtagsRegister, {userName, userPID, tweetLimit, updatedTweets})
        IO.inspect("#{userName} tweeted with Hashtag: #{tweets}")
        send(userPID, {:userTweetedWithHashTags})
        {:noreply, state}
    end

    @impl true
    def handle_cast({:userTweetWithMention, userName, userPID, tweetLimit, tweets, mentionedUser}, state) do
        existingTweets = elem(Enum.at(:ets.lookup(:mentionsRegister,userName),0),3)
        # IO.inspect(existingTweets)
        updatedTweets = existingTweets ++ [tweets]
        tweetLimit = tweetLimit + 1
        :ets.insert(:mentionsRegister, {userName, userPID, tweetLimit, updatedTweets})
        IO.inspect("#{userName} mentioned #{mentionedUser}: #{tweets}")
        send(userPID, {:userTweetedWithMentions})
        {:noreply, state}
    end

    def handle_cast({:addToFollowers, userName, followerName}, state) do
        existingFollowers = elem(Enum.at(:ets.lookup(:followersRegister,userName),0),1)
        updatedFollowers =  if(!Enum.member?(existingFollowers, followerName)) do
                                existingFollowers ++ [followerName]
                            else
                                existingFollowers
                            end
        :ets.insert(:followersRegister, {userName, updatedFollowers})
        existingSubscribers = elem(Enum.at(:ets.lookup(:followingRegister,userName),0),1)
        updatedSubscribers =if(!Enum.member?(existingSubscribers, userName)) do
                                existingSubscribers ++ [userName]
                            else
                                existingSubscribers
                            end
        :ets.insert(:followingRegister, {followerName, updatedSubscribers})
        {:noreply, state}
    end

    def handle_cast({:deleteRandomUsers, deleteUserName, usersToDelete}, state) do
        existingUser = elem(Enum.at(:ets.lookup(:userRegister,deleteUserName),0),1)
        deleteCounter = elem(Enum.at(:ets.lookup(:deletedUsers, deleteUserName),0),1)
        deleteCounter =  if((existingUser != nil) && deleteCounter <= usersToDelete ) do
            IO.puts("deleting user:")
            IO.inspect(deleteUserName)
            # usersToDelete - 1
            :ets.insert(:userRegister, {deleteUserName, nil})
            :ets.insert(:deletedUsers, {deleteUserName, deleteCounter})
            deleteCounter = deleteCounter + 1  
        # else 
        #     IO.puts("Unable to delete!")
        #     deleteCounter          
        end
        {:noreply, state}
    end

    @impl true
    def handle_call({:getTweetLimit, userName}, _from, state) do
        tweetLimit = elem(Enum.at(:ets.lookup(:tweetsRegister,userName),0),2)
        # IO.inspect(tweetLimit)
        {:reply, tweetLimit, state}
    end

     # Helper functions
    # def whereis(userId) do
    #     if :ets.lookup(:userRegister, userId) == [] do
    #         nil
    #     else
    #         [tup] = :ets.lookup(:userRegister, userId)
    #         elem(tup, 1)
    #     end
    # end
end