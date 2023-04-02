# Uptime-kuma Backup&Send 

Uptime-Kuma service - https://github.com/louislam/uptime-kuma

### Automatic Backups 
A cron daemon is running inside the container and the container keeps running in background.

After complete backup start Rclone and send backup-file(s) to S3 storage

docker-compose for rclone :
```
    volumes:
      - /root/.config/rclone/rclone.conf:/root/.config/rclone/rclone.conf
    environment:
      - BACKUP_SEND=true
      - BACKUP_SEND_DEST_PATH='storj-s3:/backup/uptime'
```
- BACKUP_SEND = true/false (falsee as default value) - Send after backup to S3
- BACKUP_SEND_DEST_PATH - Path to S3 for rclone format (S3-name:/<backet name>/<path>)

Start backup container with default settings (automatic backup at 5 am)
```sh
docker run -d --restart=always --name uk-backup --volumes-from=uptime-kuma-vol nerdsav/uptime-kuma-backup
```

Example for hourly backups
```sh
docker run -d --restart=always --name uk-backup --volumes-from=uptime-kuma-vol -e CRON_TIME="0 * * * *" nerdsav/uptime-kuma-backup
```

Example for backups that delete after 30 days
```sh
docker run -d --restart=always --name vaultwarden --volumes-from=uptime-kuma-vol -e TIMESTAMP=true -e DELETE_AFTER=30 nerdsav/uptime-kuma-backup
```

### Manual Backups
You can use the crontab of your host to schedule the backup and the container will only be running during the backup process.

```sh
docker run --rm --volumes-from=uptime-kuma-vol nerdsav/uptime-kuma-backup manual
```

If you want the backed up file to be stored outside the container you have to mount
a directory by adding `-v <PATH_ON_YOUR_HOST>:<PATH_INSIDE_CONTAINER>`. The complete command could look like this

```sh
docker run --rm --volumes-from=uptime-kuma-vol -e UID=0 -e BACKUP_DIR=/myBackup -e TIMESTAMP=true -v $(pwd)/myBackup:/myBackup nerdsav/uptime-kuma-backup manual
```

Keep in mind that the commands will be executed *inside* the container. So `$BACKUP_DIR` can be any place inside the container. Easiest would be to set it to `/data/backup` which will create the backup next to the original database file.

### Restore

There is no automated restore process to prevent accidential data loss. So if you need to restore a backup you need to do this manually by following the steps below (assuming your backups are located at `./backup/` and your uptime-kuma data ist located at `/var/lib/docker/volumes/uptime-kuma/_data/`)

```sh
# Delete any existing sqlite3 files
rm /var/lib/docker/volumes/uptime-kuma/_data/db.sqlite3*

# Extract the archive
gunzip ./backup/[TIMESTAMP]_name.sql.gz -C /var/lib/docker/volumes/uptime-kuma/_data/

#restore 
Please read https://www.ibiblio.org/elemental/howto/sqlite-backup.html

```

## Environment variables
| ENV                          | Description                                                                         |
| ---------------------------- | ----------------------------------------------------------------------------------- |
| APP_DIR                      | App dir inside the container (should not be changed)                                |
| APP_DIR_PERMISSIONS          | Permissions of app dir inside container (should not be changed)                     |
| BACKUP_ADD_DATABASE [^3]     | Set to `true` to include the database itself in the backup                          |
| BACKUP_ADD_ATTACHMENTS [^3]  | Set to `true` to include the attachments folder in the backup                       |
| BACKUP_ADD_CONFIG_JSON [^3]  | Set to `true` to include `config.json` in the backup                                |
| BACKUP_ADD_ICON_CACHE [^3]   | Set to `true` to include the icon cache folder in the backup                        |
| BACKUP_ADD_RSA_KEY [^3]      | Set to `true` to include the RSA keys in the backup                                 |
| BACKUP_ADD_SENDS [^3]        | Set to `true` to include the sends folder in the backup                             |
| BACKUP_DIR                   | Seths the path of the backup folder *inside* the container                          |
| BACKUP_DIR_PERMISSIONS       | Sets the permissions of the backup folder (**CAUTION** [^1]). Set to -1 to disable. |
| CRONFILE                     | Path to the cron file *inside* the container                                        |
| CRON_TIME                    | Cronjob format "Minute Hour Day_of_month Month_of_year Day_of_week Year"            |
| DELETE_AFTER                 | Delete old backups after X many days. Set to 0 to disable                           |
| TIMESTAMP                    | Set to `true` to append timestamp to the backup file                                |
| GID                          | Group ID to run the cron job with                                                   |
| HEALTHCHECK_URL              | Set a healthcheck url like <https://hc-ping.com/xyz>                                |
| HEALTHCHECK_FILE             | Set the path of the local healtcheck (container health) file                        |
| HEALTHCHECK_FILE_PERMISSIONS | Set the permissions of the local healtcheck (container health) file                 |
| LOG_LEVEL                    | DEBUG, INFO, WARNING, ERROR, CRITICAL are supported                                 |
| LOG_DIR                      | Path to the logfile folder *inside* the container                                   |
| LOG_DIR_PERMISSIONS          | Set the permissions of the logfile folder. Set to -1 to disable.                    |
| TZ                           | Set the timezone inside the container [^2]                                          |
| UID                          | User ID to run the cron job with                                                    |
| VW_DATA_FOLDER [^4]          | Set the location of the uptime-kuma data folder *inside* the container              |
| VW_DATABASE_URL [^4]         | Set the location of the uptime-kuma database file *inside* the container            |
| VW_ATTACHMENTS_FOLDER [^4]   | Set the location of the uptime-kuma attachments folder *inside* the container       |
| VW_ICON_CACHE_FOLDER [^4]    | Set the location of the uptime-kuma icon cache folder *inside* the container        |

For default values see [src/opt/scripts/set-env.sh](src/opt/scripts/set-env.sh)

