#!/usr/bin/env python
##
# Copyright 2013 Ghent University
#
# This file is part of optcomplete-deps,
# originally created by the HPC team of Ghent University (http://ugent.be/hpc/en),
# with support of Ghent University (http://ugent.be/hpc),
# the Flemish Supercomputer Centre (VSC) (https://vscentrum.be/nl/en),
# the Hercules foundation (http://www.herculesstichting.be/in_English)
# and the Department of Economy, Science and Innovation (EWI) (http://www.ewi-vlaanderen.be/en).
#
# http://github.com/hpcugent/optcomplete-deps
#
# optcomplete-deps is free software: you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as
# published by the Free Software Foundation, either version 2 of
# the License, or (at your option) any later version.
#
# optcomplete-deps is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public License
# along with optcomplete-deps. If not, see <http://www.gnu.org/licenses/>.
##
"""
optcomplete-deps install script

@author: Kenneth Hoste (Ghent University)
"""

from setuptools import setup

PACKAGE = {
    'name': 'optcomplete-deps',
    'version': '0.1',
    'author': ('Stijn De Weirdt', 'stijn.deweirdt@ugent.be'),
    'maintainer': ('Stijn De Weirdt', 'stijn.deweirdt@ugent.be'),
    'packages': [],
    'namespace_packages': [],
    'provides': [],
    'scripts': ['minimal_bash_completion.bash'],
    'install_requires': [],
}
setup(**PACKAGE)
