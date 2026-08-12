#
# vm-bhyve-qemu Makefile
#

PREFIX?=/usr/local
BINDIR=$(DESTDIR)$(PREFIX)/sbin
EXAMPLESDIR=$(DESTDIR)$(PREFIX)/share/examples/vm-bhyve
LIBDIR=$(DESTDIR)$(PREFIX)/lib/vm-bhyve
MANDIR=$(DESTDIR)$(PREFIX)/share/man/man8

CP=/bin/cp
INSTALL=/usr/bin/install
LN=/bin/ln
MKDIR=/bin/mkdir

PROG=vm
MAN=$(PROG).8

install:
	$(MKDIR) -p $(BINDIR)
	$(INSTALL) -m 755 $(PROG) $(BINDIR)/
	# Linux uses GNU sed, whose in-place syntax does not require the
	# empty backup suffix used by FreeBSD sed.
	sed -i -e 's|/usr/local/lib/vm-bhyve|$(LIBDIR)|g' $(BINDIR)/$(PROG)

	$(MKDIR) -p $(LIBDIR)
	$(INSTALL) lib/* $(LIBDIR)/

	$(MKDIR) -p $(EXAMPLESDIR)
	$(INSTALL) sample-templates/* $(EXAMPLESDIR)/

	# FreeBSD-specific rc.d installation removed.
	# Linux service integration should use systemd unit files instead.
	# $(MKDIR) -p $(RCDIR)
	# $(INSTALL) -m 555 rc.d/* $(RCDIR)/

	$(MKDIR) -p $(MANDIR)
	gzip -fk $(MAN)
	$(INSTALL) $(MAN).gz $(MANDIR)/
	rm -f -- $(MAN).gz
	$(LN) -sf $(MANDIR)/$(MAN).gz $(MANDIR)/vm-bhyve.8.gz

vmdir:
	@if [ -z "${PATH}" ]; then \
		echo "Usage: make vmdir PATH=/path"; \
	else \
		${MKDIR} -p "${PATH}/.templates"; \
		${MKDIR} -p "${PATH}/.iso"; \
		${MKDIR} -p "${PATH}/.config"; \
		${CP} sample-templates/* "${PATH}/.templates/"; \
	fi

.MAIN: clean
clean: ;
