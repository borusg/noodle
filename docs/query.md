# Querying Noodle

# How to use Noodle
Noodle has a simple and intuitive query CLI: `noodle` often
abbreviated as simply `n`.  Examples:

List all production HR nodes:
```bash
n project=hr prodlevel=prod
bucatini.example.com
campanelle.example.com
conchigliette.example.com
leftoversalmon.example.com
```

Again, including site:
```bash
n project=hr prodlevel=prod site=
bucatini.example.com        site=mars
campanelle.example.com      site=jupiter
conchigliette.example.com   site=mars
leftoversalmon.example.com  site=jupiter
```

Again, including role:
```bash
n project=hr prodlevel=prod site= role=
bucatini.example.com        site=mars     role=mariadb,web
campanelle.example.com      site=jupiter  role=app,ssh
conchigliette.example.com   site=mars     role=db,elasticsearch
leftoversalmon.example.com  site=jupiter  role=house,sauna
```

Again but exclude nodes with role=ssh:
```bash
n project=hr prodlevel=prod site= role= @role=ssh
bucatini.example.com        site=mars     role=mariadb,web
conchigliette.example.com   site=mars     role=db,elasticsearch
leftoversalmon.example.com  site=jupiter  role=house,sauna
```

Find all nodes that have 'needle' defined and display the value(s) of needle
```bash
n needle?=
bucatini.example.com  needle=haystack
```

Find all nodes that have 'needle' defined
```bash
n needle?
bucatini.example.com  needle=haystack
```
