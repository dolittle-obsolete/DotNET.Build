#!/bin/bash
[[ ! -d Source ]] && { echo "You're probably in the wrong folder. Execute this command from the root of the repository"; exit 1; }

if [ ! -z "$1" ]; then
  VERSION=$1.0.0
else
  {
    git fetch origin

  } &> /dev/null
  [[ $? -ne 0 ]] && { echo "An error happened while trying to get latest tags. There is probably not a remote called '$REMOTE'"; exit 1; }
  VERSION=$(git tag --sort=-version:refname | head -1) 
fi

MAJOR_VERSION=$(echo $VERSION | sed 's/\([0-9]*\).*$/\1/g')
MINOR_VERSION=$(echo $VERSION | sed 's/[0-9]*.\([0-9]*\).*$/\1/g')
PATCH_VERSION=$(echo $VERSION | sed 's/[0-9]*.[0-9]*.\([0-9]*\).*$/\1/g')
PRE_RELEASE_TAG=$(echo $VERSION | sed 's/[0-9]*.[0.9]*.[0-9]-\([a-zA-Z]*\).*$/\1/g')

if [ -n "$PRE_RELEASE_TAG" ]; then
    PACKAGE_VERSION=$MAJOR_VERSION.$MINOR_VERSION.$PATCH_VERSION-$PRE_RELEASE_TAG.1000
else
    PACKAGE_VERSION=$MAJOR_VERSION.1000.0
fi

echo "Git Version : " $VERSION 
echo "Package Version : " $PACKAGE_VERSION

PACKAGEDIR=$PWD/Packages
TARGETROOT=~/.nuget/packages

if [ ! -d "$PACKAGEDIR" ]; then
    mkdir $PACKAGEDIR
fi

rm $PACKAGEDIR/*
dotnet pack -p:PackageVersion=$PACKAGE_VERSION -o $PACKAGEDIR

for f in $PACKAGEDIR/*.symbols.nupkg; do
  mv ${f} ${f/.symbols/}
done

for f in $PACKAGEDIR/*.nupkg; do
    echo ""
    packagename=$(basename ${f%.$PACKAGE_VERSION.nupkg})
    packagename=$(echo "$packagename" | tr [A-Z] [a-z])
    target=$TARGETROOT/$packagename/$PACKAGE_VERSION
    # Delete outdated .nupkg 
    find $TARGETROOT/$packagename -name $PACKAGE_VERSION -exec rm -rf {} \;

    mkdir -pv $target && cp -v $f $target
    # Unzip package
    unzip -qq $target/$(basename $f) -d $target 


    # Create an empty .sha512 file, or else it won't recognize the package for some reason
    touch $target/$(basename $f).sha512

    pushd $TARGETROOT/$packagename
    find . -maxdepth 2 -type f | while read path; do

      dir="$(dirname $path)"
      file="$(basename $path)"
      low_path=$(echo "$path" | tr [A-Z] [a-z])
      low_file=$(echo "$file" | tr [A-Z] [a-z])
      if [ ! "$path" = "$low_path" ]; then
          mv "$path" "$dir/$low_file"
      fi
    done
    find . | while read path; do
      chmod 755 "$path"
    done
    popd

done
