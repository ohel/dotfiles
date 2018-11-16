let g:airline#themes#minigun#palette = {}

let s:guibg = '#262626'
let s:guibg2 = '#303030'
let s:termbg = 235
let s:termbg2= 236

let s:N1 = [ s:guibg , '#5fafff' , s:termbg , 75 ] " center status line background color
let s:N2 = [ '#c0c0c0' , s:guibg2, 7 , s:termbg2 ] " file encoding area color
let s:N3 = [ '#c0c0c0' , s:guibg, 7 , s:termbg] " center status line text color
let g:airline#themes#minigun#palette.normal = airline#themes#generate_color_map(s:N1, s:N2, s:N3)
let g:airline#themes#minigun#palette.normal_modified = {
      \ 'airline_c': [ '#c0c0c0' , s:guibg, 7     , s:termbg    , ''     ] ,
      \ } " center status line text color when buffer modified

let s:I1 = [ s:guibg, '#ff87ff' , s:termbg , 213 ]
let s:I2 = [ '#c0c0c0' , s:guibg2, 7 , s:termbg2 ]
let s:I3 = [ '#c0c0c0' , s:guibg, 7 , s:termbg]
let g:airline#themes#minigun#palette.insert = airline#themes#generate_color_map(s:I1, s:I2, s:I3)
let g:airline#themes#minigun#palette.insert_modified = copy(g:airline#themes#minigun#palette.normal_modified)
let g:airline#themes#minigun#palette.insert_paste = {
      \ 'airline_a': [ s:I1[0]   , '#ff00ff' , s:I1[2] , 201     , ''     ] ,
      \ }
let g:airline#themes#minigun#palette.replace = {
      \ 'airline_a': [ s:I1[0]   , '#ff00ff' , s:I1[2] , 201     , ''     ] ,
      \ }
let g:airline#themes#minigun#palette.replace_modified = copy(g:airline#themes#minigun#palette.normal_modified)

let s:V1 = [ s:guibg, '#00ffff' , s:termbg , 51 ]
let s:V2 = [ '#c0c0c0' , s:guibg2, 7 , s:termbg2 ]
let s:V3 = [ '#c0c0c0' , s:guibg, 7 , s:termbg]
let g:airline#themes#minigun#palette.visual = airline#themes#generate_color_map(s:V1, s:V2, s:V3)
let g:airline#themes#minigun#palette.visual_modified = copy(g:airline#themes#minigun#palette.normal_modified)

let s:IA  = [ '#4e4e4e' , s:guibg  , 239 , s:termbg  , '' ]
let s:IA2 = [ '#4e4e4e' , s:guibg2 , 239 , s:termbg2 , '' ]
let g:airline#themes#minigun#palette.inactive = airline#themes#generate_color_map(s:IA, s:IA2, s:IA2)
let g:airline#themes#minigun#palette.inactive_modified = {
      \ 'airline_c': [ '#df0000', '', 160, '', '' ] ,
      \ }

let g:airline_mode_map = {
    \ '__' : '--',
    \ 'n'  : 'N',
    \ 'i'  : 'I',
    \ 'R'  : 'R',
    \ 'c'  : 'C',
    \ 'v'  : 'V',
    \ 'V'  : 'V-L',
    \ '' : 'V-B',
    \ 's'  : 'S',
    \ 'S'  : 'S-L',
    \ '' : 'S-B',
    \ 't'  : 'T',
    \ }
