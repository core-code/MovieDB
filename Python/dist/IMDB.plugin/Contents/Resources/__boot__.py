def _site_packages():
    import site, sys, os
    paths = []
    prefixes = [sys.prefix]
    if sys.exec_prefix != sys.prefix:
        prefixes.append(sys.exec_prefix)
    for prefix in prefixes:
	if prefix == sys.prefix:
	    paths.append(os.path.join("/Library/Python", sys.version[:3], "site-packages"))
	    paths.append(os.path.join(sys.prefix, "Extras", "lib", "python"))
	else:
	    paths.append(os.path.join(prefix, 'lib', 'python' + sys.version[:3],
		'site-packages'))
    if os.path.join('.framework', '') in os.path.join(sys.prefix, ''):
        home = os.environ.get('HOME')
        if home:
            paths.append(os.path.join(home, 'Library', 'Python',
                sys.version[:3], 'site-packages'))

    # Work around for a misfeature in setuptools: easy_install.pth places
    # site-packages way to early on sys.path and that breaks py2app bundles.
    # NOTE: this is hacks into an undocumented feature of setuptools and
    # might stop to work without warning.
    sys.__egginsert = len(sys.path)

    for path in paths:
        site.addsitedir(path)
_site_packages()


def _path_inject(paths):
    import sys
    sys.path[:0] = paths


_path_inject(['/Users/julian/Documents/Development/MovieDB/Python'])


def _run(*scripts):
    global __file__
    import os, sys, site
    import Carbon.File
    sys.frozen = 'macosx_plugin'
    site.addsitedir(os.environ['RESOURCEPATH'])
    for (script, path) in scripts:
        alias = Carbon.File.Alias(rawdata=script)
        target, wasChanged = alias.FSResolveAlias(None)
        if not os.path.exists(path):
            path = target.as_pathname()
        sys.path.append(os.path.dirname(path))
        __file__ = path
        execfile(path, globals(), globals())


try:
    _run(('\x00\x00\x00\x00\x012\x00\x02\x00\x00\x0cMacintosh HD\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xcbzzdH+\x00\x00\x00\x08\x15\x01\x07IMDB.py\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x18\xd6\xc6\xb5\xeeW\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xff\x00\x00I \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x08\x00\x00\xcbzlT\x00\x00\x00\x11\x00\x08\x00\x00\xc6\xb5\xd27\x00\x00\x00\x0e\x00\x10\x00\x07\x00I\x00M\x00D\x00B\x00.\x00p\x00y\x00\x0f\x00\x1a\x00\x0c\x00M\x00a\x00c\x00i\x00n\x00t\x00o\x00s\x00h\x00 \x00H\x00D\x00\x12\x009Users/julian/Documents/Development/MovieDB/Python/IMDB.py\x00\x00\x13\x00\x01/\x00\x00\x15\x00\x02\x00\r\xff\xff\x00\x00\x00\x00\x00\x00', '/Users/julian/Documents/Development/MovieDB/Python/IMDB.py'))
except KeyboardInterrupt:
    pass
