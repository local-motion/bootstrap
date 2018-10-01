[![Build Status](https://travis-ci.org/local-motion/bootstrap.svg?branch=master)](https://travis-ci.org/local-motion/bootstrap)


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
