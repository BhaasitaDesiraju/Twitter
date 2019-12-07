defmodule Final do 

  def main(args) do
    # Create table to maintain server pid for handling Genserver handle calls and casts
    :ets.new(:serverNode, [:set, :public, :named_table])
    # start server
    Task.start(fn -> Server.start_link() end)
    Process.sleep(1000)

    # starting client
    numOfUsers = String.to_integer(Enum.at(args, 0))
    numOfRequests = String.to_integer(Enum.at(args, 1))
    # maxSubscribers = if numOfRequests > 0.5 * numOfUsers do
    #                     numOfRequests
    #                  else
    #                     round(0.5 * numOfUsers)
    #                  end
    # IO.inspect(maxSubscribers)
    serverPID = elem(Enum.at(:ets.lookup(:serverNode,"Server"),0),1)
    :ets.new(:globalRegister, [:set, :public, :named_table])
    createNewUsers(1,numOfUsers,numOfRequests, serverPID)
    Process.sleep(50000)
  end

  def createNewUsers(userNumber, numOfUsers, numOfRequests, serverPID) when userNumber <= numOfUsers do
    userName = "User" <> Integer.to_string(userNumber)
    userPID = spawn(fn -> Client.start_link(userName, numOfUsers, numOfRequests, false) end)
    :ets.insert(:globalRegister, {userName, userPID})
    # IO.inspect(elem(Enum.at(:ets.lookup(:globalRegister,userName),0),2))
    userNumber = userNumber + 1
    createNewUsers(userNumber, numOfUsers, numOfRequests, serverPID)
  end

  def createNewUsers(_userNumber, numOfUsers, _numOfRequests, _serverPID) do
    IO.puts("\nAll #{numOfUsers} users registered!\n")
  end
end
