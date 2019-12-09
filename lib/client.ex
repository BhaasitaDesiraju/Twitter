defmodule Client do
use GenServer

#Start client PIDs
def start_link(userName, numOfUsers, numOfFollowing,isExistingUser) do
    GenServer.start_link(__MODULE__, [userName, numOfUsers, numOfFollowing,isExistingUser])
end

#handle client functions after starting them
@impl true
def init([userName, numOfUsers, numOfRequests, _isExistingUser]) do
    serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
    userPID = self()
    registerUser(serverPID, userName, userPID)
    receive do
        {:userRegistered, userName} -> IO.puts("#{userName} is now registered!")
    end

    usersToDelete = round(Float.ceil(0.1 * numOfUsers))
    numOfUsersToDisconnect = round(Float.ceil(0.4 * numOfUsers))
    twitterHandler(serverPID, userName, numOfUsers, numOfRequests, userPID, usersToDelete, numOfUsersToDisconnect)
end

def twitterHandler(serverPID, userName, numOfUsers, numOfRequests, userPID, usersToDelete, numOfUsersToDisconnect) do
    followerGenerator(serverPID, userName, numOfUsers, numOfRequests, userPID)

        timeCounter = System.system_time(:millisecond)
        tweetForUser(numOfUsers, numOfRequests, serverPID, userPID)
        tweetWithHashtags(numOfUsers, numOfRequests, serverPID, userPID)
        tweetWithMentions(numOfUsers, numOfRequests, serverPID, userPID)
        timeForAllTweets = System.system_time(:millisecond) - timeCounter
        timeForTweets = timeForAllTweets/(3 * numOfRequests)

        getLiveView(serverPID, numOfUsers, userPID)
        sendRetweets(serverPID, numOfUsers, userPID)

        timeCounter = System.system_time(:millisecond)
        queryForSubscribedTo(numOfUsers, serverPID, userPID)
        timeForSubscribedToQueries = System.system_time(:millisecond) - timeCounter

        timeCounter = System.system_time(:millisecond)
        queryHashTag(serverPID, numOfUsers)
        timeForHashtagQueries = System.system_time(:millisecond) - timeCounter

        timeCounter = System.system_time(:millisecond)
        queryMention(serverPID, numOfUsers, userPID)
        timeForMentionQueries = System.system_time(:millisecond) - timeCounter

        disconnectUsers(numOfUsersToDisconnect, serverPID, numOfUsers, userPID)
        reconnectUsers(serverPID, numOfUsers, userPID)

        timeDetailList = [timeForTweets, timeForSubscribedToQueries, timeForHashtagQueries, timeForMentionQueries]
        :ets.insert(:timeRegister, {userName, timeDetailList})

        deleteUsers(usersToDelete, serverPID, numOfUsers)

        Proj4.infiniteLoop()
        createZipfFollowers(serverPID, numOfUsers, 1, userPID)
end

# randomly pick a tweet from tweest list and use it for a user
def getRandomTweet() do
    # list of tweets
    tweetList = ["This is Twitter clone", "I ate a clock yesterday, it was very time-consuming.", "How do prisoners call each other? On their cell phones!", "The light heart lives long."]
    tweets = Enum.random(tweetList)
    tweets
end

# randomly pick a hashtag from hashtags list and use it for a user
def getRandomHashtags() do
    hashtagsList = ["#COP5615", "#DOS", "#Twitter", "#Elixir", "#UFlorida", "#GoGators", "#ComputerScience"]
    hashtags = Enum.random(hashtagsList)
    hashtags
end

#get a tweet containing hashtag in it
def getTweetsWithHashtags() do
    space = " "
    tweetsWithHashtags = getRandomTweet() <> space <> getRandomHashtags()
    tweetsWithHashtags
end

def getMentionedUser(numOfUsers) do
    randomUser = getRandomUser(numOfUsers)
    space = " "
    mentionUser = space <> "@" <> randomUser
    mentionUser
end

def getRandomUser(numOfUsers) do
    randomUser = "User" <> Integer.to_string(Enum.random(1..numOfUsers))
    randomUser
end

def isExistingUser(serverPID, userName) do
    check = GenServer.call(serverPID, {:isExistingUser,userName})
    check
end

def tweetForUser(numOfUsers, numOfRequests, serverPID, userPID) do
    # get a random user from global register
    randomUser = getRandomUser(numOfUsers)
        if(getTweetLimit(serverPID, randomUser) > numOfRequests) do
        # if user reached tweet limit pick another user
        tweetForUser(numOfUsers, numOfRequests, serverPID, userPID)
        end
    tweetGenerator(numOfRequests, serverPID, randomUser, userPID)
end

def tweetWithHashtags(numOfUsers, numOfRequests, serverPID, userPID) do
    randomUser = getRandomUser(numOfUsers)
    if(getTweetLimit(serverPID, randomUser) > numOfRequests) do
        # if user reached tweet limit pick another user
        tweetWithHashtags(numOfUsers, numOfRequests, serverPID, userPID)
    end
    hashtagTweetGenerator(numOfRequests, serverPID, randomUser, userPID)
end

def tweetWithMentions(numOfUsers, numOfRequests, serverPID, userPID) do
    randomUser = getRandomUser(numOfUsers)
    if(getTweetLimit(serverPID, randomUser) > numOfRequests) do
        # if user reached tweet limit, pick another user
        tweetWithMentions(numOfUsers, numOfRequests, serverPID, userPID)
    end
    mentionTweetGenerator(numOfUsers, numOfRequests, serverPID, randomUser, userPID)
end

def tweetGenerator(numOfRequests, serverPID, userName, userPID) do
    tweets = getRandomTweet()
    sendTweets(serverPID, userName, userPID, numOfRequests, tweets)
    receive do
        {:userTweeted, tweet} -> {:ok, tweet}
    end
end

def hashtagTweetGenerator(numOfRequests, serverPID, userName, userPID) do
    hashtagsTweets = getTweetsWithHashtags()
    sendTweetsWithHashtags(serverPID, userName, userPID, numOfRequests, hashtagsTweets)
    receive do
        {:userTweetedWithHashTags, tweet} -> {:ok, tweet}
    end
end

def mentionTweetGenerator(numOfUsers, numOfRequests, serverPID, userName, userPID) do
    mentionedUser = getMentionedUser(numOfUsers)
    tweet = getRandomTweet() <> mentionedUser
    sendTweetsWithMention(serverPID, userName, userPID, numOfRequests, tweet, mentionedUser)
    receive do
        {:userTweetedWithMentions, tweet} -> {:ok, tweet}
     end
end

def sendRetweets(serverPID, numOfUsers, userPID)  do
userName = getRandomUser(numOfUsers)
retweetDetail = getRetweet(serverPID, userName)
if(!Enum.empty?(retweetDetail)) do
    retweet = Enum.at(retweetDetail, 1)
    retweetOfUser = Enum.at(retweetDetail, 0)
    sendReTweetCast(serverPID, userName, retweet, retweetOfUser, userPID)
else
    sendRetweets(serverPID, numOfUsers, userPID)
end
end

def sendReTweetCast(serverPID, userName, retweet, retweetOfUser, userPID) do
    if(isExistingUser(serverPID, userName)) do
        GenServer.cast(serverPID, {:sendRetweets, userName, retweet, retweetOfUser, userPID})
    else
        raise UserNotFoundError
    end
end

def getRetweet(serverPID, userName) do
retweetDetail = GenServer.call(serverPID, {:getTweetToRetweet, userName})
retweetDetail
end

#Query by hashtag
def queryHashTag(serverPID, numOfUsers) do
    #select a random hashtag and call the server to fetch all the tweets with hashtags
    randomHashTag = getRandomHashtags()
    GenServer.cast(serverPID, {:queryHashTag, randomHashTag, numOfUsers})
end


#Query by Mention
@spec queryMention(atom | pid | {atom, any} | {:via, atom, any}, integer, any) :: {:ok, any}
def queryMention(serverPID, numOfUsers, userPID) do
    randomUserName = getRandomUser(numOfUsers)
    queryByMention(serverPID,randomUserName, numOfUsers, userPID)
end

def queryByMention(serverPID, randomUserName, numOfUsers, userPID) do
    if(isExistingUser(serverPID, randomUserName)) do
    GenServer.cast(serverPID, {:queryMention, randomUserName, numOfUsers, userPID})
    receive do
        {:userMentioned, mentionedUser} -> {:ok, mentionedUser}
    end

    else
    raise UserNotFoundError
end
end

#Query for a user you subscribed to
def queryForSubscribedTo(numOfUsers, serverPID, userPID) do
    randomUser = getRandomUser(numOfUsers)
    followingList = getFollowingList(serverPID, randomUser, userPID)
    randomSubscribedTo =if !Enum.empty?(followingList) do
                            Enum.random(followingList)
                        else
                            ""
                        end
    if randomSubscribedTo != "" do
        getTweetsOfSubscribedTo(serverPID, randomUser, randomSubscribedTo, userPID)
    else
        queryForSubscribedTo(numOfUsers, serverPID, userPID)
    end
end

def getFollowingList(serverPID, userName, userPID) do
if(isExistingUser(serverPID, userName)) do
    followingUsersList = GenServer.call(serverPID, {:getfollowingUsers, userName, userPID})
    followingUsersList
else
    raise UserNotFoundError
end


end

def getTweetsOfSubscribedTo(serverPID, userName, userSubscribedTo, userPID) do
    if(isExistingUser(serverPID, userName)) do
        GenServer.cast(serverPID, {:getAllTweets, userName, userSubscribedTo, userPID})
        receive do
            {:queryTweetSubscribedTo, userName, userSubscribedTo} -> {:ok, userName, userSubscribedTo}
        end
    else
        raise UserNotFoundError
    end
end

#Register Account for  new User.
def registerUser(serverPID, userName, userPID) do
    GenServer.cast(serverPID, {:registerUser,userName,userPID})
end

#send tweets
def sendTweets(serverPID, userName, userPID, numOfRequests, tweets) do
if(isExistingUser(serverPID, userName)) do
    GenServer.cast(serverPID, {:userTweet, userName, userPID, numOfRequests, tweets})
else
    raise UserNotFoundError
end
end

    #get the tweetlimit which should be less than the numOfRequests
def getTweetLimit(serverPID, userName) do
    tweetLimit = GenServer.call(serverPID, {:getTweetLimit, userName})
    tweetLimit
end

#send tweets with hashtags
def sendTweetsWithHashtags(serverPID, userName, userPID, numOfRequests, tweets) do
if(isExistingUser(serverPID, userName)) do
    GenServer.cast(serverPID, {:userTweetWithHashtags, userName, userPID, numOfRequests, tweets})
else
    raise UserNotFoundError
end
end
#send tweets with mentions
def sendTweetsWithMention(serverPID, userName, userPID, numOfRequests, tweet, mentionedUser) do
if(isExistingUser(serverPID, userName)) do
    GenServer.cast(serverPID, {:userTweetWithMention, userName, userPID, numOfRequests, tweet, mentionedUser})
else
    raise UserNotFoundError
end
end

def followerGenerator(serverPID, userName, numOfUsers, numOfRequests, userPID) when numOfRequests > 0 do
    addFollowers(userName, serverPID, numOfUsers, userPID)
    followerGenerator(serverPID, userName, numOfUsers, numOfRequests - 1, userPID)
end

def followerGenerator(_serverPID, _userName, _numOfUsers, numOfRequests, _userPID) when numOfRequests == 0 do

end

#generate followers for a user
def addFollowers(userName, serverPID, numOfUsers, userPID) do
    followerName = getFollower(userName, numOfUsers)
    addingFollowerCast(serverPID, userName, followerName, userPID)
end

def addingFollowerCast(serverPID, userName, followerName, userPID) do
    if(isExistingUser(serverPID, userName)) do
        GenServer.cast(serverPID, {:addToFollowers, userName, followerName, userPID})
        receive do
            {:followerAdded, followerName} -> {:ok, followerName}
        end
       else
        raise UserNotFoundError
       end
end

def getFollower(userName, numOfUsers) do
    followerString = getRandomUser(numOfUsers)
    followerName =  if userName == followerString do
                        getFollower(userName, numOfUsers)
                    else
                        followerString
                    end
    followerName
end

def deleteUsers(usersToDelete, serverPID, numOfUsers) do
    deleteUserName = getRandomUser(numOfUsers)
    if(isExistingUser(serverPID, deleteUserName)) do
    GenServer.cast(serverPID, {:deleteRandomUsers, deleteUserName, usersToDelete})
    else
    raise UserNotFoundError
end
end

def disconnectUsers(numOfUsersToDisconnect, serverPID, numOfUsers, userPID) do
    userToDisconnect = getRandomUser(numOfUsers)
    disconnectUser(serverPID, userToDisconnect, numOfUsersToDisconnect, userPID)
end

def disconnectUser(serverPID, userToDisconnect, numOfUsersToDisconnect, userPID) do
    if(isExistingUser(serverPID, userToDisconnect)) do
        GenServer.cast(serverPID, {:disconnectRandomUsers, userToDisconnect, numOfUsersToDisconnect, userPID})
        receive do
            {:userDisconnected, userToDisconnect} -> {:ok, userToDisconnect}
        end
    else
        raise UserNotFoundError
    end
end

def reconnectUsers(serverPID, numOfUsers, userPID) do
    userToReconnect = getDisconnectedUser(serverPID, numOfUsers)
    reconnectUser(serverPID, userToReconnect, userPID)
end

def reconnectUser(serverPID, userToReconnect, userPID) do
if(isExistingUser(serverPID, userToReconnect)) do
    if userToReconnect != " " do
        GenServer.cast(serverPID, {:reconnectUser, userToReconnect, userPID})
    end
    receive do
        {:reconnectedUser, userName} -> {:ok, userName}
            # code
    end

else
    raise UserNotFoundError
end
end

def getDisconnectedUser(serverPID, numOfUsers) do
    disconnectedUsersList = GenServer.call(serverPID, {:getDisconnectedUsers, numOfUsers})
    disconnectUser =     if !Enum.empty?(disconnectedUsersList) do
                            Enum.random(disconnectedUsersList)
                         else
                            " "
                         end
    disconnectUser
end



def getLiveView(serverPID, numOfUsers, userPID) do
    userName = getRandomUser(numOfUsers)
    retrieveUserLiveView(serverPID, userName, userPID, numOfUsers)
end

def retrieveUserLiveView(serverPID, userName, userPID, numOfUsers) do
    if(isExistingUser(serverPID, userName)) do
    disconnectedUsersList = getDisconnectedUserList(serverPID, numOfUsers)
    if (!Enum.member?(disconnectedUsersList, userName)) do
        GenServer.cast(serverPID, {:getLiveView, userName, userPID})
    end
    receive do
        {:liveView, userName} -> {:ok, userName}
    end

else
    raise UserNotFoundError
end

end

def getDisconnectedUserList(serverPID, numOfUsers) do
    disconnectedUserList = GenServer.call(serverPID, {:getDisconnectedUsers, numOfUsers})
    disconnectedUserList
end

def createZipfFollowers(serverPID, numOfUsers, userCount, userPID) when userCount <= numOfUsers do
    userName = "User" <> Integer.to_string(userCount)
    followerList = getZipfFollowers(numOfUsers)
    userFollowers = Enum.at(followerList, userCount-1)
    if userFollowers != nil or userFollowers != [] do
        addZipfFollowers(userName, serverPID, userFollowers, userPID)
        createZipfFollowers(serverPID, numOfUsers, userCount + 1, userPID)
    else
        createZipfFollowers(serverPID, numOfUsers, userCount + 1, userPID)
    end
end

def createZipfFollowers(_serverPID, numOfUsers, userCount, _userPID) when userCount > numOfUsers do
end

def addZipfFollowers(userName, serverPID, userFollowers, userPID) do
    if(isExistingUser(serverPID, userName)) do
    GenServer.cast(serverPID, {:addToZipfFollowers, userName, userFollowers, userPID})
        receive do
            {:zipf, userName, userFollowers} -> {:ok, userName, userFollowers}
        end

    else
        raise UserNotFoundError
    end
end

#___________________BONUS PART___________________

def getZipfFollowers(numOfUsers) do
    usersList = Enum.map(1..numOfUsers, fn(users)->
                        "User" <> Integer.to_string(users)
                        end )
    zipfConstant = getZipfConstant(numOfUsers, 1 , 0)
    zipfConstant = (1/zipfConstant) * numOfUsers

    zipfFollowersList = Enum.map(1..length(usersList),fn(userNum)->

      numOfZipfFollowers = zipfConstant/userNum
      userName = "User" <> Integer.to_string(userNum)
      usersList = usersList -- [userName]
      zipfFollowersList = Enum.take_random(usersList, round(numOfZipfFollowers))
      zipfFollowersList
    end)
    zipfFollowersList
  end

  def getZipfConstant(numOfUsers, count, zipfConstantValue) when count <= numOfUsers do
    zipfConstantValue = zipfConstantValue + (1/count)
    getZipfConstant(numOfUsers, count + 1, zipfConstantValue)
  end

  def getZipfConstant(numOfUsers, count, zipfConstantValue) when count > numOfUsers do
    zipfConstantValue
  end

end
