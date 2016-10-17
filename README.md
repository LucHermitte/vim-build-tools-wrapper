# Introduction

BTW has two main purposes:
  * [To simplify the on-the-fly tuning of `'compiler'` settings.](doc/filter.md)
  * [To offer a simplified interface to build, execute, test our programs.](doc/make_run.md)

It is also able to interface with [projects under CMake](doc/cmake.md).

And, it provides an [airline](https://github.com/bling/vim-airline) extension
that displays the current project name and compilation mode. This information
will also be displayed for the quickfix window.

# Installation
  * Requirements: Vim 7.+, [lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib) (v4.0.0)
  * With [vim-addon-manager](https://github.com/MarcWeber/vim-addon-manager), install build-tools-wrapper (this is the preferred method because of the dependencies)
```vim
ActivateAddons build-tools-wrapper
```
  * or with [vim-flavor](http://github.com/kana/vim-flavor) which also supports
    dependencies:
```
flavor 'LucHermitte/vim-build-tools-wrapper'
```
  * or you can clone the git repositories (expecting I haven't forgotten anything):
```vim
git clone git@github.com:LucHermitte/lh-vim-lib.git
git clone git@github.com:LucHermitte/vim-build-tools-wrapper.git
```
  * or with Vundle/NeoBundle (expecting I haven't forgotten anything):
```vim
Bundle 'LucHermitte/lh-vim-lib'
Bundle 'LucHermitte/vim-build-tools-wrapper'
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
