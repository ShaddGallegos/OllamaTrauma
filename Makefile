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
	@echo "  deps          Install all Python dependencies (runtime+dev)"
	@echo "  deps-runtime  Install runtime dependencies only"
	@echo "  deps-dev      Install development/test dependencies only"
	@echo "  test          Run interactive menu test harness"
	@echo "  test-ci       Run menu harness in CI-safe mode"
	@echo "  lint-shell    Run shell lint checks (if shellcheck installed)"
	@echo "  lint-python   Run Python syntax checks"
	@echo "  check         Run lint + test suite"
	@echo "  help          Show this help message"
# BEGIN MANAGED BLOCK: configure
.PHONY: configure
configure:
	@echo "Configuring project (interactive wizard)..."
	TPL=""; \
	if [ -f templates/ansible.cfg.j2 ]; then TPL="templates/ansible.cfg.j2"; \
	elif [ -f ansible/templates/ansible.cfg.j2 ]; then TPL="ansible/templates/ansible.cfg.j2"; \
	elif [ -f scripts/templates/ansible.cfg.j2 ]; then TPL="scripts/templates/ansible.cfg.j2"; \
	fi; \
	if [ -n "$${TPL}" ] && [ -f scripts/python/generate_ansible_cfg.py ]; then \
	  python3 scripts/python/generate_ansible_cfg.py --project-root . --template "$${TPL}" --output ansible.cfg; \
	elif [ -n "$${TPL}" ]; then \
	  echo "Local renderer not found (scripts/python/generate_ansible_cfg.py)."; \
	  echo "Copying template to ansible.cfg as fallback."; \
	  cp "$${TPL}" ansible.cfg; \
	else \
	  echo "No ansible.cfg template found; creating minimal ansible.cfg fallback."; \
	  printf '%s\n' '[defaults]' 'host_key_checking = False' 'retry_files_enabled = False' 'stdout_callback = yaml' 'interpreter_python = auto_silent' > ansible.cfg; \
	fi
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
	@echo "Installing Python dependencies..."
	pip3 install -r requirements.txt

.PHONY: deps-runtime
deps-runtime:
	@echo "Installing runtime dependencies..."
	pip3 install -r requirements-runtime.txt

.PHONY: deps-dev
deps-dev:
	@echo "Installing development/test dependencies..."
	pip3 install -r requirements-dev.txt

.PHONY: test
test: deps
	@echo "Running menu test harness..."
	python3 test/test_runner.py || (echo "Tests failed. See test output for details." && exit 1)

.PHONY: test-ci
test-ci: deps
	@echo "Running menu test harness (CI mode)..."
	OT_CI_MODE=1 python3 test/test_runner.py || (echo "CI mode: warnings allowed." && exit 0)

.PHONY: lint-shell
lint-shell:
	@if command -v shellcheck >/dev/null 2>&1; then \
	  echo "Running shellcheck..."; \
	  shellcheck OllamaTrauma_v2.sh scripts/*.sh scripts/*/*.sh; \
	else \
	  echo "shellcheck not installed; skipping shell lint."; \
	fi

.PHONY: lint-python
lint-python:
	@echo "Running Python syntax checks..."
	@python3 -m py_compile OllamaTrauma_v2.py test/test_runner.py test/test_runner_pytest.py scripts/python/*.py

.PHONY: check
check: lint-shell lint-python
	@echo "Running pytest suite..."
	@pytest -q
