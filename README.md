 gpackage
==========

Copyright 2013, Gunnar Strand

gpackage is a simple package/symbolic link manager. It manages symbolic links
to the physical files locations instead of copying files, making it possible to
install software packages in completely separate locations. This makes it easy
to uninstall applications by simply removing the entire directory tree for the
application.

Most Linux software packages install themselves in /usr, /lib etc., which makes
difficult to uninstall the files without a sharp package management system like
dpkg. But how what about software not in the distribution's repositories, or
bleeding edge? This is where gpackage can help out.

A setup can look like this:

    /opt/app             - physical install location
    /opt/bin,lib,usr,... - structure with symbolic links pointing into /opt/app

The package files are simple to create:

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
    mythtv.0.26.0
    % gpackage enable mythtv-0.26.0
    Installing X files
    % ls -l /opt/bin/mythtv-setup
    /opt/bin/mythtv-setup -> /opt/app/mythtv-0.26.0/bin/mythtv-setup

Of course, the first sevens steps should also be handled by gpackage, but are
not, yet.

See `gpackage ---man-page` for more information.

 License
=========

gpackage is distributed under [The Artistic License 2.0][tal2].

   [tal2]: http://www.perlfoundation.org/artistic_license_2_0

