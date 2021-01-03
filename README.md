# The photoprism port for FreeBSD 

The port will compile and install [libtensorflow](https://www.tensorflow.org/install/lang_c) 1.15.2 and build [photoprism](https://github.com/photoprism/photoprism) from source on FreeBSD.

## Install using ports

# Download and Install
```
git clone https://github.com/huo-ju/photoprism-freebsd-port
cd photoprism-freebsd-port
make config
make && make install
```


# Add entries to rc.conf

```
photoprism_enable="YES"
photoprism_assetspath="/var/photoprism/assets"
photoprism_storagepath="/var/photoprism/storage"
```

# Run the service

```
service photoprism start
```

# Go to http://your_server_IP_address:2342/ in your browser
