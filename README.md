# lenc
Bootleg gpg/pgp alternative written in zig


# Build 

```bash
git clone https://github.com/idkso/lenc
cd lenc
zig build
```

# usage
```
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

# Examples
Generating keypair
```
$ ./zig-out/bin/enc -g
info: wrote secret key to key.sec
info: wrote public key to key.pub
```
Encrypting a file
```
$ ./zig-out/bin/enc -e build.zig -o build.zig.lenc -p target.pub -s mykey.sec -c 75kb
```
Decrypting a file
```
$ ./zig-out/bin/enc -d build.zig.lenc -p target.pub -s mykey.sec
```

# Misc

`format.txt` contains the encrypted file format

Message me on discord at `lenny#5884` for any suggestions/ideas


# TODO
- Dedicated folder in `$HOME` or `$HOME/.config` for keys
- Password protected secret keys
- Compression
- Pubkey regeneration
- Multi-recipient support
