MANIFEST_INPUT_DIR=manifests
MANIFEST_OUTPUT_DIR=rendered-manifests

.PHONY: help render-manifests
.DEFAULT_GOAL := help

help: ## Show help
	@echo "Available targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

start-dev-cluster: ## Start a local minikube development cluster
	minikube start

stop-dev-cluster: ## Stop the local minikube development cluster
	minikube stop

render-manifests: ## Render Kubernetes manifests using Kustomize
	$(eval TEMP_MANIFESTS_FILE := $(shell mktemp))
	kustomize build --enable-helm ${MANIFEST_INPUT_DIR} > ${TEMP_MANIFESTS_FILE}
	mkdir -p ${MANIFEST_OUTPUT_DIR}/crds
	yq 'select(.kind == "CustomResourceDefinition")' ${TEMP_MANIFESTS_FILE} > ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml
	yq -i 'del(select(.kind == "CustomResourceDefinition"))'  ${TEMP_MANIFESTS_FILE} ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml
	mkdir -p ${MANIFEST_OUTPUT_DIR}/composite-resources
	export XR_APIVERSIONS=$$(yq ea -o=json -I=0 '[.spec.compositeTypeRef.apiVersion]' ${TEMP_MANIFESTS_FILE}) && \
	export XR_KINDS=$$(yq ea -o=json -I=0 '[.spec.compositeTypeRef.kind]' ${TEMP_MANIFESTS_FILE}) && \
	yq "select(.apiVersion == $$XR_APIVERSIONS[] and .kind == $$XR_KINDS[])" ${TEMP_MANIFESTS_FILE} > ${MANIFEST_OUTPUT_DIR}/composite-resources/composite-resources.yaml && \
	yq -i "del(select(.apiVersion == $$XR_APIVERSIONS[] and .kind == $$XR_KINDS[]))" ${TEMP_MANIFESTS_FILE}
	mkdir -p ${MANIFEST_OUTPUT_DIR}/resources
	cp ${TEMP_MANIFESTS_FILE} ${MANIFEST_OUTPUT_DIR}/resources/resources.yaml
	rm ${TEMP_MANIFESTS_FILE}

rendered-manifests-diff: render-manifests ## Render Kubernetes manifests and show the diff from the rendered_manifests branch
	# Create temporary directory
	$(eval TEMP_DIR := $(shell mktemp -d))
	@echo "Created temporary directory: $(TEMP_DIR)"
	
	# Clone rendered_manifests branch to temp directory
	@echo "Checking out rendered_manifests to temporary directory..."
	git worktree add $(TEMP_DIR) rendered_manifests
	
	# Copy rendered manifests to temp directory
	cp -r rendered-manifests/* $(TEMP_DIR)
	
	# Go to temp directory and generate diff
	@echo "Generating diff..."
	cd $(TEMP_DIR) && git --no-pager diff --color
	
	# Clean up
	@echo "Cleaning up temporary directory..."
	git worktree remove --force $(TEMP_DIR)
	rm -rf $(TEMP_DIR)
	@echo "Done"

apply-rendered-crds: ## Apply rendered CRDs, needed for dry-run (ref https://github.com/kubernetes/kubectl/issues/711)
	kubectl apply --server-side -f ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml

test: apply-rendered-crds ## Test rendered manifests (dry-run)
	yq ${MANIFEST_OUTPUT_DIR}/resources/*.yaml | kubectl apply --dry-run=client -f -

render-and-test: render-manifests test

clean-charts: ## Clean downloaded helm chart folders
	find manifests/ -type d -name "charts" -exec rm -rv {} +

clean-manifests: ## Clean generated manifests
	rm ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml
	rm ${MANIFEST_OUTPUT_DIR}/composite-resources/composite-resources.yaml
	rm ${MANIFEST_OUTPUT_DIR}/resources/resources.yaml

clean: clean-charts clean-manifests ## Clean generated manifests and helm charts
