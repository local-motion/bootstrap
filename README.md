[![Build Status](https://travis-ci.org/local-motion/bootstrap.svg?branch=master)](https://travis-ci.org/local-motion/bootstrap)

## Set it all up

```
curl -s -L https://gist.githubusercontent.com/errrrk/40acff3b97f27d08958054d07b56fd02/raw/c443b27993303d47139ca3bf51d99c7ae77fb43a/clone_all_github_repos.sh > clone_all_github_repos.sh \
    && chmod +x clone_all_github_repos.sh \
    && ./clone_all_github_repos.sh --organization local-motion --target-dir ~/dev/local-motion
cd ~/dev/local-motion/bootstrap/development
./bootstrap_osx_native.sh --name localmotion --cleanup-first --yes
./build_and_deploy_services.sh
```
