git for OpenComputer
====================

Seen these cool projects on github? Pain to download? This program is for you!

Installation
------------
The easiest way to install this project on your computer is by running:

    pastebin run kydcWA2y NeOzay/git-for-OpenComputer [<branch>]

The branch or tag argument is optional, and defaults to 'master'.

Usage
-----

### Cloning a repo
    git clone [--b=<branchname> | --t=<tagname> | -r] [--d=<path>|--d] [--i=<exe>|--i|--I=<exe>] [--a=<username>] <user>/<repo> [<destination>]

The branch and tag arguments are optional, and default to 'master'.  You may only specify a branch or tag, you may not specify both.

The destination folder is optional, and defaults to the current folder name. Watch out - this script will happily overwrite any existing files!

The Authentication argument is optional. You must first create a user with `github auth` (see below) to use the authorized requests.

    fetch repo
    check available space
    start Downloading:
     [1 / 5]  /.package.lua
     [2 / 5]  /bin/git.lua
     [3 / 5]  /lib/dkjson.lua
     [4 / 5]  /lib/github.lua
     [5 / 5]  /usr/man/git


### Adding Authentication
To use authenticated requests you must first [create a github](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) api token on your github account. You do not need to provide any api scopes for the token unless you plan on accessing private repositories.

    git auth <user> [<api token> | -d]

The delete argument is optional and will delete the specified user.

**Warning:** data provided to `git auth` will be stored locally on the computer in clear text . You can delete the access token at anytime by hitting the delete button in your personal [access tokens menu](https://github.com/settings/tokens) on github.
---

Thanks to David Kolf for his [dkjson](http://chiselapp.com/user/dhkolf/repository/dkjson/home) module, which made parsing github APIs possible.

this project is a fork/adaptation of [computercraft-github](https://github.com/eric-wieser/computercraft-github/tree/master) for OpenComputer, thanks to its author for teaching me how to use HTTP methods to use the github api.