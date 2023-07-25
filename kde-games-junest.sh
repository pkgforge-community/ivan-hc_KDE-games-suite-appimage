#!/bin/sh

# NAME OF THE APP BY REPLACING "SAMPLE"
APP=kde-games
BIN="$APP" #CHANGE THIS IF THE NAME OF THE BINARY IS DIFFERENT FROM "$APP" (for example, the binary of "obs-studio" is "obs")
DEPENDENCES="python python-twisted"
#BASICSTUFF="binutils gzip"
#COMPILERS="gcc"

# ADD A VERSION, THIS IS NEEDED FOR THE NAME OF THE FINEL APPIMAGE, IF NOT AVAILABLE ON THE REPO, THE VALUE COME FROM AUR, AND VICE VERSA
for REPO in { "core" "extra" "community" "multilib" }; do
echo "$(wget -q https://archlinux.org/packages/$REPO/any/kde-games-meta/flag/ -O - | grep kde-games-meta | grep details | head -1 | grep -o -P '(?<=/a> ).*(?= )' | grep -o '^\S*')" >> version
done
VERSION=$(cat ./version | grep -w -v "" | head -1)
VERSIONAUR=$(wget -q https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=$APP -O - | grep pkgver | head -1 | cut -c 8-)

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# ENABLE MULTILIB (optional)
echo "
[multilib]
Include = /etc/pacman.d/mirrorlist" >> ./.junest/etc/pacman.conf

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
rm -R ./.junest/etc/pacman.d/mirrorlist
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL THE APP, BEING JUNEST STRICTLY MINIMAL, YOU NEED TO ADD ALL YOU NEED, INCLUDING BINUTILS AND GZIP
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -Syu

# INSTALL THE PROGRAM USING YAY
./.local/share/junest/bin/junest -- yay -Syy
./.local/share/junest/bin/junest -- yay --noconfirm -S gnu-free-fonts $(echo "$BASICSTUFF $COMPILERS $DEPENDENCES $APP")

# SET THE LOCALE (DON'T TOUCH THIS)
#sed "s/# /#>/g" ./.junest/etc/locale.gen | sed "s/#//g" | sed "s/>/#/g" >> ./locale.gen # UNCOMMENT TO ENABLE ALL THE LANGUAGES
#sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen # ENABLE ONLY YOUR LANGUAGE, COMMENT IF YOU NEED MORE THAN ONE
#rm ./.junest/etc/locale.gen
#mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
#echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
#./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
#./.local/share/junest/bin/junest -- sudo locale-gen

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR...
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/256x256/apps/kpat* ./$APP.AppDir/ 2>/dev/null
echo "[Desktop Entry]
Name=kdegames
Exec=AppRun
Icon=kpat
Type=Application
Categories=Game;" >> ./$APP.AppDir/$APP.desktop

# TEST IF THE DESKTOP FILE AND THE ICON ARE IN THE ROOT OF THE FUTURE APPIMAGE (./*AppDir/*)
if test -f ./$APP.AppDir/*.desktop; then
	echo "The .desktop file is available in $APP.AppDir/"
else 
	cat <<-HEREDOC >> "./$APP.AppDir/$APP.desktop"
	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=KDE Games Suite
	Comment=
	Exec=AppRun
	Icon=tux
	Terminal=true
	StartupNotify=true
	HEREDOC
	wget https://raw.githubusercontent.com/Portable-Linux-Apps/Portable-Linux-Apps.github.io/main/favicon.ico -O ./$APP.AppDir/tux.png
fi

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
mkdir -p $HOME/.cache
case $1 in
'')
echo "
 USAGE: 
    [GAME]
    [GAME] [OPTION]

 See -h to know the names of the available games.
"; exit;;
-h|--help) echo "
 AVAILABLE KDE GAMES:
 
    bomber
    bovo
    granatier
    kajongg
    kapman
    katomic
    kblackbox
    kblocks
    kbounce	
    kbreakout
    kdiamond
    kfourinline
    kgoldrunner
    kigo
    killbots
    kiriki
    kjumpingcube
    klickety
    klines
    kmahjongg
    kmines
    knavalbattle
    knetwalk
    knights
    kolf
    kollision
    konquest
    kpat
    kreversi
    kshisen
    ksirk
    ksnakeduel
    kspaceduel
    ksquares
    ksudoku
    ktuberling
    kubrick
    lskat
    palapeli
    picmi
";;
bomber|bovo|granatier|kajongg|kapman|katomic|kblackbox|kblocks|kbounce|kbreakout|kdiamond|kfourinline|kgoldrunner|kigo|killbots|kiriki|kjumpingcube|klickety|klines|kmahjongg|kmines|knavalbattle|knetwalk|knights|kolf|kollision|konquest|kpat|kreversi|kshisen|ksirk|ksnakeduel|kspaceduel|ksquares|ksudoku|ktuberling|kubrick|lskat|palapeli|picmi) 
$HERE/.local/share/junest/bin/junest proot -n -b "--bind=/home --bind=/home/$(echo $USER) --bind=/media --bind=/mnt --bind=/opt --bind=/usr/lib/locale --bind=/etc/fonts" 2> /dev/null -- $1 "$@"
;;
*)
echo " $1 does not exists, see -h";;
esac
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE "READ-ONLY FILE SYSTEM" ERRORS
sed -i 's#${JUNEST_HOME}/usr/bin/junest_wrapper#${HOME}/.cache/junest_wrapper.old#g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/rm -f "${JUNEST_HOME}${bin_path}_wrappers/#rm -f "${JUNEST_HOME}${bin_path}_wrappers/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh
sed -i 's/ln/#ln/g' ./$APP.AppDir/.local/share/junest/lib/core/wrappers.sh

# REMOVE SOME BLOATWARES
find ./$APP.AppDir/.junest/usr/share/doc/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL DOCUMENTATION NOT RELATED TO THE APP
#find ./$APP.AppDir/.junest/usr/share/locale/*/*/* -not -iname "*$BIN*" -a -not -name "." -delete #REMOVE ALL ADDITIONAL LOCALE FILES
rm -R -f ./$APP.AppDir/.junest/etc/makepkg.conf
rm -R -f ./$APP.AppDir/.junest/etc/pacman.conf
rm -R -f ./$APP.AppDir/.junest/usr/bin/[
rm -R -f ./$APP.AppDir/.junest/usr/bin/4channels
rm -R -f ./$APP.AppDir/.junest/usr/bin/acceleration_speed
rm -R -f ./$APP.AppDir/.junest/usr/bin/addgnupghome
rm -R -f ./$APP.AppDir/.junest/usr/bin/addpart
rm -R -f ./$APP.AppDir/.junest/usr/bin/addr2line
rm -R -f ./$APP.AppDir/.junest/usr/bin/agetty
rm -R -f ./$APP.AppDir/.junest/usr/bin/amdgpu_stress
rm -R -f ./$APP.AppDir/.junest/usr/bin/aomdec
rm -R -f ./$APP.AppDir/.junest/usr/bin/aomenc
rm -R -f ./$APP.AppDir/.junest/usr/bin/applygnupgdefaults
rm -R -f ./$APP.AppDir/.junest/usr/bin/ar
rm -R -f ./$APP.AppDir/.junest/usr/bin/archlinux-keyring-wkd-sync
rm -R -f ./$APP.AppDir/.junest/usr/bin/argon2
rm -R -f ./$APP.AppDir/.junest/usr/bin/arptables-nft
rm -R -f ./$APP.AppDir/.junest/usr/bin/arptables-nft-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/arptables-nft-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/as
rm -R -f ./$APP.AppDir/.junest/usr/bin/asn1Coding
rm -R -f ./$APP.AppDir/.junest/usr/bin/asn1Decoding
rm -R -f ./$APP.AppDir/.junest/usr/bin/asn1Parser
rm -R -f ./$APP.AppDir/.junest/usr/bin/attr
rm -R -f ./$APP.AppDir/.junest/usr/bin/audisp-af_unix
rm -R -f ./$APP.AppDir/.junest/usr/bin/audispd-zos-remote
rm -R -f ./$APP.AppDir/.junest/usr/bin/audisp-remote
rm -R -f ./$APP.AppDir/.junest/usr/bin/audisp-syslog
rm -R -f ./$APP.AppDir/.junest/usr/bin/auditctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/auditd
rm -R -f ./$APP.AppDir/.junest/usr/bin/augenrules
rm -R -f ./$APP.AppDir/.junest/usr/bin/aulast
rm -R -f ./$APP.AppDir/.junest/usr/bin/aulastlog
rm -R -f ./$APP.AppDir/.junest/usr/bin/aureport
rm -R -f ./$APP.AppDir/.junest/usr/bin/ausearch
rm -R -f ./$APP.AppDir/.junest/usr/bin/ausyscall
rm -R -f ./$APP.AppDir/.junest/usr/bin/autopoint
rm -R -f ./$APP.AppDir/.junest/usr/bin/autrace
rm -R -f ./$APP.AppDir/.junest/usr/bin/auvirt
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-autoipd
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-bookmarks
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-browse
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-browse-domains
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-daemon
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-discover
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-discover-standalone
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-dnsconfd
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-publish
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-publish-address
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-publish-service
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-resolve
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-resolve-address
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-resolve-host-name
rm -R -f ./$APP.AppDir/.junest/usr/bin/avahi-set-host-name
rm -R -f ./$APP.AppDir/.junest/usr/bin/awk
rm -R -f ./$APP.AppDir/.junest/usr/bin/b2sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/badblocks
rm -R -f ./$APP.AppDir/.junest/usr/bin/base32
rm -R -f ./$APP.AppDir/.junest/usr/bin/base64
rm -R -f ./$APP.AppDir/.junest/usr/bin/basename
rm -R -f ./$APP.AppDir/.junest/usr/bin/basenc
rm -R -f ./$APP.AppDir/.junest/usr/bin/bashbug
rm -R -f ./$APP.AppDir/.junest/usr/bin/bjoentegaard
rm -R -f ./$APP.AppDir/.junest/usr/bin/blkdeactivate
rm -R -f ./$APP.AppDir/.junest/usr/bin/blkdiscard
rm -R -f ./$APP.AppDir/.junest/usr/bin/blkid
rm -R -f ./$APP.AppDir/.junest/usr/bin/blkpr
rm -R -f ./$APP.AppDir/.junest/usr/bin/blkzone
rm -R -f ./$APP.AppDir/.junest/usr/bin/blockdev
rm -R -f ./$APP.AppDir/.junest/usr/bin/block-rate-estim
rm -R -f ./$APP.AppDir/.junest/usr/bin/bootctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/brotli
rm -R -f ./$APP.AppDir/.junest/usr/bin/bsdcat
rm -R -f ./$APP.AppDir/.junest/usr/bin/bsdcpio
rm -R -f ./$APP.AppDir/.junest/usr/bin/bsdtar
rm -R -f ./$APP.AppDir/.junest/usr/bin/bshell
rm -R -f ./$APP.AppDir/.junest/usr/bin/bssh
rm -R -f ./$APP.AppDir/.junest/usr/bin/bunzip2
rm -R -f ./$APP.AppDir/.junest/usr/bin/busctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/bvnc
rm -R -f ./$APP.AppDir/.junest/usr/bin/bwrap
rm -R -f ./$APP.AppDir/.junest/usr/bin/bzcat
rm -R -f ./$APP.AppDir/.junest/usr/bin/bzdiff
rm -R -f ./$APP.AppDir/.junest/usr/bin/bzgrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/bzip2
rm -R -f ./$APP.AppDir/.junest/usr/bin/bzip2recover
rm -R -f ./$APP.AppDir/.junest/usr/bin/bzmore
rm -R -f ./$APP.AppDir/.junest/usr/bin/c++
rm -R -f ./$APP.AppDir/.junest/usr/bin/c89
rm -R -f ./$APP.AppDir/.junest/usr/bin/c99
rm -R -f ./$APP.AppDir/.junest/usr/bin/cairo-trace
rm -R -f ./$APP.AppDir/.junest/usr/bin/cal
rm -R -f ./$APP.AppDir/.junest/usr/bin/capsh
rm -R -f ./$APP.AppDir/.junest/usr/bin/captest
rm -R -f ./$APP.AppDir/.junest/usr/bin/captoinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/captree
rm -R -f ./$APP.AppDir/.junest/usr/bin/cat
rm -R -f ./$APP.AppDir/.junest/usr/bin/cc
rm -R -f ./$APP.AppDir/.junest/usr/bin/certtool
rm -R -f ./$APP.AppDir/.junest/usr/bin/certutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/cfdisk
rm -R -f ./$APP.AppDir/.junest/usr/bin/c++filt
rm -R -f ./$APP.AppDir/.junest/usr/bin/chacl
rm -R -f ./$APP.AppDir/.junest/usr/bin/chage
rm -R -f ./$APP.AppDir/.junest/usr/bin/chattr
rm -R -f ./$APP.AppDir/.junest/usr/bin/chcon
rm -R -f ./$APP.AppDir/.junest/usr/bin/chcpu
rm -R -f ./$APP.AppDir/.junest/usr/bin/chfn
rm -R -f ./$APP.AppDir/.junest/usr/bin/chgpasswd
rm -R -f ./$APP.AppDir/.junest/usr/bin/chgrp
rm -R -f ./$APP.AppDir/.junest/usr/bin/chmem
rm -R -f ./$APP.AppDir/.junest/usr/bin/chmod
rm -R -f ./$APP.AppDir/.junest/usr/bin/choom
rm -R -f ./$APP.AppDir/.junest/usr/bin/chown
rm -R -f ./$APP.AppDir/.junest/usr/bin/chpasswd
rm -R -f ./$APP.AppDir/.junest/usr/bin/chrt
rm -R -f ./$APP.AppDir/.junest/usr/bin/chsh
rm -R -f ./$APP.AppDir/.junest/usr/bin/chvt
rm -R -f ./$APP.AppDir/.junest/usr/bin/cjpeg
rm -R -f ./$APP.AppDir/.junest/usr/bin/cjpeg_hdr
rm -R -f ./$APP.AppDir/.junest/usr/bin/cjxl
rm -R -f ./$APP.AppDir/.junest/usr/bin/cksum
rm -R -f ./$APP.AppDir/.junest/usr/bin/clear
rm -R -f ./$APP.AppDir/.junest/usr/bin/clrunimap
rm -R -f ./$APP.AppDir/.junest/usr/bin/cmsutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/col
rm -R -f ./$APP.AppDir/.junest/usr/bin/colcrt
rm -R -f ./$APP.AppDir/.junest/usr/bin/colrm
rm -R -f ./$APP.AppDir/.junest/usr/bin/column
rm -R -f ./$APP.AppDir/.junest/usr/bin/comm
rm -R -f ./$APP.AppDir/.junest/usr/bin/compile_et
rm -R -f ./$APP.AppDir/.junest/usr/bin/coredumpctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/core_perl
rm -R -f ./$APP.AppDir/.junest/usr/bin/cp
rm -R -f ./$APP.AppDir/.junest/usr/bin/cpp
rm -R -f ./$APP.AppDir/.junest/usr/bin/c_rehash
rm -R -f ./$APP.AppDir/.junest/usr/bin/crlutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/cryptsetup
rm -R -f ./$APP.AppDir/.junest/usr/bin/csplit
rm -R -f ./$APP.AppDir/.junest/usr/bin/ctrlaltdel
rm -R -f ./$APP.AppDir/.junest/usr/bin/cups-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/curl
rm -R -f ./$APP.AppDir/.junest/usr/bin/curl-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/cut
rm -R -f ./$APP.AppDir/.junest/usr/bin/cwebp
rm -R -f ./$APP.AppDir/.junest/usr/bin/cxpm
rm -R -f ./$APP.AppDir/.junest/usr/bin/date
rm -R -f ./$APP.AppDir/.junest/usr/bin/dav1d
rm -R -f ./$APP.AppDir/.junest/usr/bin/db5.3
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_archive
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_checkpoint
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_convert
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_deadlock
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_dump
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_hotbackup
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_load
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_log_verify
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_printlog
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_recover
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_replicate
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_stat
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_tuner
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_upgrade
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-cleanup-sockets
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-daemon
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-launch
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-monitor
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-run-session
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-send
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-test-tool
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-update-activation-environment
rm -R -f ./$APP.AppDir/.junest/usr/bin/dbus-uuidgen
rm -R -f ./$APP.AppDir/.junest/usr/bin/db_verify
rm -R -f ./$APP.AppDir/.junest/usr/bin/dconf
rm -R -f ./$APP.AppDir/.junest/usr/bin/dcraw_emu
rm -R -f ./$APP.AppDir/.junest/usr/bin/dcraw_half
rm -R -f ./$APP.AppDir/.junest/usr/bin/dd
rm -R -f ./$APP.AppDir/.junest/usr/bin/deallocvt
rm -R -f ./$APP.AppDir/.junest/usr/bin/debugfs
rm -R -f ./$APP.AppDir/.junest/usr/bin/dec265
rm -R -f ./$APP.AppDir/.junest/usr/bin/delpart
rm -R -f ./$APP.AppDir/.junest/usr/bin/depmod
rm -R -f ./$APP.AppDir/.junest/usr/bin/derb
rm -R -f ./$APP.AppDir/.junest/usr/bin/desktop-file-edit
rm -R -f ./$APP.AppDir/.junest/usr/bin/desktop-file-install
rm -R -f ./$APP.AppDir/.junest/usr/bin/desktop-file-validate
rm -R -f ./$APP.AppDir/.junest/usr/bin/df
rm -R -f ./$APP.AppDir/.junest/usr/bin/dir
rm -R -f ./$APP.AppDir/.junest/usr/bin/dircolors
rm -R -f ./$APP.AppDir/.junest/usr/bin/dirmngr
rm -R -f ./$APP.AppDir/.junest/usr/bin/dirmngr-client
rm -R -f ./$APP.AppDir/.junest/usr/bin/dirname
rm -R -f ./$APP.AppDir/.junest/usr/bin/djpeg
rm -R -f ./$APP.AppDir/.junest/usr/bin/djxl
rm -R -f ./$APP.AppDir/.junest/usr/bin/dmesg
rm -R -f ./$APP.AppDir/.junest/usr/bin/dmeventd
rm -R -f ./$APP.AppDir/.junest/usr/bin/dmsetup
rm -R -f ./$APP.AppDir/.junest/usr/bin/dmstats
rm -R -f ./$APP.AppDir/.junest/usr/bin/drmdevice
rm -R -f ./$APP.AppDir/.junest/usr/bin/du
rm -R -f ./$APP.AppDir/.junest/usr/bin/dumpe2fs
rm -R -f ./$APP.AppDir/.junest/usr/bin/dumpkeys
rm -R -f ./$APP.AppDir/.junest/usr/bin/dumpsexp
rm -R -f ./$APP.AppDir/.junest/usr/bin/dwebp
rm -R -f ./$APP.AppDir/.junest/usr/bin/dwp
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2freefrag
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2fsck
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2image
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2label
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2mmpstatus
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2scrub
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2scrub_all
rm -R -f ./$APP.AppDir/.junest/usr/bin/e2undo
rm -R -f ./$APP.AppDir/.junest/usr/bin/e4crypt
rm -R -f ./$APP.AppDir/.junest/usr/bin/e4defrag
rm -R -f ./$APP.AppDir/.junest/usr/bin/ebtables-nft
rm -R -f ./$APP.AppDir/.junest/usr/bin/ebtables-nft-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/ebtables-nft-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/ebtables-translate
rm -R -f ./$APP.AppDir/.junest/usr/bin/echo
rm -R -f ./$APP.AppDir/.junest/usr/bin/egrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/eject
rm -R -f ./$APP.AppDir/.junest/usr/bin/elfedit
#rm -R -f ./$APP.AppDir/.junest/usr/bin/env
rm -R -f ./$APP.AppDir/.junest/usr/bin/env.fakechroot
rm -R -f ./$APP.AppDir/.junest/usr/bin/envsubst
rm -R -f ./$APP.AppDir/.junest/usr/bin/escapesrc
rm -R -f ./$APP.AppDir/.junest/usr/bin/event_rpcgen.py
rm -R -f ./$APP.AppDir/.junest/usr/bin/exiv2
rm -R -f ./$APP.AppDir/.junest/usr/bin/expand
rm -R -f ./$APP.AppDir/.junest/usr/bin/expiry
rm -R -f ./$APP.AppDir/.junest/usr/bin/expr
rm -R -f ./$APP.AppDir/.junest/usr/bin/exr2aces
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrenvmap
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrheader
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrmakepreview
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrmaketiled
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrmultipart
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrmultiview
rm -R -f ./$APP.AppDir/.junest/usr/bin/exrstdattr
rm -R -f ./$APP.AppDir/.junest/usr/bin/factor
rm -R -f ./$APP.AppDir/.junest/usr/bin/fadvise
rm -R -f ./$APP.AppDir/.junest/usr/bin/faillock
rm -R -f ./$APP.AppDir/.junest/usr/bin/faillog
rm -R -f ./$APP.AppDir/.junest/usr/bin/faked
rm -R -f ./$APP.AppDir/.junest/usr/bin/fakeroot
rm -R -f ./$APP.AppDir/.junest/usr/bin/fallocate
rm -R -f ./$APP.AppDir/.junest/usr/bin/false
rm -R -f ./$APP.AppDir/.junest/usr/bin/fancontrol
rm -R -f ./$APP.AppDir/.junest/usr/bin/fax2ps
rm -R -f ./$APP.AppDir/.junest/usr/bin/fax2tiff
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-cache
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-cat
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-conflist
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-match
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-pattern
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-query
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-scan
rm -R -f ./$APP.AppDir/.junest/usr/bin/fc-validate
rm -R -f ./$APP.AppDir/.junest/usr/bin/fdisk
rm -R -f ./$APP.AppDir/.junest/usr/bin/fgconsole
rm -R -f ./$APP.AppDir/.junest/usr/bin/fgrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/file
rm -R -f ./$APP.AppDir/.junest/usr/bin/filecap
rm -R -f ./$APP.AppDir/.junest/usr/bin/filefrag
rm -R -f ./$APP.AppDir/.junest/usr/bin/fincore
rm -R -f ./$APP.AppDir/.junest/usr/bin/find
rm -R -f ./$APP.AppDir/.junest/usr/bin/findfs
rm -R -f ./$APP.AppDir/.junest/usr/bin/findmnt
rm -R -f ./$APP.AppDir/.junest/usr/bin/flock
rm -R -f ./$APP.AppDir/.junest/usr/bin/fmt
rm -R -f ./$APP.AppDir/.junest/usr/bin/fold
rm -R -f ./$APP.AppDir/.junest/usr/bin/fribidi
rm -R -f ./$APP.AppDir/.junest/usr/bin/fsck
rm -R -f ./$APP.AppDir/.junest/usr/bin/fsck.cramfs
rm -R -f ./$APP.AppDir/.junest/usr/bin/fsck.ext2
rm -R -f ./$APP.AppDir/.junest/usr/bin/fsck.ext3
rm -R -f ./$APP.AppDir/.junest/usr/bin/fsck.ext4
rm -R -f ./$APP.AppDir/.junest/usr/bin/fsck.minix
rm -R -f ./$APP.AppDir/.junest/usr/bin/fsfreeze
rm -R -f ./$APP.AppDir/.junest/usr/bin/fstrim
rm -R -f ./$APP.AppDir/.junest/usr/bin/g++
rm -R -f ./$APP.AppDir/.junest/usr/bin/gapplication
rm -R -f ./$APP.AppDir/.junest/usr/bin/gawk
rm -R -f ./$APP.AppDir/.junest/usr/bin/gawk-5.2.2
rm -R -f ./$APP.AppDir/.junest/usr/bin/gawkbug
rm -R -f ./$APP.AppDir/.junest/usr/bin/gcc
rm -R -f ./$APP.AppDir/.junest/usr/bin/gcc-ar
rm -R -f ./$APP.AppDir/.junest/usr/bin/gcc-nm
rm -R -f ./$APP.AppDir/.junest/usr/bin/gcc-ranlib
rm -R -f ./$APP.AppDir/.junest/usr/bin/gcov
rm -R -f ./$APP.AppDir/.junest/usr/bin/gcov-tool
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdbm_dump
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdbm_load
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdbmtool
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdbus
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdbus-codegen
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdk-pixbuf-csource
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdk-pixbuf-pixdata
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdk-pixbuf-query-loaders
rm -R -f ./$APP.AppDir/.junest/usr/bin/gdk-pixbuf-thumbnailer
rm -R -f ./$APP.AppDir/.junest/usr/bin/genbrk
rm -R -f ./$APP.AppDir/.junest/usr/bin/gencat
rm -R -f ./$APP.AppDir/.junest/usr/bin/genccode
rm -R -f ./$APP.AppDir/.junest/usr/bin/gencfu
rm -R -f ./$APP.AppDir/.junest/usr/bin/gencmn
rm -R -f ./$APP.AppDir/.junest/usr/bin/gencnval
rm -R -f ./$APP.AppDir/.junest/usr/bin/gendict
rm -R -f ./$APP.AppDir/.junest/usr/bin/gen-enc-table
rm -R -f ./$APP.AppDir/.junest/usr/bin/genl-ctrl-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/gennorm2
rm -R -f ./$APP.AppDir/.junest/usr/bin/genrb
rm -R -f ./$APP.AppDir/.junest/usr/bin/gensprep
rm -R -f ./$APP.AppDir/.junest/usr/bin/getcap
rm -R -f ./$APP.AppDir/.junest/usr/bin/getconf
rm -R -f ./$APP.AppDir/.junest/usr/bin/getent
rm -R -f ./$APP.AppDir/.junest/usr/bin/getfacl
rm -R -f ./$APP.AppDir/.junest/usr/bin/getfattr
rm -R -f ./$APP.AppDir/.junest/usr/bin/getkeycodes
rm -R -f ./$APP.AppDir/.junest/usr/bin/getopt
rm -R -f ./$APP.AppDir/.junest/usr/bin/getpcaps
rm -R -f ./$APP.AppDir/.junest/usr/bin/getsubids
rm -R -f ./$APP.AppDir/.junest/usr/bin/gettext
rm -R -f ./$APP.AppDir/.junest/usr/bin/gettextize
rm -R -f ./$APP.AppDir/.junest/usr/bin/gettext.sh
rm -R -f ./$APP.AppDir/.junest/usr/bin/getunimap
rm -R -f ./$APP.AppDir/.junest/usr/bin/gif2rgb
rm -R -f ./$APP.AppDir/.junest/usr/bin/gif2webp
rm -R -f ./$APP.AppDir/.junest/usr/bin/gifbuild
rm -R -f ./$APP.AppDir/.junest/usr/bin/gifclrmp
rm -R -f ./$APP.AppDir/.junest/usr/bin/giffix
rm -R -f ./$APP.AppDir/.junest/usr/bin/giftext
rm -R -f ./$APP.AppDir/.junest/usr/bin/giftool
rm -R -f ./$APP.AppDir/.junest/usr/bin/gio
rm -R -f ./$APP.AppDir/.junest/usr/bin/gio-querymodules
rm -R -f ./$APP.AppDir/.junest/usr/bin/git
rm -R -f ./$APP.AppDir/.junest/usr/bin/git-cvsserver
rm -R -f ./$APP.AppDir/.junest/usr/bin/gitk
rm -R -f ./$APP.AppDir/.junest/usr/bin/git-receive-pack
rm -R -f ./$APP.AppDir/.junest/usr/bin/git-shell
rm -R -f ./$APP.AppDir/.junest/usr/bin/git-upload-archive
rm -R -f ./$APP.AppDir/.junest/usr/bin/git-upload-pack
rm -R -f ./$APP.AppDir/.junest/usr/bin/g-lensfun-update-data
rm -R -f ./$APP.AppDir/.junest/usr/bin/glib-compile-resources
rm -R -f ./$APP.AppDir/.junest/usr/bin/glib-compile-schemas
rm -R -f ./$APP.AppDir/.junest/usr/bin/glib-genmarshal
rm -R -f ./$APP.AppDir/.junest/usr/bin/glib-gettextize
rm -R -f ./$APP.AppDir/.junest/usr/bin/glib-mkenums
rm -R -f ./$APP.AppDir/.junest/usr/bin/gnutls-cli
rm -R -f ./$APP.AppDir/.junest/usr/bin/gnutls-cli-debug
rm -R -f ./$APP.AppDir/.junest/usr/bin/gnutls-serv
rm -R -f ./$APP.AppDir/.junest/usr/bin/gobject-query
rm -R -f ./$APP.AppDir/.junest/usr/bin/gp-archive
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpasswd
rm -R -f ./$APP.AppDir/.junest/usr/bin/gp-collect-app
rm -R -f ./$APP.AppDir/.junest/usr/bin/gp-display-html
rm -R -f ./$APP.AppDir/.junest/usr/bin/gp-display-src
rm -R -f ./$APP.AppDir/.junest/usr/bin/gp-display-text
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpg
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpg2
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpg-agent
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgconf
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpg-connect-agent
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpg-error
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgme-json
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgme-tool
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgparsemail
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgrt-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgscm
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgsm
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgsplit
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgtar
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgv
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpgv2
rm -R -f ./$APP.AppDir/.junest/usr/bin/gpg-wks-server
rm -R -f ./$APP.AppDir/.junest/usr/bin/gprof
rm -R -f ./$APP.AppDir/.junest/usr/bin/gprofng
rm -R -f ./$APP.AppDir/.junest/usr/bin/gr2fonttest
rm -R -f ./$APP.AppDir/.junest/usr/bin/grep
rm -R -f ./$APP.AppDir/.junest/usr/bin/gresource
rm -R -f ./$APP.AppDir/.junest/usr/bin/groot
rm -R -f ./$APP.AppDir/.junest/usr/bin/groupadd
rm -R -f ./$APP.AppDir/.junest/usr/bin/groupdel
rm -R -f ./$APP.AppDir/.junest/usr/bin/groupmems
rm -R -f ./$APP.AppDir/.junest/usr/bin/groupmod
rm -R -f ./$APP.AppDir/.junest/usr/bin/groups
rm -R -f ./$APP.AppDir/.junest/usr/bin/grpck
rm -R -f ./$APP.AppDir/.junest/usr/bin/grpconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/grpunconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/gsettings
rm -R -f ./$APP.AppDir/.junest/usr/bin/gss-client
rm -R -f ./$APP.AppDir/.junest/usr/bin/gss-server
rm -R -f ./$APP.AppDir/.junest/usr/bin/gtester
rm -R -f ./$APP.AppDir/.junest/usr/bin/gtester-report
rm -R -f ./$APP.AppDir/.junest/usr/bin/gtk4-update-icon-cache
rm -R -f ./$APP.AppDir/.junest/usr/bin/gtk-builder-convert
rm -R -f ./$APP.AppDir/.junest/usr/bin/gtk-demo
rm -R -f ./$APP.AppDir/.junest/usr/bin/gtk-query-immodules-2.0
rm -R -f ./$APP.AppDir/.junest/usr/bin/gtk-update-icon-cache
rm -R -f ./$APP.AppDir/.junest/usr/bin/half_mt
rm -R -f ./$APP.AppDir/.junest/usr/bin/hardlink
rm -R -f ./$APP.AppDir/.junest/usr/bin/hdrcopy
rm -R -f ./$APP.AppDir/.junest/usr/bin/head
rm -R -f ./$APP.AppDir/.junest/usr/bin/healthd
rm -R -f ./$APP.AppDir/.junest/usr/bin/heif-convert
rm -R -f ./$APP.AppDir/.junest/usr/bin/heif-enc
rm -R -f ./$APP.AppDir/.junest/usr/bin/heif-info
rm -R -f ./$APP.AppDir/.junest/usr/bin/heif-thumbnailer
rm -R -f ./$APP.AppDir/.junest/usr/bin/hexdump
rm -R -f ./$APP.AppDir/.junest/usr/bin/hmac256
rm -R -f ./$APP.AppDir/.junest/usr/bin/homectl
rm -R -f ./$APP.AppDir/.junest/usr/bin/hostid
rm -R -f ./$APP.AppDir/.junest/usr/bin/hostnamectl
rm -R -f ./$APP.AppDir/.junest/usr/bin/hwclock
rm -R -f ./$APP.AppDir/.junest/usr/bin/i386
rm -R -f ./$APP.AppDir/.junest/usr/bin/iconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/iconvconfig
rm -R -f ./$APP.AppDir/.junest/usr/bin/icu-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/icuexportdata
rm -R -f ./$APP.AppDir/.junest/usr/bin/icuinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/icupkg
rm -R -f ./$APP.AppDir/.junest/usr/bin/id
rm -R -f ./$APP.AppDir/.junest/usr/bin/idiag-socket-details
rm -R -f ./$APP.AppDir/.junest/usr/bin/idn2
rm -R -f ./$APP.AppDir/.junest/usr/bin/infocmp
rm -R -f ./$APP.AppDir/.junest/usr/bin/infotocap
rm -R -f ./$APP.AppDir/.junest/usr/bin/insmod
rm -R -f ./$APP.AppDir/.junest/usr/bin/install
rm -R -f ./$APP.AppDir/.junest/usr/bin/integritysetup
rm -R -f ./$APP.AppDir/.junest/usr/bin/ionice
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-apply
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-legacy
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-legacy-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-legacy-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-nft
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-nft-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-nft-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-restore-translate
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/ip6tables-translate
rm -R -f ./$APP.AppDir/.junest/usr/bin/ipcmk
rm -R -f ./$APP.AppDir/.junest/usr/bin/ipcrm
rm -R -f ./$APP.AppDir/.junest/usr/bin/ipcs
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-apply
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-legacy
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-legacy-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-legacy-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-nft
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-nft-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-nft-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-restore
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-restore-translate
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-save
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-translate
rm -R -f ./$APP.AppDir/.junest/usr/bin/iptables-xml
rm -R -f ./$APP.AppDir/.junest/usr/bin/irqtop
rm -R -f ./$APP.AppDir/.junest/usr/bin/isadump
rm -R -f ./$APP.AppDir/.junest/usr/bin/isaset
rm -R -f ./$APP.AppDir/.junest/usr/bin/isosize
rm -R -f ./$APP.AppDir/.junest/usr/bin/jasper
rm -R -f ./$APP.AppDir/.junest/usr/bin/jiv
rm -R -f ./$APP.AppDir/.junest/usr/bin/join
rm -R -f ./$APP.AppDir/.junest/usr/bin/journalctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/json-glib-format
rm -R -f ./$APP.AppDir/.junest/usr/bin/json-glib-validate
rm -R -f ./$APP.AppDir/.junest/usr/bin/junest_wrapper
rm -R -f ./$APP.AppDir/.junest/usr/bin/jxlinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/k5srvutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/kadmin
rm -R -f ./$APP.AppDir/.junest/usr/bin/kadmind
rm -R -f ./$APP.AppDir/.junest/usr/bin/kadmin.local
rm -R -f ./$APP.AppDir/.junest/usr/bin/kbdinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/kbd_mode
rm -R -f ./$APP.AppDir/.junest/usr/bin/kbdrate
rm -R -f ./$APP.AppDir/.junest/usr/bin/kbxutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/kdb5_ldap_util
rm -R -f ./$APP.AppDir/.junest/usr/bin/kdb5_util
rm -R -f ./$APP.AppDir/.junest/usr/bin/kdestroy
rm -R -f ./$APP.AppDir/.junest/usr/bin/kernel-install
rm -R -f ./$APP.AppDir/.junest/usr/bin/keyctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/key.dns_resolver
rm -R -f ./$APP.AppDir/.junest/usr/bin/kill
rm -R -f ./$APP.AppDir/.junest/usr/bin/kinit
rm -R -f ./$APP.AppDir/.junest/usr/bin/klist
rm -R -f ./$APP.AppDir/.junest/usr/bin/kmod
rm -R -f ./$APP.AppDir/.junest/usr/bin/kpasswd
rm -R -f ./$APP.AppDir/.junest/usr/bin/kprop
rm -R -f ./$APP.AppDir/.junest/usr/bin/kpropd
rm -R -f ./$APP.AppDir/.junest/usr/bin/kproplog
rm -R -f ./$APP.AppDir/.junest/usr/bin/krb5-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/krb5kdc
rm -R -f ./$APP.AppDir/.junest/usr/bin/krb5-send-pr
rm -R -f ./$APP.AppDir/.junest/usr/bin/ksu
rm -R -f ./$APP.AppDir/.junest/usr/bin/kswitch
rm -R -f ./$APP.AppDir/.junest/usr/bin/ktutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/kvno
rm -R -f ./$APP.AppDir/.junest/usr/bin/last
rm -R -f ./$APP.AppDir/.junest/usr/bin/lastb
rm -R -f ./$APP.AppDir/.junest/usr/bin/lastlog
rm -R -f ./$APP.AppDir/.junest/usr/bin/ld
rm -R -f ./$APP.AppDir/.junest/usr/bin/ldattach
rm -R -f ./$APP.AppDir/.junest/usr/bin/ld.bfd
rm -R -f ./$APP.AppDir/.junest/usr/bin/ldconfig
rm -R -f ./$APP.AppDir/.junest/usr/bin/ldd
rm -R -f ./$APP.AppDir/.junest/usr/bin/ldd.fakechroot
rm -R -f ./$APP.AppDir/.junest/usr/bin/ld.gold
rm -R -f ./$APP.AppDir/.junest/usr/bin/ld.so
rm -R -f ./$APP.AppDir/.junest/usr/bin/lensfun-add-adapter
rm -R -f ./$APP.AppDir/.junest/usr/bin/lensfun-update-data
rm -R -f ./$APP.AppDir/.junest/usr/bin/libassuan-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/libgcrypt-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/libpng16-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/libpng-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/libwmf-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/libwmf-fontmap
rm -R -f ./$APP.AppDir/.junest/usr/bin/link
rm -R -f ./$APP.AppDir/.junest/usr/bin/linkicc
rm -R -f ./$APP.AppDir/.junest/usr/bin/linux32
rm -R -f ./$APP.AppDir/.junest/usr/bin/linux64
rm -R -f ./$APP.AppDir/.junest/usr/bin/ln
rm -R -f ./$APP.AppDir/.junest/usr/bin/loadkeys
rm -R -f ./$APP.AppDir/.junest/usr/bin/loadunimap
rm -R -f ./$APP.AppDir/.junest/usr/bin/locale
rm -R -f ./$APP.AppDir/.junest/usr/bin/localectl
rm -R -f ./$APP.AppDir/.junest/usr/bin/localedef
rm -R -f ./$APP.AppDir/.junest/usr/bin/locale-gen
rm -R -f ./$APP.AppDir/.junest/usr/bin/logger
rm -R -f ./$APP.AppDir/.junest/usr/bin/login
rm -R -f ./$APP.AppDir/.junest/usr/bin/loginctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/logname
rm -R -f ./$APP.AppDir/.junest/usr/bin/logsave
rm -R -f ./$APP.AppDir/.junest/usr/bin/look
rm -R -f ./$APP.AppDir/.junest/usr/bin/losetup
rm -R -f ./$APP.AppDir/.junest/usr/bin/ls
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsattr
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsblk
rm -R -f ./$APP.AppDir/.junest/usr/bin/lscpu
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsfd
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsipc
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsirq
rm -R -f ./$APP.AppDir/.junest/usr/bin/lslocks
rm -R -f ./$APP.AppDir/.junest/usr/bin/lslogins
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsmem
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsmod
rm -R -f ./$APP.AppDir/.junest/usr/bin/lsns
rm -R -f ./$APP.AppDir/.junest/usr/bin/luajit
rm -R -f ./$APP.AppDir/.junest/usr/bin/luajit-2.1.0-beta3
rm -R -f ./$APP.AppDir/.junest/usr/bin/lz4
rm -R -f ./$APP.AppDir/.junest/usr/bin/lz4c
rm -R -f ./$APP.AppDir/.junest/usr/bin/lz4cat
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzcat
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzcmp
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzdiff
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzegrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzfgrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzgrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzless
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzma
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzmadec
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzmainfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/lzmore
rm -R -f ./$APP.AppDir/.junest/usr/bin/machinectl
rm -R -f ./$APP.AppDir/.junest/usr/bin/makeconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/makedb
rm -R -f ./$APP.AppDir/.junest/usr/bin/makepkg
rm -R -f ./$APP.AppDir/.junest/usr/bin/makepkg-template
rm -R -f ./$APP.AppDir/.junest/usr/bin/mapscrn
rm -R -f ./$APP.AppDir/.junest/usr/bin/mcookie
rm -R -f ./$APP.AppDir/.junest/usr/bin/md5sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/mem_image
rm -R -f ./$APP.AppDir/.junest/usr/bin/memusage
rm -R -f ./$APP.AppDir/.junest/usr/bin/memusagestat
rm -R -f ./$APP.AppDir/.junest/usr/bin/mesg
rm -R -f ./$APP.AppDir/.junest/usr/bin/mk_cmds
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkdir
rm -R -f ./$APP.AppDir/.junest/usr/bin/mke2fs
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfifo
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfs
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfs.bfs
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfs.cramfs
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfs.ext2
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfs.ext3
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfs.ext4
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkfs.minix
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkhomedir_helper
rm -R -f ./$APP.AppDir/.junest/usr/bin/mklost+found
rm -R -f ./$APP.AppDir/.junest/usr/bin/mknod
rm -R -f ./$APP.AppDir/.junest/usr/bin/mkswap
rm -R -f ./$APP.AppDir/.junest/usr/bin/mktemp
rm -R -f ./$APP.AppDir/.junest/usr/bin/modeprint
rm -R -f ./$APP.AppDir/.junest/usr/bin/modetest
rm -R -f ./$APP.AppDir/.junest/usr/bin/modinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/modprobe
rm -R -f ./$APP.AppDir/.junest/usr/bin/modutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/mongoose
rm -R -f ./$APP.AppDir/.junest/usr/bin/more
rm -R -f ./$APP.AppDir/.junest/usr/bin/mount
rm -R -f ./$APP.AppDir/.junest/usr/bin/mountpoint
rm -R -f ./$APP.AppDir/.junest/usr/bin/mpicalc
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgattrib
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgcat
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgcmp
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgcomm
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgen
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgexec
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgfilter
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgfmt
rm -R -f ./$APP.AppDir/.junest/usr/bin/msggrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/msginit
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgmerge
rm -R -f ./$APP.AppDir/.junest/usr/bin/msgunfmt
rm -R -f ./$APP.AppDir/.junest/usr/bin/msguniq
rm -R -f ./$APP.AppDir/.junest/usr/bin/mtrace
rm -R -f ./$APP.AppDir/.junest/usr/bin/multirender_test
rm -R -f ./$APP.AppDir/.junest/usr/bin/mv
rm -R -f ./$APP.AppDir/.junest/usr/bin/namei
rm -R -f ./$APP.AppDir/.junest/usr/bin/ncursesw6-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/netcap
rm -R -f ./$APP.AppDir/.junest/usr/bin/nettle-hash
rm -R -f ./$APP.AppDir/.junest/usr/bin/nettle-lfib-stream
rm -R -f ./$APP.AppDir/.junest/usr/bin/nettle-pbkdf2
rm -R -f ./$APP.AppDir/.junest/usr/bin/networkctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/newgidmap
rm -R -f ./$APP.AppDir/.junest/usr/bin/newgrp
rm -R -f ./$APP.AppDir/.junest/usr/bin/newuidmap
rm -R -f ./$APP.AppDir/.junest/usr/bin/newusers
rm -R -f ./$APP.AppDir/.junest/usr/bin/nfbpf_compile
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-ct-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-ct-events
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-ct-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-exp-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-exp-delete
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-exp-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-log
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-monitor
rm -R -f ./$APP.AppDir/.junest/usr/bin/nfnl_osf
rm -R -f ./$APP.AppDir/.junest/usr/bin/nf-queue
rm -R -f ./$APP.AppDir/.junest/usr/bin/ngettext
rm -R -f ./$APP.AppDir/.junest/usr/bin/nice
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-addr-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-addr-delete
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-addr-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-class-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-class-delete
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-classid-lookup
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-class-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-cls-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-cls-delete
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-cls-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-fib-lookup
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-link-enslave
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-link-ifindex2name
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-link-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-link-name2ifindex
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-link-release
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-link-set
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-link-stats
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-list-caches
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-list-sockets
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-monitor
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-neigh-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-neigh-delete
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-neigh-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-neightbl-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-pktloc-lookup
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-qdisc-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-qdisc-delete
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-qdisc-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-route-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-route-delete
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-route-get
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-route-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-rule-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-tctree-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/nl-util-addr
rm -R -f ./$APP.AppDir/.junest/usr/bin/nm
rm -R -f ./$APP.AppDir/.junest/usr/bin/nohup
rm -R -f ./$APP.AppDir/.junest/usr/bin/nologin
rm -R -f ./$APP.AppDir/.junest/usr/bin/nproc
rm -R -f ./$APP.AppDir/.junest/usr/bin/npth-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/nscd
rm -R -f ./$APP.AppDir/.junest/usr/bin/nsenter
rm -R -f ./$APP.AppDir/.junest/usr/bin/nspr-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/nss-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/numfmt
rm -R -f ./$APP.AppDir/.junest/usr/bin/objcopy
rm -R -f ./$APP.AppDir/.junest/usr/bin/objdump
rm -R -f ./$APP.AppDir/.junest/usr/bin/ocsptool
rm -R -f ./$APP.AppDir/.junest/usr/bin/od
rm -R -f ./$APP.AppDir/.junest/usr/bin/omxregister-bellagio
rm -R -f ./$APP.AppDir/.junest/usr/bin/oomctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/openssl
rm -R -f ./$APP.AppDir/.junest/usr/bin/openvt
rm -R -f ./$APP.AppDir/.junest/usr/bin/opj_compress
rm -R -f ./$APP.AppDir/.junest/usr/bin/opj_decompress
rm -R -f ./$APP.AppDir/.junest/usr/bin/opj_dump
rm -R -f ./$APP.AppDir/.junest/usr/bin/outpsfheader
rm -R -f ./$APP.AppDir/.junest/usr/bin/p11-kit
rm -R -f ./$APP.AppDir/.junest/usr/bin/p11tool
rm -R -f ./$APP.AppDir/.junest/usr/bin/pacman
rm -R -f ./$APP.AppDir/.junest/usr/bin/pacman-conf
rm -R -f ./$APP.AppDir/.junest/usr/bin/pacman-db-upgrade
rm -R -f ./$APP.AppDir/.junest/usr/bin/pacman-key
rm -R -f ./$APP.AppDir/.junest/usr/bin/pal2rgb
rm -R -f ./$APP.AppDir/.junest/usr/bin/pam_namespace_helper
rm -R -f ./$APP.AppDir/.junest/usr/bin/pam_timestamp_check
rm -R -f ./$APP.AppDir/.junest/usr/bin/pango-list
rm -R -f ./$APP.AppDir/.junest/usr/bin/pango-segmentation
rm -R -f ./$APP.AppDir/.junest/usr/bin/pango-view
rm -R -f ./$APP.AppDir/.junest/usr/bin/partx
rm -R -f ./$APP.AppDir/.junest/usr/bin/passwd
rm -R -f ./$APP.AppDir/.junest/usr/bin/paste
rm -R -f ./$APP.AppDir/.junest/usr/bin/pathchk
rm -R -f ./$APP.AppDir/.junest/usr/bin/pcap-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/pcprofiledump
rm -R -f ./$APP.AppDir/.junest/usr/bin/pcre2-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/pcre2grep
rm -R -f ./$APP.AppDir/.junest/usr/bin/pcre2test
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdfattach
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdfdetach
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdffonts
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdfimages
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdfinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdfseparate
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdfsig
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdftocairo
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdftohtml
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdftoppm
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdftops
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdftotext
rm -R -f ./$APP.AppDir/.junest/usr/bin/pdfunite
rm -R -f ./$APP.AppDir/.junest/usr/bin/perl
rm -R -f ./$APP.AppDir/.junest/usr/bin/pg
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinentry
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinentry-curses
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinentry-emacs
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinentry-gnome3
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinentry-gtk-2
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinentry-qt
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinentry-tty
rm -R -f ./$APP.AppDir/.junest/usr/bin/pinky
rm -R -f ./$APP.AppDir/.junest/usr/bin/pipesz
rm -R -f ./$APP.AppDir/.junest/usr/bin/pivot_root
rm -R -f ./$APP.AppDir/.junest/usr/bin/pk12util
rm -R -f ./$APP.AppDir/.junest/usr/bin/pkcs1-conv
rm -R -f ./$APP.AppDir/.junest/usr/bin/pkgdata
rm -R -f ./$APP.AppDir/.junest/usr/bin/pldd
rm -R -f ./$APP.AppDir/.junest/usr/bin/pluginviewer
rm -R -f ./$APP.AppDir/.junest/usr/bin/pnm2png
rm -R -f ./$APP.AppDir/.junest/usr/bin/portablectl
rm -R -f ./$APP.AppDir/.junest/usr/bin/postprocessing_benchmark
rm -R -f ./$APP.AppDir/.junest/usr/bin/ppm2tiff
rm -R -f ./$APP.AppDir/.junest/usr/bin/pprof
rm -R -f ./$APP.AppDir/.junest/usr/bin/pprof-symbolize
rm -R -f ./$APP.AppDir/.junest/usr/bin/pr
rm -R -f ./$APP.AppDir/.junest/usr/bin/printenv
rm -R -f ./$APP.AppDir/.junest/usr/bin/printf
rm -R -f ./$APP.AppDir/.junest/usr/bin/prlimit
rm -R -f ./$APP.AppDir/.junest/usr/bin/proot-arm
rm -R -f ./$APP.AppDir/.junest/usr/bin/proptest
rm -R -f ./$APP.AppDir/.junest/usr/bin/pscap
rm -R -f ./$APP.AppDir/.junest/usr/bin/psfaddtable
rm -R -f ./$APP.AppDir/.junest/usr/bin/psfgettable
rm -R -f ./$APP.AppDir/.junest/usr/bin/psfstriptable
rm -R -f ./$APP.AppDir/.junest/usr/bin/psfxtable
rm -R -f ./$APP.AppDir/.junest/usr/bin/psicc
rm -R -f ./$APP.AppDir/.junest/usr/bin/psktool
rm -R -f ./$APP.AppDir/.junest/usr/bin/psl
rm -R -f ./$APP.AppDir/.junest/usr/bin/ptx
rm -R -f ./$APP.AppDir/.junest/usr/bin/pwck
rm -R -f ./$APP.AppDir/.junest/usr/bin/pwconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/pwd
rm -R -f ./$APP.AppDir/.junest/usr/bin/pwhistory_helper
rm -R -f ./$APP.AppDir/.junest/usr/bin/pwmconfig
rm -R -f ./$APP.AppDir/.junest/usr/bin/pwunconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/pzstd
rm -R -f ./$APP.AppDir/.junest/usr/bin/qemu-x86_64-static-arm
rm -R -f ./$APP.AppDir/.junest/usr/bin/qemu-x86_64-static-x86_64
rm -R -f ./$APP.AppDir/.junest/usr/bin/ranlib
rm -R -f ./$APP.AppDir/.junest/usr/bin/raw2tiff
rm -R -f ./$APP.AppDir/.junest/usr/bin/raw-identify
rm -R -f ./$APP.AppDir/.junest/usr/bin/rawtextdump
rm -R -f ./$APP.AppDir/.junest/usr/bin/rbash
rm -R -f ./$APP.AppDir/.junest/usr/bin/rd-curves
rm -R -f ./$APP.AppDir/.junest/usr/bin/rdjpgcom
rm -R -f ./$APP.AppDir/.junest/usr/bin/readelf
rm -R -f ./$APP.AppDir/.junest/usr/bin/readlink
rm -R -f ./$APP.AppDir/.junest/usr/bin/readprofile
rm -R -f ./$APP.AppDir/.junest/usr/bin/realpath
rm -R -f ./$APP.AppDir/.junest/usr/bin/recode-sr-latin
rm -R -f ./$APP.AppDir/.junest/usr/bin/rename
rm -R -f ./$APP.AppDir/.junest/usr/bin/renice
rm -R -f ./$APP.AppDir/.junest/usr/bin/repo-add
rm -R -f ./$APP.AppDir/.junest/usr/bin/repo-elephant
rm -R -f ./$APP.AppDir/.junest/usr/bin/repo-remove
rm -R -f ./$APP.AppDir/.junest/usr/bin/request-key
rm -R -f ./$APP.AppDir/.junest/usr/bin/reset
rm -R -f ./$APP.AppDir/.junest/usr/bin/resize2fs
rm -R -f ./$APP.AppDir/.junest/usr/bin/resizecons
rm -R -f ./$APP.AppDir/.junest/usr/bin/resizepart
rm -R -f ./$APP.AppDir/.junest/usr/bin/resolvectl
rm -R -f ./$APP.AppDir/.junest/usr/bin/rev
rm -R -f ./$APP.AppDir/.junest/usr/bin/rfkill
rm -R -f ./$APP.AppDir/.junest/usr/bin/rm
rm -R -f ./$APP.AppDir/.junest/usr/bin/rmdir
rm -R -f ./$APP.AppDir/.junest/usr/bin/rmmod
rm -R -f ./$APP.AppDir/.junest/usr/bin/rsvg-convert
rm -R -f ./$APP.AppDir/.junest/usr/bin/rtcwake
rm -R -f ./$APP.AppDir/.junest/usr/bin/runcon
rm -R -f ./$APP.AppDir/.junest/usr/bin/runuser
rm -R -f ./$APP.AppDir/.junest/usr/bin/sasldblistusers2
rm -R -f ./$APP.AppDir/.junest/usr/bin/saslpasswd2
rm -R -f ./$APP.AppDir/.junest/usr/bin/scalar
rm -R -f ./$APP.AppDir/.junest/usr/bin/sclient
rm -R -f ./$APP.AppDir/.junest/usr/bin/scmp_sys_resolver
rm -R -f ./$APP.AppDir/.junest/usr/bin/screendump
rm -R -f ./$APP.AppDir/.junest/usr/bin/script
rm -R -f ./$APP.AppDir/.junest/usr/bin/scriptlive
rm -R -f ./$APP.AppDir/.junest/usr/bin/scriptreplay
rm -R -f ./$APP.AppDir/.junest/usr/bin/secret-tool
rm -R -f ./$APP.AppDir/.junest/usr/bin/sed
rm -R -f ./$APP.AppDir/.junest/usr/bin/sensord
rm -R -f ./$APP.AppDir/.junest/usr/bin/sensors
rm -R -f ./$APP.AppDir/.junest/usr/bin/sensors-conf-convert
rm -R -f ./$APP.AppDir/.junest/usr/bin/sensors-detect
rm -R -f ./$APP.AppDir/.junest/usr/bin/seq
rm -R -f ./$APP.AppDir/.junest/usr/bin/setarch
rm -R -f ./$APP.AppDir/.junest/usr/bin/setcap
rm -R -f ./$APP.AppDir/.junest/usr/bin/setfacl
rm -R -f ./$APP.AppDir/.junest/usr/bin/setfattr
rm -R -f ./$APP.AppDir/.junest/usr/bin/setfont
rm -R -f ./$APP.AppDir/.junest/usr/bin/setkeycodes
rm -R -f ./$APP.AppDir/.junest/usr/bin/setleds
rm -R -f ./$APP.AppDir/.junest/usr/bin/setlogcons
rm -R -f ./$APP.AppDir/.junest/usr/bin/setmetamode
rm -R -f ./$APP.AppDir/.junest/usr/bin/setpalette
rm -R -f ./$APP.AppDir/.junest/usr/bin/setpriv
rm -R -f ./$APP.AppDir/.junest/usr/bin/setsid
rm -R -f ./$APP.AppDir/.junest/usr/bin/setterm
rm -R -f ./$APP.AppDir/.junest/usr/bin/setvesablank
rm -R -f ./$APP.AppDir/.junest/usr/bin/setvtrgb
rm -R -f ./$APP.AppDir/.junest/usr/bin/sexp-conv
rm -R -f ./$APP.AppDir/.junest/usr/bin/sfdisk
rm -R -f ./$APP.AppDir/.junest/usr/bin/sg
rm -R -f ./$APP.AppDir/.junest/usr/bin/sha1sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/sha224sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/sha256sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/sha384sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/sha512sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/sherlock265
rm -R -f ./$APP.AppDir/.junest/usr/bin/shlibsign
rm -R -f ./$APP.AppDir/.junest/usr/bin/showconsolefont
rm -R -f ./$APP.AppDir/.junest/usr/bin/showdb
rm -R -f ./$APP.AppDir/.junest/usr/bin/showjournal
rm -R -f ./$APP.AppDir/.junest/usr/bin/showkey
rm -R -f ./$APP.AppDir/.junest/usr/bin/showstat4
rm -R -f ./$APP.AppDir/.junest/usr/bin/showwal
rm -R -f ./$APP.AppDir/.junest/usr/bin/shred
rm -R -f ./$APP.AppDir/.junest/usr/bin/shuf
rm -R -f ./$APP.AppDir/.junest/usr/bin/signtool
rm -R -f ./$APP.AppDir/.junest/usr/bin/signver
rm -R -f ./$APP.AppDir/.junest/usr/bin/sim_client
rm -R -f ./$APP.AppDir/.junest/usr/bin/simple_dcraw
rm -R -f ./$APP.AppDir/.junest/usr/bin/sim_server
rm -R -f ./$APP.AppDir/.junest/usr/bin/site_perl
rm -R -f ./$APP.AppDir/.junest/usr/bin/size
rm -R -f ./$APP.AppDir/.junest/usr/bin/sleep
rm -R -f ./$APP.AppDir/.junest/usr/bin/sln
rm -R -f ./$APP.AppDir/.junest/usr/bin/sort
rm -R -f ./$APP.AppDir/.junest/usr/bin/sotruss
rm -R -f ./$APP.AppDir/.junest/usr/bin/spawn_console
rm -R -f ./$APP.AppDir/.junest/usr/bin/spawn_login
rm -R -f ./$APP.AppDir/.junest/usr/bin/split
rm -R -f ./$APP.AppDir/.junest/usr/bin/sprof
rm -R -f ./$APP.AppDir/.junest/usr/bin/sqldiff
rm -R -f ./$APP.AppDir/.junest/usr/bin/sqlite3
rm -R -f ./$APP.AppDir/.junest/usr/bin/sserver
rm -R -f ./$APP.AppDir/.junest/usr/bin/ssltap
rm -R -f ./$APP.AppDir/.junest/usr/bin/stat
rm -R -f ./$APP.AppDir/.junest/usr/bin/stdbuf
rm -R -f ./$APP.AppDir/.junest/usr/bin/strings
rm -R -f ./$APP.AppDir/.junest/usr/bin/strip
rm -R -f ./$APP.AppDir/.junest/usr/bin/stty
rm -R -f ./$APP.AppDir/.junest/usr/bin/su
rm -R -f ./$APP.AppDir/.junest/usr/bin/sudo
rm -R -f ./$APP.AppDir/.junest/usr/bin/sulogin
rm -R -f ./$APP.AppDir/.junest/usr/bin/sum
rm -R -f ./$APP.AppDir/.junest/usr/bin/swaplabel
rm -R -f ./$APP.AppDir/.junest/usr/bin/swapoff
rm -R -f ./$APP.AppDir/.junest/usr/bin/swapon
rm -R -f ./$APP.AppDir/.junest/usr/bin/switch_root
rm -R -f ./$APP.AppDir/.junest/usr/bin/sxpm
rm -R -f ./$APP.AppDir/.junest/usr/bin/symkeyutil
rm -R -f ./$APP.AppDir/.junest/usr/bin/sync
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-ac-power
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-analyze
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-ask-password
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-cat
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-cgls
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-cgtop
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-creds
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-cryptenroll
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-delta
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-detect-virt
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-dissect
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-escape
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-firstboot
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-hwdb
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-id128
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-inhibit
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-machine-id-setup
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-mount
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-notify
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-nspawn
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-path
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-repart
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-resolve
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-run
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-socket-activate
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-stdio-bridge
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-sysext
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-sysusers
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-tmpfiles
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-tty-ask-password-agent
rm -R -f ./$APP.AppDir/.junest/usr/bin/systemd-umount
rm -R -f ./$APP.AppDir/.junest/usr/bin/tabs
rm -R -f ./$APP.AppDir/.junest/usr/bin/tac
rm -R -f ./$APP.AppDir/.junest/usr/bin/tail
rm -R -f ./$APP.AppDir/.junest/usr/bin/taskset
rm -R -f ./$APP.AppDir/.junest/usr/bin/tee
rm -R -f ./$APP.AppDir/.junest/usr/bin/test
rm -R -f ./$APP.AppDir/.junest/usr/bin/testpkg
rm -R -f ./$APP.AppDir/.junest/usr/bin/tic
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiff2bw
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiff2pdf
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiff2ps
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiff2rgba
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffcmp
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffcp
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffcrop
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffdither
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffdump
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffgt
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffmedian
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffset
rm -R -f ./$APP.AppDir/.junest/usr/bin/tiffsplit
rm -R -f ./$APP.AppDir/.junest/usr/bin/tificc
rm -R -f ./$APP.AppDir/.junest/usr/bin/timedatectl
rm -R -f ./$APP.AppDir/.junest/usr/bin/timeout
rm -R -f ./$APP.AppDir/.junest/usr/bin/tjbench
rm -R -f ./$APP.AppDir/.junest/usr/bin/toe
rm -R -f ./$APP.AppDir/.junest/usr/bin/touch
rm -R -f ./$APP.AppDir/.junest/usr/bin/tput
rm -R -f ./$APP.AppDir/.junest/usr/bin/tr
rm -R -f ./$APP.AppDir/.junest/usr/bin/transicc
rm -R -f ./$APP.AppDir/.junest/usr/bin/trietool
rm -R -f ./$APP.AppDir/.junest/usr/bin/trietool-0.2
rm -R -f ./$APP.AppDir/.junest/usr/bin/true
rm -R -f ./$APP.AppDir/.junest/usr/bin/truncate
rm -R -f ./$APP.AppDir/.junest/usr/bin/trust
rm -R -f ./$APP.AppDir/.junest/usr/bin/tset
rm -R -f ./$APP.AppDir/.junest/usr/bin/tsort
rm -R -f ./$APP.AppDir/.junest/usr/bin/tty
rm -R -f ./$APP.AppDir/.junest/usr/bin/tune2fs
rm -R -f ./$APP.AppDir/.junest/usr/bin/tunelp
rm -R -f ./$APP.AppDir/.junest/usr/bin/tzselect
rm -R -f ./$APP.AppDir/.junest/usr/bin/uclampset
rm -R -f ./$APP.AppDir/.junest/usr/bin/uconv
rm -R -f ./$APP.AppDir/.junest/usr/bin/udevadm
rm -R -f ./$APP.AppDir/.junest/usr/bin/ul
rm -R -f ./$APP.AppDir/.junest/usr/bin/umount
rm -R -f ./$APP.AppDir/.junest/usr/bin/uname
rm -R -f ./$APP.AppDir/.junest/usr/bin/uname26
rm -R -f ./$APP.AppDir/.junest/usr/bin/unexpand
rm -R -f ./$APP.AppDir/.junest/usr/bin/unicode_start
rm -R -f ./$APP.AppDir/.junest/usr/bin/unicode_stop
rm -R -f ./$APP.AppDir/.junest/usr/bin/uniq
rm -R -f ./$APP.AppDir/.junest/usr/bin/unix_chkpwd
rm -R -f ./$APP.AppDir/.junest/usr/bin/unix_update
rm -R -f ./$APP.AppDir/.junest/usr/bin/unlink
rm -R -f ./$APP.AppDir/.junest/usr/bin/unlz4
rm -R -f ./$APP.AppDir/.junest/usr/bin/unlzma
rm -R -f ./$APP.AppDir/.junest/usr/bin/unprocessed_raw
rm -R -f ./$APP.AppDir/.junest/usr/bin/unshare
rm -R -f ./$APP.AppDir/.junest/usr/bin/unxz
rm -R -f ./$APP.AppDir/.junest/usr/bin/unzstd
rm -R -f ./$APP.AppDir/.junest/usr/bin/update-ca-trust
rm -R -f ./$APP.AppDir/.junest/usr/bin/update-desktop-database
rm -R -f ./$APP.AppDir/.junest/usr/bin/update-mime-database
rm -R -f ./$APP.AppDir/.junest/usr/bin/useradd
rm -R -f ./$APP.AppDir/.junest/usr/bin/userdbctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/userdel
rm -R -f ./$APP.AppDir/.junest/usr/bin/usermod
rm -R -f ./$APP.AppDir/.junest/usr/bin/users
rm -R -f ./$APP.AppDir/.junest/usr/bin/utmpdump
rm -R -f ./$APP.AppDir/.junest/usr/bin/uuclient
rm -R -f ./$APP.AppDir/.junest/usr/bin/uuidd
rm -R -f ./$APP.AppDir/.junest/usr/bin/uuidgen
rm -R -f ./$APP.AppDir/.junest/usr/bin/uuidparse
rm -R -f ./$APP.AppDir/.junest/usr/bin/uuserver
rm -R -f ./$APP.AppDir/.junest/usr/bin/vbltest
rm -R -f ./$APP.AppDir/.junest/usr/bin/vdir
rm -R -f ./$APP.AppDir/.junest/usr/bin/vendor_perl
rm -R -f ./$APP.AppDir/.junest/usr/bin/vercmp
rm -R -f ./$APP.AppDir/.junest/usr/bin/veritysetup
rm -R -f ./$APP.AppDir/.junest/usr/bin/vigr
rm -R -f ./$APP.AppDir/.junest/usr/bin/vipw
rm -R -f ./$APP.AppDir/.junest/usr/bin/vlock
rm -R -f ./$APP.AppDir/.junest/usr/bin/waitpid
rm -R -f ./$APP.AppDir/.junest/usr/bin/wall
rm -R -f ./$APP.AppDir/.junest/usr/bin/watchgnupg
rm -R -f ./$APP.AppDir/.junest/usr/bin/wayland-scanner
rm -R -f ./$APP.AppDir/.junest/usr/bin/wc
rm -R -f ./$APP.AppDir/.junest/usr/bin/wdctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/webpinfo
rm -R -f ./$APP.AppDir/.junest/usr/bin/webpmux
rm -R -f ./$APP.AppDir/.junest/usr/bin/whereis
rm -R -f ./$APP.AppDir/.junest/usr/bin/who
rm -R -f ./$APP.AppDir/.junest/usr/bin/whoami
rm -R -f ./$APP.AppDir/.junest/usr/bin/wipefs
rm -R -f ./$APP.AppDir/.junest/usr/bin/wmf2eps
rm -R -f ./$APP.AppDir/.junest/usr/bin/wmf2fig
rm -R -f ./$APP.AppDir/.junest/usr/bin/wmf2gd
rm -R -f ./$APP.AppDir/.junest/usr/bin/wmf2svg
rm -R -f ./$APP.AppDir/.junest/usr/bin/wmf2x
rm -R -f ./$APP.AppDir/.junest/usr/bin/write
rm -R -f ./$APP.AppDir/.junest/usr/bin/wrjpgcom
rm -R -f ./$APP.AppDir/.junest/usr/bin/x265
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-linux-gnu-c++
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-linux-gnu-g++
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-linux-gnu-gcc
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-linux-gnu-gcc-ar
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-linux-gnu-gcc-nm
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-linux-gnu-gcc-ranlib
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-pc-linux-gnu-c++
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-pc-linux-gnu-g++
rm -R -f ./$APP.AppDir/.junest/usr/bin/x86_64-pc-linux-gnu-gcc*
rm -R -f ./$APP.AppDir/.junest/usr/bin/xargs
rm -R -f ./$APP.AppDir/.junest/usr/bin/xgettext
rm -R -f ./$APP.AppDir/.junest/usr/bin/xml2-config
rm -R -f ./$APP.AppDir/.junest/usr/bin/xmlcatalog
rm -R -f ./$APP.AppDir/.junest/usr/bin/xmllint
rm -R -f ./$APP.AppDir/.junest/usr/bin/xmlwf
rm -R -f ./$APP.AppDir/.junest/usr/bin/xprop
rm -R -f ./$APP.AppDir/.junest/usr/bin/xtables-legacy-multi
rm -R -f ./$APP.AppDir/.junest/usr/bin/xtables-monitor
rm -R -f ./$APP.AppDir/.junest/usr/bin/xtables-nft-multi
rm -R -f ./$APP.AppDir/.junest/usr/bin/xtrace
rm -R -f ./$APP.AppDir/.junest/usr/bin/xz
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzcat
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzcmp
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzdec
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzdiff
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzegrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzfgrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzgrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzless
rm -R -f ./$APP.AppDir/.junest/usr/bin/xzmore
rm -R -f ./$APP.AppDir/.junest/usr/bin/yat2m
rm -R -f ./$APP.AppDir/.junest/usr/bin/yay
rm -R -f ./$APP.AppDir/.junest/usr/bin/yes
rm -R -f ./$APP.AppDir/.junest/usr/bin/yuv-distortion
rm -R -f ./$APP.AppDir/.junest/usr/bin/zdump
rm -R -f ./$APP.AppDir/.junest/usr/bin/zic
rm -R -f ./$APP.AppDir/.junest/usr/bin/zramctl
rm -R -f ./$APP.AppDir/.junest/usr/bin/zstd
rm -R -f ./$APP.AppDir/.junest/usr/bin/zstdcat
rm -R -f ./$APP.AppDir/.junest/usr/bin/zstdgrep
rm -R -f ./$APP.AppDir/.junest/usr/bin/zstdless
rm -R -f ./$APP.AppDir/.junest/usr/bin/zstdmt
rm -R -f ./$APP.AppDir/.junest/usr/include
rm -R -f ./$APP.AppDir/.junest/usr/include/alpm.h
rm -R -f ./$APP.AppDir/.junest/usr/include/alpm_list.h
rm -R -f ./$APP.AppDir/.junest/usr/lib32
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/bfd-plugins/liblto_plugin.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/crocus_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/d3d12_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/i*
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/kms_swrast_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/r*
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/nouveau_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/radeonsi_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/virtio_gpu_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/vmwgfx_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/dri/zink_dri.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/gcc
rm -R -f ./$APP.AppDir/.junest/usr/lib/git-*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libalpm.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/libalpm.so.13
rm -R -f ./$APP.AppDir/.junest/usr/lib/libalpm.so.13.0.2
rm -R -f ./$APP.AppDir/.junest/usr/lib/libasan_preinit.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcc1.so
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcc1.so.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/libcc1.so.0.0.0
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgomp.spec
rm -R -f ./$APP.AppDir/.junest/usr/lib/libitm.spec
rm -R -f ./$APP.AppDir/.junest/usr/lib/liblsan_preinit.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsanitizer.spec
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++exp.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++fs.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libstdc++_libbacktrace.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libsupc++.a
rm -R -f ./$APP.AppDir/.junest/usr/lib/libtsan_preinit.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/*.o
rm -R -f ./$APP.AppDir/.junest/usr/lib/pkgconfig/*
rm -R -f ./$APP.AppDir/.junest/usr/lib/pkgconfig/libalpm.pc
rm -R -f ./$APP.AppDir/.junest/usr/lib/systemd/system/git-daemon@.service
rm -R -f ./$APP.AppDir/.junest/usr/lib/systemd/system/git-daemon.socket
rm -R -f ./$APP.AppDir/.junest/usr/lib/sysusers.d/git.conf
rm -R -f ./$APP.AppDir/.junest/usr/man #APPIMAGES ARE NOT MENT TO HAVE MAN COMMAND
rm -R -f ./$APP.AppDir/.junest/usr/share/bash-completion
rm -R -f ./$APP.AppDir/.junest/usr/share/devtools
rm -R -f ./$APP.AppDir/.junest/usr/share/gcc-*
rm -R -f ./$APP.AppDir/.junest/usr/share/gdb
rm -R -f ./$APP.AppDir/.junest/usr/share/git
rm -R -f ./$APP.AppDir/.junest/usr/share/git-*
rm -R -f ./$APP.AppDir/.junest/usr/share/gitk
rm -R -f ./$APP.AppDir/.junest/usr/share/gitweb
rm -R -f ./$APP.AppDir/.junest/usr/share/makepkg
rm -R -f ./$APP.AppDir/.junest/usr/share/makepkg-template
rm -R -f ./$APP.AppDir/.junest/usr/share/man
rm -R -f ./$APP.AppDir/.junest/usr/share/pacman
rm -R -f ./$APP.AppDir/.junest/usr/share/perl5/vendor_perl/Git
rm -R -f ./$APP.AppDir/.junest/usr/share/perl5/vendor_perl/Git.pm
rm -R -f ./$APP.AppDir/.junest/usr/share/pkgconfig/libmakepkg.pc
rm -R -f ./$APP.AppDir/.junest/usr/share/zsh/site-functions/_pacman
rm -R -f ./$APP.AppDir/.junest/var/* #REMOVE ALL PACKAGES DOWNLOADED WITH THE PACKAGE MANAGER

# ADDITIONAL REMOVALS
#rm -R -f ./$APP.AppDir/.junest/usr/lib/dri
rm -R -f ./$APP.AppDir/.junest/usr/lib/libgo.so*
#rm -R -f ./$APP.AppDir/.junest/usr/lib/libLLVM*
rm -R -f ./$APP.AppDir/.junest/usr/lib/libOSMesa.so*
#rm -R -f ./$APP.AppDir/.junest/usr/lib/python*

# REMOVE THE INBUILT HOME
rm -R -f ./$APP.AppDir/.junest/home

# ENABLE MOUNTPOINTS
mkdir -p ./$APP.AppDir/.junest/home
mkdir -p ./$APP.AppDir/.junest/media

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./"$(cat ./$APP.AppDir/*.desktop | grep 'Name=' | head -1 | cut -c 6- | sed 's/ /-/g')"_"$VERSION""$VERSIONAUR"-x86_64.AppImage
