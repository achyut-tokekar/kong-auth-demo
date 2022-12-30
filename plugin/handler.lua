local http = require "resty.http"
local cjson = require "cjson"
-- local Storage = require "kong.plugins.custom-auth.storage"

local redis_connector, err = require("resty.redis.connector")

kong.log(redis_connector, "REDIS CONNECTOR");

kong.log(err, "ERROR FROM REDIS CONNECTOR")


local TokenHandler = {
    VERSION = "1.0",
    PRIORITY = 1000,
}


local function introspect_access_token(conf, access_token)
  local httpc = http:new()
  -- local storage, err = Storage:new()
  -- kong.log(storage, ">>>>>>>>>>>>storage Value");

  -- kong.log(err, "ERROR IN CONNECTING LUA REDIS CONNECTOR")

  -- storage:set_config()

  -- local cached_value, err = storage:get("demo_key")
  -- if not cached_value then
  --   storage:set("demo_key", "DEMO VALUE", 8000)
  -- end
  -- local cached_value, err = storage:get("demo_key")
  -- kong.log(cached_value)


  local res, err = httpc:request_uri(conf.jwt_verification_endpoint, {
      method = "POST",
      ssl_verify = false,
      headers = {
          ["Authorization"] = access_token,
          ["path"] = kong.request.get_path(),
          ["method"] = kong.request.get_method(),
          ["client-type"] = kong.request.get_headers()['client-type'],
          ["client-id"] = kong.request.get_headers()['client-id'],
          ["randomid"] = kong.request.get_headers()['randomid'],
          ["origin"] = kong.request.get_headers()['origin'],
        }
  })

  if not res then
    kong.log.err("failed to call jwt_verification_endpoint: ",err)
    return kong.response.exit(500)
  end

  if res.status == 201 then
        local body = cjson.decode(res.body)
        if body and body["data"] and body["data"]["userId"] then 
            kong.service.request.set_headers({["xx-kong-userId"] = body["data"]["userId"]})
        end
        if body and body["data"] and body["data"]["public"] then
            kong.service.request.set_headers({["xx-public-true"] = body["data"]["public"]})
        end
        if body and body["data"] and body["data"]["req_matchedPath"] then 
            kong.service.request.set_headers({["xx-req-matchedPath"] = body["data"]["req_matchedPath"]})
        end
        if body and body["data"] and body["data"]["req_url"] then
            kong.service.request.set_headers({["xx-req-url"] = body["data"]["req_url"]})
        end
  else
    kong.response.exit(res.status)
  end

  kong.log(" <=========== all is well ============>")
  return true
end

function TokenHandler:access(conf)
  local access_token = kong.request.get_headers()[conf.token_header]
  introspect_access_token(conf, access_token)
end


return TokenHandler
