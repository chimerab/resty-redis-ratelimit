local redis = require "resty.redis"
local redis_client = redis:new()

redis_client:set_timeout(1000)
local ok, err = redis_client:connect ("ip",6379)

if not ok then
    ngx.log(ngx.ERR, "failed to connect to redis: ", err)
    return
end

local userid = ngx.req.get_headers()["token"]
local uri = ngx.var.uri

if userid == nil then
    redis_client:set_keepalive(1000, 20)
    ngx.status = 404
    -- ngx.say("userid is empty")
    ngx.exit(404)
end

local current = redis_client:get("ratelimit:"..userid)
-- 10 requests in window
if current ~= ngx.null and tonumber(current) > 10 then
    redis_client:set_keepalive(1000, 20)
    ngx.exit(429)
else
    -- 5 seconds window
    err = redis_client:eval("local value = redis.call('incr',KEYS[1]) if value == 1 then redis.call('expire',KEYS[1],5) end",1,"ratelimit:"..userid)
    redis_client:set_keepalive(1000, 20)
end

-- ngx.exec("/php/index.html",uri)
