#!/bin/bash
[[ ! -d Source ]] && { echo "You're probably in the wrong folder. Execute this command from the root of the repository"; exit 1; }

if [ ! -z "$1" ]; then
  PACKAGE_MAJOR_VERSION="$1"
else
  {
    git fetch origin

  } &> /dev/null
  [[ $? -ne 0 ]] && { echo "An error happened while trying to get latest tags. There is probably not a remote called '$REMOTE'"; exit 1; }
  PACKAGE_MAJOR_VERSION=$(git tag --sort=-version:refname | head -1 | sed 's/\([0-9]*\).*$/\1/g')
fi

PACKAGEDIR=$PWD/Packages
PACKAGEVERSION=$PACKAGE_MAJOR_VERSION.1000.0
TARGETROOT=~/.nuget/packages

if [ ! -d "$PACKAGEDIR" ]; then
    mkdir $PACKAGEDIR
fi

rm $PACKAGEDIR/*
dotnet pack -p:PackageVersion=$PACKAGEVERSION -o $PACKAGEDIR

for f in $PACKAGEDIR/*.symbols.nupkg; do
  mv ${f} ${f/.symbols/}
done

for f in $PACKAGEDIR/*.nupkg; do
    echo ""
    packagename=$(basename ${f%.$PACKAGE_MAJOR_VERSION.1000.0.nupkg})
    packagename="${packagename,,}"
    target=$TARGETROOT/$packagename/$PACKAGEVERSION
    # Delete outdated .nupkg 
    find $TARGETROOT/$packagename -name $PACKAGEVERSION -exec rm -rf {} \;

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

