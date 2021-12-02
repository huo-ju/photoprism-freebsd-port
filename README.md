# The photoprism port for FreeBSD

The port will compile and install [libtensorflow](https://www.tensorflow.org/install/lang_c) 1.15.2 and build [photoprism](https://github.com/photoprism/photoprism) from source on FreeBSD.

## If you need pre-built binaries you can use this repo

https://github.com/psa/photoprism-freebsd-port/releases

## Install using ports

### Download and Install
```
git clone https://github.com/huo-ju/photoprism-freebsd-port
cd photoprism-freebsd-port
make config
make && make install
```
or 

Upgrade and skip the tensorflow building

```
make FLAVOR=notf && make FLAVOR=notf install
```

### Poudriere

If you are using poudriere to build the port, you will need to set the
following in `poudriere.conf`:
* `ALLOW_NETWORKING_PACKAGES="photoprism"` as the `dep-js`
  target calls `npm audit fix`.
* `TMPFS_LIMIT` or `MFSSIZE` should be at least `6` as the build is very large.
* `MAX_MEMORY=8` or more is required for bazel

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
