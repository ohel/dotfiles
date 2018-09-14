buffer_size=512
arecord -r 44100 -c 2 -f S16_LE -D loop_vm_dac_out --buffer-size=$buffer_size | aplay --buffer-size=$buffer_size &
arecord -r 44100 -c 2 -f S16_LE -D julia_ain_mix_44100 --buffer-size=$buffer_size | aplay -D loop_vm_adc_in --buffer-size=$buffer_size
