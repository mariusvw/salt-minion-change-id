# salt-minion-change-id

A simple script to rename a minion and wait for it to return.

## Usage

```
./minion-change-id.sh <old_id> <new_id>
```

## Verify checksums

### Linux
```
diff <(cat minion-change-id.sh.md5) <(md5 minion-change-id.sh) && echo 'OK'
cat minion-change-id.sh.sha1 | sha1sum -c -
cat minion-change-id.sh.sha256 | sha256sum -c -
```

### BSD / MacOS
```
diff <(cat minion-change-id.sh.md5) <(md5 minion-change-id.sh) && echo 'OK'
cat minion-change-id.sh.sha1 | shasum -a 1 -c -
cat minion-change-id.sh.sha256 | shasum -a 256 -c -
```

## Calculate checksums

### Linux
```
md5 minion-change-id.sh > minion-change-id.sh.md5
sha1sum minion-change-id.sh > minion-change-id.sh.sha1
sha256sum minion-change-id.sh > minion-change-id.sh.sha256
```

### BSD / MacOS
```
md5 minion-change-id.sh > minion-change-id.sh.md5
shasum -a 1 minion-change-id.sh > minion-change-id.sh.sha1
shasum -a 256 minion-change-id.sh > minion-change-id.sh.sha256
```

## TODO
- Cleanup :)
- Tests
