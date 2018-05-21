#!/usr/bin/env lua5.1

local luasql = require('luasql.mysql')

local migrate = {}

local migrations = {
  [1] = function(db)
    local cursor, err = db:execute(
      "CREATE TABLE IF NOT EXISTS migrations ( \
        id INT(11) UNSIGNED NOT NULL COMMENT 'migration state / database version', \
        executed INT(11) UNSIGNED NOT NULL COMMENT 'execution time', \
        \
        UNIQUE KEY idx_id (id) \
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='migrations state';")
    if not cursor then return nil, err end

    local cursor, err = db:execute(
      "CREATE TABLE IF NOT EXISTS session ( \
        token VARCHAR(36) NOT NULL COMMENT 'api auth token', \
        acctid INT(11) unsigned NOT NULL COMMENT 'unique account id', \
        ip VARCHAR(45) NOT NULL COMMENT 'ipv4/ipv6 address of the client', \
        expiry INT(11)NOT NULL COMMENT 'timestamp of token expiry', \
        \
        UNIQUE KEY idx_token (token) \
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC COMMENT='api access sessions';")
    if not cursor then return nil, err end
    return true
  end
}

function migrate.commit(self, db, state)
  local cursor = db:execute(
    "INSERT INTO migrations \
    (id, executed) \
    VALUES \
    (" .. db:escape(state) .. "), \
    " .. os.time() .. "")
end

function migrate.get_current_state(self, db)
  local cursor = db:execute("SELECT id ORDER BY id DESC LIMIT 1;")
  if cursor then
    local state = cursor:fetch({}, 'a')
    cursor:close()
    return state.id
  end
end

function migrate.run(self)
  local mysql = luasql.mysql()
  local db = mysql:connect(
    arg[1] or 'core_api',
    arg[2] or 'api',
    arg[3] or 'api',
    arg[4] or '127.0.0.1',
    arg[5] or 3306)
  local state = migrate:get_current_state(db) or 0
  local latest = #migrations

  print('DB Version: current(' .. state .. ') / latest(' .. latest .. ')')
  local nxt = state + 1
  if latest > state then
    for k = nxt, latest, 1 do
      local m, e = migrations[k](db)
      if m then
        print('[' .. k .. '] migrated')
        migrate:commit(db, k)
      else
        print('[' .. k .. '] failed!')
        print(e)
        os.exit(1)
      end
    end
  end

  db:close()
end

-- usage: migrate.lua db user pass host port
migrate:run()
