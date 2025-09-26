# Loop device


## Steps


```sh linenums="1" title="snippet.sh" 

# create backing file
dd if=/dev/zero of=exp1.img bs=1MB count=16

# convert file to ext4-fs
mkfs.ext4 exp1.img

# create loop device
sudo losetup --find --show exp1.img

# create folder to mount loop-device
mkdir exp-fs

# mount loop-device on exp-fs
sudo mount /dev/loop<NUM> exp-fs

# list files
ls exp-fs

```


## Refer
- <https://www.man7.org/linux/man-pages/man4/loop.4.html>