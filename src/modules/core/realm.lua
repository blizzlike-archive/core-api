local config = require('core.config')
local luasql = require('luasql.mysql')

local mysql = luasql.mysql()
local db = mysql:connect(
  config.db.realmd.name,
  config.db.realmd.user,
  config.db.realmd.pass,
  config.db.realmd.host,
  config.db.realmd.port)

local realm = {}

function realm.list(self)
  local cursor = db:execute("SELECT * FROM realmlist")
  if not cursor then
    return nil, 'database error'
  end
  if cursor:numrows() ~= 0 then
    local row = cursor:fetch({}, 'a')
    local list = {}
    while row do
      table.insert(list, row)
      row = cur:fetch(row, 'a')
    end
    cursor:close()
    return list
  end
  return {}, 'no realms available'
end

return realm
