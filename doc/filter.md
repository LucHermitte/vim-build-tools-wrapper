# Filter compilation output

## Rationale

When one wants to use another compiler from vim, he has to load it with the `:compiler` command. This is nice. But this is not enough.
  * If we want to parse compilation output to transform all C++ mangled names into something comprehensible, with gcc, sun CC, clang, or whatever compiler, we need to patch {rtp}/compiler/gcc.vim, or to change manually `'makeprg'` to run `c++filt`
  * If we want to transform cygwin pathnames into windows pathnames (because we are using compilers, coming from cygwin, from win32-gvim), we will have to patch all related compiler-plugins to fix `'makeprg'`.
  * We may also want to parse C++ compilation outputs with the [indispensable STLfilt](http://www.bdsoft.com/tools/stlfilt.html).
  * If we want to use a compiler, or another, from ant+cpp\_task, well. There I don't know what needs to be patched.
  * If we compile (with whatever compiler) from CMake, or if we run CTest, we will have to get rid of those damn leading "`%d><>«»`" that CMake adds, otherwise vim won't be able to apply correctly `'errorformat'` in order to populate the quickfix-window.

In short, compiler-plugins don't scale. Sometimes, we need to add one filter, sometimes another or several. This is where BTW saves the day.

## Filters

Filters are of several kinds:
  * The ones that set what is to used as the main compilation chain (make, nmake, ant, rake, javac, ...)
  * The ones that filter the result of the compilation chain (cygwin make&gcc called from win32-gvim, application of STLfilt, cleaning up of CMake noise, ...)
  * The ones that fix `'errorformat'`
  * The ones that add useless but neat things (highlighting of result, folding related things, ...)

### Use a filter

Filters that set the compilation chain are to be used with either:
```vim
:BTW set _name of the filter_
:BTW setlocal _name of the filter_
```

By default, vim default `'errorformat`' and `'makeprg'` are used.

Other filters are simply added with either:
```vim
:BTW add _name of the filter_
:BTW addlocal _name of the filter_
```

### Default filters

#### Compiler-plugins
Any compiler-plugin installed can be used as a filter.

#### Executables
Any program available in the path can be a filter (dmSTLfilt.pl, c++filt, ...)

#### `cygwin`
Fixes cygwin pathnames into windows pathnames.

#### Compilation chains
`make`, `ant` (fix program output), `aap`

#### `cmake`, `ctest`
Fixes this damn "`%d>`" that prepends outputs from `cmake` and `ctest`
executables.

#### `STLfilt`
Filters C++ compiler output to in order to have readable error messages (the
.vim file may need to be tuned to use the right STL filter).

#### `SunSWProLinkIsError`
To have SunCC link error appear as link errors.

#### `shorten_filenames`
This filter conceals part of filenames.

It is parametrized with the [lh-dev option](http://github.com/LucHermitte/lh-dev)
`(bg):{ft_}BTW_shorten_names`. The option takes a list of regex to conceal with
`&` and/or lists of regex+conceal-characters, e.g.

```vim
" in a _vimrc_local.vim file
let b:BTW_shorten_names = [
    \   [ '/usr/include', 'I' ],
    \   [ '/usr/local/include', 'L' ],
    \   'foobar'
    \ ]
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
[lh-dev option](http://github.com/LucHermitte/lh-dev)
`(bg):{ft_}BTW_substitute_names`. The option takes a list of lists. Each
sublist contains a regex to match filenames to corrects, and the replacement
text.

```vim
" in a _vimrc_local.vim file
let b:BTW_substitute_names = [
    \   [ '\d\+>\s*', ''],
    \   [ lh#function#bind(b:build_dir.'/xsd'), b:sources_dir.'/xsd']
    \ ]
```

Note: It's executed with a _post_ _hook_ of priority 2.

```vim
call lh#btw#filters#register_hook(2, 'BTW_Substitute_Filenames', 'post')
```
### Create a new filter

To be documented...

## Some examples

### Simple C++ project, that may be compiled under cygwin

In the _vimrc\_local file, I write:
```vim
BTW add STLfilt
if lh#system#OnDOSWindows() && lh#system#SystemDetected() == 'unix'
    BTW add cygwin
endif
```_

### C++ project, compiled with g++ through ant and cpp\_task
```vim
BTW add ant
BTW add STLfilt
```

### ...
