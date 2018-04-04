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
  local validation = {
    username = true,
    email = true,
    password = true
  }

  if body then
    data = cjson.decode(body)
  else
    validation = {
      username = false,
      email = false,
      password = false
    }
  end

  if not data.username then validation.username = false end
  if not data.email then validation.email = false end
  if not data.password then validation.password = false end

  if validation.username and
      validation.email and
      validation.password then
    cursor = db:execute(
      "SELECT username, email FROM account WHERE \
        username = '" ..  db:escape(data.username) .. "' OR \
        email = '" .. db:escape(data.email) .. "';"
      )
    local numrows = cursor:numrows()

    if numrows ~= 0 then
      while cursor:fetch(result, 'a') do
        if result.username == data.username then validation.username = false end
        if result.email == data.email then validation.email = false end
      end
    else
      insert = db:execute(
        "INSERT INTO account \
          (username, sha_pass_hash, gmlevel, v, s, email, joindate, last_ip) \
          VALUES (
            '" .. db:escape(data.username) .. "', \
            SHA1(CONCAT( \
              UPPER('" .. db:escape(data.username) .. "'), ':', \
              UPPER('" .. db:escape(data.password) .. "') \
            )), 0, 0, 0, \
            '" .. db:escape(data.email).. "', \
            '" .. os.date("%Y-%m-%d %H:%M:%I", os.time()) .. "', \
            '" .. db:escape(ngx.var.remote_addr) .. "');"
      )
      if insert == 1 then
        response(ngx.HTTP_CREATED, validation)
      else
        response(ngx.HTTP_INTERNAL_SERVER_ERROR, nil)
      end
    end
    cursor:close()
    response(ngx.HTTP_BAD_REQUEST, validation)
  end
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
  elseif ngx.var.request_method == 'OPTIONS' then
    -- browser cors implementation sucks
    response(ngx.HTTP_OK, nil)
  end
end
response(ngx.HTTP_NOT_FOUND, nil)
