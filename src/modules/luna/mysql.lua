local config = require('api.config')
local luasql = require('luasql.mysql')

local mysql = luasql.mysql()
return = mysql:connect(
  config.db.name,
  config.db.user,
  config.db.pass,
  config.db.host,
  config.db.port)
