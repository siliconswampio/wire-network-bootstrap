include mkutils/meta.mk mkutils/help.mk

BUILDS_DIR ?= ./.builds

build-docker-compose: ##@local Build local docker-compose
	@rm -Rf $(BUILDS_DIR)/docker-compose.yml
	@mkdir -p $(BUILDS_DIR)
	@$(SHELL_EXPORT) envsubst <docker-compose.yml >$(BUILDS_DIR)/docker-compose.yml

build: ##@devops Builds a new  production docker image
build:
	@docker build \
		--target prod-stage \
		-t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(VERSION) \
		.

run-vault: ##@local Only run the vault service
run-vault: build-docker-compose
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml up -d vault

run: ##@local Build and run the blockchain locally (validator, wallet and writer-api)
run: build-docker-compose ## test
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml build
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml up -d
	
ifeq (,$(wildcard vault_keys.json))
	@echo "Generating vault keys... [vault_keys.json]"
	@sleep 5
	@curl \
		-X PUT \
		-d '{"secret_shares": 10, "secret_threshold": 5}' \
		http://localhost:8200/v1/sys/init | jq -r . > vault_keys.json
else
	@echo 'Vault keys already exist.'
endif
	@echo "Unsealing the vault..."
	@for key in $(shell jq -r '.keys_base64[5:][]' vault_keys.json); do \
		curl \
			-X PUT \
			-d "{\"key\": \"$$key\"}" \
			http://localhost:8200/v1/sys/unseal; \
	done

logs:
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml logs -f bios

stop: ##@local Stop all instances of the currently running services
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml stop

down: ##@local Stop all instances of the currently running services
	@docker-compose -f $(BUILDS_DIR)/docker-compose.yml down

run-shell: ##@devops Run ansible machine but just open up a shell
run-shell: build
	@docker run \
		-it \
		--add-host=naboo:$(NABOO_IP) \
		--add-host=alderaan:$(ALDERAAN_IP) \
		--add-host=hoth:$(HOTH_IP) \
		-e ANSIBLE_VAULT_PASSWORD=$(ANSIBLE_VAULT_PASSWORD) \
		--entrypoint bash \
		$(IMAGE_NAME):$(VERSION)
