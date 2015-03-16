# Introduction

BTW has two main purposes:
  * [To simplify the on-the-fly tuning of `'compiler'` settings.](doc/filter.md)
  * [To offer a simplified interface to build, execute, test our programs.](doc/make_run.md)

And it is also able to interface with [projects under CMake](doc/CMake.md).

# Installation
  * Requirements: Vim 7.+, [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib), [SearchInRuntime](http://github.com/LucHermitte/SearchInRuntime), and [system-tools](http://github.com/LucHermitte/vim-system-tools).
  * With [vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), install lh-brackets (this is the preferred method because of the dependencies)
```vim
ActivateAddons build-tools-wrapper
```
  * or you can clone the git repositories
```vim
git clone git@github.com:LucHermitte/lh-vim-lib.git
git clone git@github.com:LucHermitte/SearchInRuntime.git
git clone git@github.com:LucHermitte/vim-system-tools.git
git clone git@github.com:LucHermitte/vim-build-tools-wrapper.git
```
  * or with Vundle/NeoBundle:
```vim
Bundle 'LucHermitte/lh-vim-lib'
Bundle 'LucHermitte/SearchInRuntime'
Bundle 'LucHermitte/vim-system-tools'
Bundle 'LucHermitte/vim-build-tools-wrappers'
```

# See also

## Dependencies

You will most certainly require a project management plugin. I can offer you [local\_vimrc](http://github.com/LucHermitte/local_vimrc), there are plenty alternatives (with similar names), or even the good old project.vim plugin.

## Examples of configuration of BTW

  * See the two `_local_vimrc*.vim` files from my [Rasende Roboter solver](http://github.com/LucHermitte/Rasende).
  * See the two same files from my configuration for working with openjpeg _(link to be added)_.

## Alternatives
There are a few alternative plugins that I'm aware of:
  * [Tim Pope's vim-dispatch](http://github.com/tpope/vim-dispatch) regarding the encapsulation of `:make`
  * Marc Weber's _name-forgotten_ plugin to run things in background
  * [Jacky Alciné's CMake.vim plugin](http://jalcine.github.io/cmake.vim/)

[![Project Stats](https://www.openhub.net/p/21020/widgets/project_thin_badge.gif)](https://www.openhub.net/p/21020)
