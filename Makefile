#
# vm-bhyve-qemu Makefile (GNU make)
#
PREFIX?=		/usr/local
SYSCONFDIR?=		/etc
SYSTEMDUNITDIR?=	/usr/lib/systemd/system

BINDIR=			$(DESTDIR)$(PREFIX)/sbin
LIBDIR=			$(DESTDIR)$(PREFIX)/lib/vm-bhyve
EXAMPLESDIR=		$(DESTDIR)$(PREFIX)/share/vm-bhyve/templates
MANDIR=			$(DESTDIR)$(PREFIX)/share/man/man8
UNITDIR=		$(DESTDIR)$(SYSTEMDUNITDIR)
CONFDIR=		$(DESTDIR)$(SYSCONFDIR)

# runtime (unstaged) library path - this is what gets baked into the
# script, so it must NOT contain $(DESTDIR) or a package built with
# DESTDIR=/tmp/build would look for its libraries in /tmp/build.
RUNTIME_LIBDIR=		$(PREFIX)/lib/vm-bhyve

INSTALL?=		install
PROG=			vm
MAN=			$(PROG).8

.PHONY: all install install-systemd install-config vmdir clean

all:
	@echo "nothing to build - run 'make install' (optionally with PREFIX=...)"

install:
	$(INSTALL) -d -m 755 $(BINDIR)
	$(INSTALL) -m 755 $(PROG) $(BINDIR)/
	sed -i -e 's|^VM_BHYVE_LIB_DEFAULT=.*|VM_BHYVE_LIB_DEFAULT="$(RUNTIME_LIBDIR)"|' \
		$(BINDIR)/$(PROG)
	$(INSTALL) -d -m 755 $(LIBDIR)
	$(INSTALL) -m 644 lib/* $(LIBDIR)/
	$(INSTALL) -d -m 755 $(EXAMPLESDIR)
	$(INSTALL) -m 644 sample-templates/* $(EXAMPLESDIR)/
	$(INSTALL) -d -m 755 $(MANDIR)
	gzip -9 -c $(MAN) > $(MANDIR)/$(MAN).gz
	chmod 644 $(MANDIR)/$(MAN).gz
	ln -sf $(MAN).gz $(MANDIR)/vm-bhyve.8.gz

install-systemd:
	$(INSTALL) -d -m 755 $(UNITDIR)
	$(INSTALL) -m 644 systemd/vm-network.service $(UNITDIR)/
	$(INSTALL) -m 644 systemd/vm.service $(UNITDIR)/
	sed -i -e 's|/usr/local/sbin/vm|$(PREFIX)/sbin/vm|g' \
		$(UNITDIR)/vm-network.service $(UNITDIR)/vm.service
	@echo "now run: systemctl daemon-reload && systemctl enable vm.service"

# only installed if it isn't there yet - never clobber a live config
install-config:
	$(INSTALL) -d -m 755 $(CONFDIR)
	@if [ -e "$(CONFDIR)/vm-bhyve.conf" ]; then \
		echo "$(CONFDIR)/vm-bhyve.conf exists, leaving it alone"; \
	else \
		$(INSTALL) -m 644 vm-bhyve.conf.sample $(CONFDIR)/vm-bhyve.conf && \
		echo "installed $(CONFDIR)/vm-bhyve.conf - set vm_dir in it"; \
	fi

# create the datastore directory layout:  make vmdir VMDIR=/var/lib/vm-bhyve
# (do NOT call this variable PATH - make imports PATH from the environment,
# so the "is it empty" test can never fire and the recipe would run against
# your search path)
vmdir:
	@if [ -z "$(VMDIR)" ]; then \
		echo "Usage: make vmdir VMDIR=/path/to/datastore"; \
		exit 1; \
	fi
	$(INSTALL) -d -m 755 "$(VMDIR)/.templates" "$(VMDIR)/.iso" \
		"$(VMDIR)/.img" "$(VMDIR)/.config"
	cp sample-templates/* "$(VMDIR)/.templates/"

clean:
	@:
