#!/bin/bash
[[ ! -d Source ]] && { echo "You're probably in the wrong folder. Execute this command from the root of the repository"; exit 1; }
export REMOTE=origin
[[ ! -z "$1" ]] && REMOTE=$1

{
  git fetch $REMOTE

} &> /dev/null
[[ $? -ne 0 ]] && { echo "An error happened while trying to get latest tags. There is probably not a remote called '$REMOTE'"; exit 1; }
export PACKAGEDIR=$PWD/Packages
export PACKAGE_MAJOR_VERSION=$(git tag --sort=-version:refname | head -1 | sed 's/\([0-9]*\).*$/\1/g')
export PACKAGEVERSION=$PACKAGE_MAJOR_VERSION.1000.0
export TARGETROOT=~/.nuget/packages

if [ ! -d "$PACKAGEDIR" ]; then
    mkdir $PACKAGEDIR
fi

rm $PACKAGEDIR/*
dotnet pack -p:PackageVersion=$PACKAGEVERSION --include-symbols --include-source -o $PACKAGEDIR

for f in $PACKAGEDIR/*.symbols.nupkg; do
  mv ${f} ${f/.symbols/}
done

for f in $PACKAGEDIR/*.nupkg; do
    echo ""
    packagename=$(basename ${f%.$PACKAGE_MAJOR_VERSION.1000.0.nupkg})
    target=$TARGETROOT/$packagename/$PACKAGEVERSION
    # Delete outdated .nupkg 
    find $TARGETROOT/$packagename -name $PACKAGEVERSION -exec rm -rf {} \;

    mkdir -pv $target && cp -v $f $target
    # Unzip package
    tar -xzf $target/$(basename $f) -C $target
    # Create an empty .sha512 file, or else it won't recognize the package for some reason
    touch $target/$(basename $f).sha512
done
