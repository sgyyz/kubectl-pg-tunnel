.PHONY: help lint test install uninstall clean check setup-hooks dev-setup release

help:
	@echo "kubectl-pg-tunnel - Development Commands"
	@echo ""
	@echo "Available targets:"
	@echo "  make dev-setup  - Install development dependencies"
	@echo "  make setup-hooks- Set up git pre-commit hooks"
	@echo "  make lint       - Run shellcheck on all scripts"
	@echo "  make test       - Run BATS test suite"
	@echo "  make check      - Run both lint and test"
	@echo "  make install    - Install the plugin locally"
	@echo "  make uninstall  - Uninstall the plugin"
	@echo "  make clean      - Remove temporary files"
	@echo "  make release    - Prepare a new release (usage: make release VERSION=1.0.0)"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "First time setup:"
	@echo "  1. make dev-setup    (installs shellcheck, bats, yq)"
	@echo "  2. make setup-hooks  (installs git pre-commit hook)"
	@echo "  3. make check        (verify everything works)"
	@echo ""
	@echo "Release process:"
	@echo "  1. make release VERSION=1.0.0"
	@echo "  2. git push origin main --tags"
	@echo "  3. GitHub Actions will create the release automatically"
	@echo ""
	@echo "Prerequisites:"
	@echo "  shellcheck - brew install shellcheck"
	@echo "  bats       - brew install bats-core"
	@echo "  yq         - brew install yq"
	@echo ""

lint:
	@echo "Running shellcheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck kubectl-pg_tunnel && \
		shellcheck install.sh && \
		shellcheck uninstall.sh && \
		echo "✓ All shellcheck tests passed!"; \
	else \
		echo "Error: shellcheck not found. Install with: brew install shellcheck"; \
		exit 1; \
	fi

test:
	@echo "Running BATS tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/pg_tunnel_test.bats; \
	else \
		echo "Error: bats not found. Install with: brew install bats-core"; \
		exit 1; \
	fi

check: lint test
	@echo "✓ All checks passed!"

install:
	@echo "Installing kubectl-pg-tunnel..."
	@./install.sh

uninstall:
	@echo "Uninstalling kubectl-pg-tunnel..."
	@./uninstall.sh

clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.log" -delete
	@find . -name "*.tmp" -delete
	@echo "✓ Clean complete"

setup-hooks:
	@echo "Setting up git hooks..."
	@if [ -d .git ]; then \
		git config core.hooksPath .githooks && \
		echo "✓ Git hooks configured to use .githooks/"; \
		echo "✓ Pre-commit hook will run shellcheck automatically"; \
	else \
		echo "Error: Not a git repository"; \
		exit 1; \
	fi

dev-setup:
	@echo "Running development setup..."
	@./dev-setup.sh

release:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required"; \
		echo "Usage: make release VERSION=1.0.0"; \
		exit 1; \
	fi
	@echo "Preparing release v$(VERSION)..."
	@./scripts/prepare-release.sh $(VERSION)
	@echo ""
	@echo "Release prepared! Review changes and then:"
	@echo "  git push origin main --tags"
