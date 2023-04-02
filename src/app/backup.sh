#!/bin/sh


# shellcheck disable=SC1091

. /opt/scripts/logging.sh
. /opt/scripts/set-env.sh
: "${warning_counter:=0}"
: "${error_counter:=0}"

### Functions ###

# Initialize variables
init() {
  if [ "$TIMESTAMP" = true ]; then
    TIMESTAMP_PREFIX="$(date "+%F-%H%M%S")_"
  fi

  BACKUP_FILE_DB=$BACKUP_DIR/${TIMESTAMP_PREFIX}kuma.db
  BACKUP_FILE_DATA=$BACKUP_DIR/${TIMESTAMP_PREFIX}uptime-kuma.sql.gz

    if [ ! -f "$APP_DATABASE_URL" ]; then
      printf 1 > "$HEALTHCHECK_FILE"
      critical "Database $APP_DATABASE_URL not found! Please check if you mounted the Uptime-kuma volume (in docker-compose or with '--volumes-from=utime-kuma-data'!)" >> "$LOGFILE_APP"
  fi
}

# Backup the database
backup_database() {

  if /usr/bin/sqlite3 "$APP_DATABASE_URL" ".dump" |gzip -c > "$BACKUP_FILE_DATA"; then 
    info "Backup of the database to $BACKUP_FILE_DB was successfull" >> "$LOGFILE_APP"
  else
    error "Backup of the database failed" >> "$LOGFILE_APP"
  fi
}

# Backup additional data like attachments, sends, etc.
backup_additional_data() {
  if [ "$BACKUP_ADD_ATTACHMENTS" = true ] && [ -e "$APP_ATTACHMENTS_FOLDER" ]; then set -- "$APP_ATTACHMENTS_FOLDER"; fi
  if [ "$BACKUP_ADD_ICON_CACHE" = true ] && [ -e "$APP_ICON_CACHE_FOLDER" ]; then set -- "$@" "$APP_ICON_CACHE_FOLDER"; fi
  if [ "$BACKUP_ADD_SENDS" = true ] && [ -e "$APP_DATA_FOLDER/sends" ]; then set -- "$@" "$APP_DATA_FOLDER/sends"; fi
  if [ "$BACKUP_ADD_CONFIG_JSON" = true ] && [ -e "$APP_DATA_FOLDER/config.json" ]; then set -- "$@" "$APP_DATA_FOLDER/config.json"; fi
  if [ "$BACKUP_ADD_RSA_KEY" = true ]; then
    rsa_keys="$(find "$APP_DATA_FOLDER" -iname 'rsa_key*')"
    debug "found RSA keys $rsa_keys" >> "$LOGFILE_APP"
    for rsa_key in $rsa_keys; do
      set -- "$@" "$rsa_key"
    done
  fi

  debug "\$@ is: $*" >> "$LOGFILE_APP"
  loop_ctr=0
  for i in "$@"; do
    if [ "$loop_ctr" -eq 0 ]; then debug "Clear \$@ on first loop" >> "$LOGFILE_APP"; set --; fi

    # Prevent the "leading slash" warning from tar command
    if [ "$(dirname "$i")" = "$APP_DATA_FOLDER" ]; then
      debug "dirname of $i matches $APP_DATA_FOLDER. This means we can scrap it." >> "$LOGFILE_APP"
      set -- "$@" "$(basename "$i")"
    fi

    loop_ctr=$((loop_ctr+1))
  done

  debug "Backing up: $*" >> "$LOGFILE_APP"

  # Run the backup command for additional data folders
  # We need to use the "cd" here instead of "tar -C ..." because of the wildcard for RSA keys.
  #"$(cd "$APP_DATA_FOLDER" && bin/tar -czf "$BACKUP_FILE_DATA" "$@")"
  if /bin/tar -czf "$BACKUP_FILE_DATA" -C "$APP_DATA_FOLDER" "$@"; then
    info "Backup of additional data folders to $BACKUP_FILE_DATA was successfull" >> "$LOGFILE_APP"
  else
    error "Backup of additional data folders failed" >> "$LOGFILE_APP"
  fi
}

# Performs a healthcheck
perform_healthcheck() {
  debug "\$error_counter=$error_counter" >> "$LOGFILE_APP"

  if [ "$error_counter" -ne 0 ]; then
    warn "There were $error_counter errors during backup. Not sending health check ping." >> "$LOGFILE_APP"
    printf 1 > "$HEALTHCHECK_FILE"
    return 1
  fi

  # At this point the container is healthy. So we create a health-check file used to determine container health
  # and send a health check ping if the HEALTHCHECK_URL is set.
  printf 0 > "$HEALTHCHECK_FILE"
  debug "Evaluating \$HEALTHCHECK_URL" >> "$LOGFILE_APP"
  if [ -z "$HEALTHCHECK_URL" ]; then
    debug "Variable \$HEALTHCHECK_URL not set. Skipping health check." >> "$LOGFILE_APP"
    return 0
  fi
  
  info "Sending health check ping." >> "$LOGFILE_APP"
  wget "$HEALTHCHECK_URL" -T 10 -t 5 -q -O /dev/null
}

backup_send() {
    rclone copy $BACKUP_DIR/ ${BACKUP_SEND_DEST_PATH}/ -vL 2>&1 >> "$LOGFILE_APP"
}


cleanup() {
  if [ -n "$DELETE_AFTER" ] && [ "$DELETE_AFTER" -gt 0 ]; then
    if [ "$TIMESTAMP" != true ]; then warn "DELETE_AFTER will most likely have no effect because TIMESTAMP is not set to true." >> "$LOGFILE_APP"; fi
    find "$BACKUP_DIR" -type f -mtime +"$DELETE_AFTER" -exec sh -c '. /opt/scripts/logging.sh; file="$1"; rm -f "$file"; info "Deleted backup "$file" after $DELETE_AFTER days"' shell {} \;  >> "$LOGFILE_APP"
  fi
}

### Main ###

# Run init
init

# Dump Env if INFO or DEBUG
[ "$LOG_LEVEL_NUMBER" -ge 6 ] && (set > "${LOG_DIR}/env.txt")

mkdir ${BACKUP_DIR} 2>>/dev/null

# Run the backup command for the database file
if [ "$BACKUP_ADD_DATABASE" = true ]; then
  backup_database
fi

# Run the backup command for additional data folders
if [ "$BACKUP_ADD_ATTACHMENTS" = true ] \
    || [ "$BACKUP_ADD_CONFIG_JSON" = true ] \
    || [ "$BACKUP_ADD_ICON_CACHE" = true ] \
    || [ "$BACKUP_ADD_RSA_KEY" = true ] \
    || [ "$BACKUP_ADD_SENDS" = true ]; then
  backup_additional_data
fi

# Perform healthcheck
perform_healthcheck

if [ "$BACKUP_SEND" = true ]; then
  if [ "$BACKUP_SEND_DEST_PATH" != "" ]; then 
  backup_send
  else
    error "Backup send: [BACKUP_SEND_DEST_PATH] is null" >> "$LOGFILE_APP"
  fi
fi

# Delete backup files after $DELETE_AFTER days.
cleanup
