# package-gui-lin-win


requires 3 secrets:
- `SSH_KEY` - paste the entire contents of the private key file into github secrets
- `USER`- ssh username
- `SCP_SERVER` - server ip address e.g. 192.1.0.1

Steps:
### Create ssh key and add to repo secrets
The `SSH_KEY` has to be a specific type supported by Posh-SSH.    
On your local machine run: (provide full path for filename e.g. `~/.ssh/new_key`)
```
ssh-keygen -m PEM -t rsa -b 4096
```
This will generate `new_key` and `new_key.pub`. 

Copy the entire contents of your private key `new_key` and paste it into a secret for this repo named `SSH_KEY`:

```
-----BEGIN RSA PRIVATE KEY-----
hunter2
-----END RSA PRIVATE KEY-----

```

While you're adding secrets, you may aswell add your `USER` and `SCP_SERVER` secrets too.

### Add key to remote server

Copy the local pub key from e.g `new_key.pub` because we're going to add it to the remote servers authorized keys.

ssh into your remote server e.g:
```
ssh plowsof@192.1.1.1
```

Paste the pub key on a new line inside `~/.ssh/authorized_keys` 

### Run the workflow
The default values are set to build v0.18.0.0 amd save packaged files to `/tmp` on the remote server. Cusomise this _but the directory/path MUST exist already or the script will error_    

![package](https://user-images.githubusercontent.com/77655812/179846501-00a21098-cda9-4517-b615-28ece442184a.png)
