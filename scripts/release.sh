#!/bin/bash
#
# Script for replacing the version number
# in main.go, committing and tagging the code

readonly prgdir=$(cd $(dirname $0); pwd)
readonly basedir=$(cd $prgdir/..; pwd)
readonly COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
readonly BUILD_DATE=$(date +%FT%T%z)

v=$1

[[ -n "$v" ]] || read -p "Enter version: " v
if [[ -z "$v" ]]; then
	echo "Usage: $0 <version>"
	exit 1
fi

echo "Building binary..."
CGO_ENABLED=0 GOOS=linux go build -ldflags "-X main.Branch=${COMMIT_HASH} -X main.BuildDate=${BUILD_DATE} -X main.Version=${v}" -o bin/landinginfo ./landinginfo.go

#grep -q "$v" README.md || echo "README.md not updated"
grep -q "$v" CHANGELOG.md || echo "CHANGELOG.md not updated"

read -p "Release version $v? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	exit 1
fi

#sed -i '' -e "s|^var version .*$|var version = \"$v\"|" $basedir/main.go
#git add $basedir/main.go
#git commit -S -m "Release v$v"
#git commit -S --amend
$prgdir/release-docker.sh ${v}

echo "Syncing git repo state"
git tag -l | xargs git tag -d && git fetch -t

echo "Creating tag $v"
git tag v$v -m "Tag v${v}" && git push --tags
