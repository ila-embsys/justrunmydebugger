PREFIX ?= /usr/local
DESTDIR=
BIN=$(DESTDIR)$(PREFIX)/bin/

BUILD_DIR=src-tauri/target

.PHONY: all
all: build

.PHONY: build
build:
	yarn install
	yarn build:prod

install:
	cp $(BUILD_DIR)/release/justrunmydebugger $(BIN)

clean:
	rm -rf $(BUILD_DIR)/debug
	rm -rf $(BUILD_DIR)/release