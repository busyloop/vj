SHELL=/bin/bash

test:
	bundle exec bundle-audit check --update
	bundle exec rubocop
