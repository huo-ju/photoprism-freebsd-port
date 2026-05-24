# The photoprism port for FreeBSD

The port will compile and install
[photoprism](https://github.com/photoprism/photoprism) from source on FreeBSD.

## Dependencies

This port depends on science/py-tensorflow (**2.13.1**)

### Download and Install
```
git clone [...]/photoprism-freebsd-port
cd photoprism-freebsd-port
make && make install
```

### Upgrade from an old version
```
cd photoprism-freebsd-port
git pull
make reinstall clean
```

### Poudriere

`ALLOW_NETWORKING_PACKAGES="photoprism"` is needed in `/usr/local/etc/poudriere.conf` so build it in poudriere.

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
