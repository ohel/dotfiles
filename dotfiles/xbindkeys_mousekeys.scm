#!xbindkeys -fg
!#
; Mouse events are not registered if using a simple control key mapping (xdotool keydown Control) while the mapped key is down.
; Therefore a generic thumb + scroll wheel zoom would not work, as the wheel events are not registered.
; To achieve the zoom, we map: mouse thumb button + wheel -> control + +/-. This needs a Guile script.
; In this config, button 11 is the thumb button, 4 is wheel up and 5 is wheel down.
; Additionally, for tilt wheel or horizontal scroll wheel feature, mouse buttons 6/7 are mapped to send alt+left/right for back and forward.

(define (thumb-binding)
    (xbindkey-function '("b:11") scroll-binding)
)

(define (reset)
    (ungrab-all-keys)
    ; Removes scroll-binding
    (remove-all-keys)
    (thumb-binding)
    (grab-all-keys)
)

(define (scroll-binding)
    ; Removes thumb-binding
    (remove-all-keys)

    ; Scroll up
    (xbindkey-function '("b:4")
        (lambda ()
            (run-command "xdotool key ctrl+plus")
        )
    )

    ; Scroll down
    (xbindkey-function '("b:5")
        (lambda ()
            (run-command "xdotool key ctrl+minus")
        )
    )

    ; Scroll left
    (xbindkey-function '("b:6")
        (lambda ()
            (run-command "xdotool key alt+Left")
        )
    )

    ; Scroll right
    (xbindkey-function '("b:7")
        (lambda ()
            (run-command "xdotool key alt+Right")
        )
    )

    (xbindkey-function '(release "b:11")
        (lambda ()
            (reset)
        )
    )
)

(thumb-binding)
