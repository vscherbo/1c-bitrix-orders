#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import sys
from odf.opendocument import load
from odf_dump import odf_dump_nodes

"""
NODE: 1 : p  ATTR:( style-name:P2 )  ИНН: 
     NODE: 3 :(text): None
     NODE: 1 : variable-get  ATTR:( data-style-name:N0,name:inn )  0
       NODE: 3 :(text): None
     NODE: 3 :(text): None
     NODE: 1 : variable-get  ATTR:( data-style-name:N0,name:kpp )  0
       NODE: 3 :(text): None
   NODE: 1 : table  ATTR:( style-name:Таблица1,name:Таблица1 ) 
"""

infile = u""
infile += sys.argv[1]
doc = load(infile)


odf_dump_nodes(doc.text)




