tags: [rstblog, mitsuhiko, python, blog]
public: yes
summary: Config & maintenance of Armin Ronacher's rstblog

===================
My guide to rstblog
===================

For about six months now I've been using `Armin Ronacher's <http://lucumr.pocoo.org/>`_ minimalist blog "platform", `rstblog <https://github.com/mitsuhiko/rstblog>`_. For static blogs like this one, it's great. However, it is definitely not a plug-and-play blog solution. It has definitely had a learning curve, but nothing too intimidating. This post will describe some of my experiences with rstblog over the past six months, and some of the optimizations I've made to the publishing process.

Before I go any further, I want to thank `Morten Siebuhr <http://sbhr.dk>`_, whose excellent `blog post on rstblog <http://sbhr.dk/2010/11/30/using_rstblog/>`_ helped me both configure and maintain my blog. He illuminated some of the general points of rstblog, and before you go any further, please read it.

---------------
Some background
---------------

First, rstblog is so called because it is powered by `reStructuredText <http://docutils.sourceforge.net/rst.html>`_, a very powerful, easy-to-grok markup syntax. (It's right up there with `Fabric <http://fabfile.org/>`_ on my `"Idiot-Proof/Time-Saving" graph <http://mattdeboard.net/static/GRAPH.png>`_.) I never realized how pervasive rst is, until I decided to move to rstblog from `Tumblr <http://tumblr.com>`_. Using Armin's blog platform (which he calls a `"Not-invented-here <http://en.wikipedia.org/wiki/Not_Invented_Here>`_ site generator") has paid dividends just in terms of the knowledge of rst I've been forced to acquire.

Some other concepts & tech with which I've had to get familiar in support of rstblog:
  1. `YAML <http://www.yaml.org/spec/1.2/spec.html>`_ - Specifically, getting a grip on how finicky it can be about whitespace.
  2. `Makefiles <http://linuxdevcenter.com/pub/a/linux/2002/01/31/make_intro.html>`_ - I knew ``make`` is how Linux compiles or otherwise builds software. But I was not aware of how to put Makefiles into play to control this behavior. (I'm really getting sick of mentioning this guy here, but Brett Hoerner has a simple Makefile `here <https://github.com/bretthoerner/bretthoerner.com/blob/master/Makefile>`_ that I incorporated into my own workflow.)
  3. `virtualenv <http://pypi.python.org/pypi/virtualenv>`_ - Though virtualenv is now so pervasive in my dev work that I don't really remember a time when I *wasn't* using it, I know I first used it for my blog. I consider `this <http://www.clemesha.org/blog/modern-python-hacker-tools-virtualenv-fabric-pip>`_ to be a canonical explanation of why virtualenv is great. (Not that I'm a keeper of canon or anything.)
  4. `RVM <https://rvm.beginrescueend.com/>`_ - I use `Blueprint <http://blueprintcss.org>`_ to manage CSS files for each of my websites. Blueprint requires Ruby. I'm an idiot, so I need Ruby Version Manager to help me be not stupid.

--------
Workflow
--------

The big, tough nut to crack for rstblog, from my perspective, has been workflow. Nowadays, mine looks like this:
  
  1. Fire up emacs on my local machine and create blog post.
  2. Tab over to terminal, cd to my blog's root directory (still on local machine).
  3. ``$ make clean``
  4. ``$ make build``
  5. ``$ make upload``
  6. ???
  7. Publish

Pretty fast. It's nearly instant. However, there were some confusing spots when I first started.


Stay local
~~~~~~~~~~

First, note that **I did no work on the server hosting my blog**, excepting the initial directory creation. Everything was created locally, and my Makefile took care of pushing data to my live server, courtesy of `scp <http://linux.die.net/man/1/scp>`_. Don't make the mistake I did last December/January in doing all the work on the remote end. Make a single /blog/ directory on your local machine and use that as your staging area.


Beware extraneous files
~~~~~~~~~~~~~~~~~~~~~~~

The second thing to be aware of is that the build process for rstblog is a big vacuum. It does not discern between .rst, .rst~, #foo.rst#, overmyhead.jpg, asco.png, etc., files. It will create a blog entry for every file that is in either a ``<yyyy>/<mm>/<dd>/`` format directory or in the blog's root directory (mine is ``/a/mattdeboard.net/blog`` on my local machine). Before you ``make build``, ensure that there's nothing but entry.rst in that day's directory.

For example, if use vim and you're working on an entry titled "Matt's birthday" for June 3, 2011, you'll do:

.. sourcecode:: bash
  
  matt@Ubuntu:/a/mattdeboard.net/blog$ mkdir -p 2011/06/03
  matt@Ubuntu:/a/mattdeboard.net/blog$ vim 2011/06/03/matts-birthday.rst

If vim does an auto-save/backup of your file mid-edit, you may wind up with a matts-birthday.rst~ file in the directory along with matts-birthday.rst. rstblog's build process will create a blog entry for each. So make sure you somehow curate your directories and remove extraneous files. (For emacs, I added the following to my .emacs file:

.. sourcecode:: cl

  (setq backup-directory-alist '(("." . "~/.emacs_backups")))

If you use anything else, `you're on your own <http://google.com>`_).


index.html wonkiness
~~~~~~~~~~~~~~~~~~~~

I found that when I accidentally created unwanted blog entries as described above, they were really persistent about sticking around my root index.html file. Finally I figured out that I had to **delete the remote blog/index.html file** and re-``make upload``. That fixes it.


CSS & syntax highlighting
~~~~~~~~~~~~~~~~~~~~~~~~~

As you may be able to tell, I'm as excited as a puppy who just found his penis about syntax highlighting in my blog posts. That's because I recently figured out how to get it working using `Pygments <http://pygments.org/docs/quickstart/>`_ and CSS. 

A word about CSS: Use `Blueprint <http://blueprintcss.org>`_ for organizing and maintaining your CSS files. It makes things a million times easier once you get the hang of it. The finer points of Blueprint are beyond the scope of this post, but here is my bash alias I use to roll any CSS changes into my build:

.. sourcecode:: bash

  alias er="cd /a/mattdeboard.net; . bin/activate; cd /home/matt/blueprint/lib/; ruby compress.rb -p blog; cd /a/mattdeboard.net/blog; make clean; make build"

I am 100% sure I'm doing it wrong with Pygments. I have the styles hard-coded in my stylesheet, which I don't think I need to do. rstblog has support for Pygments, so it doesn't make sense that I'd need to put them in my stylesheet. However, it's done, it works, it looks how I want, so fixing it is an extremely low priority. If you've got insight on how this actually works, I'm all ears!


----------
Conclusion
----------

I like having this much control over the under-the-hood components of my blog. If you don't see the need, it's probably not worth the time investment. However, if you're a relative newcomer to Linux and/or Python, and you have the desire to learn more about both while simultaneously wanting to stab yourself in the face occasionally, I strongly recommend checking out rstblog. It is a great vehicle for self-education.
