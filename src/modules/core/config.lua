local config = {}
local cfg = {}

function config.load(self)
  local file = '/etc/luna/core.lua'
  local fd = io.open(file, 'r')

  if fd then
    fd:close()
    cfg = dofile(file)
  else
    cfg = {
      db = {
        api = {
          name = '',
          user = '',
          pass = '',
          host = '',
          port = 3306,
        },
        realmd = {
          name = '',
          user = '',
          pass = '',
          host = '',
          port = 3306,
        }
      },
      session = {
        expiry = 86400
      }
    }
  end
end

config:load()

return cfg
