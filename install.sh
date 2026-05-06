#!/usr/bin/env sh
set -eu

repo="${XR_REPO:-hvpaiva/xr}"
branch="${XR_BRANCH:-main}"
repo_url="${XR_REPO_URL:-https://github.com/$repo.git}"
repo_url_explicit=0
install_dir="${XR_INSTALL_DIR:-$HOME/.local/share/xr}"
bin_dir="${XR_BIN_DIR:-$HOME/.local/bin}"
bin_path="$bin_dir/xr"
install_exercism="${XR_INSTALL_EXERCISM:-auto}"
exercism_version="${XR_EXERCISM_VERSION:-latest}"
tmp_dir=""

if [ "${XR_REPO_URL+x}" = "x" ]; then
  repo_url_explicit=1
fi

usage() {
  cat <<'USAGE'
xr installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/hvpaiva/xr/main/install.sh | sh
  curl -fsSL https://raw.githubusercontent.com/hvpaiva/xr/main/install.sh | sh -s -- --no-exercism

Options:
  --repo-url <url>          Git clone URL for xr
  --branch <name>          Git branch to install (default: main)
  --install-dir <path>     Install checkout path (default: ~/.local/share/xr)
  --bin-dir <path>         Symlink/bin path (default: ~/.local/bin)
  --with-exercism          Install or update the Exercism CLI
  --no-exercism            Do not install the Exercism CLI
  --exercism-version <v>   Exercism CLI version, for example 3.5.8 or v3.5.8
  -h, --help               Show this help

Environment:
  XR_REPO                  GitHub repo slug (default: hvpaiva/xr)
  XR_REPO_URL              Full Git clone URL
  XR_BRANCH                Git branch (default: main)
  XR_INSTALL_DIR           Install checkout path
  XR_BIN_DIR               Symlink/bin path
  XR_INSTALL_EXERCISM      auto, always, or never (default: auto)
  XR_EXERCISM_VERSION      latest or a specific version (default: latest)
USAGE
}

say() {
  printf '%s\n' "xr install: $*"
}

warn() {
  printf '%s\n' "xr install: warning: $*" >&2
}

die() {
  printf '%s\n' "xr install: $*" >&2
  exit 1
}

cleanup() {
  if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
    rm -rf "$tmp_dir"
  fi
}

trap cleanup EXIT HUP INT TERM

need() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --repo-url)
        shift
        [ "$#" -gt 0 ] || die "missing value for --repo-url"
        repo_url="$1"
        repo_url_explicit=1
        ;;
      --branch)
        shift
        [ "$#" -gt 0 ] || die "missing value for --branch"
        branch="$1"
        ;;
      --install-dir)
        shift
        [ "$#" -gt 0 ] || die "missing value for --install-dir"
        install_dir="$1"
        ;;
      --bin-dir)
        shift
        [ "$#" -gt 0 ] || die "missing value for --bin-dir"
        bin_dir="$1"
        ;;
      --with-exercism|--install-exercism)
        install_exercism="always"
        ;;
      --no-exercism)
        install_exercism="never"
        ;;
      --exercism-version)
        shift
        [ "$#" -gt 0 ] || die "missing value for --exercism-version"
        exercism_version="$1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1"
        ;;
    esac
    shift
  done

  bin_path="$bin_dir/xr"
}

safe_install_dir() {
  case "$install_dir" in
    ""|"/"|"$HOME") die "refusing unsafe install directory: $install_dir" ;;
  esac
}

safe_overwrite_dir() {
  safe_install_dir
  case "$install_dir" in
    */xr) ;;
    *) die "refusing to overwrite non-xr directory: $install_dir" ;;
  esac
}

download_file() {
  url="$1"
  target="$2"

  if command -v curl >/dev/null 2>&1; then
    curl --proto '=https' --tlsv1.2 -fsSL "$url" -o "$target"
  elif command -v wget >/dev/null 2>&1; then
    wget -q -O "$target" "$url"
  else
    die "missing required command: curl or wget"
  fi
}

detect_exercism_os() {
  case "$(uname -s)" in
    Darwin) printf '%s\n' "darwin" ;;
    Linux) printf '%s\n' "linux" ;;
    FreeBSD) printf '%s\n' "freebsd" ;;
    OpenBSD) printf '%s\n' "openbsd" ;;
    *) die "unsupported OS for automatic Exercism install: $(uname -s)" ;;
  esac
}

detect_exercism_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf '%s\n' "x86_64" ;;
    arm64|aarch64) printf '%s\n' "arm64" ;;
    i386|i686) printf '%s\n' "i386" ;;
    armv5*) printf '%s\n' "armv5" ;;
    armv6*|armv7*) printf '%s\n' "armv6" ;;
    ppc64*) printf '%s\n' "ppc64" ;;
    *) die "unsupported architecture for automatic Exercism install: $(uname -m)" ;;
  esac
}

latest_exercism_tag() {
  need sed

  release_json="$tmp_dir/exercism-release.json"
  download_file "https://api.github.com/repos/exercism/cli/releases/latest" "$release_json"
  tag="$(sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$release_json" | sed -n '1p')"
  [ -n "$tag" ] || die "could not determine latest Exercism CLI version"
  printf '%s\n' "$tag"
}

requested_exercism_tag() {
  if [ "$exercism_version" = "latest" ]; then
    latest_exercism_tag
    return
  fi

  case "$exercism_version" in
    v*) printf '%s\n' "$exercism_version" ;;
    *) printf 'v%s\n' "$exercism_version" ;;
  esac
}

verify_exercism_checksum() {
  archive="$1"
  archive_path="$2"
  checksums="$tmp_dir/exercism_checksums.txt"

  download_file "https://github.com/exercism/cli/releases/download/$tag/exercism_checksums.txt" "$checksums"
  line="$(grep "$archive" "$checksums" || true)"
  [ -n "$line" ] || die "checksum not found for $archive"
  expected="${line%% *}"

  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$archive_path" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
  else
    warn "sha256sum/shasum not found; skipping Exercism checksum verification"
    return
  fi

  [ "$actual" = "$expected" ] || die "checksum mismatch for $archive"
}

install_exercism_cli() {
  need tar
  need grep
  need awk

  os="$(detect_exercism_os)"
  arch="$(detect_exercism_arch)"
  tag="$(requested_exercism_tag)"
  version="${tag#v}"
  archive="exercism-$version-$os-$arch.tar.gz"
  archive_path="$tmp_dir/$archive"
  url="https://github.com/exercism/cli/releases/download/$tag/$archive"

  say "installing Exercism CLI $tag for $os-$arch"
  download_file "$url" "$archive_path"
  verify_exercism_checksum "$archive" "$archive_path"
  tar -xzf "$archive_path" -C "$tmp_dir"
  [ -f "$tmp_dir/exercism" ] || die "downloaded archive did not contain exercism"
  chmod +x "$tmp_dir/exercism"
  mkdir -p "$bin_dir"

  if [ -L "$bin_dir/exercism" ]; then
    rm "$bin_dir/exercism"
  elif [ -e "$bin_dir/exercism" ] && [ "$install_exercism" != "always" ] && [ "${XR_INSTALL_OVERWRITE:-}" != "1" ]; then
    die "$bin_dir/exercism already exists. Use --with-exercism or set XR_INSTALL_OVERWRITE=1 to replace it."
  elif [ -d "$bin_dir/exercism" ]; then
    die "refusing to replace directory: $bin_dir/exercism"
  fi

  cp "$tmp_dir/exercism" "$bin_dir/exercism"
  say "exercism installed at $bin_dir/exercism"
}

maybe_install_exercism() {
  case "$install_exercism" in
    auto)
      if command -v exercism >/dev/null 2>&1; then
        say "exercism already installed: $(command -v exercism)"
      elif [ -e "$bin_dir/exercism" ]; then
        warn "$bin_dir/exercism exists but is not in PATH; leaving it untouched"
      else
        install_exercism_cli
      fi
      ;;
    always)
      install_exercism_cli
      ;;
    never)
      say "skipping Exercism CLI install"
      ;;
    *)
      die "invalid XR_INSTALL_EXERCISM value: $install_exercism"
      ;;
  esac
}

link_xr() {
  target="$install_dir/bin/xr"

  if [ -L "$bin_path" ]; then
    current="$(readlink "$bin_path" 2>/dev/null || true)"
    if [ "$current" = "$target" ]; then
      return
    fi
    if [ "${XR_INSTALL_OVERWRITE:-}" != "1" ]; then
      die "$bin_path already points to $current. Set XR_INSTALL_OVERWRITE=1 to replace it."
    fi
    rm "$bin_path"
  elif [ -e "$bin_path" ] && [ "${XR_INSTALL_OVERWRITE:-}" != "1" ]; then
    die "$bin_path already exists. Set XR_INSTALL_OVERWRITE=1 to replace it."
  elif [ -d "$bin_path" ]; then
    die "refusing to replace directory: $bin_path"
  elif [ -e "$bin_path" ]; then
    rm "$bin_path"
  fi

  ln -s "$target" "$bin_path"
}

install_xr() {
  need git
  need ruby
  safe_install_dir

  mkdir -p "$bin_dir"
  mkdir -p "$(dirname "$install_dir")"

  if [ -d "$install_dir/.git" ]; then
    say "updating xr in $install_dir"
    if [ "$repo_url_explicit" = "1" ]; then
      git -C "$install_dir" remote set-url origin "$repo_url"
    fi
    git -C "$install_dir" fetch origin "$branch"
    git -C "$install_dir" checkout -q "$branch"
    git -C "$install_dir" pull --ff-only origin "$branch"
  elif [ -e "$install_dir" ]; then
    if [ "${XR_INSTALL_OVERWRITE:-}" = "1" ]; then
      safe_overwrite_dir
      rm -rf "$install_dir"
    else
      die "$install_dir already exists and is not a git checkout. Set XR_INSTALL_OVERWRITE=1 to replace it."
    fi
  fi

  if [ ! -d "$install_dir/.git" ]; then
    say "cloning xr from $repo_url"
    git clone --branch "$branch" "$repo_url" "$install_dir"
  fi

  chmod +x "$install_dir/bin/xr"
  link_xr
  say "xr installed at $bin_path"
  "$bin_path" version
}

parse_args "$@"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/xr-install.XXXXXX")"
install_xr
maybe_install_exercism

case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) warn "$bin_dir is not in PATH" ;;
esac
