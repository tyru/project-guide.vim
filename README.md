# project-guide.vim

This library provides cool function to quickly open a project.

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

## Requirements

* [gof](https://github.com/mattn/gof)
* [vargs](https://github.com/tyru/vargs)
* [peco](https://github.com/peco/peco)
