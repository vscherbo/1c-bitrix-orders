#!/usr/local/bin/python2.7
# -*- coding: utf-8 -

### !/usr/bin/env python2.7


from datetime import datetime
from decimal import Decimal
import codecs
import re
import psycopg2
import sys, os
from xml.etree import ElementTree as ET
from xml.etree.ElementTree import tostring

#outf.write("truncate table bx_buyer;\n")
#outf.write("truncate table bx_order;\n")
#outf.write("truncate table bx_order_feature;\n")
#outf.write("truncate table bx_order_item;\n")
#outf.write("truncate table bx_order_item_feature;\n")

xml_input_file=sys.argv[1]
sql_output_file=sys.argv[2]
pg_srv=sys.argv[3]

if (xml_input_file is None) or (not os.path.isfile(xml_input_file)) or (0 == os.path.getsize(xml_input_file)):
    print "file " + xml_input_file + " doesn't exist OR has zero size. Exiting..."
    sys.exit(0)    

if (sql_output_file is None) or (pg_srv is None):
    print "A wrong number of parameters in comnmand line. Exiting..."
    sys.exit(0)    

#TODO check pg_srv
con = psycopg2.connect("host='" + pg_srv + "' dbname='arc_energo' user='arc_energo'") # password='XXXX' - .pgpass
#TODO check return code
cur = con.cursor()
cur.execute('SELECT bx_buyer_id FROM bx_buyer')
db_buyers = cur.fetchall()
cur.execute('SELECT "Номер" FROM bx_order')
db_orders = cur.fetchall()


# Moved outside of this programm
#fname_parts=os.path.splitext(xml_fullname)
#sql_fullname=fname_parts[0]+'.sql'

#tree=ET.parse('orders-2014.xml')
#sqlf=codecs.open('orders.sql', 'w', 'utf-8')
#tree=ET.parse('orders-2014-11-28_09_30_46.xml')
#sqlf=codecs.open('orders-2014-11-28_09_30_46.sql', 'w', 'utf-8')
tree=ET.parse(xml_input_file)
sqlf=codecs.open(sql_output_file, 'w', 'utf-8')

createf=codecs.open('create.sql', 'w', 'utf-8')

root = tree.getroot()

def elem2str(aLabel, aTag, aText):
    global sql_flds,sql_vals
    if None != aText and u'\n' != aText:
       rstr = aLabel + aTag + u'=' + aText +u'\n'
       sql_flds.append(' "' + aTag.replace(' ', '_') + u'"')
       sql_vals.append(' \'' + aText.replace('\'', '\'\'') + u'\'')
    else:
       rstr = u''
    return rstr

cnt=0
existing_order = re.compile(u'Статуса заказа ИД=(.*)')
# db_buyers = []  -  fetchall from DB
for child in root:
    outf=codecs.open('order.tmp', 'w', 'utf-8')
    cnt=cnt+1
    #outf.write("#=" + str(cnt) + ", child=" +child.tag + "\n")

    sql_flds = []
    sql_vals = []
    for clients in child.findall(u'Контрагенты'):
        for cli in clients.findall(u'Контрагент'):
            # DEBUG outf.write(u'    -- next client\n')
            for elem in cli.iter():
		        if u'Ид'== elem.tag:
		            outf.write(u'\n\n-- ###################################################\n')
		            outf.write(elem2str(u'-- bx_buyer:', elem.tag, elem.text))
		            buyer = elem.text.split("#") #0-id, 1-bx_logname, 2-bx_name
		            sb_id = buyer[0]
		            buyer[1] = buyer[1].strip(u' ')
		            buyer[2] = buyer[2].strip(u' ')
		            #outf.write(u"-- typeof sb_id=" + str(type(sb_id)) + u"'\n")
		            #print 'sb_id=', sb_id
		            #print 'sb_id_key=', (int(sb_id), )
		            #print db_buyers
		            if (int(sb_id), ) in db_buyers:
		                outf.write(u"-- UPDATE bx_buyer SET bx_logname='" + buyer[1] + u"', bx_name='" + buyer[2] + u"'\n")
		                outf.write(u"-- WHERE bx_buyer_id=" + buyer[0] +";\n")
		            else:
		                db_buyers.append( (int(sb_id), ) )
		                #print "after append db_buyers=", db_buyers
		                outf.write(u'INSERT INTO bx_buyer(bx_buyer_id,bx_logname,bx_name)\n')
		                outf.write(u"VALUES (\'" + u'\', \''.join(buyer) + "\');\n")
		            if 1 == cnt:
		                createf.write(u"-- DROP TABLE bx_buyer CASCADE;\n")
		                createf.write(u"CREATE TABLE bx_buyer(bx_buyer_id integer,dt_insert timestamp without time zone DEFAULT now(), bx_logname varchar,bx_name varchar);\n\n")
                 

    if 1 == cnt:
        createf.write(u"-- DROP TABLE bx_order CASCADE;\n")
        createf.write(u"CREATE TABLE bx_order(id serial, bx_buyer_id integer\n")
    outf.write(u"\nINSERT INTO bx_order(\n")
    
    sql_flds = ['bx_buyer_id']
    sql_vals = [sb_id]
    for elem in child.findall(u'*'):
        outf.write(elem2str(u'-- bx_order:', elem.tag, elem.text))
    bx_order_id = child.find(u'Номер').text
    if (int(bx_order_id), ) in db_orders:
        flagNew = False
    else:
        flagNew = True
        db_orders.append( (int(bx_order_id), ) )
    
    for reqs in child.findall(u'ЗначенияРеквизитов'):
        sale_order_features_insert_dict = []
        for req in reqs.findall(u'ЗначениеРеквизита'):
            sale_order_features_insert = u'INSERT INTO bx_order_feature (bx_order_Номер, fname, fvalue) VALUES(' + bx_order_id +',\n'
            str1 = u''

            for elem in req.iterfind(u'Наименование'):
                str1 = elem.text
                sale_order_features_insert += '\'' + elem.text + '\', '
            for elem in req.iterfind(u'Значение'):
                if elem.text:
                    elem_text = elem.text.replace('\r\n','/').replace('\n','/')
                    #'/'.join(elem_text.splitlines())
                else:
                    elem_text = u""
                str1 = str1 + u'=' + elem_text+'\n'
                sale_order_features_insert += '\'' + elem_text + '\');'
            #order_status = existing_order.search(str1)
            #if order_status:
            #    tmp_status = u''
            #    tmp_status = tmp_status + order_status.group(1)
                #outf.write(u" >>> order_status=_" + tmp_status + u"_\n")
            #    if 'N' == tmp_status:
            #        flagNew = True
                    #outf.write(u" >>> flagNew=True\n")
            #    else:
            #        flagNew = False
                    #outf.write(u" >>> flagNew=False\n")
            outf.write(u"-- Реквизит::"+str1)
            req.clear()
            sale_order_features_insert_dict.append(sale_order_features_insert)

    if 1 == cnt:
        createf.write(u' varchar\n,'.join(sql_flds) + " varchar);\n\n")
    outf.write(u','.join(sql_flds) + ")\n")
    outf.write(u"VALUES (" + u','.join(sql_vals) + ");\n\n")

    for insert_clause in sale_order_features_insert_dict:
        outf.write(insert_clause + '\n')


    sql_flds = ['bx_order_Номер']
    sql_vals = []
    sql_vals.append(bx_order_id)
    if 1 == cnt: 
        createf.write(u"-- DROP TABLE bx_order_item CASCADE;\n")
        createf.write(u"CREATE TABLE bx_order_item(id serial,\n")
# OLD place    outf.write(u"INSERT INTO bx_order_item(\n")
    for basket in child.findall(u'Товары'):
        # IT WORKS! for sale_item in basket.findall(u'*'):
        for sale_item in basket.iter(u'Товар'):
            outf.write(u"\nINSERT INTO bx_order_item(\n")
            if sale_item.find(u'Ид').text:
               bx_order_item_id = sale_item.find(u'Ид').text
            else:
               bx_order_item_id = u"NO_ID"
            #bx_order_item_id = sale_item.find(u'Ид').text
            for reqs in sale_item.findall(u'ЗначенияРеквизитов'):
                sale_item_features_insert_dict = []
                for req in reqs.findall(u'ЗначениеРеквизита'):
                    sale_item_features_insert = u"INSERT INTO bx_order_item_feature (bx_order_Номер, bx_order_item_id, fname, fvalue) VALUES(" + bx_order_id +", '" + bx_order_item_id +"',\n"
                    str1 = u''
                    for elem in req.iterfind(u'Наименование'):
                        str1 = elem.text
                        sale_item_features_insert += '\'' + elem.text + '\', '
                    for elem in req.iterfind(u'Значение'):
                        if elem.text:
                            elem_text = elem.text
                        else:
                            elem_text = u""
                        str1 = str1 + u'=' + elem_text+'\n'
                        sale_item_features_insert += '\'' + elem_text + '\');'
                    outf.write(u"-- Реквизит::"+str1)
                    req.clear()
                    # After INSERT  bx_order_item  outf.write(sale_item_features_insert + '\n')
                    sale_item_features_insert_dict.append(sale_item_features_insert)
        
        
            outf.write(u'    -- next item\n')
            sql_flds = [u'bx_order_Номер']
            sql_vals = []
            sql_vals.append(bx_order_id)


            for elem in sale_item.iter():
                outf.write(elem2str(u'-- bx_order_item:', elem.tag, elem.text))
            if 1 == cnt:
                createf.write(u' varchar\n,'.join(sql_flds) + " varchar);\n\n")
            outf.write(u','.join(sql_flds) + ")\n")
            outf.write(u"VALUES (" + u','.join(sql_vals) + ");\n\n")

            if 1 == cnt:
                createf.write(u"-- DROP TABLE bx_order_item_feature CASCADE;\n")
                createf.write(u'CREATE TABLE bx_order_item_feature (id serial, bx_order_item_id numeric, fname varchar, fvalue varchar);\n') 
            for insert_clause in sale_item_features_insert_dict:
                outf.write(insert_clause + '\n')

    outf.write(u'SELECT fn_createinetbill('+ bx_order_id +u');')
    outf.close()
    outf=codecs.open('order.tmp', 'r', 'utf-8')
    if flagNew:
        #sqlf.write(" >>>>>>>>> copy sql to output\n")
        sqlf.write(outf.read())
    else:
        sqlf.write("-- Skip existing order " + bx_order_id + "\n")
    outf.close()



#sqlf.write(u'-- Add constraints\n')
#sqlf.write(u'ALTER TABLE bx_order ADD CONSTRAINT "UX_bx_order_id" UNIQUE ("Номер");\n')
#sqlf.write(u'ALTER TABLE bx_order_feature ADD CONSTRAINT "FK_bx_order" FOREIGN KEY (bx_order_Номер) REFERENCES bx_order ("Номер") ON UPDATE CASCADE ON DELETE RESTRICT;\n')
#sqlf.write(u'ALTER TABLE bx_order_item ADD CONSTRAINT "FK_bx_order" FOREIGN KEY (bx_order_Номер) REFERENCES bx_order ("Номер") ON UPDATE CASCADE ON DELETE RESTRICT;\n')

#sqlf.write(u'CREATE INDEX "FKI_bx_order_Номер_item" ON bx_order_item USING btree ("bx_order_Номер");')
#sqlf.write(u'CREATE INDEX "FKI_bx_order_Номер_feature" ON bx_order_feature USING btree ("bx_order_Номер");')


createf.close()
sqlf.close()

