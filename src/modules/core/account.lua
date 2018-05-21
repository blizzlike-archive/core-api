local config = require('core.config')
local session = require('core.session')
local luasql = require('luasql.mysql')
local salt = require('salt')

local _connect = function()
  local mysql = luasql.mysql()
  return mysql:connect(
    config.db.realmd.name,
    config.db.realmd.user,
    config.db.realmd.pass,
    config.db.realmd.host,
    config.db.realmd.port)
end

local account = {}

function account.auth(self, username, password, ip)
  local db = _connect()
  local cursor = db:execute(
    "SELECT id FROM account WHERE \
      UPPER(username) = '" .. db:escape(username:upper()) .. "' AND \
      sha_pass_hash = \
        SHA1(CONCAT( \
          UPPER(`username`), ':', \
          UPPER('" .. db:escape(password) .. "') \
        ));")
  if cursor and cursor:numrows() ~= 0 then
    local row = cursor:fetch({}, 'a')
    cursor:close()
    local s = session:create(row.id, ip)
    if s then
      db:close()
      return s
    end
  end
  db:close()
  return nil, 'cannot authenticate'
end

function account.create(self, username, email, password, ip)
  local db = _connect()
  local autoid = nil
  local cursor = db:execute(
    "INSERT INTO account \
      (username, sha_pass_hash, email, email_check, joindate, last_ip) \
      VALUES ( \
        '" .. db:escape(username:upper()) .. "', \
        SHA1(CONCAT( \
          UPPER('" .. db:escape(username) .. "'), ':', \
          UPPER('" .. db:escape(password) .. "') \
        )), \
        LOWER('" .. db:escape(email) .. "'), \
        '" .. salt:gen(16) .. "', \
        NOW(), \
        '" .. db:escape(ip) .. "' \
      );")
  if cursor == 1 then autoid = db:getlastautoid() end
  db:close()
  return autoid
end

function account.email_exists(self, email)
  local db = _connect()
  local cursor = db:execute(
    "SELECT LOWER(email) AS email \
      FROM account WHERE \
      email = '" .. db:escape(email:lower()) .. "';")

  if cursor:numrows() ~= 0 then
    cursor:close()
    db:close()
    return true
  end
  db:close()
  return false
end

function account.passwd(self, id, password)
  local db = _connect()
  local cursor = db:execute(
    "UPDATE account SET sha_pass_hash = \
      SHA1(CONCAT( \
        UPPER(`username`), ':', \
        UPPER('" .. db:escape(password) .. "') \
      )), \
      WHERE id = " .. id .. ";")
  if cursor == 1 then
    db:close()
    return true
  end
  db:close()
  return nil, 'cannot update password'
end

function account.username_exists(self, username)
  local db = _connect()
  local cursor = db:execute(
    "SELECT id, LOWER(username) AS username \
      FROM account WHERE \
      username = '" .. db:escape(username:lower()) .. "';")

  if cursor:numrows() ~= 0 then
    local row = cursor:fetch({}, 'a')
    cursor:close()
    db:close()
    return row.id
  end
  db:close()
  return false, 'user does not exist'
end

return account
