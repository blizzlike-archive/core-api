local helper = {}

local timeout = 86400

function helper.set_cookie(self, token)
  local expiry = ngx.time() + timeout
  local cookie = 'token=' .. token .. '; Path=/; Expires=' .. ngx.cookie_time(expiry)

  ngx.header['Set-Cookie'] = { cookie }
end

function helper.get_body(self)
  ngx.req.read_body()
  local body = ngx.var.request_body
  if not body then
    return nil, 'empty/truncated body'
  end
  return body
end

return helper
