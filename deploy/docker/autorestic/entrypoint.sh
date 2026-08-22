#!/bin/sh
# Generates the autorestic config from AR_* environment variables on every
# start (or writes AR_CONFIG as-is when provided and valid), then runs the
# requested AR_COMMAND (backup or restore).
set -eu

# Empty AUTORESTIC_* vars would be passed through to restic as empty
# strings, shadowing real credentials and autorestic's random-key fallback
for var in $(export | sed -n 's/^export \(AUTORESTIC_[A-Z0-9_]*\)=.*/\1/p'); do
	eval "value=\${$var}"
	[ -z "$value" ] && unset "$var" || true
done

config_file=/etc/autorestic/.autorestic.yml

if [ -n "${AR_CONFIG:-}" ] && printf '%s\n' "$AR_CONFIG" > "$config_file" && autorestic -c "$config_file" info >/dev/null 2>&1; then
	echo "Using AR_CONFIG as $config_file"
else
	if [ -n "${AR_CONFIG:-}" ]; then
		echo "WARNING: AR_CONFIG failed 'autorestic info', generating the config from variables instead" >&2
	fi
	# AR_BACKUP_VOLUMES / AR_BACKUP_PATHS are newline-separated; strip blank
	# lines and whitespace-only entries, then bail out when nothing remains
	AR_BACKUP_VOLUMES=$(printf '%s\n' "${AR_BACKUP_VOLUMES:-}" | sed '/^[[:space:]]*$/d' | tr -d '\r')
	AR_BACKUP_PATHS=$(printf '%s\n' "${AR_BACKUP_PATHS:-}" | sed '/^[[:space:]]*$/d' | tr -d '\r')
	if [ -z "$AR_BACKUP_VOLUMES$AR_BACKUP_PATHS" ]; then
		echo "No backup sources (AR_BACKUP_VOLUMES and AR_BACKUP_PATHS are empty), nothing to do"
		exit 0
	fi
	emit_location() {
		# $1 = location key, $2 = from, $3 = type (volume|path)
		echo "  \"$1\":"
		echo "    from: $2"
		echo "    type: $3"
		echo "    to:"
		echo "      - main"
		# doco-cd scheduled jobs take precedence over autorestic cron
		if [ "${AR_CRON:-false}" = true ] && [ "${DOCOCD_JOB_ENABLED:-true}" != true ]; then
			echo "    cron: ${AR_CRON_EXPR:-0 4 * * *}"
		fi
		echo "    forget: $AR_FORGET_OPTIONS"
		echo "    options:"
		echo "      backup:"
		# AR_EXCLUDE is newline-separated; skip blank entries; patterns are
		# quoted as double-quoted YAML scalars (backslash/quote escaped)
		if [ -n "${AR_EXCLUDE:-}" ]; then
			echo "        exclude:"
			printf '%s\n' "$AR_EXCLUDE" | tr -d '\r' | while IFS= read -r pattern; do
				case $pattern in *[![:space:]]*)
					escaped=$(printf '%s' "$pattern" | sed 's/\\/\\\\/g; s/"/\\"/g')
					echo "          - \"$escaped\""
					;;
				esac
			done
		fi
		echo "        exclude-file: ${AR_EXCLUDE_FILE:-.gitignore}"
		if [ -n "${AR_TAGS:-}" ]; then
			echo "        tag:"
			# AR_TAGS is comma-separated; skip blank entries
			printf '%s\n' "$AR_TAGS" | tr ',' '\n' | while IFS= read -r tag; do
				case $tag in *[![:space:]]*) echo "          - $tag" ;; esac
			done
		fi
		echo "      forget:"
		# Options are a flag map, e.g. "--keep-daily 7" becomes "keep-daily: 7"
		printf '%s\n' $AR_FORGET_OPTIONS | awk '
			{ tokens[++n] = $1 }
			END {
				for (i = 1; i <= n; i++) {
					flag = substr(tokens[i], 3)
					if (i < n && substr(tokens[i + 1], 1, 1) != "-")
						print "        " flag ": " tokens[++i]
					else
						print "        " flag ": true"
				}
			}
		'
		# Copy every snapshot from "main" to "replica" after a successful backup
		if [ -n "${AR_REPLICA_TYPE:-}" ]; then
			echo "    copy:"
			echo "      main:"
			echo "        - replica"
		fi
	}
	{
		echo "version: 2"
		echo "backends:"
		echo "  main:"
		echo "    type: $AR_MAIN_TYPE"
		echo "    path: $AR_MAIN_PATH"
		if [ -n "${AR_REPLICA_TYPE:-}" ]; then
			echo "  replica:"
			echo "    type: $AR_REPLICA_TYPE"
			echo "    path: $AR_REPLICA_PATH"
		fi
		echo "locations:"
		# One location per volume: volume-type locations only use the first "from" entry
		[ -n "$AR_BACKUP_VOLUMES" ] && printf '%s\n' "$AR_BACKUP_VOLUMES" | while IFS= read -r volume; do
			emit_location "$volume" "$volume" volume
		done
		# Path-type ("local") locations run restic in this container directly
		# and resolve "from" relative to the config file, so absolute paths only;
		# they must be mounted into it by the including compose
		[ -n "$AR_BACKUP_PATHS" ] && printf '%s\n' "$AR_BACKUP_PATHS" | while IFS= read -r path; do
			emit_location "$path" "$path" local
		done
	} > "$config_file"
fi
# Clear a stale lock left by a killed previous run; the lock file lives in
# this container only, so it cannot belong to another instance
autorestic -c "$config_file" unlock --force
case ${AR_COMMAND:-backup} in
	cron)
		# Long-running loop calling `autorestic cron`, which decides per
		# location whether the schedule is due (state in the lock file)
		while :; do
			autorestic -c "$config_file" --ci cron || true
			sleep "${AR_CRON_INTERVAL:-5m}"
		done
		;;
	backup)
		autorestic -c "$config_file" check -a
		autorestic -c "$config_file" backup -a
		;;
	restore)
		# restore has no -a and requires -l, so iterate the location keys
		# in the config (block-style keys only); volume-type locations
		# ignore --to and always restore into the volume itself
		snapshot=${AR_RESTORE_SNAPSHOT:-latest}
		for location in $(awk '
			/^locations:/ { in_locations = 1; next }
			in_locations && /^[^ ]/ { in_locations = 0 }
			in_locations && /^  [^ #]/ {
				sub(/^  /, ""); sub(/:.*$/, ""); gsub(/["'"'"']/, ""); print
			}
		' "$config_file"); do
			autorestic -c "$config_file" restore -l "$location" "$snapshot"
		done
		;;
	*)
		echo "ERROR: unknown AR_COMMAND '$AR_COMMAND' (expected backup or restore)" >&2
		exit 1
		;;
esac
