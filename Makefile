UNAME := $(shell uname)
ARCH := $(shell uname -m)

ifeq ($(UNAME), Linux)
	OS := linux
	EXT := so
else ifeq ($(UNAME), Darwin)
	OS := darwin
	EXT := dylib
else
	$(error Unsupported operating system: $(UNAME))
endif


BUILD_DIR := build

all: luajit

luajit: $(BUILD_DIR)/reqsign_aws.$(EXT)


define build_from_source
	cd lib_reqsign_aws && cargo build --release
	cp lib_reqsign_aws/target/release/liblua_reqsign_aws.$(EXT) $(BUILD_DIR)/reqsign_aws.$(EXT)
	cd lib_reqsign_aws && cargo clean
endef

$(BUILD_DIR)/reqsign_aws.$(EXT): $(BUILD_DIR)
	$(call build_from_source)


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

luacheck:
	luacheck `find -name "*.lua"` --codes

stylecheck:
	stylua --check lua/

stylefix:
	stylua lua/

