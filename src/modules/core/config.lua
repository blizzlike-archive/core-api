local config = {}

function config.load(self)
  local file = '/etc/luna/core.lua'
  local fd = io.open(file, 'r')

  if fd then
    fd:close()
    self.config = dofile(file)
  else
    self.config = {
      db = {
        realmd = {
          name = '',
          user = '',
          pass = '',
          host = '',
          port = 3306,
        }
      }
    }
  end
end

config:load()

return config
