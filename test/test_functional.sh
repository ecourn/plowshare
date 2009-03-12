#!/bin/bash
set -e

# Note that *-auth files are not in the source code, you need to create
# them with your accounts if you want to run the function test suite.

ROOTDIR=$(dirname $(dirname "$(readlink -f "$0")"))
SRCDIR=$ROOTDIR/src
EXTRASDIR=$ROOTDIR/src/modules/extras
TESTSDIR=$ROOTDIR/test
source $ROOTDIR/src/lib.sh
source $ROOTDIR/test/lib.sh

download() {
    $SRCDIR/download.sh "$@" 2>/dev/null
}

download_with_debug() {
    $SRCDIR/download.sh "$@"
}

upload() {
    $SRCDIR/upload.sh "$@" 2>/dev/null
}

UPFILE="/etc/services"

## Rapidshare

RAPIDSHARE_URL="http://www.rapidshare.com/files/86545320/Tux-Trainer_25-01-2008.rar"

test_rapidshare_download_anonymous() {
    FILENAME="Tux-Trainer_25-01-2008.rar"
    assert_equal "$FILENAME" "$(download $RAPIDSHARE_URL)"
    rm -f $FILENAME
}        

test_rapidshare_upload_anonymous() {
    assert_match "http://rapidshare.com/files/" "$(upload rapidshare:$UPFILE)"
}        

test_rapidshare_upload_freezone() {
    FREEZONE_URL="https://ssl.rapidshare.com/cgi-bin/collectorszone.cgi"
    AUTH=$(cat $TESTSDIR/.rapidshare-auth)
    LOGIN_DATA='username=$USER&password=$PASSWORD'
    COOKIES=$(post_login "$AUTH" "$LOGIN_DATA" "$FREEZONE_URL" 2>/dev/null)
    PARSE="<td>Files: <b>\(.*\)<\/b>"
    FILES1=$(curl -s -b <(echo "$COOKIES") "$FREEZONE_URL" | parse $PARSE)
    URL=$(upload -a "$AUTH" rapidshare:$UPFILE)
    assert_match "http://rapidshare.com/files/" "$URL" 
    FILES2=$(curl -s -b <(echo "$COOKIES") "$FREEZONE_URL" | parse $PARSE)
    assert_equal $(($FILES1+1)) $FILES2    
}        

## Megaupload

MEGAUPLOAD_URL="http://www.megaupload.com/?d=ieo1g52v"

test_megaupload_download_anonymous() {
    FILENAME="testmotion2.mp4"
    assert_equal "$FILENAME" "$(download $MEGAUPLOAD_URL)"
    rm -f $FILENAME
}        

test_megaupload_download_a_password_protected_file() {
    URL="http://www.megaupload.com/?d=4YF0D6A3"
    FILENAME="asound.conf"
    assert_equal "$FILENAME" "$(download -p test1 $URL)"
    rm -f $FILENAME
}

test_megaupload_download_member() {
    AUTH=$(cat $TESTSDIR/.megaupload-auth)
    OUTPUT=$(download_with_debug -a "$AUTH" $MEGAUPLOAD_URL 2>&1)
    assert_match "^Waiting 26 seconds" "$OUTPUT"
    URL=$(echo "$OUTPUT" | tail -n1)
    FILENAME="testmotion2.mp4"
    assert_equal "$FILENAME" "$URL"
    rm -f $FILENAME
}        

test_megaupload_download_premium() {
    AUTH=$(cat $TESTSDIR/.megaupload-premium-auth)
    OUTPUT=$(download -a "$AUTH" $MEGAUPLOAD_URL)
    FILENAME="testmotion2.mp4"
    assert_equal "$FILENAME" "$OUTPUT" || return 1 
    rm -f $FILENAME
}        

test_megaupload_upload_anonymous() {
    URL="$(upload -d 'Plowshare test' megaupload:$UPFILE)"
    assert_match "http://www.megaupload.com/?d=" "$URL"
}        

test_megaupload_upload_member() {
    AUTH=$(cat $TESTSDIR/.megaupload-auth)
    URL=$(upload -d 'Plowshare test' -a "$AUTH" megaupload:$UPFILE)
    assert_equal "http://www.megaupload.com/?d=IDXJG1RN" "$URL"
}        

test_megaupload_upload_premium() {
    AUTH=$(cat $TESTSDIR/.megaupload-premium-auth)
    URL=$(upload -a "$AUTH" -p "mypassword" \
        -d 'Plowshare test' megaupload:$UPFILE)
    assert_equal "http://www.megaupload.com/?d=115BX7GS" "$URL"
    assert_return 0 'match "name=\"filepassword\"" "$(curl $URL)"'
}        

## 2Shared

SHARED_URL="http://www.2shared.com/file/4446939/c9fd70d6/Test.html"

test_2shared_download() {
    FILENAME="Test.mp3"
    assert_equal "$FILENAME" "$(download $SHARED_URL)"
    rm -f $FILENAME
}        

test_2shared_download_and_get_only_link() {
    URL="2shared.com/download/4446939/c9fd70d6/Test.mp3"
    assert_match "$URL" "$(download -l $SHARED_URL)"    
}

test_2shared_download_using_file_argument_and_mark_as_downloaded() {
    URL="2shared.com/download/4446939/c9fd70d6/Test.mp3"
    TEMP=$(create_tempfile)
    echo "$SHARED_URL" > $TEMP
    assert_match "$URL" "$(download -l -m "$TEMP")"
    assert_match "^#$SHARED_URL" "$(cat $TEMP)"
    rm -f "$TEMP"    
}        
        
test_2shared_upload() {
    assert_match "^http://www.2shared.com/file/" "$(upload 2shared:$UPFILE)"
}        

## Badongo

BADONGO_URL="http://www.badongo.com/file/13153017"

test_badongo_download() {
    FILENAME="Kandinsky_Wassily_-_De_lo_espiritual_en_el_arte.rar"
    assert_equal "$FILENAME" "$(download $BADONGO_URL)"
    rm -f $FILENAME
}        

### Setup script

INSTALLED="usr
usr/local
usr/local/bin
usr/local/bin/plowdown
usr/local/bin/plowup
usr/local/share
usr/local/share/doc
usr/local/share/doc/plowshare
usr/local/share/doc/plowshare/CHANGELOG
usr/local/share/doc/plowshare/COPYING
usr/local/share/doc/plowshare/README
usr/local/share/plowshare
usr/local/share/plowshare/download.sh
usr/local/share/plowshare/lib.sh
usr/local/share/plowshare/modules
usr/local/share/plowshare/modules/2shared.sh
usr/local/share/plowshare/modules/badongo.sh
usr/local/share/plowshare/modules/mediafire.sh
usr/local/share/plowshare/modules/megaupload.sh
usr/local/share/plowshare/modules/rapidshare.sh
usr/local/share/plowshare/upload.sh"

UNINSTALLED="usr
usr/local
usr/local/bin
usr/local/share
usr/local/share/doc"

test_setup_script() {
    TEMPDIR=$(mktemp -d)
    assert_return 0 "DESTDIR=$TEMPDIR $ROOTDIR/setup.sh install"
    assert_equal "$INSTALLED" \
        "$(find $TEMPDIR | sed "s#^$TEMPDIR/\?##" | grep -v "^$" | sort)"
    assert_return 0 "DESTDIR=$TEMPDIR $ROOTDIR/setup.sh uninstall"
    assert_equal "$UNINSTALLED" \
        "$(find $TEMPDIR | sed "s#^$TEMPDIR/\?##" | grep -v "^$" | sort)"
    rm -rf $TEMPDIR
}

#

## Badongo

MEDIAFIRE_URL="http://www.mediafire.com/?mokvnz2y43y"

test_mediafire_download() {
    FILENAME="Nature+Medicine.pdf"
    assert_equal "$FILENAME" "$(download $MEDIAFIRE_URL)"
    rm -f $FILENAME
}        
 
run_tests "$@"
