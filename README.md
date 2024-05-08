# The photoprism port for FreeBSD

The port will compile and install
[photoprism](https://github.com/photoprism/photoprism) from source on FreeBSD.

## Dependencies

This port depends on science/libtensorflow1
* [freshports](https://www.freshports.org/science/libtensorflow1/)
* [Git repo](https://github.com/psa/libtensorflow1-freebsd-port)

You can install it by freebsd ports or build a private copy using poudriere.

## If you need pre-built binaries you can use this repo

AVX2 is required for your CPU.

https://github.com/Gaojianli/photoprism-freebsd-port/releases

## Install using ports

### Download and Install
```
git clone https://github.com/huo-ju/photoprism-freebsd-port
cd photoprism-freebsd-port
make && make install
```

### Poudriere

If you are using poudriere to build the port, you will need to set the
following in `poudriere.conf`:
* `ALLOW_NETWORKING_PACKAGES="photoprism"` as the `dep-js` target downloads
  node packages.
* `TMPFS_LIMIT` or `MFSSIZE` should be at least `6` as the build is very large.
* `MAX_MEMORY=16` or more is required for node

## Add entries to rc.conf

```
photoprism_enable="YES"
photoprism_assetspath="/var/db/photoprism/assets"
photoprism_storagepath="/var/db/photoprism/storage"
```

## Set an initial admin password (fresh install)

```
photoprism --assets-path=/var/db/photoprism/assets --storage-path=/var/db/photoprism/storage --originals-path=/var/db/photoprism/storage/originals --import-path=/var/db/photoprism/storage/import passwd
```

## Run the service

```
service photoprism start
```

## Go to http://your_server_IP_address:2342/ in your browser
