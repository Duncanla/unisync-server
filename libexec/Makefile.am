
pkglibexec_SCRIPTS = unisync-client-mon \
					 unisync-conflict-resolve \
					 unisync-server-syncinit \
					 unisync-sync-client \
					 unisync-update-clients

EXTRA_DIST = unisync-client-mon.sh \
			 unisync-conflict-resolve.sh \
			 unisync-server-syncinit.sh \
			 unisync-sync-client.sh \
			 unisync-update-clients.sh

CLEANFILES = $(pkglibexec_SCRIPTS)

pkgsysconfdir = $(sysconfdir)/$(PACKAGE)

do_subst = sed -i -e 's,[@]pkgsysconfdir[@],$(pkgsysconfdir),g' \
			      -e 's,[@]VERSION[@],$(VERSION),g' \
				  -e 's,[@]pkglibexecdir[@],$(pkglibexecdir),g'

cmd_subst = sed -i -e "s,[@]UNISON[@],$(UNISON),g"


$(pkglibexec_SCRIPTS):%: %.sh
	rm -f $@
	echo "#! " $(BASH) > $@
	cat $^ >> $@
	$(do_subst) $@
	$(cmd_subst) $@
	chmod u+x $@
