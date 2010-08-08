# Node Version Manager
# Implemented as a bash function
# To use source this file from your bash profile
#
# Implemented by Tim Caswell <tim@creationix.com>
# with much bash help from Matthew Ranney
#
# Improved by Donald Luo <donaldluo@gmail.com>

nvm()
{
  START=`pwd`
  if [ $# -lt 1 ]; then
    nvm help
    return
  fi
  case $1 in
    "help" )
      echo
      echo "Node Version Manager"
      echo
      echo "Usage:"
      echo "    nvm help              (Show this message)"
      echo "    nvm install version   (Download and install a released version)"
      echo "    nvm clone             (Install the HEAD version)"
      echo "    nvm update            (Update the HEAD with the latest from the repo)"
      echo "    nvm list              (Show all installed versions)"
      echo "    nvm list -a           (Show all available versions)"
      echo "    nvm use version       (Set this version in the PATH)"
      echo "    nvm use               (Use the latest stable version or HEAD if none)"
      echo "    nvm deactivate        (Remove nvm entry from PATH)"
      echo "    nvm addlib            (Copies the module in cwd to the current env)"
      echo "    nvm linklib           (Links the module in cwd to the current env)"
      echo "    nvm listlibs          (Show the modules in the current env)"
      echo "    nvm uninstall version (Remove a version (incl. HEAD)"
      echo
      echo "Example:"
      echo "    nvm install v0.1.94"
      echo
    ;;
    "install" )
      if [[ $# -ne 2 ]]; then
        nvm help
        return;
      fi
      mkdir -p "$NVM_DIR/src" && \
      cd "$NVM_DIR/src" && \
      wget "http://nodejs.org/dist/node-$2.tar.gz" -N && \
      tar -xzf "node-$2.tar.gz" && \
      cd "node-$2" && \
      ./configure --prefix="$NVM_DIR/$2" && \
      make && \
      make install && \
      cd $START
      nvm use $2
    ;;
    "clone" )
      mkdir -p "$NVM_DIR/src" && \
      cd "$NVM_DIR/src" && \
      git clone "git://github.com/ry/node.git" "HEAD" && \
      cd "HEAD" && \
      ./configure --prefix="$NVM_DIR/HEAD" && \
      make && \
      make install && \
      nvm use HEAD
      cd $START
    ;;
    "update" )
      if [[ -d "$NVM_DIR/src/HEAD" ]]; then
        cd "$NVM_DIR/src/HEAD" && \
        git pull && \
        ./configure --prefix="$NVM_DIR/HEAD" && \
        make && \
        make install && \
        nvm use HEAD
      else
        echo "HEAD version is not installed yet"
      fi
      cd $START
    ;;
    "uninstall" )
      if [[ $# -ne 2 ]]; then
        nvm help
        return;
      fi
      if [[ "$2" == "HEAD" ]]; then
        rm -rf "$NVM_DIR/src/$2" > /dev/null
        rm -rf "$NVM_DIR/HEAD" > /dev/null
      else
        rm -rf "$NVM_DIR/src/node-$2" > /dev/null
        rm -f  "$NVM_DIR/src/node-$2.tar.gz" > /dev/null
        rm -rf "$NVM_DIR/$2" > /dev/null
      fi
      cd $START
      nvm use
    ;;
    "deactivate" )
      if [[ $PATH == *$NVM_DIR/*/bin* ]]; then
        export PATH=${PATH%$NVM_DIR/*/bin*}${PATH#*$NVM_DIR/*/bin:}
        echo "$NVM_DIR/*/bin removed from \$PATH"
      else
        echo "Could not find $NVM_DIR/*/bin in \$PATH"
      fi
      unset NVM_PATH
      unset NVM_DIR
      unset NVM_BIN
      echo "Unset NVM_PATH, NVM_BIN, and NVM_DIR."
    ;;
    "addlib" )
      mkdir -p $NVM_PATH
      mkdir -p $NVM_BIN
      if [ -d `pwd`/lib ]; then
        cp -r `pwd`/lib/ "$NVM_PATH/"
        cp -r `pwd`/bin/ "$NVM_BIN/"
      else
        echo "Can't find lib dir at `pwd`/lib"
      fi
    ;;
    "linklib" )
      mkdir -p $NVM_PATH
      mkdir -p $NVM_BIN
      if [ -d `pwd`/lib ]; then
        ln -sf `pwd`/lib/* "$NVM_PATH/"
        ln -sf `pwd`/bin/* "$NVM_BIN/"
      else
        echo "Can't find lib dir at `pwd`/lib"
      fi
    ;;
    "use" )
      if [[ $# -ne 2 ]]; then
        for f in $NVM_DIR/HEAD $NVM_DIR/v*; do
          nvm use ${f##*/} > /dev/null
        done
        return;
      fi
      if [ ! -d $NVM_DIR/$2 ]; then
        echo "$2 version is not installed yet"
        return;
      fi
      if [[ $PATH == *$NVM_DIR/*/bin* ]]; then
        PATH=${PATH%$NVM_DIR/*/bin*}$NVM_DIR/$2/bin${PATH#*$NVM_DIR/*/bin}
      else
        PATH="$NVM_DIR/$2/bin:$PATH"
      fi
      export PATH
      export NVM_PATH="$NVM_DIR/$2/lib/node"
      export NVM_BIN="$NVM_DIR/$2/bin"
      echo "Now using node $2"
    ;;
    "listlibs" )
      ls $NVM_PATH | grep -v wafadmin
    ;;
    "list" )
      if [[ $# -ne 1 && $# -ne 2 ]]; then
        nvm help
        return;
      fi
      if [[ -d $NVM_DIR/HEAD ]]; then
        if [[ $PATH == *$NVM_DIR/HEAD/bin* ]]; then
          echo "HEAD *"
        else
          echo "HEAD"
        fi
      fi
      INSTALLED=$(ls $NVM_DIR | grep -E 'v[0-9]+\.[0-9]+\.[0-9]+')
      if [[ "$2" != "-a" ]]; then
		for i in $INSTALLED; do
		  if [[ $PATH == *$i/bin* ]]; then
		    echo "v${i##*v} I *"
		  else
		    echo "v${i##*v} I"
		  fi
		 done
      else
        ALL_VERSIONS=$(curl -sS 'http://nodejs.org/dist/' | sed -n -r 's/^<a href="(node-(v[0-9]+\.[0-9]+\.[0-9]+).tar.gz)">\1<\/a>.*$/\2/p')
        for v in $ALL_VERSIONS; do
          FOUND=0
          for i in $INSTALLED; do
            if [[ ${v##*v} == ${i##*v} ]]; then
              FOUND=1
              if [[ $PATH == *$v/bin* ]]; then
                echo "v${v##*v} I *"
              else
                echo "v${v##*v} I"
              fi
              break
            fi
          done
          if [[ $FOUND -eq 0 ]]; then
            echo "v${v##*v}"
          fi
        done
      fi
    ;;
    * )
      nvm help
    ;;
  esac
}
