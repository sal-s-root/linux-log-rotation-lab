.PHONY: test
test:
	bash -n logger.sh drill.sh
	shellcheck logger.sh drill.sh
	bash drill.sh
