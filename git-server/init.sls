#!stateconf -o yaml . jinja
#
# Install a git user with git-shell and add authorised users
########################################################################

{% set git_server = pillar.get('git-server', {}) %}
{% set git_home = git_server.get('server_root', '/srv/git') %}

.Git system package:
  pkg.installed:
    - name: git

.Git-server root directory:
  file.directory:
    - name: {{ git_home }}
    - user: git
    - group: git
    - dir_mode: 770
    - file_mode: 660
    - makedirs: True

.Git system user:
  user.present:
    - name: git
    - git_from_name: True
    - createhome: True
    - home: /srv/git
    - shell: /usr/bin/git-shell

.Git system user's authorized_keys files:
  file.managed:
    - name: {{ git_home ~ '/.ssh/authorized_keys' }}
    - user: git
    - group: git
    - file_mode: 600
    - dir_mode: 700
    - makedirs: True

# Add authorized git users from the 'users' pillar used by the users formula
{% for git_user in git_server.get('authorized_users', [] ) %}
  {% set public_keys = pillar['users'][git_user]['ssh_auth'] %}
  {% for public_key in public_keys %}
    {% set key_count = ' ' %}
    {% if loop.length > 1 %}
      {% set key_count = ' (' ~ loop.index ~ ' of ' ~ loop.length ~ ') ' %}
    {% endif %}

.Public key{{ key_count }}for Git-authorised user {{ git_user }}:
  file.append:
    - name: {{ git_home ~ '/.ssh/authorized_keys' }}
    - text: {{ public_key }}

  {% endfor %}
{% endfor %}

# Add contrib commands runnable by git-shell
.Command directory for git-shell:
  file.directory:
    - name: {{ git_home ~ '/git-shell-commands' }}
    - user: git
    - group: git
    - dir_mode: 750

{% for cmd in ('help', 'list') %}

.Copy contrib git-shell command '{{ cmd }}':
  file.copy:
    - name: {{ git_home ~ '/git-shell-commands/' ~ cmd }}
    - source: /usr/share/doc/git/contrib/git-shell-commands/{{ cmd }}

.Permissions on contrib git-shell command '{{ cmd }}':
  file.managed:
    - name: {{ git_home ~ '/git-shell-commands/' ~ cmd }}
    - user: git
    - group: git
    - mode: 750

{% endfor %}

# Add contrib commands runnable by git-shell
{% for cmd in ('create', 'addkey') %}

.Git shell command '{{ cmd }}':
  file.managed:
    - name: {{ git_home ~ '/git-shell-commands/' ~ cmd }}
    - source: salt://git-server/templates/{{ cmd }}
    - user: git
    - group: git
    - mode: 750

{% endfor %}
