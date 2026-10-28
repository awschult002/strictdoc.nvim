NVIM ?= nvim

test:
	$(NVIM) --headless -u NONE -i NONE -l tests/run.lua
	XDG_DATA_HOME=$$(mktemp -d) $(NVIM) --headless -u NONE -i NONE -l tests/pack_add.lua

.PHONY: test
