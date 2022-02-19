#!/bin/bash

cfn_templates_dir='./cfn/templates'
drawio_diagram_dir='./docs/drawio'

for cfn_template_file in $(ls -F $cfn_templates_dir | grep -v '/')
do
  echo $cfn_template_file
  ./node_modules/.bin/cfn-dia draw.io -c -t ${cfn_templates_dir}/${cfn_template_file} -o ${drawio_diagram_dir}/${cfn_template_file}.drawio
done
