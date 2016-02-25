#!/usr/bin/env python
# -*- coding: utf-8 -

import codecs
import re
import sys

xml_file=sys.argv[1]

inpf=codecs.open(xml_file, 'r', 'utf-8')

escaped = re.compile(u'&(?!quot;|lt;|amp;|gt;|apos;)')
# Isaac (?!Asimov)
"""
&lt;
&amp;
&gt;
&apos
"""

lines = inpf.readlines()
inpf.close()
outf=codecs.open(xml_file, 'w', 'utf-8')

for l in lines:
    esc_found = escaped.search(l)
    if esc_found:
        #outf.write(l)
        broken_fixed = re.sub(r'&(\w+)', '', l )
        if broken_fixed:
            outf.write(broken_fixed)
    else:
       outf.write(l)

outf.close()
