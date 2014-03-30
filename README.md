multi_dokku
===========

Prototype of dokku router (routing git pushes and HTTP)

# Prerequisites

- VirtualBox
- Vagrant (1.5+)

# Preparation

```
echo "192.168.50.2 flokku.dev app1.flokku.dev app2.flokku.dev" | sudo tee -a /etc/hosts
git clone https://github.com/sevos/multi_dokku.git
cd multi_dokku
vagrant up
```

After loooooonger while you will have 3 machines configured:

* router at 192.168.50.2
* first application server at 192.168.50.3
* second application server at 192.168.50.4

You can access etcd dashboard at http://192.168.50.2:4001/mod/dashboard

You need add your public ssh key to etcd in `/deployers` directory. The key stands
for user name and value should contain plain text public ssh key.

# Deploying an app

Before pushing application you need to configure router for it. Head to
[etcd dashboard](http://192.168.50.2:4001/mod/dashboard) and in lower section
add new key `/apps/app1` with value `192.168.50.3`. This will tell router to
deploy application to first app server and route HTTP traffic to it.

After that download sample nodejs app:

```
cd ..
git clone https://github.com/heroku/node-js-sample.git
cd node-js-sample
```

Add remote:

```
git remote add flokku git@flokku.dev:app1
```

and deploy app:

```
git push flokku master
```

You can reconfigure router, to have app1 on another server. After
changing setting in etcd dashboard you need to deploy the app again!
