scriptencoding utf-8
scriptversion 4

function! project_guide#open(dirs_pattern) abort
  if v:version < 802
    echohl ErrorMsg
    echomsg 'project-guide: Please use Vim 8.2 or higher.'
    echohl None
  endif
  if !s:check_required_cmds()
    return
  endif
  if !s:current_tabpage_is_empty()
    tabedit
  endif
  " Select a project
  let in_name = tempname()
  let project_dirs = glob(a:dirs_pattern, 1, 1)->filter({-> isdirectory(v:val)})
  call writefile(project_dirs, in_name)
  let term_bufnr = term_start(['peco', '--exec', 'vargs call project_guide#_tcd_and_open', in_name], #{
    \ curwin: v:true,
    \ term_finish: 'close',
    \ term_api: 'project_guide#_',
    \})
  call setbufvar(term_bufnr, 'project_guide_context', #{
    \ in_name: in_name,
    \})
endfunction

function! s:current_tabpage_is_empty() abort
  return winnr('$') ==# 1 && !&modified && line('$') ==# 1 && getline(1) ==# ''
endfunction

function! s:check_required_cmds() abort
  if exists('s:checked_required_cmds')
    return s:checked_required_cmds
  endif
  let ok = v:true
  for cmd in ['gof', 'peco', 'vargs']
    if !executable(cmd)
      echohl ErrorMsg
      echomsg "project-guide: missing '" .. cmd .. "' command in your PATH"
      echohl None
      let ok = v:false
    endif
  endfor
  let s:checked_required_cmds = ok
  return ok
endfunction

function! project_guide#_tcd_and_open(bufnr, path) abort
  let ctx = getbufvar(a:bufnr, 'project_guide_context', v:null)
  if ctx is# v:null
    throw 'project_guide#_tcd_and_open: could not get b:project_guide_context from terminal buffer'
  endif
  tabedit
  call term_sendkeys(a:bufnr, "\<Esc>")  " exit peco
  call delete(ctx.in_name)
  " Change current directory to the project
  execute 'tcd' a:path
  " Select a file to open
  let popup = popup_dialog('Select a file to open', {})
  let term_bufnr = term_start(['gof', '-tf', 'project_guide#_finalize'], #{
    \ curwin: v:true,
    \ term_finish: 'close',
    \ term_api: 'project_guide#_',
    \})
  call setbufvar(term_bufnr, 'project_guide_context', #{
    \ popup: popup,
    \ term_winid: win_getid(bufwinnr(term_bufnr))
    \})
endfunction

function! project_guide#_finalize(bufnr, file) abort
  let ctx = getbufvar(a:bufnr, 'project_guide_context', v:null)
  if ctx is# v:null
    throw 'project_guide#_finalize: could not get b:project_guide_context from terminal buffer'
  endif
  call popup_close(ctx.popup)
  execute 'drop' a:file.fullpath
endfunction
