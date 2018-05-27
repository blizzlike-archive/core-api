local config = require('core.config')
local luasql = require('luasql.mysql')

local _connect = function()
  local mysql = luasql.mysql()
  return mysql:connect(
    config.db.realmd.name,
    config.db.realmd.user,
    config.db.realmd.pass,
    config.db.realmd.host,
    config.db.realmd.port)
end

local realm = {}

function realm.list(self)
  local db = _connect()
  local cursor = db:execute("SELECT * FROM realmlist")
  if not cursor then
    db:close()
    return nil, 'database error'
  end
  if cursor:numrows() ~= 0 then
    local row = cursor:fetch({}, 'a')
    local list = {}
    while row do
      local state = 0
      local sock = ngx.socket.tcp()
      local ok, err = sock:connect(row.address, row.port)
      if ok then
        sock:close()
        state = 1
      end
      table.insert(list, {
        icon = tonumber(row.icon),
        timezone = tonumber(row.timezone),
        population = tonumber(row.population),
        name = row.name,
        id = tonumber(row.id),
        state = state
      })
      row = cursor:fetch(row, 'a')
    end
    cursor:close()
    db:close()
    return list
  end
  db:close()
  return {}, 'no realms available'
end

return realm
