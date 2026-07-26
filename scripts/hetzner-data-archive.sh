#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  hetzner-data-archive.sh backup <source-directory> <archive.tgz>
  hetzner-data-archive.sh quarantine <destination-directory>
  hetzner-data-archive.sh restore <archive.tgz> <destination-directory>

The backup command creates <archive.tgz> and <archive.tgz>.sha256.
The quarantine command moves application-created destination content into a
private .restore-quarantine.* directory on the same filesystem.
The restore command verifies that sidecar before extracting into an empty
destination directory or a fresh Hetzner volume containing only the bootstrap
.formatted marker, an empty lost+found directory, and one quarantine directory.
USAGE
  exit 64
}

sha256_file() {
  local file_path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -- "${file_path}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -- "${file_path}" | awk '{print $1}'
  else
    echo "sha256sum or shasum is required." >&2
    return 1
  fi
}

validate_archive_members() {
  local archive_path="$1"

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to validate archive contents." >&2
    return 1
  fi

  python3 - "${archive_path}" <<'PY'
import pathlib
import sys
import tarfile


def fail(message: str) -> None:
    print(f"Unsafe archive member: {message}", file=sys.stderr)
    raise SystemExit(1)


def normalized_parts(path: pathlib.PurePosixPath) -> list[str]:
    parts: list[str] = []
    for part in path.parts:
        if part in ("", "."):
            continue
        if part == "..":
            if not parts:
                fail(str(path))
            parts.pop()
            continue
        parts.append(part)
    return parts


archive = pathlib.Path(sys.argv[1])
with tarfile.open(archive, mode="r:gz") as bundle:
    for member in bundle.getmembers():
        member_path = pathlib.PurePosixPath(member.name)
        if member_path.is_absolute() or ".." in member_path.parts:
            fail(member.name)
        member_parts = normalized_parts(member_path)
        if member_parts and member_parts[0].startswith(".restore-quarantine."):
            fail(f"{member.name} uses the reserved restore-quarantine namespace")

        if member.issym() or member.islnk():
            fail(f"{member.name} has unsupported link type")
        if member.isdev() or member.isfifo():
            fail(f"{member.name} has unsupported special-file type")
PY
}

restore_destination_is_ready() {
  local destination_directory="$1"
  local entry
  local entry_name
  local quarantine_count=0

  for entry in \
    "${destination_directory}"/.[!.]* \
    "${destination_directory}"/..?* \
    "${destination_directory}"/*; do
    if [[ ! -e "${entry}" && ! -L "${entry}" ]]; then
      continue
    fi
    entry_name="$(basename "${entry}")"
    case "${entry_name}" in
      .formatted)
        if [[ -L "${entry}" || ! -f "${entry}" || -s "${entry}" ]]; then
          return 1
        fi
        ;;
      lost+found)
        if [[ -L "${entry}" || ! -d "${entry}" ]] ||
          [[ -n "$(find "${entry}" -mindepth 1 -print -quit)" ]]; then
          return 1
        fi
        ;;
      .restore-quarantine.*)
        if [[ -L "${entry}" || ! -d "${entry}" ]]; then
          return 1
        fi
        quarantine_count=$((quarantine_count + 1))
        if [[ "${quarantine_count}" -gt 1 ]]; then
          return 1
        fi
        ;;
      *)
        return 1
        ;;
    esac
  done
}

quarantine_existing_data() {
  local destination_directory="$1"
  local quarantine_directory=""
  local entry
  local entry_name
  local moved_any=false

  if [[ -L "${destination_directory}" || ! -d "${destination_directory}" ]]; then
    echo "Quarantine destination is not a directory: ${destination_directory}" >&2
    return 1
  fi

  for entry in \
    "${destination_directory}"/.[!.]* \
    "${destination_directory}"/..?* \
    "${destination_directory}"/*; do
    if [[ ! -e "${entry}" && ! -L "${entry}" ]]; then
      continue
    fi
    entry_name="$(basename "${entry}")"
    case "${entry_name}" in
      .formatted | lost+found)
        continue
        ;;
      .restore-quarantine.*)
        echo "A restore quarantine already exists: ${entry}" >&2
        return 1
        ;;
    esac

    if [[ -z "${quarantine_directory}" ]]; then
      umask 077
      quarantine_directory="$(mktemp -d "${destination_directory}/.restore-quarantine.XXXXXX")"
    fi
    mv -- "${entry}" "${quarantine_directory}/"
    moved_any=true
  done

  if [[ "${moved_any}" == true ]]; then
    printf 'Quarantined existing data in %s\n' "${quarantine_directory}"
  else
    printf 'No application-created data required quarantine in %s\n' "${destination_directory}"
  fi
}

backup_data() {
  local source_directory="$1"
  local archive_path="$2"
  local archive_parent
  local archive_absolute
  local checksum_path
  local source_absolute
  local checksum
  local completed=false
  local archive_published=false
  local checksum_published=false
  local temporary_archive=""
  local temporary_checksum=""

  if [[ ! -d "${source_directory}" ]]; then
    echo "Backup source is not a directory: ${source_directory}" >&2
    return 1
  fi
  if [[ -e "${archive_path}" || -L "${archive_path}" ||
    -e "${archive_path}.sha256" || -L "${archive_path}.sha256" ]]; then
    echo "Refusing to overwrite an existing archive or checksum: ${archive_path}" >&2
    return 1
  fi

  source_absolute="$(cd "${source_directory}" && pwd -P)"
  archive_parent="$(cd "$(dirname "${archive_path}")" && pwd -P)"
  archive_absolute="${archive_parent}/$(basename "${archive_path}")"
  checksum_path="${archive_absolute}.sha256"

  case "${archive_absolute}" in
    "${source_absolute}" | "${source_absolute}"/*)
      echo "Archive must be outside the source directory." >&2
      return 1
      ;;
  esac

  cleanup_partial_backup() {
    if [[ "${completed}" != true ]]; then
      if [[ "${checksum_published}" == true ]]; then
        rm -f -- "${checksum_path}"
      fi
      if [[ "${archive_published}" == true ]]; then
        rm -f -- "${archive_absolute}"
      fi
    fi
    if [[ -n "${temporary_archive}" ]]; then
      rm -f -- "${temporary_archive}"
    fi
    if [[ -n "${temporary_checksum}" ]]; then
      rm -f -- "${temporary_checksum}"
    fi
  }
  trap cleanup_partial_backup EXIT

  umask 077
  temporary_archive="$(mktemp "${archive_parent}/.$(basename "${archive_absolute}").tmp.XXXXXX")"
  temporary_checksum="$(mktemp "${archive_parent}/.$(basename "${checksum_path}").tmp.XXXXXX")"
  tar -C "${source_absolute}" \
    --exclude='./.restore-quarantine.*' \
    -czf "${temporary_archive}" .
  validate_archive_members "${temporary_archive}"
  checksum="$(sha256_file "${temporary_archive}")"
  printf '%s  %s\n' "${checksum}" "$(basename "${archive_absolute}")" >"${temporary_checksum}"

  if ! ln -- "${temporary_archive}" "${archive_absolute}"; then
    echo "Refusing to overwrite an archive created concurrently: ${archive_absolute}" >&2
    return 1
  fi
  archive_published=true
  if ! ln -- "${temporary_checksum}" "${checksum_path}"; then
    echo "Refusing to overwrite a checksum created concurrently: ${checksum_path}" >&2
    return 1
  fi
  checksum_published=true

  completed=true
  cleanup_partial_backup
  trap - EXIT
  printf 'Created %s and %s\n' "${archive_absolute}" "${checksum_path}"
}

restore_data() {
  local archive_path="$1"
  local destination_directory="$2"
  local checksum_path="${archive_path}.sha256"
  local expected_checksum
  local actual_checksum

  if [[ -L "${archive_path}" || ! -f "${archive_path}" ]]; then
    echo "Archive does not exist: ${archive_path}" >&2
    return 1
  fi
  if [[ -L "${checksum_path}" || ! -f "${checksum_path}" ]]; then
    echo "Checksum sidecar does not exist: ${checksum_path}" >&2
    return 1
  fi
  if [[ -L "${destination_directory}" || ! -d "${destination_directory}" ]]; then
    echo "Restore destination is not a directory: ${destination_directory}" >&2
    return 1
  fi
  if ! restore_destination_is_ready "${destination_directory}"; then
    echo "Restore destination must be empty or contain only a fresh Hetzner bootstrap marker: ${destination_directory}" >&2
    return 1
  fi

  expected_checksum="$(awk 'NR == 1 {print $1}' "${checksum_path}")"
  if [[ ! "${expected_checksum}" =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "Checksum sidecar is invalid: ${checksum_path}" >&2
    return 1
  fi
  actual_checksum="$(sha256_file "${archive_path}")"
  if [[ "${actual_checksum}" != "${expected_checksum}" ]]; then
    echo "Archive checksum verification failed: ${archive_path}" >&2
    return 1
  fi

  validate_archive_members "${archive_path}"
  tar -C "${destination_directory}" -xzf "${archive_path}"
  printf 'Restored %s into %s\n' "${archive_path}" "${destination_directory}"
}

command_name="${1:-}"
case "${command_name}" in
  backup)
    if [[ "$#" -ne 3 ]]; then
      usage
    fi
    backup_data "$2" "$3"
    ;;
  quarantine)
    if [[ "$#" -ne 2 ]]; then
      usage
    fi
    quarantine_existing_data "$2"
    ;;
  restore)
    if [[ "$#" -ne 3 ]]; then
      usage
    fi
    restore_data "$2" "$3"
    ;;
  *)
    usage
    ;;
esac
