
-- Watch for updates that are pushed to the server
sync {
   server_update,
   unisync_id = "data_sync",
   source = "/home/luke/testunisync",
   target = localhost
}