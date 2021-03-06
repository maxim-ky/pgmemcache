short_ver = 2.1.1
long_ver = $(shell git describe --long 2>/dev/null || echo $(short_ver)-0-unknown)

MODULE_big = pgmemcache
OBJS = pgmemcache.o

EXTENSION = pgmemcache
DATA_built = pgmemcache--$(short_ver).sql pgmemcache.control
DATA =	ext/pgmemcache--unpackaged--2.0.sql \
	ext/pgmemcache--2.0--2.1.sql \
	ext/pgmemcache--2.1--2.1.1.sql

SHLIB_LINK = -lmemcached -lsasl2

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

pgmemcache.control: ext/pgmemcache.control
	sed -e 's,__short_ver__,$(short_ver),g' < $^ > $@

pgmemcache--$(short_ver).sql: ext/pgmemcache.sql
	cp -fp $^ $@

# Build a release tarball. To make a release, adjust the
# version number in the README, and add an entry to NEWS.
html:
	rst2html.py README README.html

dist:
	git archive --output=../pgmemcache_$(long_ver).tar.gz --prefix=pgmemcache/ HEAD .

deb%:
	cp debian/changelog.in debian/changelog
	dch -v $(long_ver) "Automatically built package"
	sed -e s/PGVER/$(subst deb,,$@)/g < debian/packages.in > debian/packages
	yada rebuild
	debuild -uc -us -b

rpm:
	git archive --output=pgmemcache-rpm-src.tar.gz --prefix=pgmemcache/ HEAD
	rpmbuild -ta pgmemcache-rpm-src.tar.gz \
		--define 'full_version $(long_ver)' \
		--define 'major_version $(short_ver)' \
		--define 'minor_version $(subst -,.,$(subst $(short_ver)-,,$(long_ver)))'
	$(RM) pgmemcache-rpm-src.tar.gz

build-dep:
	apt-get install libmemcached-dev postgresql-server-dev libpq-dev devscripts yada flex bison libsasl2-dev
