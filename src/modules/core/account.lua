local config = require('core.config')
local luasql = require('luasql.mysql')

local mysql = luasql.mysql()
local db = mysql:connect(
  config.db.realmd.name,
  config.db.realmd.user,
  config.db.realmd.pass,
  config.db.realmd.host,
  config.db.realmd.port)

local account = {}

function account.create(self, username, email, password, ip, lock)
  local locked = 0
  if lock then locked = 1 end
  local cursor = db:execute(
    "INSERT INTO account \
      (username, sha_pass_hash, email, joindate, locked, last_ip) \
      VALUES ( \
        'UPPER(" .. db:escape(username) .. ")', \
        SHA1(CONCAT( \
          UPPER('" .. db:escape(username) .. "'), ':', \
          UPPER('" .. db:escape(password) .. "') \
        )), \
        'LOWER(" .. db:escape(email) .. ")', \
        NOW(), " .. locked .. " \
        '" .. db:escape(ip) .. "'
      );")
  if cursor == 1 then return true end
  return false
end

function account.email_exists(self, email)
  local cursor = db:execute(
    "SELECT LOWER(email) AS email \
      FROM account WHERE \
      email = '" .. db:escape(email:lower()) .. "';")

  if cursor:numrows() ~= 0 then
    cursor:close()
    return true
  end
  return false
end

function account.username_exists(self, username)
  local cursor = db:execute(
    "SELECT LOWER(username) AS username \
      FROM account WHERE \
      username = '" .. db:escape(username:lower()) .. "';")

  if cursor:numrows() ~= 0 then
    cursor:close()
    return true
  end
  return false
end

return account
