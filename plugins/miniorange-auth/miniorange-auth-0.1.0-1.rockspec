package = "miniorange-auth"

version = "0.1.0-1"

-- The version '0.1.0' is the source code version, the trailing '1' is the version of this rockspec
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

supported_platforms = {"linux", "macosx"}

source = {
  url = "https://github.com/jaiswarvipin/kong-plugin-miniorange-auth",
  tag = "1.0.1"
}

description = {
  summary = "A Kong plugin that allows any request authrization before proxying the original.",
  license = "MIT"
}

dependencies = {
}

local pluginName = "miniorange-auth"
build = {
  type = "builtin",
  modules = {
	["kong.plugins."..pluginName..".access"] = "kong/plugins/"..pluginName.."/access.lua",
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
	["kong.plugins."..pluginName..".json"] = "kong/plugins/"..pluginName.."/json.lua"
  }
}