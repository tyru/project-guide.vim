# project-guide.vim

This library provides cool function to quickly open a project.
Currently `project_guide#open({project directories pattern})` does:

1. Show project directories
2. `:tcd {project directory}`
3. Show files in the project
4. `:drop {file}`

## Examples

### Open `$GOPATH/src/*/*/*`

```vim
function! s:gopath_dirs_pattern() abort
  let root_dir = exists('$GOPATH') ? expand('$GOPATH') : expand('$HOME/go')
  let dirs_pattern = root_dir .. '/src/*/*/*'
  return dirs_pattern
endfunction
" call project_guide#define_command() at VimEnter,
" because project-guide.vim is not loaded yet in your vimrc.
autocmd VimEnter * call project_guide#define_command('Gopath', function('s:gopath_dirs_pattern'), #{gof_args: ['-f']})
```

![](https://i.imgur.com/YJ4qWsT.gif)

You can also specify initial query (`:Gopath myproject`)

![](https://i.imgur.com/x1cagS1.gif)

And you can complete Ex command arguments (`:Gopath <Tab>` or `:Gopath myproj<Tab>`)

![](https://i.imgur.com/DEM2bDk.gif)

### Open `$VOLTPATH/repos/*/*/*` of [Volt](https://github.com/vim-volt/volt) (Vim plugin manager)

I often open Vim plugin repositories to edit the scripts.

```vim
command! VoltRepos call s:volt_repos()
function! s:volt_repos() abort
  let root_dir = exists('$VOLTPATH') ? expand('$VOLTPATH') : expand('$HOME/volt')
  call project_guide#open(root_dir .. '/repos/*/*/*')
endfunction
```

![](https://i.imgur.com/7Ish7j6.gif)

## Requirements

* Vim 8.2 or higher
* [gof](https://github.com/mattn/gof)
* [vargs](https://github.com/tyru/vargs)
* [peco](https://github.com/peco/peco)

## `project_guide#open({dirs_pattern} [, {options}])`

1. List up `{dirs_pattern}` directories
2. `:tcd {selected directory}`
3. List up files under the selected directory
4. `:drop {selected file}`

```
{options} = {
  peco_args: <peco additional arguments (List)>,
  gof_args: <gof additional arguments (List)>,
}
```

Here is the example to use `{options}` (`peco_args`, `gof_args`).

```vim
command! -nargs=* -complete=dir Gopath call s:gopath(<q-args>)
function! s:gopath(query) abort
  let root_dir = exists('$GOPATH') ? expand('$GOPATH') : expand('$HOME/go')
  call project_guide#open(root_dir .. '/src/*/*/*', #{
  \ peco_args: a:query !=# '' ? ['--query', a:query] : [],
  \ gof_args: ['-f'],
  \})
endfunction
```

Now you can specify initial query to peco (`:Gopath myproject`)

And more, if you also want to complete Ex command arguments, you can use
`project_guide#complete()`.

## `project_guide#complete({dirs_pattern}, {arglead}, {cmdline}, {pos})`

You can create custom completion function using this.

```vim
command! -nargs=* -complete=customlist,s:complete Gopath call s:gopath(<q-args>)

function! s:gopath(query) abort
  call project_guide#open(s:gopath_dirs_pattern(), #{
  \ peco_args: a:query !=# '' ? ['--query', a:query] : [],
  \ gof_args: ['-f'],
  \})
endfunction

function! s:complete(...) abort
  return call('project_guide#complete', [s:gopath_dirs_pattern()] + a:000)
endfunction

function! s:gopath_dirs_pattern() abort
  let root_dir = exists('$GOPATH') ? expand('$GOPATH') : expand('$HOME/go')
  let dirs_pattern = root_dir .. '/src/*/*/*'
  return dirs_pattern
endfunction
```

Hmm, code is getting messy, is there more an "easy" way to do it?

## `project_guide#define_command({cmdname} (string), {dirs_pattern_func} (string or function) [, {options} = {}])`

This is the final answer, `project_guide#define_command()`.<br>
This generates the same functions above.

```vim
function! s:gopath_dirs_pattern() abort
  let root_dir = exists('$GOPATH') ? expand('$GOPATH') : expand('$HOME/go')
  let dirs_pattern = root_dir .. '/src/*/*/*'
  return dirs_pattern
endfunction
call project_guide#define_command('Gopath', function('s:gopath_dirs_pattern'), #{gof_args: ['-f']})
```

Now you can:

* Specify initial query to peco (`:Gopath myproject`)
* Complete Ex command arguments (`:Gopath <Tab>` or `:Gopath myproj<Tab>`)
