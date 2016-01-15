# From zero to Samza

To run this image on your workstation / laptop you 'just' need to provide a running docker engine.

## MacOSX

### homebrew

If you are nerdy enough to use homebrew just fire up (I've already installed it - obviously):
```
$ brew install docker docker-compose docker-machine
Warning: docker-1.9.1 already installed
Warning: docker-compose-1.5.2 already installed
Error: docker-machine-0.5.1 already installed
To install this version, first `brew unlink docker-machine`
83 10:10:02 rc=0 wrex1 QNIBIncBlog (master) $
```

### Docker Toolbox

Docker Inc. provides a toolbox that comes with all the components you need: https://www.docker.com/docker-toolbox


# Create a machine

**Note**: If you use a Linux machine and your docker-engine is running localhost, you can skip this step.

`docker-machine` provides a nice mechanism to create a virtual machine (most likely VirtualBox), put the right image in there, create certificates and prepare you bash environment to get started.

```
$ docker-machine create -d virtualbox samza
Running pre-create checks...
Creating machine...
(samza) OUT | Creating VirtualBox VM...
(samza) OUT | Creating SSH key...
(samza) OUT | Starting VirtualBox VM...
(samza) OUT | Starting VM...
Waiting for machine to be running, this may take a few minutes...
Machine is running, waiting for SSH to be available...
Detecting operating system of created instance...
Detecting the provisioner...
Provisioning created instance...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
To see how to connect Docker to this machine, run: docker-machine env samza
$ 
```

The VM is ready to go, change your environemnt and off you go.
```
$ eval $(docker-machine env samza)
$ docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
$
```

# Pull and start the image

```
$ docker pull qnib/u-samza
Using default tag: latest
latest: Pulling from qnib/u-samza
*snip*
Status: Downloaded newer image for qnib/u-samza:latest
$
```

With that please switch back to the README.md...
