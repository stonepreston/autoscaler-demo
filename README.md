# Autoscaler Demo
This repository houses the scripted demo of the [Kubernetes Autoscaler Charm](https://charmhub.io/kubernetes-autoscaler). It also houses the mocks used to supply command output. 

## Cloning the repo
[demo-magic](https://github.com/paxtonhare/demo-magic) is included as a gitsubmodule. Ensure you clone recursively:
```
git clone --recurse-submodules https://github.com/stonepreston/autoscaler-demo.git
```

## Dependencies
PipeViewer is required:
```
sudo apt install pv
```

## Running the demo
The script automatically proceeds through the demo, waiting a few seconds after typing each command. 
```
./demo_script.sh
```

## Recording the demo
Asciinema can be used to create a recording of the demo. To install:
```
sudo apt-add-repository ppa:zanchey/asciinema
sudo apt-get update
sudo apt-get install asciinema
```

To record:
```
asciinema rec -c "./demo_script.sh" myrecording
```

