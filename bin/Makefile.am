
bin_SCRIPTS = unisync-client-port \
			  unisync-reg-client \
			  unisync-server \
			  unisync-server-status \
			  unisync-sync-req \
			  unisync-client-mon 

EXTRA_DIST = unisync-client-port.sh \
			 unisync-reg-client.sh \
			 unisync-server.sh  \
			 unisync-server-status.sh \
			 unisync-sync-req.sh \
			 unisync-client-mon.sh 


CLEANFILES = $(bin_SCRIPTS)

pkgsysconfdir = $(sysconfdir)/$(PACKAGE)

do_subst = sed -i -e 's,[@]pkgsysconfdir[@],$(pkgsysconfdir),g' \
			      -e 's,[@]VERSION[@],$(VERSION),g' \
			      -e 's,[@]pkglibexecdir[@],$(pkglibexecdir),g' \
				  -e 's,[@]bindir[@],$(bindir),g'

sync_req_cmd = `echo unisync-sync-req | sed '$(program_transform_name)'`
server_cmd = `echo unisync-server | sed '$(program_transform_name)'`
mon_cmd = `echo unisync-client-mon | sed '$(program_transform_name)'`
status_cmd = `echo unisync-server-status | sed '$(program_transform_name)'`
sync_client_cmd = `echo unisync-sync-client | sed '$(program_transform_name)'`

cmd_subst = sed -i -e "s,[@]unisync-sync-req[@],$(sync_req_cmd),g" \
				   -e "s,[@]unisync-server[@],$(server_cmd),g" \
				   -e "s,[@]unisync-client-mon[@],$(mon_cmd),g" \
				   -e "s,[@]unisync-server-status[@],$(status_cmd),g" \
				   -e "s,[@]unisync-sync-client[@],$(sync_client_cmd),g"

$(bin_SCRIPTS): %: %.sh
	rm -f $@
	echo "#!" $(BASH) > $@
	cat $^ >> $@
	$(do_subst) $@
	$(cmd_subst) $@
	chmod u+x $@
