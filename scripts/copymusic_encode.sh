#!/bin/bash
# Copy and encode music (either to Ogg Vorbis or MP3), preserving simple metadata tags.
# Replaygain info is applied (lossy) in the process.

destination="$1"
filein=$(echo $2 | sed s/\'$// | sed s/^\'// | sed s/\'\'\'/\'/g)
overridealbum=$(echo $3 | sed s/_/" "/g)
fileid=$(mutagen-inspect "$filein" | head -n 2 | tail -n 1)
typeflac=$(echo $fileid | grep FLAC)
typeogg=$(echo $fileid | grep Vorbis)
typemp3=$(echo $fileid | grep MPEG)

if test "X$typeflac" != "X"; then

    tagalbum="album="
    tagtrack="tracknumber="
    tagartist="artist="
    tagtitle="title="

elif test "X$typeogg" != "X"; then

    tagalbum="album="
    tagtrack="tracknumber="
    tagartist="artist="
    tagtitle="title="

elif test "X$typemp3" != "X"; then

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

if test "empty$meta_track" == "empty"
    then meta_track="XX"
fi
if test "empty$meta_album" == "empty"
    then meta_album="unknown album"
fi
if test "empty$overridealbum" != "empty"
    then meta_album=$overridealbum
fi
if test "empty$meta_artist" == "empty"
    then meta_artist="unknown artist"
fi
if test "empty$meta_title" == "empty"
    then meta_title="unknown title"
fi

echo -n "*"
if test "X$typeflac" != "X"; then
    tmpfile=$(tempfile -d /dev/shm/ --suffix=".ogg")

    # For MP3:
    #tmpfile=$(tempfile -d /dev/shm/ --suffix=".mp3")
    #flac -c -s -d "$filein" 2>/dev/null | lame --silent --preset extreme --noreplaygain --id3v2-only --tt "$meta_title" --ta "$meta_artist" --tl "$meta_album" --tn "$meta_track" - $tmpfile
    # For replaygain: --apply-replaygain-which-is-not-lossless=t

    flac -c -s -d "$filein" 2>/dev/null | oggenc --resample 44100 -Q -q 7 -a "$meta_artist" -l "$meta_album" -t "$meta_title" -N "$meta_track" -c "replaygain_album_peak=$meta_rg_ap" -c "replaygain_track_peak=$meta_rg_tp" -c "replaygain_album_gain=$meta_rg_ag" -c "replaygain_track_gain=$meta_rg_tg" -o $tmpfile -
    source="$tmpfile"

elif test "X$typeogg" != "X"; then
    tmpfile=$(tempfile -d /dev/shm/ --suffix=".ogg")

    # For MP3:
    #tmpwav=$(tempfile -d /dev/shm/ --suffix=".wav")
    #oggdec -Q -o $tmpwav "$filein"
    #lame --silent --preset extreme --noreplaygain --id3v2-only --tt "$meta_title" --ta "$meta_artist" --tl "$meta_album" --tn "$meta_track" $tmpwav $tmpfile
    #rm $tmpwav
    #source="$tmpfile"

    source="$filein"

elif test "X$typemp3" != "X"; then
    tmpfile=$(tempfile -d /dev/shm/ --suffix=".mp3")
    source="$filein"
fi
echo -n "*"

mkdir -p $destination/"$meta_album"
if [ ${#meta_track} -lt 2 ]
then
    padding="0"
else
    padding=""
fi
cp $source $destination/"$meta_album"/"$padding""$meta_track"_$(echo $meta_title | tr -c -d "[:alnum:]")_$(basename $tmpfile)
rm $tmpfile

echo -n "*"

exit

