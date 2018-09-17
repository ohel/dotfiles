hi clear
let g:colors_name="minigun"

hi Normal guifg=#c0c0c0 guibg=#303030 ctermfg=007 ctermbg=236

hi Cursor       guibg=#eeeeee guifg=#000000 ctermbg=255 ctermfg=000
hi CursorLine   guibg=#000000 gui=none ctermbg=000
hi CursorColumn guibg=#444444 gui=none ctermbg=238

hi DiffAdd      guifg=#ffdf87 guibg=#af875f gui=none ctermfg=222 ctermbg=137
hi DiffChange   guifg=#5fafff guibg=#005f87 gui=none ctermfg=075 ctermbg=024
hi DiffText     guifg=#87ff00 guibg=#5f8700 gui=none ctermfg=118 ctermbg=064
hi DiffDelete   guifg=#000000 guibg=#000000 gui=none ctermfg=000 ctermbg=000

hi Number       guifg=#eeeeee gui=none ctermfg=255

hi Folded       guifg=#ffffff guibg=#000000 gui=none ctermfg=015 ctermbg=000
hi vimFold      guifg=#ffffff guibg=#000000 gui=none ctermfg=015 ctermbg=000
hi FoldColumn   guifg=#ffffff guibg=#000000 gui=none ctermfg=015 ctermbg=000

hi LineNr       guifg=#585858 guibg=#303030 gui=none ctermfg=240 ctermbg=236
hi NonText      guifg=#585858 guibg=#303030 gui=none ctermfg=240 ctermbg=236
hi Folded       guifg=#585858 guibg=#303030 gui=none ctermfg=240 ctermbg=236
hi FoldeColumn  guifg=#585858 guibg=#303030 gui=none ctermfg=240 ctermbg=236

hi VertSplit    guifg=#3a3a3a guibg=#3a3a3a gui=none ctermfg=237 ctermbg=237
hi StatusLine   guibg=#3a3a3a guifg=#ffffff gui=none ctermfg=015 ctermbg=237
hi StatusLineNC guibg=#3a3a3a guifg=#808080 gui=none ctermfg=244 ctermbg=237

hi ModeMsg      guifg=#eeeeee gui=none ctermfg=255
hi MoreMsg      guifg=#eeeeee gui=none ctermfg=255
hi Visual       guifg=#ffffff guibg=#585858 gui=none ctermfg=015 ctermbg=240
hi VisualNOS    guifg=#ffffff guibg=#0000ff gui=none ctermfg=015 ctermbg=012
hi IncSearch    guifg=#ff0000 guibg=#ffffff gui=none ctermfg=009 ctermbg=015
hi Search       guifg=#ffffff guibg=#00ffff gui=none ctermfg=015 ctermbg=014
hi SpecialKey   guifg=#ffff00 gui=none ctermfg=011

hi Title        guifg=#ff0000 gui=none ctermfg=009
hi WarningMsg   guifg=#ff0000 gui=none ctermfg=009
hi Number       guifg=#00ffff gui=none ctermfg=014

hi MatchParen   guifg=#ffffff guibg=#585858 ctermfg=015 ctermbg=240
hi Comment      guifg=#8a8a8a gui=none ctermfg=245
hi Constant     guifg=#ff5f00 gui=none ctermfg=202
hi String       guifg=#ffff00 gui=none ctermfg=011
hi Identifier   guifg=#00ffff gui=none ctermfg=014
hi Statement    guifg=#ffffff gui=none ctermfg=015
hi PreProc      guifg=#ffffff gui=none ctermfg=015
hi Type         guifg=#87ff00 gui=none ctermfg=118
hi Special      guifg=#ffaf5f gui=none ctermfg=215
hi Underlined   guifg=#af87af gui=underline ctermfg=139
hi Directory    guifg=#5f87ff gui=none ctermfg=069
hi Ignore       guifg=#585858 gui=none ctermfg=240
hi Todo         guifg=#ffffff guibg=#ff5f00 gui=none ctermfg=015 ctermbg=202
hi Function     guifg=#af87af gui=none ctermfg=139

hi WildMenu     guifg=#ffffff guibg=#005faf gui=none ctermfg=015 ctermbg=025

hi Pmenu        guifg=#c0c0c0 guibg=#000000 gui=none ctermfg=007 ctermbg=000
hi PmenuSel     guifg=#ffffff guibg=#005faf gui=none ctermfg=015 ctermbg=025
hi PmenuSbar    guifg=#444444 guibg=#444444 gui=none ctermfg=238 ctermbg=238
hi PmenuThumb   guifg=#8a8a8a guibg=#8a8a8a gui=none ctermfg=245 ctermbg=245

hi cppSTLType   guifg=#5f87ff gui=none ctermfg=069

hi spellBad     guisp=#ffaf5f gui=none ctermfg=215
hi spellCap     guisp=#87ff00 gui=none ctermfg=118
hi spellRare    guisp=#af87af gui=none ctermfg=139
hi spellLocal   guifg=#5f87ff gui=none ctermfg=069

hi link cppSTL         Function
hi link Error          Todo
hi link Character      Number
hi link rubySymbol     Number
hi link htmlTag        htmlEndTag
hi link htmlLink       Underlined
hi link pythonFunction Identifier
hi link Question       Type
hi link CursorIM       Cursor
hi link VisualNOS      Visual
hi link xmlTag         Identifier
hi link xmlTagName     Identifier
hi link shDeref        Identifier
hi link shVariable     Function
hi link rubySharpBang  Special
hi link perlSharpBang  Special
hi link schemeFunc     Statement

hi TabLine      guifg=#a8a8a8 guibg=#262626 gui=none ctermfg=248 ctermbg=235
hi TabLineFill  guifg=#585858 guibg=#262626 gui=none ctermfg=240 ctermbg=235
hi TabLineSel   guifg=#ffffff gui=none ctermfg=015
