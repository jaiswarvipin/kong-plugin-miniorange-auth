local kong = kong
local type = type
local match = string.match
local noop = function() end
local ngx  = ngx
local cjson = require "cjson.safe"

local CONTENT_LENGTH_NAME  = "Content-Length"
local CONTENT_TYPE_NAME    = "Content-Type"
local CONTENT_TYPE_JSON    = "application/json; charset=utf-8"
local CONTENT_TYPE_GRPC    = "application/grpc"

-- new table
local _M = {}

-- iterate over an array of config values
local function iter(config_array)
  if type(config_array) ~= "table" then
    return noop
  end

  return function(config_array, i)
    i = i + 1

    local header_to_test = config_array[i]
    if header_to_test == nil then
      return nil
    end
    
    return i, header_to_test
  end, config_array, 0
end

function _M.filter(conf, headers)
	local strUpstreamURI = ngx.var.upstream_uri --Get the Upstream URI from NGIEX env.
	kong.log('Upstream URL :'..strUpstreamURI)	-- Printing the variable
	-- ngx.header[CONTENT_TYPE_NAME] = CONTENT_TYPE_JSON	-- Setting the response header
  
	if strUpstreamURI == nil or strUpstreamURI == "" then
		error("Invalid Service URL",2)
	end
  
	if strUpstreamURI ~= '' then
		ngx.exit("Valid Service URL");
	end
    
	ngx.status = 403
	
	ngx.exit(ngx.status)

--  return "Upstream URL found"..strUpstreamURI
end

return _M