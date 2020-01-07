scriptencoding utf-8
scriptversion 4

function! project_guide#open(dirs_pattern, options = {}) abort
  if v:version < 802
    echohl ErrorMsg
    echomsg 'project-guide: Please use Vim 8.2 or higher.'
    echohl None
  endif
  if !s:check_required_cmds(a:options)
    return
  endif
  call s:select_project(a:dirs_pattern, a:options)
endfunction

function! s:setup_nop_autocmds() abort
  augroup project-guide
    autocmd!
    autocmd User project-guide-post-tcd silent
    autocmd User project-guide-post-file-open silent
  augroup END
endfunction

function! s:select_project(dirs_pattern, options) abort
  if !s:current_tabpage_is_empty()
    tabedit
  endif
  call s:setup_nop_autocmds()
  " Select a project (peco)
  let in_name = tempname()
  let project_dirs = s:get_project_dirs(a:dirs_pattern)
  call writefile(project_dirs, in_name)
  let peco_args = get(a:options, 'peco_args', [])
  let peco_args = copy(type(peco_args) ==# v:t_list ? peco_args : [])
  let peco_args += [in_name]
  let initial_bufnr = bufnr('')
  let gof_args = get(a:options, 'gof_args', [])
  let gof_args = copy(type(gof_args) ==# v:t_list ? gof_args : [])
  let files_args = get(a:options, 'files_args', [])
  let files_args = copy(type(files_args) ==# v:t_list ? files_args : [])
  let dialog_msg = a:options->get('project_dialog_msg', 'Choose a project')
  let dialog_options = a:options->get('project_dialog_options', #{time: 2000})
  let popup = empty(dialog_msg) ? -1 : popup_dialog(dialog_msg, dialog_options)
  let file_ui = a:options->get('file_ui', 'files+peco')
  if file_ui ==# 'files+peco'
    let file_ui_cmd = [&shell, &shellcmdflag, 'files | peco']
  elseif file_ui ==# 'gof'
    " -x 0: make cancel successfull exit
    " -a ctrl-o: behave Ctrl-O like same as Enter
    let file_ui_cmd = ['gof'] + gof_args + ['-x', '0', '-a', 'ctrl-o']
  else
    throw "project-guide: unknown 'file_ui' value: " . file_ui
  endif
  let peco_ctx = #{
    \ popup: popup,
    \ in_name: in_name,
    \ files_args: files_args,
    \ initial_bufnr: initial_bufnr,
    \ open_func: a:options->get('open_func', function('project_guide#default_open_func')),
    \ file_dialog_msg: a:options->get('file_dialog_msg', 'Choose a file'),
    \ file_dialog_options: a:options->get('file_dialog_options', #{time: 2000}),
    \ file_ui: file_ui,
    \ file_ui_cmd: file_ui_cmd,
    \ load_session: a:options->get('load_session', v:true),
    \ session_file: a:options->get('session_file', 'Session.vim'),
    \}
  let term_bufnr = term_start(['peco'] + peco_args, #{
    \ curwin: v:true,
    \ exit_cb: function('s:tcd_and_select_file', [peco_ctx]),
    \})
endfunction

function! project_guide#default_open_func(path_list, opencmd = 'split') abort
  for path in a:path_list
    execute a:opencmd path
  endfor
endfunction

function! project_guide#define_command(cmdname, dirs_pattern_func, options = {}) abort
  if type(a:dirs_pattern_func) ==# v:t_func
    let dirs_pattern = call(a:dirs_pattern_func, [])
  elseif type(a:dirs_pattern_func) ==# v:t_string
    let dirs_pattern = a:dirs_pattern_func
  else
    echohl ErrorMsg
    echomsg 'project_guide#define_command: Invalid {dirs_pattern_func} argument.'
    echohl None
    return
  endif

  execute [
    \ 'function! s:complete_' .. a:cmdname .. '(...) abort',
    \ '  return call("project_guide#complete", [' .. string(dirs_pattern) .. '] + a:000)',
    \ 'endfunction',
    \]->join("\n")

  let a:options.dirs_pattern = dirs_pattern
  execute 'command! -nargs=* -complete=customlist,s:complete_' .. a:cmdname .. ' ' .. a:cmdname .. ' call s:open(' .. string(a:options) .. ', <q-args>)'
endfunction

function! project_guide#complete(dirs_pattern, arglead, cmdline, pos) abort
  let dirs = s:get_project_dirs(a:dirs_pattern)
  if a:arglead !=# ''
    call filter(dirs, 'stridx(v:val, a:arglead) !=# -1')
  endif
  return dirs
endfunction

function! s:open(options, query) abort
  let options = deepcopy(a:options)
  if !has_key(options, 'peco_args') || type(options.peco_args) !=# v:t_list
    let options.peco_args = []
  endif
  let options.peco_args += a:query !=# '' ? ['--query', a:query] : []
  call project_guide#open(a:options.dirs_pattern, options)
endfunction

function! s:get_project_dirs(dirs_pattern) abort
  return glob(a:dirs_pattern, 1, 1)->filter({-> isdirectory(v:val)})
endfunction

function! s:current_tabpage_is_empty() abort
  return winnr('$') ==# 1 && !&modified && line('$') ==# 1 && getline(1) ==# ''
endfunction

function! s:check_required_cmds(options) abort
  if exists('s:checked_required_cmds')
    return s:checked_required_cmds
  endif
  let ok = v:true
  for cmd in ['peco'] + [get(a:options, 'file_ui', 'files+peco') ==# 'files+peco' ? 'files' : 'gof']
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

function! s:tcd_and_select_file(peco_ctx, job, code) abort
  " Do peco finalization
  call popup_close(a:peco_ctx.popup)
  if a:code !=# 0
    echohl ErrorMsg
    echomsg 'project-guide: peco exited abnormally'
    echohl None
    return
  endif
  let peco_bufnr = ch_getbufnr(a:job, 'out')
  call term_wait(peco_bufnr, 2000)
  let path = term_getline(peco_bufnr, 1)
  if path ==# ''    " peco exited successfully with no result
    " Restore initial buffer
    if bufexists(a:peco_ctx.initial_bufnr) && a:peco_ctx.initial_bufnr !=# bufnr('')
      execute a:peco_ctx.initial_bufnr 'buffer'
    else
      enew
    endif
    return
  elseif !isdirectory(path)
    echohl ErrorMsg
    echomsg 'project-guide: No such directory:' path
    echohl None
    return
  endif
  call delete(a:peco_ctx.in_name)
  " Change current directory to the project
  execute 'tcd' path
  doautocmd User project-guide-post-tcd
  if a:peco_ctx.load_session && filereadable(a:peco_ctx.session_file)
    execute 'source' a:peco_ctx.session_file
    return
  endif
  " Select a file to open
  let popup = empty(a:peco_ctx.file_dialog_msg) ?
    \ -1 : popup_dialog(a:peco_ctx.file_dialog_msg, a:peco_ctx.file_dialog_options)
  let file_ctx = #{
    \ popup: popup,
    \ initial_bufnr: a:peco_ctx.initial_bufnr,
    \ open_func: a:peco_ctx.open_func,
    \}
  let term_bufnr = term_start(a:peco_ctx.file_ui_cmd, #{
    \ curwin: v:true,
    \ exit_cb: function('s:finalize_file_ui_cmd', [a:peco_ctx.file_ui, file_ctx]),
    \})
endfunction

" Do gof finalization
function! s:finalize_file_ui_cmd(file_ui, file_ctx, job, code) abort
  if a:code !=# 0
    echohl ErrorMsg
    echomsg 'project-guide: gof exited abnormally'
    echohl None
    return
  endif
  call popup_close(a:file_ctx.popup)
  let gof_bufnr = ch_getbufnr(a:job, 'out')
  if a:file_ui ==# 'gof'
    let action = term_getline(gof_bufnr, 1)
    let lnum = 2
  else
    let action = ''
    let lnum = 1
  endif
  " Open selected file(s).
  " Get all paths before :drop replaces current terminal window.
  if action ==# '' || action ==# 'ctrl-o'
    let path_list = []
    while v:true
      let path = term_getline(gof_bufnr, lnum)
      if path ==# ''
        break
      endif
      let path_list += [path]
      let lnum += 1
    endwhile
    call call(a:file_ctx.open_func, [path_list])
  else
    throw 'project-guide: unknown gof action: ' . action
  endif
  " Close gof window and may restore initial buffer if no other windows
  if bufwinnr(gof_bufnr) !=# -1
    if winnr('$') ==# 1
      if bufexists(a:file_ctx.initial_bufnr) && a:file_ctx.initial_bufnr !=# bufnr('')
        execute a:file_ctx.initial_bufnr 'buffer'
      else
        enew
      endif
    else
      let gof_winid = win_getid(bufwinnr(gof_bufnr))
      call win_execute(gof_winid, 'close')
    endif
  endif
  doautocmd User project-guide-post-file-open
endfunction
