local config = require('core.config')
local luasql = require('luasql.mysql')
local uuid = require('uuid')
local socket = require('socket')

local _connect = function()
  local mysql = luasql.mysql()
  return mysql:connect(
    config.db.api.name,
    config.db.api.user,
    config.db.api.pass,
    config.db.api.host,
    config.db.api.port)
end

local session = {}

function session.create(self, id, ip)
  uuid.randomseed(socket.gettime() * 10000)
  local token = uuid()
  local expiry = os.time() + config.session.expiry
  local db = _connect()
  local cursor = db:execute(
    "INSERT INTO session \
      (token, acctid, ip, expiry) \
      VALUES \
      ('" .. db:escape(token) .. "', \
      " .. db:escape(id) .. ", \
      '" .. db:escape(ip) .. "', \
      " .. expiry .. ");")
  if cursor and cursor == 1 then
    db:close()
    return {
      token = token,
      acctid = id,
      ip = ip,
      expiry = expiry
    }
  end
  db:close()
  return session:create(id, ip)
end

-- broken, fix it or delete it
function session.token_exists(self, token)
  local db = _connect()
  local cursor, err = db:execute(
    "SELECT * FROM session WHERE \
      token = '" .. db:escape(token) .. "';")

  print(err)
  if cursor and cursor:numrows() > 0 then
    cursor:close()
    db:close()
    return nil, 'token already taken'
  end
  db:close()
  return true
end

return session
