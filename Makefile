PREFIX ?= /usr/local
DESTDIR=
BIN=$(DESTDIR)$(PREFIX)/bin/

BUILD_DIR=src-tauri/target

.PHONY: all
all: build

.PHONY: build
build:
	yarnpkg install
	yarnpkg build:prod

.PHONY: install:
install:
	cp $(BUILD_DIR)/release/justrunmydebugger $(BIN)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)/debug
	rm -rf $(BUILD_DIR)/release