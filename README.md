# QBck.sh

Simple script for creating compressed backups to local drive synchronized with
Google Cloud Platform storage.

## Usage

### QBCK_GCP_PREFIX
`$QBCK_GCP_PREFIX` must be set to Google Cloud Platform bucket prefix used by rclone.
It can be `<RCLONE-REMOTE>:<bucket-name>[/subpath]`.

### Backup file

```bash
sh qbck.sh compress <DIR> <OUTPUT_DIR> [NAME]
sh qbck.sh compress devel/ /Volumes/WD/Backup 2022-08-11_devel
```

### Sync
```bash
sh qbck.sh sync /Volumes/WD\ -\ 5TB/Backup
```
