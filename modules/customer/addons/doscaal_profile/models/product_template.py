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

from odoo import models, fields


class ProductTemplate(models.Model):
    _inherit = 'product.template'

    complexity = fields.Selection(selection=[(1, 'easy'), (2, 'normal'), (3, 'complex'), (4, 'hard')], string='Level', help='Help note')
    meal_ok = fields.Boolean(string='Meal', help='Help note')


# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
