local cjson = require('cjson')
local acc = require('core.account')

local blacklist = {
  'ROOT',
  'ADMINISTRATOR',
  'GAMEMASTER',
  'MODERATOR'
}

local account = {}

function account.create(self)
  local validation = {
    username = true,
    email = true,
    password = true
  }

  ngx.req.read_body()
  local body = ngx.var.request_body
  if not body then
    local err = 'empty/truncated body'
    ngx.log(ngx.STDERR, 'account: ' .. err)
    return ngx.HTTP_BAD_REQUEST, {
      username = false,
      email = false,
      password = false
    }
  end

  local data = cjson.decode(body) or {}
  if data.username then
    for _, v in ipairs(blacklist) do
      if v == data.username:lower() then validation.username = false end
    end
    if #data.username > 16 or acc:username_exists(data.username) then
      validation.username = false
    end
  else
    validation.username = false
  end

  if not data.email or not data.email:match('^[%w.]+@%w+%.%w+$') or
      acc:email_exists(data.email) then
    validation.email = false
  end
  if not data.password or #data.password > 16 then validation.password = false end

  if validation.username and
      validation.email and
      validation.password then
    local accid = acc:create(data.username, data.email, data.password, ngx.var.remote_addr)
    if accid then
      -- acc:send_email_verification(accid, data.email)
      return ngx.HTTP_CREATED, validation
    else
      local err = 'error while creating account'
      ngx.log(ngx.STDERR, 'account: ' .. err)
      return ngx.HTTP_INTERNAL_SERVER_ERROR, { reason = err }
    end
  end
  return ngx.HTTP_BAD_REQUEST, validation
end 

account.routes = {
  { context = '', method = 'POST', call = account.create }
}

return account
