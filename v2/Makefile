.PHONY: lint validate smoke-all

lint:
	@bash scripts/lint-shell.sh
	@bash scripts/lint-dockerfiles.sh

validate:
	@bash scripts/validate-s6.sh

# quick matrix over the 8.4 variants (tweak as you like)
smoke-all:
	@bash scripts/smoke.sh php/8.4/apache/Dockerfile     development 8081
	@bash scripts/smoke.sh php/8.4/nginx/Dockerfile      development 8082
	@bash scripts/smoke.sh php/8.4/frankenphp/Dockerfile development 8083
	@bash scripts/smoke.sh php/8.4/swoole/Dockerfile     development 8084
