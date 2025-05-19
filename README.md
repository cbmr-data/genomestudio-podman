# GenomeStudio Container

This repository contains a Podman container for running Illumina's Genome Studio
2.0 on a headless server using wine and XRDP. It may also work with Docker, but
will probably require tweaks.

## Overview

Due to the difficulty of installing Windows components and Genome Studio during
the container build process, the container instead provides scripts for
installing these components in a mostly automated fashion.

## Prerequisites

* A copy of the [GenomeStudioInstaller.exe](https://emea.support.illumina.com/downloads/genomestudio-2-0.html) placed in `./installers`
* Podman (tested on 4.9.3 and 4.9.4)
* An XRDP client such as xfreerdp3
* make

## Usage

### Building

1. Run `make save` to save docker image to `build/`
2. Copy image to server
3. Import image on server using `podman load -i ${FILENAME}`
4. Make copy of `scripts/wrapper.py` modified to use the resulting docker image, by updating the `IMAGE` and `VERSION` variables.

### Running

The wrapper-script at `scripts/wrapper.py` is intended to help run the container images; this script takes care of mounting required folders and (optionally) projects, datasets, more.

Briefly, use the `--project` option to list projects to mount, the `--dataset` option to mount datasets, `--sdir` and `--ndir` to mount network drives, and `--hdir` to mount `H:`. All of these options, except for `--hdir`, take either the name of a project/dataset/folder or the path to that folder.

The following two commands are therefore equivalent:

```console
--project phenomics-AUDIT
--project /projects/phenomics-AUDIT
```

Note that you must authenticate to access network drives (`H:`, `N:`, and `S:`). This is accomplished by running `kinit` and entering your password *before* running the wrapper script or attempting to browse those folders. If you access the folders first, and possibly get an error, then you may have to wait a few minutes after authenticating with `kinit` before the drives are accessible.

Note that a random RDP password is generated/printed every time the container is started. This password is required to connect to the server using, for example, [freerdp](https://www.freerdp.com/):

```console
$ python3.11 scripts/wrapper.py
Password is 'b54773ca-2f1c-11f0-86f0-5f2b2e38cfd8'
xrdp-sesman[21]: [INFO ] starting xrdp-sesman with pid 21

xrdp-sesman[21]: [INFO ] Sesman now listening on /run/xrdp/sockdir/sesman.socket

xrdp[23]: [INFO ] address [0.0.0.0] port [3389] mode 1

xrdp[23]: [INFO ] listening to port 3389 on 0.0.0.0

xrdp[23]: [INFO ] xrdp_listen_pp done
```

## Connecting

1. Setup port forwarding to esrumcont01fl, e.g. at port 3389:

   ```console
   ssh -S none -N -L '3389:esrumcont01fl:3389' esrum
   ```

2. Connect with remote desktop program

   ```console
   sudo apt install freerdp3-x11
   xfreerdp3  /size:1680x970 /v:localhost:3389 /u:ubuntu /p:${PASSWORD}
   ```

The password is printed in the container output as shown above. If the container
was started in the background, use `podman logs` to view the terminal output.
