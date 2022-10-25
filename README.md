# lenc
my bootleg gpg/pgp alternative in zig

`format.txt` contains the encrypted file format

idk what to put here so msg me on discord at `lenny#5884` if u have any ideas

# building
```
$ git clone https://github.com/idkso/lenc.git --recursive
$ cd lenc
$ zig build -Drelease-fast=true
$ # or if you want to ensure safety in exchange for performance
$ zig build -Drelease-safe=true
```

# usage
```
$ ./zig-out/bin/enc -h
    -h, --help
            Display this help and exit

    -g, --generate
            Generate the keypair

    -e, --encrypt <str>
            Encrypt the specified file

    -d, --decrypt <str>
            Decrypt the specified file

    -o, --output <str>
            Set output file

    -p, --pubkey <str>
            Set the public key file to encrypt to

    -s, --seckey <str>
            Set the secret key file to encrypt with

    -c, --chunksize <str>
            Set the chunk size (must have 2x the chunk size of free ram)
```

# examples
generating keypair
```
$ ./zig-out/bin/enc -g
info: wrote secret key to key.sec
info: wrote public key to key.pub
```
encrypting a file
```
$ ./zig-out/bin/enc -e build.zig -o build.zig.lenc -p target.pub -s mykey.sec -c 75kb
```
decrypting a file
```
$ ./zig-out/bin/enc -d build.zig.lenc -p target.pub -s mykey.sec
```
# TODO
- dedicated folder in `$HOME` or `$HOME/.config` for keys
- password protected secret keys
- compression
- pubkey regeneration
- multi-recipient support
