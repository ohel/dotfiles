#!/bin/sh
# Given a directory of images (images_dir):
# 1. create a blend of two random images with a certain transparency step (step_percentage) using ImageMagick (needs magick and convert)
# 2. fade the desktop background using feh with a specified millisecond interval (blend_interval_ms) during transition
# 3. wait for some time (change_interval_s)
# 4. repeat, starting the next blend with the current desktop background from last round
# If ~/.themes/background is a symbolic link to background image, it is updated as well after blending.

change_interval_s=${1:-1800}
images_dir=${2:-~/.themes/backgrounds}
tmp_dir=${3:-~/.cache/background_blender}

step_percentage=2
blend_interval_ms=50

mkdir -p $tmp_dir
cd $tmp_dir

# Initial images.
count=$(ls -1 $images_dir/ | wc -l)
image_a=$(ls -1 $images_dir/ | head -n $(shuf -i 1-$count -n 1) | tail -n 1)
image_b=$(ls -1 $images_dir/ | head -n $(shuf -i 1-$count -n 1) | tail -n 1)
[ -L ~/.themes/background ] && rm ~/.themes/background && ln -s $images_dir/$image_a ~/.themes/background
feh --no-fehbg --bg-fill $images_dir/$image_a

while [ 1 ]
do
    # Create fading images.
    percentage=0
    while [ $percentage -le 100 ]
    do
        p_a=$(expr 100 - $percentage)
        p_b=$percentage
        percentage=$(expr $percentage + $step_percentage)
        [ $percentage -gt 100 ] && percentage=100
        if [ $p_a -eq 100 ]
        then
            if [ "$image_a" = "blend_100.png" ]
            then
                cp $image_a blend_0.png
            else
                image_a=$images_dir/$image_a
                convert -quality 05 $image_a blend_0.png
            fi
            continue
        elif [ $p_b -eq 100 ]
        then
            convert -quality 05 $images_dir/$image_b blend_100.png
            break
        fi
        magick $image_a $images_dir/$image_b -define compose:args=$p_b,$p_a -compose blend -composite blend_$p_b.jpg
    done

    sleep $change_interval_s

    # Fade images.
    percentage=0
    while [ $percentage -le 100 ]
    do
        time1=$(date +%s%N | cut -b1-13)
        feh --no-fehbg --bg-fill blend_$percentage.???
        time2=$(date +%s%N | cut -b1-13)
        time_diff=$(expr $time2 - $time1)
        time_wait=$(expr $blend_interval_ms - $time_diff)
        [ $time_wait -gt 0 ] && sleep $(echo "scale=3; $time_wait / 1000" | bc)
        percentage=$(expr $percentage + $step_percentage)
    done

    # Start next blend from current background image.
    image_a=blend_100.png
    count=$(ls -1 $images_dir/ | wc -l)
    image_b=$(ls -1 $images_dir/ | head -n $(shuf -i 1-$count -n 1) | tail -n 1)

    # Update symlink to background if one exists.
    [ -L ~/.themes/background ] && rm ~/.themes/background && ln -s $tmp_dir/$image_a ~/.themes/background
done
