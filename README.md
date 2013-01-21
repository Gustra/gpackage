# gpackage

gpackage is a simple package/symbolic link manager

## Description

Most software packages install files all over /usr, /lib, etc., which makes it
difficult to uninstall the files without a decent package management system
like dpkg. An alternative would be to put each package inside its own
directory, and install symbolic links in a central location. That is what
gpackage does.

gpackage manages symbolic links to the physical location of the files, making
it possible to install software packages in completely separate locations. This
makes it easy to uninstall applications by simply removing the entire directory
tree for the application. It was originally written to handle bleeding-edge
software in /opt, so that multiple versions of a package could be installed at
the same time, but only one version enabled at a time.

A setup can look like this:

    /opt/app             - physical installation location
    /opt/bin,lib,usr,... - structure with symbolic links pointing into /opt/app

The format of the package files is simple. The following creates symbolic links
in `/opt` for everything in `myssh-1.15`:

    @/opt
    /opt/app/myssh-1.15/

An installation run can look like this (assuming /opt/gpackages holds package
files):

    % cd /opt/build
    % wget ftp://ftp.osuosl.org/pub/mythtv/mythtv-0.26.0.tar.bz2
    % tar xjf mythtv-0.26.0.tar.bz2
    % cd mythtv-0.26.0
    % ./configure --prefix=/opt/app/mythtv-0.26.0
    % make install
    % echo "@/opt\n/opt/app/mythtv-0.26.0/" > /opt/gpackages/mythtv-0.26.0
    % gpackage list
    mythtv-0.26.0
    % gpackage enable mythtv-0.26.0
    % ls -l /opt/bin/mythtv-setup
    /opt/bin/mythtv-setup -> /opt/app/mythtv-0.26.0/bin/mythtv-setup

Of course, the first sevens steps should also be handled by gpackage, but are
not, yet.

See `gpackage ---man-page` for more information.

## Running the tests

You will need to have the follwing perl modules installed to execute the tests:

- Expect
- Test::Builder
- Test::Harness
- Test::More

To run the tests, go to the gpackage root directory and run:

    % prove t

## License

Copyright 2013, Gunnar Strand. gpackage is distributed under [The Artistic License 2.0][tal2].

   [tal2]: http://www.perlfoundation.org/artistic_license_2_0

