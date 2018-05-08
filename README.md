# ORCA

## Private CA container

My very customized serverless certificate authority, designed to support backend cloud communications with auto generated certificates for your apps and users. By design, the private certificates remain in volitile storage in the container, and is only run to generate new certificates. Essentially acts as an on demand certificate authority for authenticating your apps and users without exposing a certificate service to the network directly.

Configured for Securing Labs
