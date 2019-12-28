scriptencoding utf-8
scriptversion 4

function! project_guide#open(dirs_pattern) abort
  if !s:check_required_cmds()
    return
  endif
  " Select a project
  let in_name = tempname()
  let project_dirs = glob(a:dirs_pattern, 1, 1)->filter({-> isdirectory(v:val)})
  call writefile(project_dirs, in_name)
  let term_bufnr = term_start(['peco', '--exec', 'vargs call project_guide#_tcd_and_open', in_name], #{
    \ term_finish: 'close',
    \ term_api: 'project_guide#_',
    \})
  call setbufvar(term_bufnr, 'vimrc_gof_volt_repos', #{in_name: in_name})
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
  let ctx = getbufvar(a:bufnr, 'vimrc_gof_volt_repos', v:null)
  if ctx is# v:null
    throw 'project_guide#_tcd_and_open: could not get b:vimrc_gof_volt_repos from terminal buffer'
  endif
  call term_sendkeys(a:bufnr, "\<Esc>")  " exit peco
  call delete(ctx.in_name)
  tabedit
  " Change current directory to the project
  execute 'tcd' a:path
  " Select a file to open
  let popup = popup_dialog('Select a file to open.', {})
  let term_bufnr = term_start(['gof', '-tf', 'project_guide#_finalize'], #{
    \ curwin: v:true,
    \ term_finish: 'close',
    \ term_api: 'project_guide#_',
    \})
  call setbufvar(term_bufnr, 'vimrc_gof_volt_repos', #{
    \ popup: popup,
    \ term_winid: win_getid(bufwinnr(term_bufnr))
    \})
endfunction

function! project_guide#_finalize(bufnr, file) abort
  let ctx = getbufvar(a:bufnr, 'vimrc_gof_volt_repos', v:null)
  if ctx is# v:null
    throw 'project_guide#_finalize: could not get b:vimrc_gof_volt_repos from terminal buffer'
  endif
  call popup_close(ctx.popup)
  execute 'drop' a:file.fullpath
endfunction
