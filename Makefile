#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

ENV_NAME = $(shell basename "$(CURDIR)")
ENV_DIR = $$(conda info --base)/envs/${ENV_NAME}

PYTHON_VERSION = 3.10
PYTHON_INTERPRETER = ${ENV_DIR}/bin/python${PYTHON_VERSION}
PIP = ${ENV_DIR}/bin/pip3

# Docker configurations
name_registry=template
repo=template
v=:0.0.0

#################################################################################
# COMMANDS                                                                      #
#################################################################################

## Initialize the project (set up environment, pre-commit hooks, etc.)
init:
	conda create -y --name ${ENV_NAME} python=${PYTHON_VERSION}
	${PIP} install -r requirements.txt
	${PYTHON_INTERPRETER} -m ipykernel install --user --name=${ENV_NAME}
	${ENV_DIR}/bin/pre-commit install

## Format the code w/ black, nbqa and isort
format:
	black .
	nbqa black .
	isort . --profile black

## Automatically create requirements.txt
requirements:
	${PYTHON_INTERPRETER} -m pipdeptree -d 0 > requirements.txt

## Run unittests
test:
	${PYTHON_INTERPRETER} -m pytest . --collect-only | grep -q "no tests collected" && echo "No tests collected" || ${PYTHON_INTERPRETER} -m pytest .


## Run all pre-commit hooks
pre-commit:
	${ENV_DIR}/bin/pre-commit run --all-files

## Run pre-commit hooks for CI (exclude no-commit-to-branch)
pre-commit-ci:
	SKIP=no-commit-to-branch make pre-commit

## Build docker image and push to registry
pushdck:
		az login --identity
		az acr login --name $(name_registry)
		sudo docker build --no-cache -t $(name_registry) .
		sudo docker tag $(name_registry) $(name_registry).azurecr.io/$(repo)$(v)
		sudo docker push $(name_registry).azurecr.io/$(repo)$(v)

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>
.PHONY: help
help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')
