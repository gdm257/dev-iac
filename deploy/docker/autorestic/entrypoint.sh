#!/bin/sh
# Generates the autorestic config from AR_* environment variables on every
# start (or writes AR_CONFIG as-is when provided and valid), then runs the
# requested AR_COMMAND (backup or restore).
set -eu

config_file=/etc/autorestic/.autorestic.yml
mkdir -p "$(dirname "$config_file")"

# The local backend repository lives under AR_BACKEND_MOUNT, which is bound
# into this container at the same path, so autorestic can mount it into its
# per-volume backup containers through the docker socket.
if [ "$AR_BACKEND_TYPE" = local ] && [ -z "${AR_BACKEND_PATH:-}" ]; then
	AR_BACKEND_PATH=$AR_BACKEND_MOUNT
fi

if [ -n "${AR_CONFIG:-}" ] && printf '%s\n' "$AR_CONFIG" > "$config_file" && autorestic -c "$config_file" info >/dev/null 2>&1; then
	echo "Using AR_CONFIG as $config_file"
else
	if [ -n "${AR_CONFIG:-}" ]; then
		echo "WARNING: AR_CONFIG failed 'autorestic info', generating the config from variables instead" >&2
	fi
	{
		echo "version: 2"
		echo "backends:"
		echo "  main:"
		echo "    type: $AR_BACKEND_TYPE"
		echo "    path: $AR_BACKEND_PATH"
		if [ -n "${AR_OFFSITE_TYPE:-}" ]; then
			echo "  offsite:"
			echo "    type: $AR_OFFSITE_TYPE"
			echo "    path: $AR_OFFSITE_PATH"
		fi
		echo "locations:"
		# One location per volume: volume-type locations only use the first "from" entry
		for volume in $AR_BACKUP_VOLUMES; do
			echo "  \"$volume\":"
			echo "    from: $volume"
			echo "    type: volume"
			echo "    to:"
			echo "      - main"
			echo "    forget: $AR_FORGET"
			echo "    options:"
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
			# Copy every snapshot from "main" to "offsite" after a successful backup
			if [ -n "${AR_OFFSITE_TYPE:-}" ]; then
				echo "    copy:"
				echo "      main:"
				echo "        - offsite"
			fi
		done
	} > "$config_file"
fi
# Clear a stale lock left by a killed previous run; the lock file lives in
# this container only, so it cannot belong to another instance
autorestic -c "$config_file" unlock --force
case ${AR_COMMAND:-backup} in
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
