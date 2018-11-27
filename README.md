[![Build Status](https://travis-ci.org/local-motion/bootstrap.svg?branch=master)](https://travis-ci.org/local-motion/bootstrap)

## Docker-compose - Set it all up

```
export LOCALMOTION_TARGET_DIR=~/dev/local-motion
curl -s -L https://gist.githubusercontent.com/errrrk/40acff3b97f27d08958054d07b56fd02/raw/c443b27993303d47139ca3bf51d99c7ae77fb43a/clone_all_github_repos.sh > clone_all_github_repos.sh \
    && chmod +x clone_all_github_repos.sh \
    && ./clone_all_github_repos.sh --organization local-motion --target-dir "${LOCALMOTION_TARGET_DIR}"
cd ${LOCALMOTION_TARGET_DIR}/bootstrap/development
./build_and_deploy_services.sh
```


## Kube - Set it all up

```
export LOCALMOTION_TARGET_DIR=~/dev/local-motion
curl -s -L https://gist.githubusercontent.com/errrrk/40acff3b97f27d08958054d07b56fd02/raw/c443b27993303d47139ca3bf51d99c7ae77fb43a/clone_all_github_repos.sh > clone_all_github_repos.sh \
    && chmod +x clone_all_github_repos.sh \
    && ./clone_all_github_repos.sh --organization local-motion --target-dir "${LOCALMOTION_TARGET_DIR}"
cd ${LOCALMOTION_TARGET_DIR}/bootstrap/development
./bootstrap_osx_native.sh --name localmotion --cleanup-first --yes
./k8s_build_and_deploy_services.sh
```
## Enter application
The entry point for the application is: localhost:3000/onboarding
