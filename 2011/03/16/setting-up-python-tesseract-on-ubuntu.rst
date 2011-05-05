
public: yes 
tags: [ocr]

=======
foo
=======

After downloading, you'll notice that the font files (\*.tif) are named in the format *eng.arialbd.g4.tif*, while the box files are named *eng.arialbd.box*. If you try to run:

.. sourcecode:: bash

    tesseract eng.arialbd.g4.tiff eng.arialbd nobatch box.train.stderr

Tesseract will return the following error (included here for the sake of folks Googling for a solution):

.. sourcecode:: bash

    Tesseract Open Source OCR Engine with LibTiff
    read_next_box\:Error\:Can't open file\:Cant open box file eng.arialbd.g4.box 2
    Segmentation fault

The issue is that Tesseract is looking for a boxfile that exactly matches the .tif, so we've got to get that ".g4" in there. Instead of renaming each file individually, I wrote a Python script:

.. sourcecode:: python

    import os
    import subprocess

    # Make sure to change this to wherever your Tesseract install is looking
    # for the data files.
    boxfile_directory = '/usr/local/share/tessdata' 

    tif_files = []

    for filename in os.listdir(boxfile\_directory):
        root, extension = os.path.splitext(filename)
	if extension == '.box':
        # Obviously adjust this to your particular batch of tiff/box file
	# pairs. It may not be "g4" for you, I just hardcoded for sake
 	# of expediency.
            os.rename(filename, ''.join(root + '.g4.box'))

    if extension == '.tif':
        tif_files.append(root)

    for tif_file in tif_files:
        tif = ''.join(tif_file+'.tif')
        subprocess.call(["tesseract", tif, tif_file,
                         "nobatch","box.train.stderr"])

There.
    
