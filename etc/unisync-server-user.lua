
-- Unisync server user configuration
-- Add syncs below
--
-- server_update: This is the default unisync mode. Leave it as it
--                is.
--
-- unisync_id:    This is a unique id for each sync that will be used
--                by the client to identify which sync it wants to use
--
-- source:        This is the directory that you would like to sync
 

-- Watch for updates that are pushed to the server
sync {
   server_update,
   unisync_id = "",
   source = "",
}