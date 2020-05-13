local typedefs = require "kong.db.schema.typedefs"

return {
  name = "miniorange-auth",
  fields = {
    { config = {
        type = "record",
        fields = {
          { remove = {
            type = "array",
            default = {},
            elements = { type = "string" },
          } }
        },
      },
    },
  },
}