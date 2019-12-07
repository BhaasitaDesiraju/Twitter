defmodule Client do
use GenServer
#Start client PIDs
def start_link(userName, numOfUsers, numOfFollowing,isExistingUser) do
    GenServer.start_link(__MODULE__, [userName, numOfUsers, numOfFollowing,isExistingUser])
end

#handle client functions after starting them
@impl true
def init([userName, numOfUsers, numOfRequests, isExistingUser]) do
    serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
    userPID = self()
    registerUser(serverPID, userName, userPID)
    receive do
        {:userRegistered, userName} -> IO.puts("#{userName} is now registered!")
    end

    followerGenerator(serverPID, userName, numOfUsers, numOfRequests, userPID)
    usersToDelete = round(Float.ceil(0.1 * numOfUsers))
    deleteUsers(usersToDelete, serverPID, numOfUsers)
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
    # IO.inspect(tweetsWithHashtags)
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
            # IO.inspect("#{userName} tweeted: #{tweets}")
    end
end

def hashtagTweetGenerator(numOfRequests, serverPID, userName, userPID) do
    hashtagsTweets = getTweetsWithHashtags()
    # IO.inspect(hashtagsTweets)
    sendTweetsWithHashtags(serverPID, userName, userPID, numOfRequests, hashtagsTweets)
    receive do
        {:userTweetedWithHashTags, tweet} -> {:ok, tweet}
            # IO.inspect("#{userName} tweeted with Hashtag: #{hashtagsTweets}")
    end
end

def mentionTweetGenerator(numOfUsers, numOfRequests, serverPID, userName, userPID) do
    mentionedUser = getMentionedUser(numOfUsers)
    tweet = getRandomTweet() <> mentionedUser
    sendTweetsWithMention(serverPID, userName, userPID, numOfRequests, tweet, mentionedUser)
    receive do
        {:userTweetedWithMentions, tweet} -> {:ok, tweet}
            # IO.inspect("#{userName} mentioned #{mentionedUser}: #{tweet}")
    end
end

def sendRetweets(serverPID, numOfUsers, userPID)  do
userName = getRandomUser(numOfUsers)
retweetDetail = getRetweet(serverPID, userName)
if(!Enum.empty?(retweetDetail)) do
    retweet = Enum.at(retweetDetail, 1)
    retweetOfUser = Enum.at(retweetDetail, 0)
    GenServer.cast(serverPID, {:sendRetweets, userName, retweet, retweetOfUser, userPID})
else
    sendRetweets(serverPID, numOfUsers, userPID)
end
end

def getRetweet(serverPID, userName) do
retweetDetail = GenServer.call(serverPID, {:getTweetToRetweet, userName})
retweetDetail
end

#Register Account for  new User.
def registerUser(serverPID, userName, userPID) do
    GenServer.cast(serverPID, {:registerUser,userName,userPID})
end

#send tweets
def sendTweets(serverPID, userName, userPID, numOfRequests, tweets) do
    GenServer.cast(serverPID, {:userTweet, userName, userPID, numOfRequests, tweets})
end

    #get the tweetlimit which should be less than the numOfRequests
def getTweetLimit(serverPID, userName) do
    tweetLimit = GenServer.call(serverPID, {:getTweetLimit, userName})
    tweetLimit
end

#send tweets with hashtags
def sendTweetsWithHashtags(serverPID, userName, userPID, numOfRequests, tweets) do
    GenServer.cast(serverPID, {:userTweetWithHashtags, userName, userPID, numOfRequests, tweets})
end
#send tweets with mentions
def sendTweetsWithMention(serverPID, userName, userPID, numOfRequests, tweet, mentionedUser) do
    GenServer.cast(serverPID, {:userTweetWithMention, userName, userPID, numOfRequests, tweet, mentionedUser})
end

def followerGenerator(serverPID, userName, numOfUsers, numOfRequests, userPID) when numOfRequests > 0 do
    addFollowers(userName, serverPID, numOfUsers)
    followerGenerator(serverPID, userName, numOfUsers, numOfRequests - 1, userPID)
end

def followerGenerator(serverPID, _userName, numOfUsers, numOfRequests, userPID) when numOfRequests == 0 do
    # randomly pick a tweet from list and use it for a user
    tweetForUser(numOfUsers, numOfRequests, serverPID, userPID)
    tweetWithHashtags(numOfUsers, numOfRequests, serverPID, userPID)
    tweetWithMentions(numOfUsers, numOfRequests, serverPID, userPID)
    sendRetweets(serverPID, numOfUsers, userPID)
end

#generate followers for a user
def addFollowers(userName, serverPID, numOfUsers) do
    followerName = getFollower(userName, numOfUsers)
    # IO.inspect(followerName)
    GenServer.cast(serverPID, {:addToFollowers, userName, followerName})
end

def getFollower(userName, numOfUsers) do
    followerString = getRandomUser(numOfUsers)
    followerName =  if userName == followerString do
                        getFollower(userName, numOfUsers)
                    else
                        followerString
                    end
    # IO.inspect(followerName)
    followerName
end

def deleteUsers(usersToDelete, serverPID, numOfUsers) do
    # when usersToDelete > 0
    deleteUserName = getRandomUser(numOfUsers)
    GenServer.cast(serverPID, {:deleteRandomUsers, deleteUserName, usersToDelete})
end

end
