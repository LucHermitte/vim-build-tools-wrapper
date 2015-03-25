# Filter compilation output

## 1- Rationale

When we want to use another compiler from vim, we have to load it with the
`:compiler` command. This way we can change the `'errorformat'` and the
`'makeprg'` options. This is nice. But this is not enough.
  * This approach does not permit to parse every error format. For instance:
    *  It's impossible to have `'errorformat'` decode error messages produced
       by CMake (when used to compile, with whatever compiler) or CTest. Indeed
       these tools prepend each line produced with a number followed by a
       closing angle bracket: `%d>`.

  * Default compiler plugins don't translate pathnames on the fly, nor simplify
    error messages. This means that we'll have to pipe the result of the
    compilation chain (`make`, `ant`, `bjam`, ...) with:
    * the [indispensable STLfilt](http://www.bdsoft.com/tools/stlfilt.html) or
      [gccfilter](http://www.mixtion.org/gccfilter/) in order to simplify C++
      error messages ;
    * `cygpath` in order to transform cygwin pathnames into windows pathnames
      (because we are using compilers, coming from cygwin, from native-gvim).
    * `c++filt` if we want to parse compilation output to transform all C++
      mangled names into something comprehensible.

    In any case, we certainly don't want to define one compiler plugin for each
    possible situation (make + gccfilter, make + gccfilter + cygwin, ant + STLFilt +
    cygwin, ...)

  * Compiler plugins are made to support a single tool. Using several tools
    together is not expected. It means that:
    * We cannot compile with ant, convert cygwin filenames and expect gcc error
      messages (_corrupted_ by ant)
    * We cannot decode error messages from several distinct compilers or tools
      used by a common compilation chain: a Makefile can execute `$(CXX)`,
      `$(FC)`, Doxygen, and LaTeX.

  * Compiler-plugins aren't meant either to handle folding, or to conceal text
    in the quickfix window.

In short, compiler-plugins don't scale. Sometimes, we need to add one filter,
sometimes another or several. This is where BTW saves the day.

## 2- Filters

Filters are of several kinds:
  * The ones that set what is to used as the main compilation chain (make, nmake, ant, rake, javac, ...)
  * The ones that filter the result of the compilation chain (cygwin make&gcc called from win32-gvim, application of STLfilt, cleaning up of CMake noise, ...)
  * The ones that fix `'errorformat'`
  * The ones that add useless but neat things (highlighting of result, folding related things, concealling of non pertinent text, ...)

### 2.1- Using filters

#### Listing active filters: `:BTW echo ToolsChain()`
The list of active filters in the current buffer can be obtained with:
```vim
BTW echo ToolsChain()
```

#### Adding filters: `:BTW set(local)`
In order to specify the compilation chain use:
```vim
:BTW set _name of the filter_
:BTW setlocal _name of the filter_
```

By default, vim default `'errorformat`' and `'makeprg'` are used. This is `make` filter.

Other filters are simply added with either:
```vim
:BTW add _name of the filter_
:BTW addlocal _name of the filter_
```

If you're using a plugin that permits to emulate projects like
[local_vimrc](http://github.com/LucHermitte/local_vimrc) prefer `setlocal` and
`addlocal` subcommands. The filters used will be local to the buffers (/files)
belonging to the project.

Note: if `setlocal` or `addlocal` have been used in a buffer, the filters added
with `set` or `add` will be ignored.

#### Removing filters: `:BTW remove(local)`
A filter added can be removed with:
```vim
:BTW remove _name of the filter_
:BTW removelocal _name of the filter_
```

Notes:
  * This two commands are meant for interactive tests of filters. If you have
    added your filters with `:BTW addlocal` from a
    [_vimrc_local file](http://github.com/LucHermitte/local_vimrc), you'll
    quite certainly observe odd behaviours.
  * `remove` will only remove global filters
  * `removelocal` will try to remove the local filter in all known buffers.

### 2.2- Default filters

#### Compiler-plugins
Any compiler-plugin installed can be used as a filter.

#### Executables
Any program available in the `$PATH` can be a filter (dmSTLfilt.pl, c++filt, ...)

#### `cygwin`
This filter fixes cygwin pathnames into windows pathnames.

In the _vimrc\_local file, I write:
```vim
if lh#system#OnDOSWindows() && lh#system#SystemDetected() == 'unix'
    BTW addlocal cygwin
endif
```

#### Compilation chains
`make`, `ant` (fix program output), `aap`

#### `cmake`
Removes this damn `%d>` that prepends outputs from `cmake` and `ctest`
executables.

```vim
" #### in _vimrc_local.vim
:BTW setlocal cmake
```

It relies on the following options:
  * `(bg):BTW_project_build_dir` (This should changed an be masked in future
    versions)
  * `(bg):BTW_project_build_mode` (default: `Release`)

This is mainly meant when the compilation is done with `cmake --build`. Tests executed
thanks to CTest are addressed with the _project execution type_, when the tests
are run with `<C-F5>`:
```vim
" #### in _vimrc_local.vim
LetIfUndef b:BTW_project_executable.type 'ctest'
```

#### `STLfilt`
Filters C++ compiler output to in order to have readable error messages (the
.vim file may need to be tuned to use the right STL filter).

```vim
BTW addlocal STLfilt
```

#### `SunSWProLinkIsError`
To have SunCC link error appear as errors.

#### `shorten_filenames`
This filter conceals part of filenames.

It is parametrized with the [lh-dev option](http://github.com/LucHermitte/lh-dev#options-1)
`(bg):{ft_}BTW_shorten_names`. The option takes a list of regex to conceal with
`&` and/or lists of regex+conceal-characters, e.g.

```vim
" #### in a _vimrc_local.vim file
" Define the concealled file parts
let b:BTW_shorten_names = [
    \   [ '/usr/include', 'I' ],
    \   [ '/usr/local/include', 'L' ],
    \   'foobar'
    \ ]
" Tell to automatically import the buffer local variable to the quickfix
" window
QFImport b:BTW_shorten_names
" Add the filter to the list of filter applied
BTW addlocal shorten_filenames
```

Note: It's executed with _syntax_ _hooks_ of priority 8. The way quickfix
works, we cannot alter filenames without altering the associated buffer number.
Hence, the only way to simplify displayed filenames consists in concealing
some of their parts.

```vim
call lh#btw#filters#register_hook(8, 'BTW_Shorten_Filenames', 'syntax')
```

#### `substitute_filenames`
This filters corrects filenames within vim.

Some programs may produce error messages that cannot be decoded with vim
`'errorformat'` option -- see CTest that prepends each line produced by the
number of the test followed by a `>`.

This filter permits to correct, from within Vim, filenames produced. It has the
advantage of being portable (the filter relies exclusively on VimL), however
it presents some quirks. Sometimes, syntax highlighting disappear in buffers
already loaded that are recognized by the filter.

In other words, prefer to correct produced filenames while `'makeprg'` command
is executed. If you don't want to write a perl/sed/python script, you can alway
use this filter.


The filter is parametrized with the
[lh-dev option](http://github.com/LucHermitte/lh-dev#options-1)
`(bg):{ft_}BTW_substitute_names`. The option takes a list of lists. Each
sublist contains a regex to match filenames to corrects, and the replacement
text.

```vim
" #### in a _vimrc_local.vim file
" Define how filenames are converted
" - ^%d> is stripped
" - */build/{build-type}/copy_xsd (automatically filled and generated during
"   the compilation by copying files from
"   {project-root}/data/xsd/GENERATION_SCHEMAS/) is converted to the original file.
let b:BTW_substitute_names = [
    \   [ '\d\+>\s*', ''],
    \   [
    \     lh#function#bind(string('^'.b:BTW_compilation_dir.'/copy_xsds')),
    \     g:PRJ_config.paths.trunk.'/../data/xsd/GENERATION_SCHEMAS'
    \   ]
    \ ]
" Tell to automatically import the buffer local variable to the quickfix
" window
QFImport b:BTW_substitute_names
" Add the filter to the list of filter applied
BTW addlocal substitute_filenames
```

Note: It's executed with a _post_ _hook_ of priority 2.

```vim
call lh#btw#filters#register_hook(2, 'BTW_Substitute_Filenames', 'post')
```
### Create a new filter

To be documented...

## 3- Some examples

### C++ project, compiled with g++ through ant and cpp\_task
```vim
BTW addlocal ant
BTW addlocal STLfilt
```

### ...
