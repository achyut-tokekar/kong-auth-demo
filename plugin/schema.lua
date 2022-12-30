local typedefs = require "kong.db.schema.typedefs"


return {
  name = "custom-auth",
  fields = {
    { protocols = typedefs.protocols_http },
    { consumer = typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { token_header = typedefs.header_name { default = "Authorization", required = true }, }
        }, 
    }, 
    },
  },
}

