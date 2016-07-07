#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import svglue


# load the template from a file
tpl = svglue.load(file='person-bank.svg')

# replace some text
#tpl.set_text('bill_amount1', u'2870,00')
#tpl.set_text('bill_amount2', u'2870,00')
#tpl.set_text('inn_kpp1', u'ИНН: 7802731174 КПП: 780201001')
#tpl.set_text('inn_kpp2', u'ИНН: 7802731174 КПП: 780201001')

pg_inn = '7802731174'
pg_kpp = '780201001'
pg_firm = u'ООО "АРКОМ"'
pg_bank = u'СТ-ПЕТЕРБУРГСКИЙ ФИЛИАЛ ПАО "ПРОМСВЯЗЬБАНК"'
pg_account = '40702810506000011363'
pg_account_bank = pg_account + u' в ' + pg_bank

tpl.set_text('firm1', pg_firm)
tpl.set_text('firm2', pg_firm)
tpl.set_text('inn1', pg_inn)
tpl.set_text('inn2', pg_inn)
tpl.set_text('kpp1', pg_kpp) 
tpl.set_text('kpp2', pg_kpp)
tpl.set_text('account_bank1', pg_account_bank)
tpl.set_text('account_bank2', pg_account_bank)

# replace the pink box with 'hello.png'. if you do not specify the mimetype,
# the image will get linked instead of embedded
#tpl.set_image('pink-box', file='hello.png', mimetype='image/png')

# svgs are merged into the svg document (i.e. always embedded)
#tpl.set_svg('yellow-box', file='Ghostscript_Tiger.svg')

# to render the template, cast it to a string. this also allows passing it
# as a parameter to set_svg() of another template
src = str(tpl)

# write out the result as an SVG image and render it to pdf using cairosvg
import cairosvg
with open('output.pdf', 'w') as out, open('output.svg', 'w') as svgout:
    svgout.write(src)
    cairosvg.svg2pdf(bytestring=src, write_to=out)

