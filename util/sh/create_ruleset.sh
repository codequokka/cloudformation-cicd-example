#!/bin/bash

cfn_templates_dir='./cfn/templates'
guard_rulesets_dir='./cfn/rulesets'

for cfn_template_file in $(ls -F $cfn_templates_dir | grep -v '/')
do
  echo $cfn_template_file
  cfn-guard rulegen --template ${cfn_templates_dir}/${cfn_template_file} > ${guard_rulesets_dir}/${cfn_template_file}.ruleset
done
