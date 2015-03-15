# Filter compilation output

## Rationale

When one wants to use another compiler from vim, he has to load it with the `:compiler` command. This is nice. But this is not enough.
  * If we want to parse compilation output to transform all C++ mangled names into something comprehensible, with gcc, sun CC, clang, or whatever compiler, we need to patch {rtp}/compiler/gcc.vim, or to change manually `'makeprg'` to run `c++filt`
  * If we want to transform cygwin pathnames into windows pathnames (because we are using compilers, coming from cygwin, from win32-gvim), we will have to patch all related compiler-plugins to fix `'makeprg'`.
  * We may also want to parse C++ compilation outputs with the [indispensable STLfilt](http://www.bdsoft.com/tools/stlfilt.html).
  * If we want to use a compiler, or another, from ant+cpp\_task, well. There I don't know what needs to be patched.
  * If we compile (with whatever compiler) from CMake, or if we run CTest, we will have to get rid of those dawn leading "%d>" that CMake adds, otherwise vim won't be able to apply correctly `'errorformat'` in order to populate the quickfix-window.

In short. compiler-plugins don't scale. Sometimes, we need to add one filter, sometimes another or several. This is where BTW saves the day.

## Filters

Filters are of several kinds:
  * The ones that set what is to used as the main compilation chain (make, nmake, ant, rake, javac, ...)
  * The ones that filter the result of the compilation chain (cygwin make&gcc called from win32-gvim, application of STLfilt, cleaning up of CMake noise, ...)
  * The ones that fix `'errorformat'`
  * The ones that add useless but neat things (highlighting of result, folding related things, ...)

### Use a filter

Filters that set the compilation chain are to be used with either:
```
:BTW set _name of the filter_
:BTW setlocal _name of the filter_
```

By default, vim default `'errorformat`' and `'makeprg'` are used.

Other filters are simply added with either:
```
:BTW add _name of the filter_
:BTW addlocal _name of the filter_
```

### Default filters

  * Any compiler-plugin installed can be used as a filter.
  * Any program available in the path can be a filter (dmSTLfilt.pl, c++filt, ...)
  * Plus a few filters I ship with BTW:
    * compilation chains: make, ant (fix program output), aap
    * cygwin: fix cygwin pathnames into windows pathnames
    * cmake, ctest: fix this damn "%d>"
    * STLfilt: filter C++ compiler output to in order to have readable error messages (the .vim file may need to be tuned to use the right STL filter)
    * SunSWProLinkIsError: to have SunCC link error appear as link errors.

### Create a new filter

## Some examples

### Simple C++ project, that may be compiled under cygwin

In the _vimrc\_local file, I write:
```
BTW add STLfilt
if lh#system#OnDOSWindows() && lh#system#SystemDetected() == 'unix'
    BTW add cygwin
endif
```_

### C++ project, compiled with g++ through ant and cpp\_task
```
BTW add ant
BTW add STLfilt
```

### ...