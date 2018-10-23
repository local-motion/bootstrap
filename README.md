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


## Development

The sample nginx application currently lives at https://github.com/errrrk/community-web and will be moved to https://github.com/local-motion/community-web when license has been resolved

1. First setup the local Kube cluster. This step assumes you have Docker-for-Desktop installed on OSX.
    ```
    git clone git@github.com:local-motion/bootstrap.git
    cd bootstrap/development
    ./bootstrap_osx_native.sh -n localmotion
    kube apply -f community-loadbalancer.yml
    ```
1. And then deploy the sample application:
    ```
    git clone git@github.com:errrrk/community-web.git
    cd community-web
    kube apply -f kube/service.yml
    ```

1. Visit the static nginx react/redux/material-ui webapp at [http://localhost:10000](http://localhost:10000)
