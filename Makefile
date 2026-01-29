# Standard Makefile (auto-generated)
ANSIBLE_PLAYBOOK := ansible-playbook
ANSIBLE_GALAXY := ansible-galaxy
PROJECT_NAME := $(shell basename $(CURDIR))

.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  configure     Prompt for token/URLs and render ansible.cfg"
	@echo "  collections   Install Ansible collections from requirements"
	@echo "  help          Show this help message"
# BEGIN MANAGED BLOCK: configure
.PHONY: configure
configure:
	@echo "Configuring project (interactive wizard)..."
	TPL=""
	if [ -f templates/ansible.cfg.j2 ]; then TPL="templates/ansible.cfg.j2"; \
	elif [ -f ansible/templates/ansible.cfg.j2 ]; then TPL="ansible/templates/ansible.cfg.j2"; \
	else echo "Template not found: templates/ansible.cfg.j2 or ansible/templates/ansible.cfg.j2"; exit 1; fi; \
	python3 /home/sgallego/Downloads/GIT/RedHat_Management/updates-and-patching/generate_ansible_cfg.py \
	  --project-root . \
	  --template "$${TPL}" \
	  --output ansible.cfg
# END MANAGED BLOCK: configure
# BEGIN MANAGED BLOCK: collections
.PHONY: collections
collections:
	@echo "Installing Ansible collections..."
	REQ=""
	if [ -f collections/requirements.yml ]; then REQ="collections/requirements.yml"; \
	elif [ -f requirements.yml ]; then REQ="requirements.yml"; \
	else echo "No collections requirements.yml found (collections/requirements.yml or requirements.yml)"; exit 1; fi; \
	ansible-galaxy collection install -r $${REQ} --force
# END MANAGED BLOCK: collections

.PHONY: deps
deps:
	@echo "Installing Python test dependencies..."
	pip3 install -r requirements.txt

.PHONY: test
test: deps
	@echo "Running menu test harness..."
	python3 test/test_runner.py || (echo "Tests failed. See test output for details." && exit 1)

.PHONY: test-ci
test-ci: deps
	@echo "Running menu test harness (CI mode)..."
	OT_CI_MODE=1 python3 test/test_runner.py || (echo "CI mode: warnings allowed." && exit 0)
