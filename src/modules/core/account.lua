local config = require('core.config')
local luasql = require('luasql.mysql')

local smtp = require("resty.smtp")
local mime = require("resty.smtp.mime")

local mysql = luasql.mysql()
local db = mysql:connect(
  config.db.realmd.name,
  config.db.realmd.user,
  config.db.realmd.pass,
  config.db.realmd.host,
  config.db.realmd.port)

local account = {}

local charset = {}  do -- [0-9a-zA-Z]
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 65, 90  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

local function _randomString(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock()^5)
    return randomString(length - 1) .. charset[math.random(1, #charset)]
end

function account.create(self, username, email, password, ip, lock)
  local locked = 0
  if lock then locked = 1 end
  local cursor = db:execute(
    "INSERT INTO account \
      (username, sha_pass_hash, email, joindate, locked, last_ip) \
      VALUES ( \
        'UPPER(" .. db:escape(username) .. ")', \
        SHA1(CONCAT( \
          UPPER('" .. db:escape(username) .. "'), ':', \
          UPPER('" .. db:escape(password) .. "') \
        )), \
        'LOWER(" .. db:escape(email) .. ")', \
        NOW(), " .. locked .. " \
        '" .. db:escape(ip) .. "'
      );")
  if cursor == 1 then return true end
  return false
end

function account.email_exists(self, email)
  local cursor = db:execute(
    "SELECT LOWER(email) AS email \
      FROM account WHERE \
      email = '" .. db:escape(email:lower()) .. "';")

  if cursor:numrows() ~= 0 then
    cursor:close()
    return true
  end
  return false
end

function account.username_exists(self, username)
  local cursor = db:execute(
    "SELECT LOWER(username) AS username \
      FROM account WHERE \
      username = '" .. db:escape(username:lower()) .. "';")

  if cursor:numrows() ~= 0 then
    cursor:close()
    return true
  end
  return false
end

function account.send_email_verification(self, id, email)
  local token = _randomString(16)
  local cursor = db:execute(
    "UPDATE account SET email_check = \
    '" .. token .. "' WHERE id = '" .. id .. "'")
  if cursor == 1 then
    local mail = {
      headers = {
        subject = mime.ew(
          'email verification',
          nil, { charset= 'utf-8' }),
        ['Content-Transfer-Encoding']= 'BASE64',
        ['Content-Type']= "text/plain; charset='utf-8'",
      },
      body = mime.b64(
        'please verify your mail address. \
          goto https://' .. config.verification.url .. '/' .. token)
    }
    local ret, err = smtp.send({
      from = config.verification.from,
      rcpt = email,
      user = config.verification.user,
      password = config.verification.pass,
      server = config.verification.host,
      domain = nil,
      source = smtp.message(mail),
    })
    return true
  end
  return nil
end

return account
