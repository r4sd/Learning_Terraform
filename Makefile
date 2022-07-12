TERRAFORM := terraform

.PHONY: init
init:
	$(TERRAFORM) init

.PHONY: plan
plan:
	$(TERRAFORM) plan

.PHONY: apply
apply:
	$(TERRAFORM) apply

.PHONY: validate
validate:
	$(TERRAFORM) validate

.PHONY: show
show:
	$(TERRAFORM) show

.PHONY: destroy
destroy:
	$(TERRAFORM) destroy
