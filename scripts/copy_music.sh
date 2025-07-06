#!/usr/bin/bash
# Copy and encode music to a given destination ($1, default ./). Used by drag'n'dropping files from media player playlist to a terminal window, for copying into a mobile phone.
# Encoding is either AAC (default), OGG ($2 = "ogg") or MP3 ($2 = "mp3"), preserving simple metadata tags.
# Requires mutagen-inspect and either ffmpeg with fdk-aac libs, oggenc or lame encoder, faad for decoding.
# The encoding process is naively parallelized.

destination=$(readlink -f ${1:-./})
parallel_processes=7
encoding="aac"
[ "$#" -gt 1 ] && [ "$2" = "mp3" ] && encoding="mp3"
[ "$#" -gt 1 ] && [ "$2" = "ogg" ] && encoding="ogg"

encode() {
    tempdir=~/.cache
    encoding=$1
    dest_dir="$2"
    filein=$(echo $3 | sed s/\'$// | sed s/^\'// | sed s/\'\'\'/\'/g)
    override_album=$(echo $4 | sed s/_/" "/g)
    fileid=$(mutagen-inspect "$filein" | head -n 2 | tail -n 1)
    typeflac=$(echo $fileid | grep FLAC)
    typeogg=$(echo $fileid | grep Vorbis)
    typeaac=$(echo $fileid | grep AAC)
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
    elif [ "$typeaac" ]
    then
        tagalbum="^©alb="
        tagtrack="^trkn="
        tagartist="^©ART="
        tagtitle="^©nam="
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

    wavfile=$(mktemp -p $tempdir/ --suffix=".wav")
    if [ "$typeflac" ]
    then
        flac -c -s -d "$filein" -f -o $wavfile
    elif [ "$typeogg" ]
    then
        if [ "$encoding" == "ogg" ]
        then
            origin="$filein"
        else
            oggdec -Q -o $wavfile "$filein"
        fi
    elif [ "$typemp3" ]
    then
        if [ "$encoding" == "mp3" ]
        then
            origin="$filein"
        else
            lame --decode "$filein" $wavfile
        fi
    elif [ "$typeaac" ]
    then
        if [ "$encoding" == "aac" ]
        then
            origin="$filein"
        else
            faad -o $wavfile "$filein"
        fi
    fi
    echo -n "*"

    tmpfile=""
    if [ "$encoding" == "mp3" ]
    then
        tmpfile=$(mktemp -p $tempdir/ --suffix=".mp3")
        lame --silent --preset extreme --noreplaygain --id3v2-only --tt "$meta_title" --ta "$meta_artist" --tl "$meta_album" --tn "$meta_track" $wavfile $tmpfile
    elif [ "$encoding" == "ogg" ]
    then
        oggenc --resample 44100 -Q -q 7 -a "$meta_artist" -l "$meta_album" -t "$meta_title" -N "$meta_track" -c "replaygain_album_peak=$meta_rg_ap" -c "replaygain_track_peak=$meta_rg_tp" -c "replaygain_album_gain=$meta_rg_ag" -c "replaygain_track_gain=$meta_rg_tg" -o $tmpfile $wavfile
    elif [ "$encoding" == "aac" ]
    then
        tmpfile=$(mktemp -p $tempdir/ --suffix=".m4a")
        ffmpeg -loglevel error -y -i $wavfile -c:a libfdk_aac -vbr 5 -cutoff 20000 -ar 44100 \
        -metadata artist="$meta_artist" -metadata album="$meta_album" -metadata title="$meta_title" -metadata track="$meta_track" \
        $tmpfile
        # Not supported by ffmpeg, not even via -map_metadata
        # ----:com.apple.iTunes:replaygain_album_gain="MP4FreeForm(b'$meta_rg_ag', <AtomDataType.UTF8: 1>)
        # ----:com.apple.iTunes:replaygain_album_peak="MP4FreeForm(b'$meta_rg_ap', <AtomDataType.UTF8: 1>)
        # ----:com.apple.iTunes:replaygain_track_gain="MP4FreeForm(b'$meta_rg_tg', <AtomDataType.UTF8: 1>)
        # ----:com.apple.iTunes:replaygain_track_peak="MP4FreeForm(b'$meta_rg_tp', <AtomDataType.UTF8: 1>)
    fi
    echo -n "*"

    mkdir -p "$dest_dir"/"$meta_album"
    padding=""
    [ ${#meta_track} -lt 2 ] && padding="0"

    [ "$tmpfile" ] && origin=$tmpfile
    cp "$origin" "$dest_dir"/"$meta_album"/"$padding""$meta_track"_$(echo $meta_title | tr -c -d "[:alnum:]")_$(basename "$origin")
    rm $wavfile
    [ "$tmpfile" ] && rm $tmpfile
    echo -n "*"
}

export -f encode

while [ 1 ]
do
    echo "Drag flac, ogg, mp3 or aac files to the terminal window to start copying:"
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
