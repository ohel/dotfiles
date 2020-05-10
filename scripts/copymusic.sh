#!/bin/bash
# Copy and encode music to a given destination ($1, default ./). Used by drag'n'dropping files from media player playlist to a terminal window, for copying into a mobile phone.
# Encoding is either Ogg Vorbis (default) or MP3 ($2 equals "mp3"), preserving simple metadata tags.
# Ogg is encoded to MP3 (for crappy player hardware) but not vice versa.
# Requires mutagen-inspect and oggenc.
# The encoding process is naively parallelized.

destination=$(readlink -f ${1:-./})
parallel_processes=7
encoding="ogg"
[ "$#" -gt 1 ] && [ "$2" = "mp3" ] && encoding="mp3"

encode() {
    tempdir=~/.cache
    encoding=$1
    dest_dir="$2"
    filein=$(echo $3 | sed s/\'$// | sed s/^\'// | sed s/\'\'\'/\'/g)
    override_album=$(echo $4 | sed s/_/" "/g)
    fileid=$(mutagen-inspect "$filein" | head -n 2 | tail -n 1)
    typeflac=$(echo $fileid | grep FLAC)
    typeogg=$(echo $fileid | grep Vorbis)
    typemp3=$(echo $fileid | grep MPEG)

    # Default for ogg and flac.
    tagalbum="album="
    tagtrack="tracknumber="
    tagartist="artist="
    tagtitle="title="
    if [ "$typemp3" ]
    then
        tagalbum="^TALB="
        tagtrack="^TRCK="
        tagartist="^TPE1="
        tagtitle="^TIT2="
    fi

    meta_album=$(mutagen-inspect "$filein" | grep -a $tagalbum | cut -d '=' -f 2 | tr -d -c "[:alnum:] ")
    meta_track=$(mutagen-inspect "$filein" | grep -a $tagtrack | cut -d '=' -f 2 | cut -f 1 -d '/' | tr -d -c "[:alnum:] ")
    meta_artist=$(mutagen-inspect "$filein" | grep -a $tagartist | cut -d '=' -f 2 | tr -d -c "[:alnum:] ")
    meta_title=$(mutagen-inspect "$filein" | grep -a $tagtitle | cut -d '=' -f 2 | tr -d -c "[:alnum:] ")
    meta_rg_ap=$(mutagen-inspect "$filein" | grep -a "replaygain_album_peak" | cut -d '=' -f 2)
    meta_rg_tp=$(mutagen-inspect "$filein" | grep -a "replaygain_track_peak" | cut -d '=' -f 2)
    meta_rg_ag=$(mutagen-inspect "$filein" | grep -a "replaygain_album_gain" | cut -d '=' -f 2)
    meta_rg_tg=$(mutagen-inspect "$filein" | grep -a "replaygain_track_gain" | cut -d '=' -f 2)

    meta_track="${meta_track:-"XX"}"
    meta_album="${override_album:-$meta_album}"
    meta_album="${meta_album:-"unknown album"}"
    meta_artist="${meta_artist:-"unknown artist"}"
    meta_title="${meta_title:-"unknown title"}"

    echo -n "*"
    if [ "$typeflac" ]
    then
        tmpfile=$(tempfile -d $tempdir/ --suffix=".ogg")
        if [ "$encoding" == "mp3" ]
        then
            tmpfile=$(tempfile -d $tempdir/ --suffix=".mp3")
            flac -c -s -d "$filein" 2>/dev/null | lame --silent --preset extreme --noreplaygain --id3v2-only --tt "$meta_title" --ta "$meta_artist" --tl "$meta_album" --tn "$meta_track" - $tmpfile
        elif [ "$encoding" == "ogg" ]
        then
            flac -c -s -d "$filein" 2>/dev/null | oggenc --resample 44100 -Q -q 7 -a "$meta_artist" -l "$meta_album" -t "$meta_title" -N "$meta_track" -c "replaygain_album_peak=$meta_rg_ap" -c "replaygain_track_peak=$meta_rg_tp" -c "replaygain_album_gain=$meta_rg_ag" -c "replaygain_track_gain=$meta_rg_tg" -o $tmpfile -
        fi
        source="$tmpfile"

    elif [ "$typeogg" ]
    then
        tmpfile=$(tempfile -d $tempdir/ --suffix=".ogg")
        if [ "$encoding" == "mp3" ]
        then
            tmpwav=$(tempfile -d $tempdir/ --suffix=".wav")
            oggdec -Q -o $tmpwav "$filein"
            lame --silent --preset extreme --noreplaygain --id3v2-only --tt "$meta_title" --ta "$meta_artist" --tl "$meta_album" --tn "$meta_track" $tmpwav $tmpfile
            rm $tmpwav
            source="$tmpfile"
        elif [ "$encoding" == "ogg" ]
        then
            source="$filein"
        fi

    elif [ "$typemp3" ]
    then
        tmpfile=$(tempfile -d $tempdir/ --suffix=".mp3")
        source="$filein"
    fi
    echo -n "*"

    mkdir -p "$dest_dir"/"$meta_album"
    padding=""
    [ ${#meta_track} -lt 2 ] && padding="0"

    cp "$source" "$dest_dir"/"$meta_album"/"$padding""$meta_track"_$(echo $meta_title | tr -c -d "[:alnum:]")_$(basename "$tmpfile")
    rm "$tmpfile"

    echo -n "*"
}

export -f encode

while [ 1 ]
do
    echo "Drag flac, ogg or mp3 files to the terminal window to start copying:"
    read list

    ! [ "$list" ] && exit 0

    echo "Type in an album name or leave empty to read from tags:"
    read album
    echo "COPYING AND ENCODING:"
    echo -n "| 0% "
    spacecount=$(expr $(expr $(echo $list | wc -w) \* 3) - 11)
    while [ $spacecount -gt 0 ]
    do
        spacecount=$(expr $spacecount - 1)
        echo -n " "
    done
    echo "100% |"
    album=$(echo "$album" | sed s/" "/_/)

    # The underscore is a placeholder for $0.
    echo $list | tr " " "\000" | xargs --null -I {} -n 1 -P $parallel_processes bash -c 'encode "$@"' _ $encoding "$destination" "{}" "$album"

    echo ""
    echo "All done."
    echo ""
done
