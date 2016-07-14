#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-


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

def node2str(node):
    if node.firstChild is None:
        str_text = 'None'
    else:
        str_text = node.firstChild.__unicode__().encode('utf-8', 'ignore')
    return str_text

def odf_dump_nodes(start_node, level=0):
    if start_node.nodeType==3:
        # text node
        print "  "*level, "NODE:", start_node.nodeType, ":(text):", node2str(start_node)
    else:
        # element node
        attrs= []
        for k in start_node.attributes.keys():
            attrs.append( k[1] + ':' + start_node.attributes[k]  )
        print "  "*level, "NODE:", start_node.nodeType, ":", start_node.qname[1], " ATTR:(", ",".join(attrs), ") ", node2str(start_node)
        """
        print "  "*level, "NODE:", start_node.nodeType, ":"
        print "_", start_node.qname[1]
        print "_ATTR:(", ",".join(attrs), ") "
        #print "_", str(start_node)
        bad_str = u""
        bad_str += str(start_node).decode('UTF-8')
        print "_", bad_str
        """

        for n in start_node.childNodes:
            odf_dump_nodes(n, level+1)
    return
