#!/usr/bin/env bash

install_yarn() {
  local dir="$1"
  local version=${2:-1.x}
  local platform="$3"
  local number url code

  echo "Resolving yarn version $version..."
  if ! read -r number url < <(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=$version" "https://nodebin.herokai.com/v1/yarn/$platform/latest.txt"); then
    fail_bin_install yarn "$version" "$platform";
  fi

  echo "Downloading and installing yarn ($number)..."
  code=$(curl "$url" -L --silent --fail --retry 5 --retry-max-time 15 -o /tmp/yarn.tar.gz --write-out "%{http_code}")
  if [ "$code" != "200" ]; then
    echo "Unable to download yarn: $code" && false
  fi
  rm -rf "$dir"
  mkdir -p "$dir"
  # https://github.com/yarnpkg/yarn/issues/770
  if tar --version | grep -q 'gnu'; then
    tar xzf /tmp/yarn.tar.gz -C "$dir" --strip 1 --warning=no-unknown-keyword
  else
    tar xzf /tmp/yarn.tar.gz -C "$dir" --strip 1
  fi
  chmod +x "$dir"/bin/*
  echo "Installed yarn $(yarn --version)"
}

install_nodejs() {
  local version=${1:-10.x}
  local dir="${2:?}"
  local platform="$3"
  local code os cpu

  os=$(get_os)
  cpu=$(get_cpu)

  echo "Resolving node version $version..."
  if ! read -r number url < <(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=$version" "https://nodebin.herokai.com/v1/node/$platform/latest.txt"); then
    fail_bin_install node "$version" "$platform";
  fi

  echo "Downloading and installing node $number..."
  code=$(curl "$url" -L --silent --fail --retry 5 --retry-max-time 15 -o /tmp/node.tar.gz --write-out "%{http_code}")
  if [ "$code" != "200" ]; then
    echo "Unable to download node: $code" && false
  fi
  tar xzf /tmp/node.tar.gz -C /tmp
  rm -rf "${dir:?}"/*
  mv /tmp/node-v"$number"-"$os"-"$cpu"/* "$dir"
  chmod +x "$dir"/bin/*
}

install_iojs() {
  local version="$1"
  local dir="$2"
  local platform="$3"
  local code os cpu

  os=$(get_os)
  cpu=$(get_cpu)

  echo "Resolving iojs version ${version:-(latest stable)}..."
  if ! read -r number url < <(curl --silent --get --retry 5 --retry-max-time 15 --data-urlencode "range=$version" "https://nodebin.herokai.com/v1/iojs/$platform/latest.txt"); then
    fail_bin_install iojs "$version" "$platform";
  fi

  echo "Downloading and installing iojs $number..."
  code=$(curl "$url" --silent --fail --retry 5 --retry-max-time 15 -o /tmp/iojs.tar.gz --write-out "%{http_code}")
  if [ "$code" != "200" ]; then
    echo "Unable to download iojs: $code" && false
  fi
  tar xzf /tmp/iojs.tar.gz -C /tmp
  mv /tmp/iojs-v"$number"-"$os"-"$cpu"/* "$dir"
  chmod +x "$dir"/bin/*
}

install_npm() {
  local npm_version
  local version="$1"
  local dir="$2"
  local npm_lock="$3"
  npm_version="$(npm --version)"

  # If the user has not specified a version of npm, but has an npm lockfile
  # upgrade them to npm 5.x if a suitable version was not installed with Node
  if $npm_lock && [ "$version" == "" ] && [ "${npm_version:0:1}" -lt "5" ]; then
    echo "Detected package-lock.json: defaulting npm to version 5.x.x"
    version="5.x.x"
  fi

  if [ "$version" == "" ]; then
    echo "Using default npm version: $npm_version"
  elif [[ "$npm_version" == "$version" ]]; then
    echo "npm $npm_version already installed with node"
  else
    echo "Bootstrapping npm $version (replacing $npm_version)..."
    if ! npm install --unsafe-perm --quiet -g "npm@$version" 2>@1>/dev/null; then
      echo "Unable to install npm $version; does it exist?" && false
    fi
    echo "npm $version installed"
  fi
}


