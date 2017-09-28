from ranger.gui.color import *
from ranger.colorschemes.default import Default

class Scheme(Default):
    progress_bar_color = white
    def use(self, context):
        fg, bg, attr = Default.use(self, context)

        if context.directory and not context.marked and not context.link:
            fg = white

        if context.in_titlebar and context.hostname:
            fg = red if context.bad else cyan

        return fg, bg, attr
