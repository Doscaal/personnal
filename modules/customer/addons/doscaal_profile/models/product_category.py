# -*- coding: utf-8 -*-
##############################################################################
#
#    doscaal_profile module for OpenERP, Manage line per product
#
#    This file is a part of doscaal_profile
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


class ProductCategory(models.Model):
    _inherit = 'product.category'

    product_ids = fields.One2many(comodel_name='product.template',
                                  inverse_name='categ_id', string='Product')


# vim:expandtab:smartindent:tabstop=4:softtabstop=4:shiftwidth=4:
