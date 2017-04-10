#!/bin/sh

# Ureka version
urv=1.5.2

#
dvd=false

# Never use exit in this script.  Always use iexit, because the dvd
# install is running in a terminal window that may vanish when we
# exit.  We want to give the user time to read the error message first.
iexit() {
    if $dvd
    then
        echo ''
        if [ $1 -eq 0 ]
        then
            echo 'Success'
        else
            echo 'Install Failed'
        fi
        echo ''
        echo 'Press return/enter to quit'
        read a
        exit $1
    else
        exit $1
    fi
}

# warn the user that there is not enough disk space to install Ureka and ask
# whether they'd like to continue; loop until they provide a valid response
not_enough_disk_space() {

    # if unattended, then just show the warning and exit
    if $2
    then
        echo "WARNING:"
        echo "There is not enough free space in $install_location.  Only ${1}GB"
        echo "are available.  Exiting now."
        iexit 1
    fi

    valid_answer=false
    while ! $valid_answer
    do
        echo "WARNING:"
        echo "There is not enough free space in $install_location.  Only ${1}GB"
        echo "are available.  Would you like to continue with installation"
        echo "(not recommended)?  Enter yes or no [no]: " | tr -d '\n'
        read answer

        # only accept "yes" or "no" in response to the question; "" means "no"
        case "$answer"
        in
            yes)
                valid_answer=true
                ;;
            no)
                rm -rf $install_location
                iexit 0
                ;;
            "")
                rm -rf $install_location
                iexit 0
                ;;
            *)
                ;;
        esac
    done
}

# parse arguments
u=false
s=false
l=false
n=""
t=""
i=""
while [ "$1" != "" ]
do
    case "$1"
    in
        -u)
            # non-interactive
            u=true
            ;;
        -s)
            # configure login script automatically
            s=true
            ;;
        -l)
            # don't configure login scripts or check architecture
            l=true
            ;;
        -n)
            # set installation name
            n=$2
            shift
            ;;
        -t)
            # use this tar file
            t=$2
            shift
            ;;
        
        -i)
            # installation location
            i=$2
            shift
            ;;

        --dvd)
            # special flag to use with dvd; this is not intended to
            # be used except for dvd installations
            dvd=true
            ;;

        *)
            echo "Options:"
            echo "  -u  non-interactive mode"
            echo "  -s  configure login scripts automatically"
            echo "  -l  do *not* configure login scripts or check architecture"
            echo "  -n  installation name"
            echo "  -t  Ureka tarfile"
            echo "  -i  installation location"
            iexit 1
            ;;
    esac
    shift
done


# make sure $HOME is set
if [ "$HOME" = "" ]
then
    echo 'ERROR: $HOME is not defined'
    iexit 1
fi


# if root is running this script, explain that they don't need to do that and
# ask if they want to continue
if [ "$USER" = "root" ]
then
    valid_answer=false
    while ! $valid_answer
    do
        echo "WARNING:"
        echo "You are running this script as root, which is not required or"
        echo "recommended - would you like to continue?"
        echo "Enter yes or no [yes]: " | tr -d '\n'
        read answer

        # only accept "yes" or "no" in response to the question; "" means "yes"
        case "$answer"
        in
            yes)
                valid_answer=true
                echo
                ;;
            no)
                iexit 0
                ;;
            "")
                valid_answer=true
                echo
                ;;
            *)
                echo
                ;;
        esac
    done
fi


# non-interactive defaults
if $u
then
    s=true

    # use "default" as installation name
    if [ "$n" = "" ]
    then
        n=default
    fi

    # use $cwd/Ureka as installation location
    if [ "$i" = "" ]
    then
        i=`pwd`/Ureka
    fi
fi


# create ~/.ureka if it doesn't exist
dotureka=$HOME/.ureka
if [ ! -d $dotureka ]
then
    mkdir -p $dotureka
fi


# get install location from user
if [ "$i" = "" ]
then
    i=`pwd`/Ureka
    valid_answer=false
    while ! $valid_answer
    do
        echo "About to install Ureka $urv in "
        echo "$i"
        echo "Continue? Enter yes or no [yes]: " | tr -d '\n'
        read answer

        # only accept "yes" or "no" in response to the question; "" means "yes"
        case "$answer"
        in
            yes)
                valid_answer=true
                echo
                ;;
            no)
                echo
                echo "If you want to install Ureka in a different location,"
                echo "please navigate to the appropriate directory and run the"
                echo "installer again."
                iexit 0
                ;;
            "")
                valid_answer=true
                echo
                ;;
            *)
                echo
                ;;
        esac
    done
fi


# normalize installation directory path
case "$i"
in
    /*)
        :
        ;;
    *)
        i=`pwd`/$i
        ;;
esac
install_location=$i


if $dvd
then
    # we do not check for the installation location existing when installing
    # from dvd because we know it already exists.
    :
else
    # make sure the selected installation directory doesn't already exist; if it
    # does, tell the user and exit
    if [ -d $install_location ]
    then
        echo
        echo "ERROR: a directory named $install_location already exists, please"
        echo "move this script to another location or specify a different"
        echo "installation directory and try again."
        iexit 1
    fi
fi


# detect if the selected installation path has weird characters in it; if so,
# refuse to install
if echo "$install_location" | grep -q '[] <>?!$&*()[|\"]'
then
    echo "ERROR: you cannot install Ureka in this directory because there are"
    echo "weird characters in the path.  Please try again after moving the"
    echo "install script to another location that does not contain any of these"
    echo 'characters: space tab < > ? ! $ & * ( ) [ ] | \\'
	iexit 1
fi


# create installation directory
mkdir -p $install_location
if [ "$?" != 0 ]
then
    echo
    echo "ERROR: could not create $install_location, please check that you have"
    echo "sufficient privileges and try again."
    iexit 1
fi


# create a temporary directory; tarfile will be unpacked into here
# (do this before we measure the free disk space)
tmp=$install_location/tmp.$$
mkdir -p $tmp

# figure out how much disk space is available in the installation directory
avail_mb=`df -m $install_location | tail -1 | awk '{print $(NF-2)}'`
avail_gb=`echo "scale = 2; $avail_mb / 1024" | bc`

echo "Installing Ureka version $urv to $install_location"


# get tarfile (either user-provided or download)
downloaded_tarfile=false
case "$t" in
    *.tar.gz)
        tarfile=$t

        # normalize tarfile
        case "$tarfile"
        in
            /*)
                :
                ;;
            *)
                tarfile=`pwd`/$tarfile
                ;;
        esac
        
        # make sure tarfile exists
        if [ ! -e $tarfile ]
        then
            echo "ERROR: $tarfile does not exist"
            iexit 1
        fi

        cd $tmp

        # figure out how much space Ureka will need
        #
        # tar may say an error because it does not know "--version"; suppress
        # that error so the user does not see it; what we find interesting
        # is that it does not say a version number with "GNU" in it
        x=Ureka/SIZE
        case `tar --version 2> /dev/null`
        in
            *GNU*)
                tar --occurrence=1 -zxf - $x < $tarfile
                ;;
            *)
                gzip -d < $tarfile | tar -xf - $x
                ;;
        esac
        required_mb=`cat $x`
        required_gb=`echo "scale = 2; $required_mb / 1024" | bc`
        rm $x
        
        echo
        echo "Ureka requires ${required_gb}GB of disk space"
        echo

        # check that there is enough free disk space to unpack the tarfile
        # warn user if there isn't and ask whether to continue
        if [ $required_mb -gt $avail_mb ]
        then
            not_enough_disk_space $avail_gb $u
        fi
        ;;
    "")
        # misc URLs
        install_instructions=http://ssb.stsci.edu/ureka/$urv/docs/installation.html
        url_start=http://ssb.stsci.edu/ureka/$urv/Ureka_
        url_end=_$urv.tar.gz

        # find the OS and CPU type
        unknown=0
        case `uname`
        in
            Darwin)
                sw_vers=`sw_vers -productVersion 2>/dev/null`
                case "$sw_vers"
                in
                    10.5*)
                        echo "ERROR: Ureka is not supported on Mac OS 10.5"
                        iexit 1
                        ;;
                    10.6*)
                        echo "OSX $sw_vers (Snow Leopard)"
                        url=osx-6_64
                        ;;
                    10.7*)
                        echo "OSX $sw_vers (Lion)"
                        url=osx-6_64
                        ;;
                    10.8*)
                        echo "OSX $sw_vers (Mountain Lion)"
                        url=osx-6_64
                        ;;
                    10.9*)
                        echo "OSX $sw_vers (Mavericks)"
                        url=osx-6_64
                        ;;
                    10.10*)
                        echo "OSX $sw_vers (Yosemite)"
                        url=osx-6_64
                        ;;
                    10.11*)
                        echo "OSX $sw_vers (El Capitan)"
                        url=osx-6_64
                        ;;
                    *)
                        unknown=1
                        ;;
                esac
                ;;
            Linux)
                f=`file - < /bin/sh`
                case "$f"
                in
                    *x86-64*)
                        echo "Linux 64-bit"
                        url=linux-rhe6_64
                        ;;
                    *80386*)
                        echo "Linux 32-bit"
                        url=linux-rhe6_32
                        ;;
                    *64-bit*)
                        echo "Linux 64-bit"
                        url=linux-rhe6_64
                        ;;
                    *32-bit*)
                        echo "Linux 32-bit"
                        url=linux-rhe6_32
                        ;;
                esac

                # if on a RHEL 5 machine, use the RHEL 5 Ureka build
                if [ "$url" = "linux-rhe6_64" ]
                then
                    case `cat /etc/redhat-release`
                    in
                        *'release 5.'*)
                            url=linux-rhe5_64
                            ;;
                    esac
                fi
                ;;
            *)
                unknown=1
                ;;
        esac

        # make sure OS and CPU type were identified
        if [ $unknown = 0 ]
        then
            url=${url_start}${url}${url_end}
        else
            echo
            echo "ERROR:"
            echo "Ureka is expected to work on modern Linux and Macintosh systems"
            echo "This script was unable to identify your system type.  Send this"
            echo "information to help@stsci.edu:"
            echo
            echo "Ureka installer $urv"
            iexit 1
        fi

        # determine download method
        download=none
        for d in /usr/bin/wget /bin/wget /usr/bin/curl /bin/curl
        do
            if [ -e "$d" ]
            then
                download=$d
                break
            fi
        done

        # see if wget is available
        if [ $download = none ]
        then
            wget=`which wget 2>/dev/null`
            if [ "$wget" != "" ]
            then
                download=$wget
            fi
        fi

        # see if curl is available
        if [ $download = none ]
        then
            curl=`which curl 2>/dev/null`
            if [ "$curl" != "" ]
            then
                download=$curl
            fi
        fi

        # make sure a download method was found
        if [ $download = none ]
        then
            echo "ERROR:"
            echo "Neither curl nor wget were found on your system.  This script was"
            echo "unable to download $url."
            echo
            echo "You may download the file manually and follow these instructions for"
            echo "installation: $install_instructions"
            iexit 1
        fi

        cd $tmp

        # figure out how much space will be needed to download Ureka tarfile
        # and unpack it, with a buffer of 150MB just to be safe
        archive_size_url=$url.archive_size
        unpacked_size_url=$url.unpacked_size

        case "$download"
        in
            *wget)
                $download -q $archive_size_url
                $download -q $unpacked_size_url
                ;;
            *curl)
                $download -O --silent $archive_size_url
                $download -O --silent $unpacked_size_url
                ;;
        esac

        archive_size=`basename $archive_size_url`
        unpacked_size=`basename $unpacked_size_url`

        archive_mb=`cat $archive_size`
        unpacked_mb=`cat $unpacked_size`
        buffer_mb=150

        required_mb=`echo "$archive_mb + $unpacked_mb + $buffer_mb" | bc`
        required_gb=`echo "scale = 2; $required_mb / 1024" | bc`

        echo "Ureka requires ${required_gb}GB of disk space"
        echo

        # check that there is enough free disk space in the install location
        # for both the tarfile and the unpacked Ureka directory tree
        # warn user if there isn't and ask whether to continue
        if [ $required_mb -gt $avail_mb ]
        then
            not_enough_disk_space $avail_gb $u
        fi

        cd $install_location

        # download tarfile
        echo "Downloading $url"
        case "$download"
        in
            *wget)
                $download $url
                st=$?
                ;;
            *curl)
                $download -O $url
                st=$?
                ;;
        esac

        # make sure download worked
        if [ "$st" != 0 ]
        then
            echo "ERROR: download failed"
            iexit 1
        else
            echo "Download complete"
            downloaded_tarfile=true
        fi

        # find downloaded tarfile
        tarfile=`pwd`/`basename $url`

        # make sure tarfile exists
        if [ ! -e $tarfile ]
        then
            echo "ERROR: $tarfile does not exist"
            iexit 1
        fi
        ;;
    *)
        echo "ERROR: $t is not a valid tarfile"
        iexit 1
        ;;
esac


# unpack tarfile
cd $tmp
echo
echo "Unpacking $tarfile"
echo "(Ureka is big, this will take a while)"
tar -zxf $tarfile
if [ $? != 0 ]
then
    echo "ERROR: failed to unpack $tarfile"
    iexit 1
else
    echo "Done Unpacking"
    if $downloaded_tarfile
    then
        rm $tarfile
    fi
fi


# move Ureka from temporary directory into installation location; then delete
# temporary directory
mv $tmp/Ureka/* $install_location
cd $install_location
rm -rf $tmp


# perist name if specified
if [ "$n" != "" ]
then
    echo $n > $install_location/misc/name
fi


# unset PYTHONPATH before normalizing so only Ureka things are found
export PYTHONPATH=""


echo
echo "Installing"

if $s
then
    norm_flags="-s"
else
    norm_flags=""
fi

if $l
then
    norm_flags="$norm_flags -n"
fi

$install_location/bin/ur_normalize $norm_flags

if [ $? != 0 ]
then
    echo "ERROR: Ureka configuration failed"
    iexit 1
else
    echo "Installation complete"
    echo
    echo "For more information about how to use Ureka, check out the online"
    echo "documentation: http://ssb.stsci.edu/ureka/${urv}/docs/index.html"
fi

iexit 0

