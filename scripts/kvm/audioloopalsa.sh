arecord -r 44100 -c 2 -f S16_LE -D loop_vm_dac_out | aplay &
arecord -r 44100 -c 2 -f S16_LE -D julia_ain_mix_44100 | aplay -D loop_vm_adc_in

