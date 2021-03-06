# -*- coding: utf-8 -*-
##############################################################################
#
#    doscaal_profile module for OpenERP, Manage line per product
#    Copyright (C) 2016 SYLEAM Info Services (<http://www.Syleam.fr/>)
#              Alexandre Moreau <alexandre.moreau@syleam.fr>
#
#    This file is a part of doscaal_profile
#
#    doscaal_profile is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    doscaal_profile is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

{
    'name': 'Doscaal Profile',
    'version': '1.0',
    'category': 'Custom',
    'description': """Manage line per product""",
    'author': 'SYLEAM',
    'website': 'http://www.syleam.fr/',
    'depends': [
        'sale',
        'mrp',
        'purchase',
    ],
    'init_xml': [],
    'images': [],
    'update_xml': [
        'views/product_template.xml',
        'views/sale_order.xml',
        'views/product_category.xml',
        # 'security/ir.model.access.csv',
    ],
    'demo_xml': [],
    'test': [],
    # 'external_dependancies': {'python': ['kombu'], 'bin': ['which']},
    'installable': True,
    'active': False,
    'license': 'AGPL-3',
}

# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
