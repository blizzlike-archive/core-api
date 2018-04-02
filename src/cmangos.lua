-- blizz-api

local luasql = require('luasql.mysql')
local cjson = require('cjson')
local config = require('config')

local mysql = luasql.mysql()
local db = mysql:connect(
  config.db.name,
  config.db.user,
  config.db.pass,
  config.db.host,
  config.db.port)

local response = function(status, content)
  ngx.header['Content-Type'] = 'application/json'
  ngx.status = status

  if content then
    ngx.print(cjson.encode(content))
  end

  db:close()
  ngx.exit(ngx.OK)
end

local post_account = function(body)
  if body then
    data = cjson.decode(body)
  end

  if type(data) == 'table' and
      data.username and data.email and data.password then
    cursor = db:execute(
        "SELECT username, email FROM account WHERE username = '" ..
        db:escape(data.username) ..
	"' OR email = '" ..
	db:escape(data.email) .. "';"
      )
    local numrows = cursor:numrows()
    cursor:close()

    if numrows == 0 then
      password = "SHA1(CONCAT(UPPER('" .. db:escape(data.username) .. "'), ':', UPPER('" .. db:escape(data.password) .. "')))"
      cursor, err = db:execute(
        "INSERT INTO account " ..
        "(username, sha_pass_hash, gmlevel, v, s, email, joindate, last_ip) " ..
	"VALUES ('" .. db:escape(data.username) .. "', " .. password .. ", 0, 0, 0, '" ..
        db:escape(data.email).. "', '" .. os.date("%Y-%m-%d %H:%M:%I", os.time()) .. "', '" ..
        ngx.var.remote_addr .. "');"
      )

      if cursor == 1 then
        response(ngx.HTTP_CREATED, nil)
      end
    end
  end

  response(ngx.HTTP_BAD_REQUEST, nil)
end

local routes = {
  { uri = '/v1/account', method = 'POST', func = post_account }
}

for _, route in pairs(routes) do
  local uri = '^' .. route.uri
  local match = ngx.re.match(ngx.var.uri, uri, 'oi')
  if match and ngx.var.request_method == route.method then
    ngx.req.read_body()
    route.func(ngx.var.request_body or nil)
  end
  response(ngx.HTTP_NOT_FOUND, nil)
end
