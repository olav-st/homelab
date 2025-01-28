MANIFEST_INPUT_DIR=kubernetes/manifests/desired
MANIFEST_OUTPUT_DIR=kubernetes/manifests/rendered

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

apply-rendered-crds: ## Apply rendered CRDs, needed for dry-run (ref https://github.com/kubernetes/kubectl/issues/711)
	kubectl apply --server-side -f ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml

test: apply-rendered-crds ## Test rendered manifests (dry-run)
	yq ${MANIFEST_OUTPUT_DIR}/resources/*.yaml | kubectl apply --dry-run=client -f -

render-and-test: render-manifests test

clean-charts: ## Clean downloaded helm chart folders
	find kubernetes/manifests/ -type d -name "charts" -exec rm -rv {} +

clean-manifests: ## Clean generated manifests
	rm ${MANIFEST_OUTPUT_DIR}/crds/crds.yaml
	rm ${MANIFEST_OUTPUT_DIR}/composite-resources/composite-resources.yaml
	rm ${MANIFEST_OUTPUT_DIR}/resources/resources.yaml

clean: clean-charts clean-manifests ## Clean generated manifests and helm charts
