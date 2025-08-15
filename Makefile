MANIFEST_INPUT_DIR=manifests
MANIFEST_OUTPUT_DIR=rendered-manifests

.PHONY: help render-manifests
.DEFAULT_GOAL := help

help: ## Show help
	@echo "Available targets:"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

check-remote-manifests:
	@for file in $$(find . -name "kustomization.yaml"); do \
		echo "Processing $$file"; \
		for url in $$(yq e '.resources[]' "$$file" | grep -E '^https?://'); do \
			echo "Checking $$url"; \
			attempt=1; \
			success=false; \
			while [ $$attempt -le 3 ] && [ "$$success" = "false" ]; do \
				response_size=$$(curl -fsSL --max-time 30 "$$url" --write-out '%{size_download}' -o /dev/null); \
				curl_exit_code=$$?; \
				if [ $$curl_exit_code -eq 0 ] && [ "$$response_size" -gt 0 ]; then \
					echo "OK ($$response_size bytes)"; \
					success=true; \
				else \
					echo "Attempt $$attempt failed for $$url"; \
					if [ $$attempt -lt 3 ]; then \
						echo "Retrying in 60 seconds..."; \
						sleep 60; \
					fi; \
				fi; \
				attempt=$$((attempt+1)); \
			done; \
			if [ "$$success" = "false" ]; then \
				echo "Failed to reach $$url after 3 attempts"; \
				exit 1; \
			fi; \
		done; \
	done

render-manifests: ## Render Kubernetes manifests using Kustomize
	$(eval TEMP_MANIFESTS_FILE := $(shell mktemp))
	kustomize build --enable-helm ${MANIFEST_INPUT_DIR} > ${TEMP_MANIFESTS_FILE}
	mkdir -p ${MANIFEST_OUTPUT_DIR}/crds
	yq 'select(.kind == "CustomResourceDefinition")' ${TEMP_MANIFESTS_FILE} > ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml
	yq eval 'del(.metadata.creationTimestamp) | del(.status)' -i ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml
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

validate: ## Validate rendered manifests
	kubeconform \
	  --schema-location default \
	  --schema-location https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json \
	  --schema-location https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/{{.NormalizedKubernetesVersion}}/{{.ResourceKind}}.json \
	  --schema-location https://json.schemastore.org/{{.ResourceKind}}.json \
	  --ignore-missing-schemas \
	  -- ${MANIFEST_OUTPUT_DIR}/**/*.yaml

render-and-validate: render-manifests test

clean-charts: ## Clean downloaded helm chart folders
	find manifests/ -type d -name "charts" -exec rm -rv {} +

clean-manifests: ## Clean generated manifests
	rm ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml
	rm ${MANIFEST_OUTPUT_DIR}/composite-resources/composite-resources.yaml
	rm ${MANIFEST_OUTPUT_DIR}/resources/resources.yaml

clean: clean-charts clean-manifests ## Clean generated manifests and helm charts
