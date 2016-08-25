

# Introduction

BTW offers a simplified way to build and execute programs from vim. In essence, this plugin encapsulates `:make` and `:!./%<`.

# Options
Several options can permit to tune the behaviour of BTW.

## Keybindings
|   Command                        |   Default keybinding   |  Variable to set in `.vimrc`  |
|:---------------------------------|:-----------------------|:------------------------------|
| `:Make`                          | `<F7>`                 | `g:BTW_key_make`              |
| `:StopBGCompilation`<sup>1</sup> | N/A (yet)              | N/A (yet)                     |
| `:Execute`                       | `<C-F5>`               | `g:BTW_key_execute`           |
| `:Config`                        | `<M-F7>`               | `g:BTW_key_config`            |

#### Notes:
  * <sup>1</sup> Requires Vim 7.4-1980 compiled with +job feature. Tested on:
  
    |                   | Linux              | Cygwin + gvim64<sup>2</sup> | Cygwin + cyg-vim | Mingw + gvim64 | VC10 + gvim 64                  | 
    |:------------------|:-------------------|:----------------------------|:-----------------|:---------------|:--------------------------------|
    |Mono-file project  | :question:         | :heavy_check_mark:          | :question:       | :question:     | :heavy_check_mark: <sup>3</sup> |
    |Out-of-source build| :heavy_check_mark: | :question:                  | :question:       | :question:     | :question:                      |
  * <sup>2</sup> My `&shell` options are configured through my very old [system-tool plugin](https://github.com/LucHermitte/vim-system-tools). More investigations are required for other configurations.
  * <sup>3</sup> Tested with [gvim64](https://bintray.com/veegee/generic/vim_x64) launched from _VS2015 CLI for native x64_ console, and `:BTW set cl`, and `:Make %`. However, please note Cygwin is installed and in the $PATH of my windows machine.
    

## Behaviour
### Compilation

|   Role                                                                                          |   Option name                             |   Values (default)      |   Best set in/changed with   |
|:------------------------------------------------------------------------------------------------|:------------------------------------------|:------------------------|:-----------------------------|
| Shall the compilation happen in background?                                                     | `g:BTW_make_in_background`                | 1/(0)                   | `.vimrc`/`:ToggleMakeBG`     |
| Shall the background compilation autoscroll the qf-window to display last message?<sup>1</sup>  | `g:BTW_autoscroll_background_compilation` | 1/(0)                   | `.vimrc`/`:ToggleAutoScrollBG` |
| Shall the compilation use all available cores?                                                  | `g:BTW_make_multijobs`                    | _n_/(0)                 | `.vimrc`/`:ToggleMakeMJ`     |
| Directory where the compilation shall be done                                                   | `(bg):BTW_compilation_dir`                | path ('')               | `local_vimrc` / [BTW CMake submodule](doc/cmake.md) |
| Shall we update BTW tools chain every time we compile?                                          | `(bg):BTW_use_prio`                       | `''`/(`'update'`)       | `local_vimrc`                |
| Command to use to compile in background (useful to follow the compilation in an external xterm) | `(bg):BTW_make_in_background_in`          | (`''`)/`'xterm -e'`/... | `local_vimrc`                |
| Name of the project                                                                             | `(bg):BTW_Project`                        | (`'%<'`)                | `local_vimrc`                |
| Build Target                                                                                    | `(bg):BTW_project_target`                 | (project name, or `'all'` if empty) | `local_vimrc`    |

#### Notes:
  * <sup>1</sup> Requires Vim 7.4-1980 compiled with +job feature.

### Configuration

The option `(bg):BTW_project_config` says what to do on `:Config`.
When `(bg):BTW_project_config.type` equals
  * `modeline`, add a _let-modeline_
  * `makefile`, open the make file named `(bg):BTW_project_config.file` in `(bg):BTW_project_config.wd`.
  * `ccmake`, starts ccmake in `(bg):BTW_project_config.wd`, with `(bg):BTW_project_config.args` as parameters.


### Report errors
|   Role                                          |   Option name        |   Values (default)                       |   Best set in   |
|:------------------------------------------------|:---------------------|:-----------------------------------------|:----------------|
| Tunes where the quickfix window shall be opened | `g:BTW_qf_position`  | (`''`)/`'botright'`/...                  | `.vimrc`        |
| Tunes the size of the quickfix window           | `g:BTW_QF_size`      | number of lines (max(15, &winfixheight)) | `.vimrc`        |
| Tells whether we shall jump to the first error  | `g:BTW_GotoError`    | (1)/0                                    | `.vimrc`        |

### Execution

|   Role                                                     |   Option name                 |   Values (default)                       |   Best set in   |
|:-----------------------------------------------------------|:------------------------------|:-----------------------------------------|:----------------|
| Parameters to pass to the program executed with `:Execute` | `(bg):BTW_run_parameters`     | string (empty)                           | `local_vimrc`   |
| Program to execute                                         | `(bg):BTW_project_executable` | (project name, or does nothing if empty) | `local_vimrc`   |


# Build

Projects are compiled on `<F7>` or `:Make`, in the directory specified by `(bg):BTW_compilation_dir`. The compilation may be done in background (on nix boxes only), it may use all cores available.

The compilation tries to detect automatically the target though `(bg):BTW_project...` options, though it may be forced as a parameter to `:Make`.

When an error is found, the quickfix window will get automatically opened. However, when the quickfix window is not opened (link errors are not detected by default as compilation errors), the command `:Copen` is provided. `:Copen` differs from `:copen` in the sense it adjust its size the number of lines to display.

## Mono-file projects

### From the shell
First, a quick reminder. When, our system has gnu make installed (and not the badly configured gnumake from Mingw), we can compile the standalone file `foo.c` with `make foo` from our shell. We don't need to (and must not) write any Makefile! The executable `foo` will be generated in the current directory.

Any need to inject an option ? `$CFLAGS`, `$CXXFLAGS`, `$CPPFLAGS`, `$LDFLAGS` (to name the main ones) are already there waiting to be set. For instance, we can compile the C++14 standalone file bar.cpp with `CXXFLAGS='-std=c++1y' make bar`. And execute the result with `./bar`.

### From vim
How is it related to vim, you'll ask? Well, this means we can compile foo.c from vim with `:make foo`, or even `:make %<` when the current buffer is foo.c. To compile bar.cpp, we'll first have to set `$CXXFLAGS` with `:let $CXXFLAGS='-std=c++1y'`, and then we can simply compile with `:make %<`. _Et voilà!_

### From vim with BTW
The way BTW handles its default settings, we just need to hit `<F7>` to compile the current buffer. And if we need to set options, just set `$CXXFLAGS` once, and hit `<F7>` or `:Make` (note the capital 'M')

NB: my plugin let-modeline may help here.

#### Limitations
Of course, this will only work as long as there is no Makefile in the same directory of the file we wish to compile. If there is a Makefile, I strongly suggest you to better organize the directory where your pet projects/tests are. I usually have projects made of single files in a same directory, but when a project (even a small one) is made of several files, I store its files apart.

Note, that this will work only if there are implicit rules known by gnumake to handle the file you wish to compile. For other organizations, filetypes without implicit rules know by gnumake, or scripts to be interpreted, you can play with [filters](doc/filter.md), or use other plugins like [SingleCompile](https://github.com/xuhdev/SingleCompile).

## Multi-files projects

This time BTW won't be able to use the name of the current buffer to determine the target to use with `make`. Define a Makefile, and set the option `b:BTW_project_target` to whatever you wish ('all', 'myprog', or 'whatever').

The best way to define this option is from a project oriented plugin like [local\_vimrc](http://github.com/LucHermitte/local_vimrc)

## CMake based projects

[I have a lot of things to say on this topic](cmake.md).


# Execute

Just hit `<C-F5>` to execute the current program. You may have to change the keybinded if you are using vim in console instead of gvim or macvim.

In the case of the multi-files project, or a project having tests managed through CTest, you'll have to set `(bg):BTW_project_executable`.

If `(bg):BTW_project_executable` contains `{ 'type': 'make' }`, the execution is redirected to the quickfix window. Same thing with `{ 'type': 'ctest' }`, but this time the result is filtered on-the-fly to correct the noise introduced by CTest (regarding `&errorformat`)
