local cjson = require('cjson')
local core_acc = require('core.account')
local lh = require('luna.helper')

local blacklist = {
  'ROOT',
  'ADMINISTRATOR',
  'GAMEMASTER',
  'MODERATOR'
}

local account = {}

function account.auth(self)
  local body, err = lh:get_body()
  if not body then
    ngx.log(ngx.STDERR, 'account: ' .. err)
    return ngx.HTTP_BAD_REQUEST, { reason = err }
  end

  local data = cjson.decode(body) or {}
  if data.username and data.password then
    local id, err = core_acc:auth(data.username, data.password)
    if id then
      lh:create_session(id)
      return ngx.HTTP_OK, { id = id }
    end
    return ngx.HTTP_FORBIDDEN, { reason = err }
  end
  return ngx.HTTP_BAD_REQUEST, {
    username = data.username ~= nil,
    password = data.password ~= nil
  }
end

function account.create(self)
  local validation = {
    username = true,
    email = true,
    password = true
  }

  local body, err = lh:get_body()
  if not body then
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
    if #data.username > 16 or core_acc:username_exists(data.username) then
      validation.username = false
    end
  else
    validation.username = false
  end

  if not data.email or not data.email:match('^[%w.]+@%w+%.%w+$') or
      core_acc:email_exists(data.email) then
    validation.email = false
  end
  if not data.password or #data.password > 16 then validation.password = false end

  if validation.username and
      validation.email and
      validation.password then
    local accid = core_acc:create(data.username, data.email, data.password, ngx.var.remote_addr)
    if accid then
      -- core_acc:send_email_verification(accid, data.email)
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
  { context = '/auth', method = 'POST', call = account.auth }
  { context = '', method = 'POST', call = account.create }
}

return account
