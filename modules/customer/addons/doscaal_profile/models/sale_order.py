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
            for sequence in range(7):
                previous_product = sale.order_line.search([], limit=14).mapped('product_id')
                product_ids = self.env['product.product'].search([('meal_ok', '=', 'True')])
                if not product_ids:
                    raise exceptions.Warning('No meal possible')
                product = product_ids[randrange(len(product_ids))]
                values = {
                    'product_id': product.id,
                    'product_uom_qty': 3,
                    'product_uom': product.uom_id.id,
                    'order_id': sale.id,
                    'sequence': sequence,
                }
                line = self.env['sale.order.line'].create(values)
                line.product_id_change()


# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
