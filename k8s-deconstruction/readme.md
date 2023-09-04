# K8S Deconstruction LAB
## Vagrant configuration to support hands-on kuberenetes introduction

## Whats in it?

- Quick local deployment of development-ready singlenode cluster based on kubeadm
- Lightweight CNI Bridge plugin to support POD Networking
- Containerd and nerdctl preinstalled for easiness of governance and configuration
- Added aliases that come along youtube video
- Some QOL improvements for k8s ops - kubectl alias and autocompletion, configured KUBEKONFIG variable to get admins taks done right from the go

Found this [particular video][df1] by James Spurin very useful on understanding k8s guts by deconstructing main components of cluster.

## Running solution
```sh
vagrant up && vagrant ssh --command "sudo bash"
```

   [df1]: <https://youtu.be/n4zxKk2an3U?si=CgnICnJnBdI80dkO>

