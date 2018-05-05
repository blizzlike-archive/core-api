local cjson = require('cjson')
local core_realm = require('core.realm')

local realm = {}

function realm.list(self)
  local list, err = core_realm:list()
  if not list then
    ngx.log(ngx.STDERR, 'realm: ' .. err)
    return ngx.HTTP_INTERNAL_SERVER_ERROR, { reason = err }
  end

  local data = {}
  for _, v in pairs(list) do
    table.insert(data, {
      id = v.id,
      name = v.name,
      icon = v.icon,
      timezone = v.timezone,
      population = v.population
    })
  end
  return ngx.HTTP_OK, data
end

realm.routes = {
  { context = '', method = 'GET', call = realm.list }
}

return realm
