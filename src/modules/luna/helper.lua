local salt = require('salt')
local helper = {}

local expire = 86400

function helper.create_session(self, id)
  local accoundid = 'account_id=' .. id .. '; Path=/; Expires=' .. ngx.cookie_time(ngx.time() + expire)
  local sessionid = 'token=' .. salt:gen(64) .. '; Path=/; Expires=' .. ngx.cookie_time(ngx.time() + expire)

  ngx.header['Set-Cookie'] = { accountid, sessionid }
end

function helper.get_body(self)
  ngx.read_body()
  local body = ngx.var.request_body
  if not body then
    return nil, 'empty/truncated body'
  end
  return body
end

return helper
