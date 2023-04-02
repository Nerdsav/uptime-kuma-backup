#!/bin/sh

# shellcheck disable=SC1091

export LOG_LEVEL="${LOG_LEVEL:-INFO}"
. /opt/scripts/logging.sh
: "${warning_counter:=0}"
: "${error_counter:=0}"

# Functions
check_deprecations() {
  # Warning for deprecated settings
  if [ -n "$BACKUP_FILE" ]; then
    warn "\$BACKUP_FILE is deprecated and will be removed in future versions. Please use \$BACKUP_DIR instead to specify the folder of the backup."
    if [ -z "$BACKUP_DIR" ]; then
      BACKUP_DIR=$(dirname "$BACKUP_FILE");
      warn "Since \$BACKUP_DIR is not set defaulting to BACKUP_DIR=$BACKUP_DIR"
    fi
  fi

  # Warning for deprecated settings
  if [ -n "$BACKUP_FILE_PERMISSIONS" ]; then
    warn "\$BACKUP_FILE_PERMISSIONS is deprecated and will be removed in future versions. Please use \$BACKUP_DIR_PERMISSIONS instead to specify the permissions of the backup folder."
    if [ -z "$BACKUP_DIR_PERMISSIONS" ]; then
      BACKUP_DIR_PERMISSIONS="$BACKUP_FILE_PERMISSIONS";
      warn "Since \$BACKUP_DIR_PERMISSIONS is not set defaulting to BACKUP_DIR_PERMISSIONS=$BACKUP_FILE_PERMISSIONS"
    fi
  fi

  # Warning for deprecated settings
  if [ -n "$DB_FILE" ]; then
    warn "\$DB_FILE is deprecated and will be removed in future versions. Please use \$APP_DATABASE_URL instead to specify the location of the source database file."
    if [ -z "$APP_DATABASE_URL" ]; then
      APP_DATABASE_URL="$DB_FILE";
      warn "Since \$APP_DATABASE_URL is not set defaulting to APP_DATABASE_URL=$DB_FILE"
    fi
  fi

  # Warning for deprecated settings
  if [ -n "$ATTACHMENT_DIR" ]; then
    warn "\$ATTACHMENT_DIR is deprecated and will be removed in future versions. Please use \$APP_ATTACHMENTS_FOLDER instead to specify the location of the source attachments folder."
    if [ -z "$APP_ATTACHMENTS_FOLDER" ]; then
      APP_ATTACHMENTS_FOLDER="$ATTACHMENT_DIR";
      warn "Since \$APP_ATTACHMENTS_FOLDER is not set defaulting to APP_ATTACHMENTS_FOLDER=$ATTACHMENT_DIR"
    fi
  fi

  # Warning for deprecated settings
  if [ -n "$LOGFILE" ]; then
    warn "\$LOGFILE is deprecated and will be removed in future versions. Please use \$LOG_DIR instead to specify the location of the logfile folder."
    if [ -z "$LOG_DIR" ]; then
      LOG_DIR="$(dirname "$(realpath "$LOGFILE")")";
      warn "Since \$LOG_DIR is not set defaulting to LOG_DIR=$LOG_DIR"
    fi
  fi

  # Warning for deprecated settings
  if [ -n "$ATTACHMENT_BACKUP_DIR" ]; then
    warn "\$ATTACHMENT_BACKUP_DIR is deprecated and will be removed in future versions. Attachment backups are stored in the \$BACKUP_DIR."
  fi

  # Warning for deprecated settings
  if [ -n "$ATTACHMENT_BACKUP_FILE" ]; then
    warn "\$ATTACHMENT_BACKUP_FILE is deprecated and will be removed in future versions. Attachment backups are stored in the \$BACKUP_DIR."
  fi
}

check_deprecations

# Set default environment variables
# Environment variables specific to this image
export APP_DIR="${APP_DIR:-/app}"
export APP_DIR_PERMISSIONS="${APP_DIR_PERMISSIONS:-700}"
export BACKUP_DIR="${BACKUP_DIR:-/backup}"
export BACKUP_DIR_PERMISSIONS="${BACKUP_DIR_PERMISSIONS:-700}"
export CRON_TIME="${CRON_TIME:-0 5 * * *}"
export TIMESTAMP="${TIMESTAMP:-false}"
export UID="${UID:-100}"
export GID="${GID:-100}"
export CRONFILE="${CRONFILE:-/etc/crontabs/root}"
export LOG_DIR="${LOG_DIR:-$APP_DIR/log}"
export LOG_DIR_PERMISSIONS="${LOG_DIR_PERMISSIONS:-777}"
export LOGFILE_APP="${LOGFILE_APP:-$LOG_DIR/app.log}"
export LOGFILE_CRON="${LOGFILE_CRON:-$LOG_DIR/cron.log}"
export DELETE_AFTER="${DELETE_AFTER:-0}"
export APP_BACKUP_VERSION="1.0"
export HEALTHCHECK_FILE="${HEALTHCHECK_FILE:-$APP_DIR/health}"
export HEALTHCHECK_FILE_PERMISSIONS="${HEALTHCHECK_FILE_PERMISSIONS:-700}"


# Additional backup files
export BACKUP_ADD_DATABASE="${BACKUP_ADD_DATABASE:-true}"
export BACKUP_ADD_ATTACHMENTS="${BACKUP_ADD_ATTACHMENTS:-true}"
export BACKUP_ADD_CONFIG_JSON="${BACKUP_ADD_CONFIG_JSON:-true}"
export BACKUP_ADD_ICON_CACHE="${BACKUP_ADD_ICON_CACHE:-false}"
export BACKUP_ADD_RSA_KEY="${BACKUP_ADD_RSA_KEY:-true}"
export BACKUP_ADD_SENDS="${BACKUP_ADD_SENDS:-false}"

export APP_DATA_FOLDER="${APP_DATA_FOLDER:-/data}"
export APP_DATABASE_URL="${APP_DATABASE_URL:-$APP_DATA_FOLDER/db.sqlite3}"
export APP_ATTACHMENTS_FOLDER="${APP_ATTACHMENTS_FOLDER:-$APP_DATA_FOLDER/attachments}"
export APP_ICON_CACHE_FOLDER="${APP_ICON_CACHE_FOLDER:-$APP_DATA_FOLDER/icon_cache}"

export BACKUP_SEND="${BACKUP_SEND:-false}"
