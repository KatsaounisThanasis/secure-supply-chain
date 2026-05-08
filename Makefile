SHELL := /usr/bin/env bash
.SHELLFLAGS := -eu -o pipefail -c

KIND_CLUSTER_NAME ?= secure-supply-chain
KYVERNO_NAMESPACE ?= kyverno
KYVERNO_RELEASE ?= kyverno
KYVERNO_CHART_VERSION ?= 3.8.0
IMAGE_TAG ?= $(shell git rev-parse HEAD)

.PHONY: help kind-up kyverno-install policy-apply demo-pass demo-fail kyverno-demo clean

help: ## Show available targets
	@echo "Available targets:"
	@grep -E '^[a-zA-Z0-9_.-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-16s %s\n", $$1, $$2}'

kind-up: ## Create kind cluster if it does not exist
	@if kind get clusters | grep -qx "$(KIND_CLUSTER_NAME)"; then \
		echo "kind cluster '$(KIND_CLUSTER_NAME)' already exists; skipping"; \
	else \
		kind create cluster --name "$(KIND_CLUSTER_NAME)" --config scripts/kind-config.yaml; \
	fi

kyverno-install: ## Install Kyverno in-cluster with Helm
	@helm repo add kyverno https://kyverno.github.io/kyverno >/dev/null 2>&1 || true
	@helm repo update >/dev/null
	@helm upgrade --install "$(KYVERNO_RELEASE)" kyverno/kyverno \
		--namespace "$(KYVERNO_NAMESPACE)" \
		--create-namespace \
		--version "$(KYVERNO_CHART_VERSION)" \
		--wait \
		--timeout 5m
	@kubectl -n "$(KYVERNO_NAMESPACE)" rollout status deployment/kyverno-admission-controller --timeout=5m

policy-apply: ## Apply demo namespace and Kyverno image verification policy
	@kubectl apply -f k8s/namespace.yaml -f k8s/kyverno-policy.yaml

demo-pass: ## Apply signed demo pod (override with IMAGE_TAG=<commit-sha>)
	@sed "s/__IMAGE_TAG__/$(IMAGE_TAG)/g" k8s/demos/pass-signed.yaml | kubectl apply -f -

demo-fail: ## Apply unsigned demo pod and assert admission rejection
	@set +e; kubectl apply -f k8s/demos/fail-unsigned.yaml; if [ $$? -ne 0 ]; then echo "OK: rejected as expected"; else echo "ERROR: should have been rejected"; exit 1; fi

kyverno-demo: kind-up kyverno-install policy-apply demo-pass demo-fail ## Run full local Kyverno enforcement demo

clean: ## Delete kind cluster
	@if kind get clusters | grep -qx "$(KIND_CLUSTER_NAME)"; then \
		kind delete cluster --name "$(KIND_CLUSTER_NAME)"; \
	else \
		echo "kind cluster '$(KIND_CLUSTER_NAME)' not found; nothing to clean"; \
	fi
