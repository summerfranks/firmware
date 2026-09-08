# Use make install to install ghdl and gtkwave

RTL_DIR   := ..
TB_DIR    := .
WORK_DIR  := work
WAVES_DIR := waves
RUN_JOBS  ?= 8

GHDL_FLAGS := --std=08 -fsynopsys -frelaxed --workdir=$(WORK_DIR)

# We need these to build cgraph types first so other cgraph things can be built
COMMON_RTL_FILES := \
	$(RTL_DIR)/CGraphTypes.vhd \
	$(RTL_DIR)/CGraphDmTypes.vhd

TB_FILES := $(notdir $(wildcard $(TB_DIR)/*_tb.vhd))
TB_NAMES := $(patsubst %_tb.vhd,%,$(TB_FILES))
RTL_FILES := $(filter-out $(COMMON_RTL_FILES),$(patsubst %_tb.vhd,$(RTL_DIR)/%.vhd,$(TB_FILES)))
ALL_RTL_FILES := $(notdir $(wildcard $(RTL_DIR)/*.vhd))

PASS := \033[0;32m
FAIL := \033[0;31m
NC   := \033[0m

.PHONY: all build rebuild clean install help FORCE

$(WORK_DIR):
	@mkdir -p $@

build: | $(WORK_DIR)
	@ghdl -a $(GHDL_FLAGS) $(TB_DIR)/tb_utils_pkg.vhd
	@for f in $(COMMON_RTL_FILES); do \
		[ -f $$f ] && ghdl -a $(GHDL_FLAGS) $$f; \
	done
	@for f in $(RTL_FILES) $(TB_FILES:%=$(TB_DIR)/%); do \
		[ -f $$f ] && ghdl -a $(GHDL_FLAGS) $$f; \
	done
	@for tb in $(TB_NAMES); do \
		ghdl -e $(GHDL_FLAGS) $${tb}_tb; \
	done

rebuild: clean build

define run_tb
	@LOG=$(WORK_DIR)/$1_tb_output.log; \
	rm -f "$$LOG"; \
	if ghdl -r $(GHDL_FLAGS) $1_tb $2 >"$$LOG" 2>&1 && \
	   ! grep -qE 'error:|FAIL:' "$$LOG"; then \
		printf "$(PASS)$1_tb$(NC)\n"; \
	else \
		printf "$(FAIL)$1_tb$(NC)\n"; \
	fi
endef

all: build
	@$(MAKE) --no-print-directory --output-sync=target -j$(RUN_JOBS) $(TB_NAMES:%=%.run)
	@sh ./update_doxygen_baud.sh $(WORK_DIR) $(TB_DIR)
	@! grep -rlE 'error:|FAIL:' $(TB_NAMES:%=$(WORK_DIR)/%_tb_output.log) 2>/dev/null | grep -q .

%.run: FORCE
	$(call run_tb,$*)

%.sim: build
	@ghdl -r $(GHDL_FLAGS) $*_tb 2>&1 | tee $(WORK_DIR)/$*_tb_output.log; \
	! grep -qE 'error:|FAIL:' $(WORK_DIR)/$*_tb_output.log

%.wav: build
	@ghdl -r $(GHDL_FLAGS) $*_tb --wave=$(WORK_DIR)/$*_tb.ghw
	@if [ -f $(WAVES_DIR)/$*.gtkw ]; then \
		gtkwave -a $(WAVES_DIR)/$*.gtkw $(WORK_DIR)/$*_tb.ghw & \
	else \
		gtkwave $(WORK_DIR)/$*_tb.ghw & \
	fi

coverage:
	@total_num=0; \
	covered_num=0; \
	for rtl in $(ALL_RTL_FILES); do \
		total_num=$$((total_num + 1)); \
		tb_name=$${rtl%.vhd}_tb.vhd; \
		if [ -f "$(TB_DIR)/$$tb_name" ]; then \
			covered_num=$$((covered_num + 1)); \
		fi; \
	done; \
	if [ "$$total_num" -eq 0 ]; then \
		covered_percent=0; \
	else \
		covered_percent=$$((covered_num * 100 / total_num)); \
	fi; \
		printf "Testbench coverage: %s%% (%s/%s RTL files have testbenches)\n" \
			"$$covered_percent" "$$covered_num" "$$total_num"; \
		printf "Covered RTL files:\n"; \
	for rtl in $(ALL_RTL_FILES); do \
		tb_name=$${rtl%.vhd}_tb.vhd; \
		if [ -f "$(TB_DIR)/$$tb_name" ]; then \
			printf "  %s\n" "$$rtl"; \
		fi; \
	done; \
	printf "Uncovered RTL files:\n"; \
	for rtl in $(ALL_RTL_FILES); do \
		tb_name=$${rtl%.vhd}_tb.vhd; \
		if [ ! -f "$(TB_DIR)/$$tb_name" ]; then \
			printf "  %s\n" "$$rtl"; \
		fi; \
	done

clean:
	rm -rf $(WORK_DIR) *.cf *.vcd *.ghw *.log

install:
	sudo apt-get update && sudo apt-get install -y ghdl gtkwave

help:
	@printf "Targets:\n"
	@printf "  make build      Build all testbenches\n"
	@printf "  make all        Build + run all in parallel ($(RUN_JOBS) jobs)\n"
	@printf "  make <n>.sim    Build and run one testbench\n"
	@printf "  make <n>.wav    Build and open waveform\n"
	@printf "  make coverage   Show %% of RTL files with matching *_tb.vhd testbenches\n"
	@printf "  make install    Install required dependencies\n"
	@printf "  make clean      Remove build artifacts\n"
