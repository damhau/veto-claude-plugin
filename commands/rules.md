---
description: List whitelist and blacklist rules from the Veto server
---

Read ~/.veto/config.json for server_url and api_key, then call GET {server_url}/api/v1/rules with Authorization: Bearer {api_key}. Display results as a table with columns: Type, Tool Pattern, Content Pattern, Priority, Enabled.
