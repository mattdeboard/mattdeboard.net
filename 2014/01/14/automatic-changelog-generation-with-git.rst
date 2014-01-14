public: yes
tags: [git,python]
summary: Use git & Python to auto-generate changelogs.

========================================
Using git & Python to autogen changelogs
========================================

Background
==========

As part of the communication process at work, devs maintain changelogs for some of our projects. What these consist of is a single `RELEASE NOTES.md` file in the project root, which contains lines that look like::

    ## v1.7 2013/03/17
    * [#100](https://github.com/courseload/project/pull/100) - Finalized previously preliminary stuff
    * [#99](https://github.com/courseload/project/pull/99) - Did some preliminary stuff

    ## v1.6.4 2013/03/14
    * [#98](https://github.com/courseload/project/pull/98) - Made dongles brighter.
    * [#97](https://github.com/courseload/project/pull/97) - Improved widget performance by 3.8x


At first, these were created by having devs also update `RELEASE NOTES.md` with each pull request. This distributed the workload, but it also made having multiple pull requests a big pain in the ass since the same file, usually the same line in the same file, was being modified by multiple pull requests. So we stopped that practice and instead moved to a hand-made `RELEASE NOTES.md` file, maintained by these de facto primaries. Obviously this is super annoying, and creates a lot of busy work. For months though, streamlining the process fell far down on the priority list until I just couldn't take it anymore, I knew there had to be a better way of dealing with this.

git log
=======

In order to automate this, I needed to massage git to give me only merge commits. We can do that with::

  git log --merges

This is good, but it shows a lot of extra information I'd have to parse out. If you'll notice in my example above, the lines in `RELEASE NOTES.md` are formatted like ``[#<pull request number>](https://github.com/courseload/project/pull/<pull request number>) - <pull request description>``. So we notice right away we need two things from the git log:

1. The commit message of the merge. Think of this as the subject line of an email. We want this because this has the number of the pull request.

2. The pull request description, which works out to be, for the sake of this blog post, the equivalent of the first line of the body of the aforementioned email.

This git command gets us this info without a bunch of cruft::

  git log --pretty=format:'%s%n%b' --merges

Python
======

It's great that we have just the info we want, but I know we're also going to need to do two things:

1. Parse out the pull request number

2. Use it to create the changelog entry

To do this I need to massage the ``git log`` output a bit more. I want it to return the lines pre-formatted, ready for Python to plug in the pull request number: 

  .. sourcecode:: python

     #!/usr/bin/env python
     """This script generates release notes for each merged pull request from
     git merge-commit messages.

     Usage:

     `python release.py <start_commit> <end_commit> [--output {file,stdout}]`

     For example, if you wanted to find the diff between version 1.0 and 1.2,
     and write the output to the release notes file, you would type the
     following:
     
     `python release.py 1.0 1.2 -o file`
     
     """

     import os.path as op
     import re
     import subprocess


     def commit_msgs(start_commit, end_commit):
         """Run the git command that outputs the merge commits (both subject
         and body) to stdout, and return the output.

         """
         fmt_string = ("'%s%n* [#{pr_num}]"
                       "(https://github.com/courseload/project/pull/{pr_num}) - %b")
         return subprocess.check_output([
             "git",
             "log",
             "--pretty=format:%s'" % fmt_string,
             "--merges", "%s..%s" % (start_commit, end_commit)])

         
    def release_note_lines(msgs):
        """Parse the lines from git output and format the strings using the
           pull request number.

        """
        ptn = r"Merge pull request #(\d+).*\n([^']*)'$"
        pairs = re.findall(ptn, msgs, re.MULTILINE)
        return [body.format(pr_num=pr_num) for pr_num, body in pairs]


    def prepend(filename, lines):
        """Write `lines` (i.e. release notes) to file `filename`."""
        if op.exists(filename):
            with open(filename, 'r+') as f:
                first_line = f.read()
                f.seek(0, 0)
                f.write('\n\n'.join([lines, first_line]))
        else:
            with open(filename, 'w') as f:
                f.write(lines)
                f.write('\n')
 

    if __name__ == "__main__":
        import argparse
        
        parser = argparse.ArgumentParser()
        parser.add_argument('start_commit', metavar='START_COMMIT_OR_TAG')
        parser.add_argument('end_commit', metavar='END_COMMIT_OR_TAG')
        parser.add_argument('--filepath', '-f',
                            help="Absolute path to output file.")           
        args = parser.parse_args()
        start, end = args.start_commit, args.end_commit
        lines = '\n'.join(release_note_lines(commit_msgs(start, end)))

        if args.filepath:
            filename = op.abspath(args.filepath)
            prepend(filename, lines)
        else: 
            print lines

To view the output in stdout, at the command line type::

  $ ./release.py 1.7 HEAD

Or, specify an output file::

  $ ./release 1.7 HEAD ./RELEASE\ NOTES.md

  


