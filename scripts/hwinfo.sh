#!/usr/bin/sh
# Display some info about the system (sensors, CPU, AMD GPU) based on sensors output.

# Temporary files for two-column output.
left=$(mktemp -p /dev/shm) || exit 1
right=$(mktemp -p /dev/shm) || {
    rm -f "$left"
    exit 1
}

trap 'rm -f "$left" "$right"' EXIT HUP INT TERM

sensors_out=$(sensors 2>/dev/null)

# CPU frequencies.
# The thread_siblings_list is used ONLY to determine which logical CPU represents each physical core.
# Frequencies themselves come from /proc/cpuinfo.
printf '%s\n' '=====< CPU clocks [MHz] >=' > "$left"
core_cpus=$(
    for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*; do
        cpu=${cpu_dir##*cpu}
        siblings="$cpu_dir/topology/thread_siblings_list"

        [ -r "$siblings" ] || continue

        # e.g.:
        #   0,16  -> 0
        #   1,17  -> 1
        #   0-1   -> 0
        first=$(sed 's/,.*//; s/-.*//' "$siblings")

        if [ "$cpu" = "$first" ]; then
            printf '%s\n' "$cpu"
        fi
    done | sort -n | paste -sd, -
)

if [ -n "$core_cpus" ]; then
    awk -v wanted="$core_cpus" '
        BEGIN {
            n = split(wanted, ids, ",")
            for (i = 1; i <= n; i++)
                want[ids[i]] = 1
        }

        /^processor[[:space:]]*:/ {
            cpu = $3
            next
        }

        /^[[:space:]]*cpu MHz[[:space:]]*:/ && (cpu in want) {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)

            printf "Core %2d: %s\n", core++, value
        }
    ' /proc/cpuinfo >> "$left"
else
    # Fallback if CPU topology isn't available.
    awk '
        /^[[:space:]]*cpu MHz[[:space:]]*:/ {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)
            printf "Core %2d: %s\n", core++, value
        }
    ' /proc/cpuinfo |
        head -n "$(grep -m1 'cpu cores' /proc/cpuinfo |
            cut -d: -f2 | tr -d ' ')" >> "$left"
fi

# AMD GPU information.
printf '%s\n' "$sensors_out" |
awk '
    /^amdgpu-/ {
        in_gpu = 1
        print "\n=====< GPU clocks >=" value
        next
    }

    in_gpu {
        if ($0 ~ /^[[:space:]]*PPT:/) {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)
            sub(/[[:space:]]*\(.*/, "", value)
            print "Power:  " value
        }

        if ($0 ~ /^[[:space:]]*sclk:/) {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)
            print "Core:   " value
        }

        if ($0 ~ /^[[:space:]]*mclk:/) {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)
            print "Memory: " value
        }
    }' >> "$left"

# CPU temperatures.
printf '%s\n' '=====< Temperatures [°C] >=' > "$right"
printf '%s\n' "$sensors_out" |
    grep -E '^[[:space:]]*(Tctl|Tccd[0-9]*|Core [0-9]+):' |
    tr -d '°C' >> "$right"

# Motherboard temperature.
system_temp=$(printf '%s\n' "$sensors_out" |
    awk '/^[[:space:]]*SYSTIN:/ {
        value = $2
        sub(/[[:space:]]*\(.*/, "", value)
        gsub(/^[ \t]+|(°C)$/, "", value)
        print value
        exit
    }')
[ -n "$system_temp" ] && printf 'Motherboard:  %s\n' "$system_temp" >> "$right"

# GPU temperatures.
printf '%s\n' "$sensors_out" |
awk '
    /^amdgpu-/ {
        in_gpu = 1
        next
    }

    in_gpu {
        if ($0 ~ /^[[:space:]]*edge:/) {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)
            sub(/°C.*/, "", value)
            print "GPU core:     " value
        }

        if ($0 ~ /^[[:space:]]*junction:/) {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)
            sub(/°C.*/, "", value)
            print "GPU hotspot:  " value
        }

        if ($0 ~ /^[[:space:]]*mem:/) {
            value = $0
            sub(/^[^:]*:[[:space:]]*/, "", value)
            sub(/°C.*/, "", value)
            print "GPU memory:   " value
        }
    }' >> "$right"

# Fans.
printf '%s\n' '' >> "$right"
printf '%s\n' '=====< Fans [RPM] >=' >> "$right"
printf '%s\n' "$sensors_out" |
    awk '
        /^[[:space:]]*fan[0-9]+:/ {
            name = $1
            value = $2

            number = name
            sub(/^fan/, "", number)

            # When index is reset we are probably in GPU section.
            if (number < previous_fan)
                next

            previous_fan = number
            fans[number] = value
            next
        }

        /^[[:space:]]*pwm[0-9]+:/ {
            name = $1
            value = $2

            number = name
            sub(/^pwm/, "", number)

            # When index is reset we are probably in GPU section.
            if (number < previous_pwm)
                next

            previous_pwm = number
            pwms[number] = value
        }

        END {
            for (i in fans) {
                if (!(i in pwms) || pwms[i] + 0 > 100)
                    continue

                printf "Fan %d: %s", i, fans[i]
                printf " (%s)", pwms[i]
                printf "\n"
            }
        }
    ' >> "$right"

printf '%s\n' "$sensors_out" |
    awk '
        /^amdgpu-/ {
            in_gpu = 1
            next
        }

        in_gpu {
            if ($0 ~ /^[[:space:]]*fan1:/) {
                fan = $0
                sub(/^[^:]*:[[:space:]]*/, "", fan)
                sub(/ RPM.*/, "", fan)
            }

            if ($0 ~ /^[[:space:]]*pwm1:/) {
                pwm = $0
                sub(/^[^:]*:[[:space:]]*/, "", pwm)
                gsub(/^[ \t]+$/, "", pwm)
            }
        }

        in_gpu && /^[[:space:]]*$/ {
            if (fan != "") {
                printf "GPU:   %s", fan
                if (pwm != "")
                    printf " (%s)", pwm
                printf "\n"
            }
            exit
        }
    ' >> "$right"

# Print two columns.
paste "$left" "$right" |
    awk -F '\t' -v width=32 '{
        printf "%-*s  %s\n", width, $1, $2
    }'
