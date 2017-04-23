# -*- coding: utf-8 -*-
##############################################################################
#
#    doscaal_profile module for OpenERP, Manage line per product
#    Copyright (C) 2017 SYLEAM Info Services (<http://www.Syleam.fr/>)
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

from odoo import fields, models, api, exceptions
from random import randrange


class SaleOrder(models.Model):
    _inherit = 'sale.order'

    week_type = fields.Selection(selection=[('work', 'work'), ('holliday', 'holliday')], string='Week type', help='Help note')

    @api.multi
    def generate_meal(self):
        for sale in self:
            weekday = {
                0: 'Monday',
                1: 'Tuesday',
                2: 'Wenesday',
                3: 'Thursday',
                4: 'Friday',
                5: 'Saturday',
                6: 'Sunday',
            }
            attribute = []
            for sequence in range(7):
                if sale.week_type == 'work':
                    if sequence in [0, 1, 3]:
                        complexity = 1
                    elif sequence == 2:
                        complexity = 3
                    elif sequence in [4, 5, 6]:
                        complexity = 4
                if sale.week_type == 'holliday':
                    complexity = 4
                previous_product = sale.order_line.search([], limit=14).mapped('product_id.product_tmpl_id')
                if attribute:
                    product_ids = self.env['product.product'].search([('meal_ok', '=', 'True'),
                                                                      ('product_tmpl_id', 'not in', previous_product.ids),
                                                                      ('attribute_value_ids', 'not in', attribute),
                                                                      ('complexity', '<=', complexity)])
                else:
                    product_ids = self.env['product.product'].search([('meal_ok', '=', 'True'),
                                                                      ('product_tmpl_id', 'not in', previous_product.ids),
                                                                      ('complexity', '<=', complexity)])
                if not product_ids:
                    raise exceptions.Warning('No meal possible')
                product = product_ids[randrange(len(product_ids))]
                attribute += product.attribute_value_ids.ids
                values = {
                    'product_id': product.id,
                    'product_uom_qty': 3,
                    'product_uom': product.uom_id.id,
                    'order_id': sale.id,
                    'sequence': sequence,
                    'customer_lead': sequence,
                    'complexity': product.complexity,
                    'weekday': weekday[sequence],
                }
                line = self.env['sale.order.line'].create(values)
                line.product_id_change()


# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
