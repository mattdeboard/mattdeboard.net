public: yes
tags: [latex, python, math, scipy]
summary: Generate LaTeX-formatted string representation of a Chebyshev polynomial of nth degree.

==============================
Chebyshev polynomials in LaTeX
==============================

I'm recovering from an obsession with `Chebyshev polynomials <http://mathworld.wolfram.com/ChebyshevPolynomialoftheFirstKind.html>`_. Despite the fancy title and somewhat-intimidating definition, Chebyshev polynomials are actually a fantastic shortcut -- relative to what we're taught from the book -- to factoring out trigonometric double-angle problems like `cos(6x)`. 

I was originally going to write a script that calculated the Chebyshev polynomials, but when I learned Python's `SciPy <http://www.scipy.org/>`_ library already has a function, I "pivoted." Instead I wanted to write the below script, which calculates the polynomial using scipy.special.orthogonal.chebyt(), then creates a `LaTeX <http://www.latex-project.org/>`_ -formatted string representation of the equation. For example, the output for the ninth-degree Chebyshev polynomial is rendered thusly:

.. image:: http://mathbin.net/equations/62360_0.png

Here's the code, it should be pretty straightforward:

.. sourcecode:: python

 import sys
 import math
 from scipy.special import orthogonal as orth 

 def chebyTex(n):
     '''Returns a LaTeX-formatted string for a Chebyshev polynomial of
     order n.'''
     c = orth.chebyt(n)
     coeffs = []
     for i in c: 
         if i >= 1 or i <= -1:
             coeffs.append(int(round(i)))
         else:
             pass
     
     pows = [coeffs.index(i)*2 for i in coeffs]
     pows.sort(reverse=True)  

     # The only "magic" in this function is some string manipulation to
     # handle the LaTeX formatting for super- and subscript characters.
     arrays = zip(coeffs, pows)
     latex_string = 'T_{%s}(x) = ' % n
     for array in arrays:
         z = n-arrays.index(array)*2
         if arrays[-1] != array:
             latex_string += r'%sx' % array[0]
             latex_string += r'^{%s} + ' % z
         else:
             if not n % 2:
                 latex_string += '%s' % array[0]
             else:
                 latex_string += '%sx' % array[0]
                
     return latex_string
        

 if __name__ == '__main__':
     s = chebyTex(int(sys.argv[1]))
     print s

It would be trivial to connect to something like `MathBin <http://mathbin.net>`_ pull down and store the resulting image, but was beyond the scope of this little script.
