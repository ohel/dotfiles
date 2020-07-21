#!xbindkeys -fg
!#
; Emulate mouse with Vim-like keybindings. To get dynamic step sizes, a Guile script is used to calculate them from screen width.
; Mod1 = Alt
; Mod4 = Windows
; Mod5 = Alt gr

(use-modules (ice-9 popen))
(use-modules (ice-9 rdelim))
(define screen_width (let* ((port (open-pipe "xrandr | grep -o \"current [0-9]\\{3,4\\}\" | tr -d \"[:alpha:] \"" OPEN_READ))
    (str (read-line port)))
    (close-pipe port)
    str))

(define big_step_int (round/ (string->number screen_width) 32))
(define big_step (number->string big_step_int))
(define small_step (number->string (+ (round/ big_step_int 3) 8)))

(define mm_rel "xdotool mousemove_relative ")
(define mm_big_left (string-append mm_rel "-- -" big_step " 0"))
(define mm_big_down (string-append mm_rel "0 " big_step))
(define mm_big_up (string-append mm_rel "-- 0 -" big_step))
(define mm_big_right (string-append mm_rel big_step " 0"))
(define mm_small_left (string-append mm_rel "-- -" small_step " 0"))
(define mm_small_down (string-append mm_rel "0 " small_step))
(define mm_small_up (string-append mm_rel "-- 0 -" small_step))
(define mm_small_right (string-append mm_rel small_step " 0"))

(xbindkey-function '(Mod5 h)
    (lambda ()
        (run-command "sleep 0.1 && xdotool click --clearmodifiers 1")
    )
)

(xbindkey-function '(Mod5 l)
    (lambda ()
        (run-command "sleep 0.1 && xdotool click --clearmodifiers 3")
    )
)

(xbindkey-function '(Mod5 k)
    (lambda ()
        (run-command "xdotool click --clearmodifiers 4")
    )
)

(xbindkey-function '(Mod5 j)
    (lambda ()
        (run-command "xdotool click --clearmodifiers 5")
    )
)

(xbindkey-function '(Control Mod1 h)
    (lambda ()
        (run-command mm_big_left)
    )
)

(xbindkey-function '(Control Mod1 j)
    (lambda ()
        (run-command mm_big_down)
    )
)

(xbindkey-function '(Control Mod1 k)
    (lambda ()
        (run-command mm_big_up)
    )
)

(xbindkey-function '(Control Mod1 l)
    (lambda ()
        (run-command mm_big_right)
    )
)

(xbindkey-function '(Shift Control Mod1 h)
    (lambda ()
        (run-command mm_small_left)
    )
)

(xbindkey-function '(Shift Control Mod1 j)
    (lambda ()
        (run-command mm_small_down)
    )
)

(xbindkey-function '(Shift Control Mod1 k)
    (lambda ()
        (run-command mm_small_up)
    )
)

(xbindkey-function '(Shift Control Mod1 l)
    (lambda ()
        (run-command mm_small_right)
    )
)
