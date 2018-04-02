-- blizz-api

local cjson = require('cjson')

local response = function(status, content)
  ngx.header['Content-Type'] = 'application/json'
  ngx.status = status

  if content then
    ngx.print(cjson.encode(content))
  end

  ngx.exit(ngx.OK)
end

local post_account = function()
  response(ngx.HTTP_CREATED, { reason = 'created' })
end

local routes = {
  { uri = '/v1/account', method = 'POST', func = post_account }
}

for _, route in pairs(routes) do
  local uri = '^' .. route.uri
  local match = ngx.re.match(ngx.var.uri, uri, 'oi')
  if match and ngx.var.request_method == route.method then
    route.func()
  end
  response(ngx.HTTP_NOT_FOUND, nil)
end
