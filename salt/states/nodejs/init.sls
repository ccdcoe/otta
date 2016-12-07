{% set vars = pillar['nodejs'] %}

{{vars['build_dir']}}:
  file.directory:
    - makedirs: True
{{vars['deploy_dir']}}:
  file.directory:
    - makedirs: True

download_nodejs:
  cmd.run:
    - cwd: {{vars['build_dir']}}
    - shell: /bin/bash
    - name: wget https://nodejs.org/dist/v{{vars['version']}}/node-v{{vars['version']}}-linux-x64.tar.xz -O {{vars['build_dir']}}/nodejs-{{vars['version']}}.tar.xz
    - unless: find {{vars['build_dir']}} -type f -name '*{{vars['version']}}*' | egrep '.*'

deploy_nodejs:
  cmd.run:
    - cwd: {{vars['build_dir']}}
    - shell: /bin/bash
    - name: tar -xJf nodejs-{{vars['version']}}.tar.xz -C {{vars['deploy_dir']}}
    - unless: which node && node -v | grep {{vars['version']}}

/usr/bin/node:
  file.symlink:
    - target: {{vars['deploy_dir']}}/node-v{{vars['version']}}-linux-x64/bin/node
/usr/bin/npm:
  file.symlink:
    - target: {{vars['deploy_dir']}}/node-v{{vars['version']}}-linux-x64/lib/node_modules/npm/bin/npm-cli.js
