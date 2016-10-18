# Fichier qui contient les processus

# Configuration pour Python
VENV        = ~/.virtualenvs
CWD         = $(shell pwd)

PROJECT     = odooperso
CUSTOMER    = doscaal
MODULES     = $(CUSTOMER)_profile
CONFIGFILE  = odoo.conf
INTERFACE   = 127.9.9.9 

# PostgreSQL
DBHOST      = localhost
DBPORT      = 5432
DBUSER      = $(PROJECT)
DBPASS      = $(DBUSER)
DBNAME      = $(DBUSER)
DBROLE      = $(DBUSER)
TMPL_DBNAME = template0
RESTOREFILE = database/restore.pgsql

# Odoo
DBOPTIONS   = -r $(DBUSER) -w $(DBPASS) --db_host=$(DBHOST) --db_port=$(DBPORT)
IFOPTIONS   = --xmlrpc-interface=$(INTERFACE)
ADDONS      = $(CWD)/server/addons,$(CWD)/modules/customer/addons
FSTORE_PATH = ~/.local/share/Odoo/filestore

# Remote server information
REMOTE_DBHOST = localhost
REMOTE_DBPORT = 5432
REMOTE_DBUSER = oerpmaster
REMOTE_DBNAME = production
REMOTE_DBROLE = $(REMOTE_DBUSER)
REMOTE_PATH   = /tmp
REMOTE_FSTORE_PATH = $(FSTORE_PATH)

# Templates configuration
BRANCH      = master

# Bup
BUP_RESTORE_DATE = $(shell date --iso-8601)
BUP_RESTORE_TIME = 23:59:59
BUP_PATH    = database/backups

# Doc
DOC_PATH    = doc

.PHONY: doc

help:
	@echo "Vous pouvez utiliser \`make <cible>' ou <cible> est l'un de ceux ci-dessous"
	@echo "  init               Initialiser l'environnement de développement (virtualenv + utilisateur postgres)"
	@echo "  config             Creer le fichier $(CONFIGFILE) de cette instance"
	@echo "  run                Lance le service Odoo"
	@echo "  upgrade_<instance> Lance un update sur le module $(MODULES) sur l'instance choisie"
	@echo ""
	@echo "Pour une nouvelle installation, exécuter :"
	@echo "make init && make run"
	@echo "Et lancer votre navigateur sur http://$(INTERFACE):8069"

##########
#
# Environment Initialization
#
##########

python:
	@test -d $(VENV)/$(PROJECT) || virtualenv $(VENV)/$(PROJECT)
	@. $(VENV)/$(PROJECT)/bin/activate && pip install --upgrade pip
	@. $(VENV)/$(PROJECT)/bin/activate && pip install -r requirements.pip

postgresql:
	@echo "Create the PostgreSQL user $(DBUSER)"
	@createuser -SdRE $(DBUSER)
	@echo "Change default password for this one $(DBPASS)"
	@psql -c "ALTER USER $(DBUSER) ENCRYPTED PASSWORD '$(DBPASS)';" postgres
	@echo "$(DBHOST):$(DBPORT):*:$(DBUSER):$(DBPASS)" >> ~/.pgpass
ifneq ($(DBUSER), $(DBROLE))
	@psql -c "GRANT $(DBROLE) TO $(DBUSER);" postgres
endif

init: python postgresql

loopback_alias:
	sudo ifconfig lo0 alias $(INTERFACE)

loopback_alias_delete:
	sudo ifconfig lo0 -alias $(INTERFACE)

##########
#
# Utilities
#
##########

dropdb:
	-dropdb -w -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) $(DATABASE)
	@test -d $(FSTORE_PATH)/$(DATABASE) && rm -r $(FSTORE_PATH)/$(DATABASE) || exit 0

createdb:
	createdb -E UTF8 -T $(TMPL_DBNAME) -w -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) $(DATABASE)
	@test -d $(FSTORE_PATH)/$(TMPL_DBNAME) && cp -r $(FSTORE_PATH)/$(TMPL_DBNAME) $(FSTORE_PATH)/$(DATABASE) || exit 0

unset_as_template:
	@psql -c "ALTER DATABASE $(DATABASE) IS_TEMPLATE false;" postgres
	@psql -c "ALTER DATABASE $(DATABASE) OWNER TO $(DBUSER);" postgres

set_as_template:
	@psql -c "ALTER DATABASE $(DATABASE) IS_TEMPLATE true;" postgres
	@psql -c "ALTER DATABASE $(DATABASE) OWNER TO $(USER);" postgres

checkout_branch:
	git checkout $(BRANCH)

config:
	@. $(VENV)/$(PROJECT)/bin/activate && $(CWD)/server/odoo-bin -c $(CONFIGFILE) -s --load=base $(DBOPTIONS) $(IFOPTIONS) --addons-path=$(ADDONS) --stop-after-init

launch:
	@. $(VENV)/$(PROJECT)/bin/activate && $(CWD)/server/odoo-bin $(COMMAND) -c $(CONFIGFILE) $(OPTIONS) $(EXTRA_OPTIONS)

run: config launch

backup:
	@test -f database/$(DATABASE)$(NAME).tar.gz && rm database/$(DATABASE)$(NAME).tar.gz || exit 0
	tar cf database/$(DATABASE)$(NAME).tar --transform 's|^$(DATABASE)|filestore|' -C $(FSTORE_PATH) $(DATABASE)
	pg_dump -w -Fc -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) --role=$(DBROLE) -f database/$(DATABASE).pgdump $(DATABASE)
	tar rf database/$(DATABASE)$(NAME).tar --transform 's|$(DATABASE)|database|' -C database $(DATABASE).pgdump
	rm database/$(DATABASE).pgdump
	gzip database/$(DATABASE)$(NAME).tar

remote_backup:
	ssh $(REMOTE) "test -f $(REMOTE_PATH)/$(REMOTE_DBNAME)$(NAME).tar.gz && rm $(REMOTE_PATH)/$(REMOTE_DBNAME)$(NAME).tar.gz || exit 0"
	ssh $(REMOTE) "tar cf $(REMOTE_PATH)/$(REMOTE_DBNAME)$(NAME).tar --transform 's|^$(REMOTE_DBNAME)|filestore|' -C $(REMOTE_FSTORE_PATH) $(REMOTE_DBNAME)"
	ssh $(REMOTE) "pg_dump -w -Fc -h $(REMOTE_DBHOST) -p $(REMOTE_DBPORT) -U $(REMOTE_DBUSER) --role=$(REMOTE_DBROLE) -f $(REMOTE_PATH)/$(REMOTE_DBNAME).pgdump $(REMOTE_DBNAME)"
	ssh $(REMOTE) "tar rf $(REMOTE_PATH)/$(REMOTE_DBNAME)$(NAME).tar --transform 's|$(REMOTE_DBNAME)|database|' -C $(REMOTE_PATH) $(REMOTE_DBNAME).pgdump"
	ssh $(REMOTE) "rm $(REMOTE_PATH)/$(REMOTE_DBNAME).pgdump"
	ssh $(REMOTE) "gzip $(REMOTE_PATH)/$(REMOTE_DBNAME)$(NAME).tar"

download_backup:
	scp $(REMOTE):$(REMOTE_PATH)/$(REMOTE_DBNAME)$(NAME).tar.gz database/$(DATABASE)$(NAME).tar.gz

restore:
	-tar zxf database/$(DATABASE)$(NAME).tar.gz --transform 's|^filestore|$(DATABASE)|' -C $(FSTORE_PATH) filestore
	-tar zxf database/$(DATABASE)$(NAME).tar.gz -O database.pgdump | pg_restore -w -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) --role=$(DBROLE) -Ox -d $(DATABASE)
	psql -w -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) -f $(RESTOREFILE) $(DATABASE)

bup_restore:
	test -d $(BUP_PATH) || git --git-dir=$(BUP_PATH) clone --mirror git.syleam.net:backups/$(PROJECT) $(BUP_PATH)
	-git --git-dir=$(BUP_PATH) remote update
	-bup --bup-dir=$(BUP_PATH) join $$(git --git-dir=$(BUP_PATH) rev-list $$(git rev-parse --until='$(BUP_RESTORE_DATE) $(BUP_RESTORE_TIME)') --max-count=1 database/$(REMOTE_DBNAME)) | pg_restore -w -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) --role=$(DBROLE) -Ox -d $(DATABASE)
	mkdir -p $(FSTORE_PATH)/$(DATABASE)
	-bup --bup-dir=$(BUP_PATH) join $$(git --git-dir=$(BUP_PATH) rev-list $$(git rev-parse --until='$(BUP_RESTORE_DATE) $(BUP_RESTORE_TIME)') --max-count=1 filestore/$(REMOTE_DBNAME)) | tar xf - --strip-components=1 -C $(FSTORE_PATH)/$(DATABASE) $(REMOTE_DBNAME)
	psql -w -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) -f $(RESTOREFILE) $(DATABASE)

translate_base: dropdb createdb config dropdb
	@. $(VENV)/$(PROJECT)/bin/activate && $(CWD)/server/odoo-bin -c $(CONFIGFILE) -d $(DATABASE) -u $(MODULES) --stop-after-init
	@mkdir -p $(I18NDIR)
	@. $(VENV)/$(PROJECT)/bin/activate && $(CWD)/server/odoo-bin -c $(CONFIGFILE) -d $(DATABASE) --i18n-export=$(POTFILE) --modules=$(MODULES)
	@test -f $(POFILE) || cp $(POTFILE) $(POFILE)
	msgmerge -q --previous $(POFILE) $(POTFILE) -o $(POFILE)
	mv $(POTFILE) $(POTFILE)t
	vi $(POFILE)
	@. $(VENV)/$(PROJECT)/bin/activate && $(CWD)/server/odoo-bin -c $(CONFIGFILE) -d $(DATABASE) -l $(LANGCODE) --i18n-import=$(POFILE) --i18n-overwrite
	@. $(VENV)/$(PROJECT)/bin/activate && $(CWD)/server/odoo-bin -c $(CONFIGFILE) -d $(DATABASE) -l $(LANGCODE) --i18n-export=$(POFILE) --modules=$(MODULES)

doc_base:
	make -C $(DOC_PATH) $(DOC_DIRECTIVES)

##########
#
# Databases initialization
#
##########

new_db: OPTIONS=-d $(DATABASE) -u $(MODULES) --stop-after-init
new_db: dropdb createdb run
	psql -w -h $(DBHOST) -p $(DBPORT) -U $(DBUSER) -f $(RESTOREFILE) $(DATABASE)

template: DATABASE=$(DBNAME)_template
template: EXTRA_OPTIONS=-i $(MODULES) --without-demo=all
template: BRANCH=master
template: unset_as_template checkout_branch new_db set_as_template

test_template: DATABASE=$(DBNAME)_test_template
test_template: EXTRA_OPTIONS=-i $(MODULES)
test_template: BRANCH=master
test_template: unset_as_template checkout_branch new_db set_as_template

dev_db: DATABASE=$(DBNAME)_dev
dev_db: TMPL_DBNAME=$(DBNAME)_template
dev_db: new_db

backup_instance: DATABASE=$(DBNAME)$(INSTANCE)
backup_instance: backup

backup_master: INSTANCE=_master
backup_master: backup_instance

backup_dev: INSTANCE=_dev
backup_dev: backup_instance

restore_instance: DATABASE=$(DBNAME)$(INSTANCE)
restore_instance: dropdb createdb restore

restore_master: INSTANCE=_master
restore_master: restore_instance

restore_dev: INSTANCE=_dev
restore_dev: restore_instance

bup_master: INSTANCE=_master
bup_master: DATABASE=$(DBNAME)$(INSTANCE)
bup_master: MODULES=all
bup_master: EXTRA_OPTIONS=--stop-after-init
bup_master: dropdb createdb bup_restore upgrade

##########
#
# Remote databases management
#
##########

download_instance: DATABASE=$(DBNAME)$(INSTANCE)
download_instance: REMOTE=$(CUSTOMER)-$(subst _,,$(INSTANCE))
download_instance: MODULES=all
download_instance: EXTRA_OPTIONS=--stop-after-init
download_instance: remote_backup download_backup restore_instance upgrade

download_master: INSTANCE=_master
download_master: download_instance

##########
#
# Running Odoo
#
##########

run_instance: OPTIONS=-d $(DBNAME)$(INSTANCE)
run_instance: run

run_master: INSTANCE=_master
run_master: run_instance

run_preprod: INSTANCE=_preprod
run_preprod: run_instance

run_testing: INSTANCE=_testing
run_testing: run_instance

run_dev: INSTANCE=_dev
run_dev: run_instance

shell_master: COMMAND=shell
shell_master: run_master

shell_dev: COMMAND=shell
shell_dev: run_dev

upgrade: OPTIONS=-d $(DBNAME)$(INSTANCE) -u $(MODULES)
upgrade: run

upgrade_master: INSTANCE=_master
upgrade_master: upgrade

upgrade_preprod: INSTANCE=_preprod
upgrade_preprod: upgrade

upgrade_testing: INSTANCE=_testing
upgrade_testing: upgrade

upgrade_dev: INSTANCE=_dev
upgrade_dev: upgrade

test: DATABASE=$(DBNAME)_test
test: TMPL_DBNAME=$(DBNAME)_test_template
test: EXTRA_OPTIONS=--no-xmlrpc --test-enable
test: new_db

##########
#
# Translations
#
##########

translate: LANGUAGE=fr
translate: LANGCODE=fr_FR
translate: MODULE_CATEG=customer
translate: I18NDIR=$(CWD)/modules/$(MODULE_CATEG)/addons/$(MODULES)/i18n
translate: POTFILE=$(I18NDIR)/$(MODULES).po
translate: POFILE=$(I18NDIR)/$(LANGUAGE).po
translate: DATABASE=$(DBNAME)_i18n
translate: TMPL_DBNAME=$(DBNAME)_template
translate: translate_base

##########
#
# Documentation
#
##########

doc: DOC_DIRECTIVES=html latexpdf
doc: doc_base

doc-publish: DOC_DIRECTIVES=publish
doc-publish: doc_base

##########
#
# Custom scripts
#
##########
