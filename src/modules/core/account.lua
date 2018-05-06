local config = require('core.config')
local luasql = require('luasql.mysql')
local salt = require('salt')

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

function account.auth(self, username, password)
  local cursor = db:execute(
    "SELECT id FROM account WHERE \
      username = '" .. db:escape(username) .. "' AND \
      password = \
        SHA1(CONCAT( \
          UPPER(`username`), ':', \
          UPPER('" .. db:escape(password) .. "') \
        ));")
  if cursor:numrows() ~= 0 then
    local row = cursor:fetch({}, 'a')
    cursor:close()
    return row.id
  end
  return nil, 'cannot authenticate'
end

function account.create(self, username, email, password, ip)
  local cursor = db:execute(
    "INSERT INTO account \
      (username, sha_pass_hash, email, joindate, last_ip) \
      VALUES ( \
        'UPPER(" .. db:escape(username) .. ")', \
        SHA1(CONCAT( \
          UPPER('" .. db:escape(username) .. "'), ':', \
          UPPER('" .. db:escape(password) .. "') \
        )), \
        'LOWER(" .. db:escape(email) .. ")', \
        NOW(), \
        '" .. db:escape(ip) .. "' \
      );")
  if cursor == 1 then return db:getlastautoid() end
  return nil
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

function account.passwd(self, id, password)
  local cursor = db:execute(
    "UPDATE account SET sha_pass_hash = \
      SHA1(CONCAT( \
        UPPER(`username`), ':', \
        UPPER('" .. db:escape(password) .. "') \
      )), \
      WHERE id = " .. id .. ";")
  if cursor == 1 then
    return true
  end
  return nil, 'cannot update password'
end

function account.username_exists(self, username)
  local cursor = db:execute(
    "SELECT id, LOWER(username) AS username \
      FROM account WHERE \
      username = '" .. db:escape(username:lower()) .. "';")

  if cursor:numrows() ~= 0 then
    local row = cursor:fetch({}, 'a')
    cursor:close()
    return row.id
  end
  return false, 'user does not exist'
end

function account.send_email_verification(self, id, email)
  local token = salt:gen(16)
  local cursor = db:execute(
    "UPDATE account SET email_check = \
    '" .. token .. "' WHERE id = '" .. db:escape(id) .. "'")
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
