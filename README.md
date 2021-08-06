# Droll

This dice rolling simulator was designed as a digital aid for playing
roleplaying games, and named "droll" as an abbreviation for "die roll" or "dice
roller".  The term "droll" also seemed apt as a reference to its beginnings as
an amusing little toy program, though it now offers reasonably sophisticated
support for different dice-rolling techniques used in various RPGs.  It is a
Ruby library with included command line interface (`droll`) and IRC dicebot
(`drollbot`).

At present, droll provides a number of different die rolling techniques,
including simplistic roll-and-sum, various exploding roll schemes, counting
dice that meet a threshhold, and rolling several dice then discarding some by
threshhold before summing.  Threshholds are typically the highest possible
number for the die type, or the maximum possible for the sum in some cases, or
even the lowest possible number for the die type, though alternate threshholds
can be used.

Use NdN as the pattern for normal die rolls (where N stands in for a number),
and NxN for exploding die rolls, for instance.  Modifiers can be included as
well: NdN+N or NdN-N.  Die codes, at this time, do not work if they have spaces
in them.  Certain die codes are rejected (i.e.  0x0).  Exploding is limited to
an unreasonably high number (1000), to prevent crashing.  Specifying alternate
threshholds uses a .N syntax (NxN.N).  Die values are chosen (pseudo)randomly
from numbers between 1 and N (the number following the x or d), or between 0
and N if the N is preceded by a 0 character.  An example of the full
sophistication of die code parsing is:

    4x05.4+7

This would roll four virtual dice numbered 0-5, and each die would explode on
any 4 or 5 result.  All die results are added together, and 7 added to the
total to yield a final number.

The first number following each 4 or 5 in this example is the result of a die
immediately rolled to handle exploding die values.


## installation

Installing the Ruby programming language's runtime is a relatively simple
operation, and a prerequisite for running droll (because it is a Ruby project).
The "standard" reference implementation, often called MRI/YARV (for Matz' Ruby
Implementation + Yet Another Ruby VM) is available in the default software
management system of most open source Unix-like operating systems as well as
Apple MacOS X, though you should make sure your system uses the 1.9 version of
ruby instead of the older 1.8 version (see below).  For users of Microsoft
Windows, the [RubyInstaller for Windows](http://rubyinstaller.org/) makes Ruby
easy to install there, as well.

The normal way to install Ruby on most operating systems will also install the
gems tool, which is a sort of software management system specific to Ruby
tools, and is the way most Ruby libraries and applications are distributed,
including droll.

Once you have Ruby installed with rubygems, installing droll should be easy.
Just use the gem command:

    $ gem install droll

You can also download the gem package from the [FossRec project][fossrec] and
use the gem command to install it:

    $ gem install droll-<version>.gem

In this example, replace `<version>` with the version number in the name of the
gemfile you downloaded.  For version 1.0.0, for instance, the command might
look like this (though as of this writing it is not yet at version 1.0.0):

    $ gem install droll-1.0.0.gem

Note that the `$` character indicates your shell prompt, and is not part of the
command.  Depending on your setup, you may need to use `sudo`, log in as root,
or engage in some other additional activities to ensure the gem is installed
correctly.  If you know of different requirements for installation on other
systems, please feel free to submit patches to this README file via one of the
approaches detailed in the **contributions** section at the bottom of this
file.

### Ruby 1.8

Droll assumes Ruby 1.9.x or later, and some die code validation (for zero-based
die codes, e.g. 1d05) does not work properly with older Ruby versions.
Normally, it will not install on a system using a version of Ruby older than
1.9, but this can be overridden if you wish by using the `-f` option with the
`gem install` command:

    $ gem install -f droll

## usage

The following sections explain how to use the executable tools that come with
the droll library: a `droll` command line interface and a `drollbot` IRC
dicebot.


### `droll` command line

Using the basic droll program from the command line is pretty simple:

    $ droll d20
    d20: [15] + 0 = 15
    $ droll 2d4+3
    2d4+3: [1, 2] + 3 = 6
    $ droll 1d10 2d03
    1d10: [1] + 0 = 1
    2d03: [3, 2] + 0 = 5
    $ droll 4x05.4+7
    4x05.4+7: [5, 2, 0, 4, 0, 1] + 7 = 19

In each example, the numbers between `[brackets]`, separated by commas, are the
numberic results for each of the individual dice rolled.  As shown by the third
example of using the command line droll program above, multiple die codes can
be listed on a single line, with the results of each roll being shown on a
separate line of output.  In the last example, the first number following each
4 or 5 in this example is the result of a die immediately rolled to handle
exploding die values.


### `drollbot` IRC dicebot

The drollbot interface to the functionality of the droll library does some
things a little differently.  For instance, any input to a channel monitored by
drollbot will be checked to see if it starts with a die code that drollbot
understands.  If so, it will parse that line as a command to produce die roll
output.  Starting a line with `droll` or `drollbot` will not have the same
effect.  As such, this may occur:

    12:38 < apotheon> 1d20+3
    12:38 < drollbot> <apotheon> rolls 1d20+3: [10] + 3 = 13

The output from drollbot is a touch more verbose; this is an example of how it
works within a standard IRC channel.  Private messages may be sent to drollbot,
with slightly differently formatted output:

    12:40 <apotheon> /msg drollbot 1d20+3
    12:40 <drollbot> result of 1d20+3: [13] + 3 = 16

Note that this example is not perfectly representative.  The `/msg` command is
sent from an IRC channel where the drollbot instance is logged in, and the
`result` message appears in a PM that is not visible to anyone else in the IRC
channel where the dicebot was invoked.

In either case, a comment may be appended to the end of the line.  Within an
IRC channel:

    12:42 < apotheon> 1d20+3 crappy save
    12:42 < drollbot> <apotheon> rolls 1d20+3: [17] + 3 = 20 (crappy save)

Drollbot will echo any text following your die code back to you as a
parenthetical note.  This applies to die codes as well as other text so that,
unlike with the command line `droll` utility, multiple rolls cannot be
specified in a single command:

    12:43 < apotheon> 2x05 d20+3 2d4 many
    12:43 < drollbot> <apotheon> rolls 2x05: [4, 2] + 0 = 6 (d20+3 2d4 many)

To start drollbot, all you need to do is ensure that it is configured with an
IRC network to which it should connect, and some channel names it should join,
then run the program.  An example configuration file is included with the
installed gem.  After installing the droll gem, you can find the example
configuration file in the directory hierarchy where the gem was installed,
under the `etc` subdirectory.  The example configuration file is called
`drollbot.conf.sample`.  Use the `drollbot -c` or `drollbot --config` command
to see more information about configuring drollbot.


## licenses

Droll project files may be redistributed under the terms of the [COIL][coil] or
the [Open Works License][owl], at your option; it is "dual-licensed".  These
licenses were chosen with a conscious adherence to copyfree policies.  See the
[Copyfree Initiative][copyfree] site for more details about the copyfree
philosophy of licensing.

See the COPYING file in the project repository for more information about
copyright and licensing for droll and the code associated with it.

[coil]: http://coil.apotheon.org
[owl]: http://owl.apotheon.org
[copyfree]: http://copyfree.org
[fossrec]: http://droll.fossrec.com
