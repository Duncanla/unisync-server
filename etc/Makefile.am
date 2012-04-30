
pkgsysconfdir = $(sysconfdir)/$(PACKAGE)
pkgsysconf_DATA = unisync.prf unisync-server.conf unisync-server.lua unisync-server-user.lua

EXTRA_DIST = unisync.prf unisync-server.conf unisync-server-user.lua unisync-server.lua.in
CLEANFILES = unisync-server.lua

do_subst = sed -i -e 's,[@]pkgsysconfdir[@],$(pkgsysconfdir),g' \
			      -e 's,[@]VERSION[@],$(VERSION),g' \
				  -e 's,[@]pkglibexecdir[@],$(pkglibexecdir),g' \
				  -e 's/[@]program_transform_name[@]/$(program_transform_name)/g'

sync_name = `echo unisync-sync-client | sed '$(program_transform_name)'`
syncinit_name = `echo unisync-server-syncinit | sed '$(program_transform_name)'`
update_name = `echo unisync-update-clients | sed '$(program_transform_name)'`
conflict_res_name = `echo unisync-conflict-resolve | sed '${program_transform_name)'`

cmd_subst = sed -i -e "s/[@]unisync-sync-client[@]/$(sync_name)/" \
				   -e "s/[@]unisync-server-syncinit[@]/$(syncinit_name)/"
				   -e "s/[@]unisync-update-clients[@]/$(update_name}"
				   -e "s/[@]unisync-conflict-resolve[@]/$(conflict_res_name)"

unisync-server.lua: %: %.in
	rm -f $@
	cat $^ >> $@
	$(do_subst) $@
	$(cmd_subst) $@
	chmod u+x $@
