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
command! Gopath call s:gopath()
function! s:gopath() abort
  let root_dir = exists('$GOPATH') ? expand('$GOPATH') : expand('$HOME/go')
  call project_guide#open(root_dir .. '/src/*/*/*')
endfunction
```

![](https://i.imgur.com/YJ4qWsT.gif)

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
