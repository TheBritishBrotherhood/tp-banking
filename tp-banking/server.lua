local balances = {}
local user = nil

AddEventHandler('redem:playerLoaded', function(source)
    local _source = source
    
    TriggerEvent('redem:getPlayerFromId', _source, function(user)
    balances[_source] = user.getBank()
    TriggerClientEvent('banking:updateBalance', _source, user.getBank())
  end)
end)

AddEventHandler('playerDropped', function()
    local _source = source
  balances[_source] = nil
  _source = nil
  user = nil
  souce = nil
end)

-- HELPER FUNCTIONS
function bankBalance(player)
  return exports.redem:getPlayerFromId(player).getBank()
end

function deposit(player, amount)
local _source = source
  local bankbalance = bankBalance(player)
  local new_balance = bankbalance + math.abs(amount)
  balances[player] = new_balance

  local user = exports.redem:getPlayerFromId(player)
  TriggerClientEvent("banking:updateBalance", _source, new_balance)
  user.removeMoney(amount)
  user.setMoney(user.getMoney() + amount)
end

function withdraw(player, amount)
  local _source = source
  local bankbalance = bankBalance(player)
  local new_balance = bankbalance - math.abs(amount)
  balances[player] = new_balance

  local user = exports.redem:getPlayerFromId(player) 
  TriggerClientEvent("banking:updateBalance", _source, new_balance)
  user.removeBank(amount)
  user.setMoney(user.getMoney() + amount)
end

function transfer_send(id, userObj, amount)
  local bankAmount = userObj.getBank()
  local withdrawAmount = tonumber(math.abs(round(amount, 0)))
  local newBalance = tonumber(bankAmount - withdrawAmount)

  if withdrawAmount > bankAmount then
    return false
  end

  balances[id] = newBalance
  userObj.removeBank(withdrawAmount)
  TriggerClientEvent("banking:updateBalance", id, newBalance)

  return true
end

function transfer_receive(id, userObj, amount)
    local bankAmount = userObj.getBank()
    local depositAmount = math.abs(round(amount, 0))
    local newBalance = bankAmount + depositAmount

    balances[id] = newBalance
    userObj.setBankBalance(userObj.getBank() + amount)
    TriggerClientEvent("banking:updateBalance", id, newBalance)
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.abs(math.floor(num * mult + 0.5) / mult)
end

local notAllowedToDeposit = {}

AddEventHandler('bank:addNotAllowed', function(pl)
  notAllowedToDeposit[pl] = true

  local savedSource = pl
  SetTimeout(300000, function()
    notAllowedToDeposit[savedSource] = nil
  end)
end)

-- Bank Deposit

RegisterServerEvent('bank:deposit')
AddEventHandler('bank:deposit', function(amount)
local _source = source
  if not amount then return end

  TriggerEvent('redem:getPlayerFromId', _source, function(user)

    if notAllowedToDeposit[_source] == nil then
      local rounded = math.ceil(tonumber(amount))
      if(rounded <= user.getMoney()) then
        TriggerClientEvent("banking:updateBalance", _source, (user.getBank() + rounded))
        TriggerClientEvent("banking:addBalance", _source, rounded)
          
        deposit(_source, rounded)
        local new_balance = user.getBank()
      else
        TriggerClientEvent('chatMessage', _source, "", {0, 0, 200}, "^1Not enough cash!^0")
      end
    else
        TriggerClientEvent('es_rp:notify', _source, "~r~You cannot deposit recently stolen money, please wait 5 minutes.")
    end
  end)
end)


RegisterServerEvent('bank:withdraw')
AddEventHandler('bank:withdraw', function(amount)
local _source = source
  if not amount then return end
  
  TriggerEvent('redem:getPlayerFromId', _source, function(user)
      local rounded = round(tonumber(amount), 0)
      local bankbalance = user.getBank()
      if(tonumber(rounded) <= tonumber(bankbalance)) then 
        TriggerClientEvent("banking:updateBalance", _source, (user.getBank() - rounded))
        TriggerClientEvent("banking:removeBalance", _source, rounded)

        withdraw(_source, rounded)
      else
        TriggerClientEvent('chatMessage', _source, "", {0, 0, 200}, "^1Not enough money in account!^0")
      end
  end)
end)

RegisterServerEvent('bank:transfer')
AddEventHandler('bank:transfer', function(toPlayer, amount)
  local _source = source
  local fromPlayer = source

  if fromPlayer == toPlayer then
    TriggerClientEvent("es_freeroam:notify", fromPlayer, "CHAR_BANK_MAZE", 1, "Maze Bank", false, "~r~Sorry, you cannot transfer money to your own account.")return
  end

  TriggerEvent("redem:getPlayerFromId", fromPlayer, function(fromUser)
    TriggerEvent("redem:getPlayerFromId", toPlayer, function(toUser)

      -- check if we have a source user.
      if fromUser == nil or toUser == nil then
        TriggerClientEvent("es_freeroam:notify", fromPlayer, "CHAR_BANK_MAZE", 1, "Maze Bank", false, "~r~Sorry, the maze bank servers are malfunctioning. Please contact the server administrators.")
        return
      end

      -- Send transfer, check for errors.
      local transferSendState = transfer_send(fromPlayer, fromUser, amount)

      -- Insufficient money to transfer.
      if transferSendState == false then
        TriggerClientEvent("es_freeroam:notify", fromPlayer, "CHAR_BANK_MAZE", 1, "Maze Bank", false, "Balance insuffcient, required: $".. amount .." Balance: ~$" .. fromUser.getBank())
        return
      end
      
      --Receive the transfer.
      transfer_receive(toPlayer, toUser, amount)
      
      TriggerClientEvent("es_freeroam:notify", fromPlayer, "CHAR_BANK_MAZE", 1, "Maze Bank", false, "Transferred: ~r~-$".. amount .." ~n~~s~New Balance: ~g~$" .. fromUser.getBank())
      TriggerClientEvent("es_freeroam:notify", toPlayer, "CHAR_BANK_MAZE", 1, "Maze Bank", false, "Received: ~g~$".. amount .." ~n~~s~New Balance: ~g~$" .. toUser.getBank())
    end)
  end)
end)

RegisterServerEvent('bank:givecash')
local _source = source
AddEventHandler('bank:givecash', function(toPlayer, amount)
	TriggerEvent('redem:getPlayerFromId', _source, function(user)
		if (tonumber(user.getMoney()) >= tonumber(amount)) then
			TriggerEvent('redem:getPlayerFromId', toPlayer, function(recipient)
				recipient.addMoney(amount)
			end)
		else
			if (tonumber(user.getMoney()) < tonumber(amount)) then
        TriggerClientEvent('chatMessage', _source, "", {0, 0, 200}, "^1Not enough money in wallet!^0")
			end
		end
	end)
end)

AddEventHandler('redem:playerLoaded', function(source)
local _source = source
  TriggerEvent('redem:getPlayerFromId', _source, function(user)
      local bankbalance = user.getBank()
      TriggerClientEvent("banking:updateBalance", _source, bankbalance)
      --user.displayBank(bankbalance)
    end)
end)
