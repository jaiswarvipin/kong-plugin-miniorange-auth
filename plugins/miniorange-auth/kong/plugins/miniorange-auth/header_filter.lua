local kong = kong
local type = type
local match = string.match
local noop = function() end
local ngx  = ngx

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
  kong.log(strUpstreamURI)	-- Printing the variable
  
  if strUpstreamURI == nil or strUpstreamURI == "" then
	return "Invalid Service URL"
  end
  
  return "Upstream URL found"..strUpstreamURI
end

return _M