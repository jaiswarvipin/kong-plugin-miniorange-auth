local kong = kong

-- Import the base kong plugin
local BasePlugin = require "kong.plugins.base_plugin"
-- Extend our plugin from the access plugin
local access = require "kong.plugins.miniorange-auth.access"

-- Extend our plugin from the base plugin
local MiniorangeAuthHandler = BasePlugin:extend()

-- Setting this very early to avoid logging any service-tokens
MiniorangeAuthHandler.PRIORITY = 5

-- creates a new instance of the plugin
function MiniorangeAuthHandler:new()
  MiniorangeAuthHandler.super.new(self, "miniorange-auth")
end

-- plugin built-in method to handle response header
function MiniorangeAuthHandler:access(conf)
  MiniorangeAuthHandler.super.access(self)
  -- Add our logic to find the Secret-Token header and remove it
  -- kong.response.clear_header("SECRET-TOKEN")
  access.execute(conf)
end

-- return the plugin class
return MiniorangeAuthHandler