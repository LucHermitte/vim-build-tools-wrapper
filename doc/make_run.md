

# Introduction

BTW offers a simplified way to build and execute programs from vim. In essence, this plugin encapsulates `:make` and `:!./%<`.

# Options
Several options can permit to tune the behaviour of BTW.

## Keybindings
|   Command                        |   Default keybinding   |  Variable to set in `.vimrc`  |
|:---------------------------------|:-----------------------|:------------------------------|
| `:Make`                          | `<F7>`                 | `g:BTW.key.make`              |
| `:StopBGCompilation`<sup>1</sup> | N/A (yet)              | N/A (yet)                     |
| `:Execute`                       | `<C-F5>`               | `g:BTW.key.execute`           |
| `:Config`                        | `<M-F7>`               | `g:BTW.key.config`            |
| `:ReConfig`                      | `<M-F8>`               | `g:BTW.key.re_config`         |

#### Notes:
  * <sup>1</sup> Requires Vim 7.4-1980 compiled with +job feature.

## Behaviour
### Compilation

|   Role                                                                                          |   Option name                             |   Values (default)      |   Best set in/changed with   |
|:------------------------------------------------------------------------------------------------|:------------------------------------------|:------------------------|:-----------------------------|
| Shall the compilation happen in background? <sup>1</sup>                                        | `g:BTW.make_in_background`                | 1/(0)                   | `.vimrc`/`:ToggleMakeBG`     |
| Shall the background compilation autoscroll the qf-window to display last message?<sup>2</sup>  | `g:BTW.autoscroll_background_compilation` | 1/(0)                   | `.vimrc`/`:ToggleAutoScrollBG` |
| Shall the compilation use all available cores?                                                  | `g:BTW.make_multijobs`                    | _n_/(0)                 | `.vimrc`/`:ToggleMakeMJ`     |
| Directory where the compilation shall be done                                                   | `(bpg):BTW.compilation_dir`               | path ('')               | `local_vimrc` / [BTW CMake submodule](doc/cmake.md) |
| Shall we update BTW tools chain every time we compile?                                          | `(bpg):BTW.use_prio`                      | `''`/(`'update'`)       | `local_vimrc`                |
| Command to use to compile in background (useful to follow the compilation in an external xterm) | `(bpg):BTW.make_in_background_in`         | (`''`)/`'xterm -e'`/... | `local_vimrc`                |
| Name of the project                                                                             | `(bpg):BTW.project`                       | (`'%<'`)                | `local_vimrc`                |
| Build Target                                                                                    | `(bpg):BTW.target`                        | (project name, or `'all'` if empty) | `local_vimrc`    |

#### Notes:
  * <sup>1</sup> Requires perl or Vim 7.4-1980 compiled with +job feature. The
    old perl way works on *nix systems. The new +job way has been tested
    successfully on:
  
    |                   | Linux              | Cygwin + gvim64<sup>3</sup> | Cygwin + cyg-vim | Mingw + gvim64<sup>5</sup> | VC10 + gvim 64<sup>5</sup>      | 
    |:------------------|:-------------------|:----------------------------|:-----------------|:---------------------------|:--------------------------------|
    |Mono-file project  | :heavy_check_mark: | :heavy_check_mark:          | :question:       | :question:                 | :heavy_check_mark: <sup>4</sup> |
    |Out-of-source build| :heavy_check_mark: | :question:                  | :question:       | :question:                 | :question:                      |
  * <sup>2</sup> Requires Vim 7.4-1980 compiled with +job feature.
  * <sup>3</sup> My `&shell` options are configured through my very old [system-tool plugin](https://github.com/LucHermitte/vim-system-tools). More investigations are required for other configurations.
  * <sup>4</sup> Tested with [gvim64](https://bintray.com/veegee/generic/vim_x64) launched from _VS2015 CLI for native x64_ console, and `:BTW set cl`, and `:Make %`.
  * <sup>5</sup> Without any Cygwin binaries in the $PATH.
    

### Configuration

The option `(bpg):BTW.project_config` says what to do on `:Config`.
When `(bpg):BTW.project_config.type` equals
  * `modeline`, add a _let-modeline_
  * `makefile`, open the make file named `(bpg):BTW.project_config.file` in `(bpg):BTW.project_config.wd`.
  * `ccmake`, starts ccmake in `(bpg):BTW.project_config.wd`, with `(bpg):BTW.project_config.args` as parameters.


### Report errors
|   Role                                          |   Option name        |   Values (default)                       |   Best set in   |
|:------------------------------------------------|:---------------------|:-----------------------------------------|:----------------|
| Tunes where the quickfix window shall be opened | `g:BTW.qf_position`  | (`''`)/`'botright'`/...                  | `.vimrc`        |
| Tunes the size of the quickfix window           | `g:BTW.qf_size`      | number of lines (max(15, &winfixheight)) | `.vimrc`        |
| Tells whether we shall jump to the first error  | `g:BTW.goto_error`   | (1)/0                                    | `.vimrc`        |

### Execution

|   Role                                                     |   Option name              |   Values (default)                       |   Best set in   |
|:-----------------------------------------------------------|:---------------------------|:-----------------------------------------|:----------------|
| Parameters to pass to the program executed with `:Execute` | `(bpg):BTW.run_parameters` | string (empty)                           | `local_vimrc`   |
| Program to execute                                         | `(bpg):BTW.executable`     | (project name, or does nothing if empty) | `local_vimrc`   |


# Build

Projects are compiled on `<F7>` or `:Make`, in the directory specified by `(bpg):BTW.compilation_dir`. The compilation may be done in background (on nix boxes only), it may use all cores available.

The compilation tries to detect automatically the target though `(bpg):BTW.project...` options, though it may be forced as a parameter to `:Make`.

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

This time BTW won't be able to use the name of the current buffer to determine the target to use with `make`. Define a Makefile, and set the option `(bpg):BTW.target` to whatever you wish ('all', 'myprog', or 'whatever').

The best way to define this option is from a project oriented plugin like [local\_vimrc](http://github.com/LucHermitte/local_vimrc)

## CMake based projects

[I have a lot of things to say on this topic](cmake.md).


# Execute

Just hit `<C-F5>` to execute the current program. You may have to change the key bound if you are using vim in console instead of gvim or macvim.

In the case of the multi-files project, or a project having tests managed through CTest, you'll have to set `(bpg):BTW.executable`.

If `(bpg):BTW.executable` contains `{ 'type': 'make' }`, the execution is redirected to the quickfix window. Same thing with `{ 'type': 'ctest' }`, but this time the result is filtered on-the-fly to correct the noise introduced by CTest (regarding `&errorformat`)

# Demo
You'll see in this little demo, an example of use of BTW on two CMake based
projects simultaneously opened in Vim 8 (7.4-2342 actually).

The compilation of both projects is launched in background. The job queue (from
[lh-vim-lib](http://github.com/LucHermitte/lh-vim-lib)) is then opened to
follow what is done in background and what will be done shortly after.

The explicit update (in background) of tags for all files in
[ITK project](http://www.itk.org) is also requested (thanks to
[lh-tags](http://github.com/LucHermitte/lh-tags) v2.0.3).

And we see ITK compilation fails because `cmake` has never been run for the
_reldeb_ compilation mode (_ReleaseWithDebugInfo_). A problem is detected and the
next jobs are not executed automatically. The job queue is paused (I also could
have ignored the error, etc.).

Then I change the current compilation mode to _sanitize_ (some kind of
_ReleaseWithDebugInfo_ mode but compiled with clang++ with two sanitizations
activated). This time `cmake` has been executed in the associated directory. I
register the compilation on ITK in this mode.

The queue is still paused. I _unpause_ the job queue through the `:Jobs` console.
Eventually I see ITK is still not compiling, but this is another issue.

![background compilation demo](screencast-BTW.gif "Demo of background compilation of 2 dictinct projects with different compilation modes")
