# Run from repo root with:  make -C v2/tests
# Or: cd v2/tests && make

PORT_BASE ?= 9300
TARGET    ?= development

# Test pairs: "<Dockerfile path under .docker/v2> <server>"
PAIRS ?= \
  php/8.4/nginx/Dockerfile nginx \
  php/8.4/apache/Dockerfile apache \
  php/8.4/frankenphp/Dockerfile frankenphp

.PHONY: all test matrix runtime-nginx docky goss clean

all: test
test: matrix

matrix:
	@PORT_BASE=$(PORT_BASE) TARGET=$(TARGET) \
		bash scripts/test-matrix.sh $(PAIRS)

# quick single run example (nginx)
runtime-nginx:
	@bash scripts/test-runtime.sh php/8.4/nginx/Dockerfile $(TARGET) $(PORT_BASE) nginx

docky:
	@bash test-docky.sh

goss:
	@echo "Run with dgoss if you have it installed:"
	@echo "  DGOSS_WAIT=30 dgoss run -p 8099:80 -v $$PWD/fixtures/php/99-test.ini:/usr/local/etc/php/conf.d/99-test.ini:ro \
	-v $$PWD/fixtures/overlays/hello-svc:/opt/overlay/hello-svc:ro -e OVERLAY_DIRS=/opt/overlay \
	$$(basename $$(dirname $$(dirname php/8.4/nginx/Dockerfile)))-temp-image"

clean:
	@docker ps -aq --filter "name=mani-test-" | xargs -r docker rm -f
	@docker images -q "mani-test-*" | xargs -r docker rmi -f
